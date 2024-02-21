# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# required package for targets
library(targets)
library(tarchetypes)

# authenticate to googleCloudStorage
gargle::credentials_service_account(
        scopes = c("https://www.googleapis.com/auth/devstorage.full_control",
                   "https://www.googleapis.com/auth/cloud-platform"),
        path = gargle::secret_decrypt_json(
                path = ".secrets/gcp_demos",
                key = 'GCS_AUTH_KEY'
        )
)

# packages
tar_option_set(
        packages = c("dplyr",
                     "tidyr", 
                     "readr",
                     "pins",
                     "DBI",
                     "bigrquery",
                     "bggUtils",
                     "googleCloudStorageR",
                     "here"),
        repository = "gcp",
        resources = tar_resources(
                gcp = tar_resources_gcp(
                        bucket = "bgg_data",
                        prefix = "raw"
                )
        )
)

# # authenticate to bigquery
# gcp_connect =
#         bigrquery::bq_auth(
#                 path = gargle::secret_decrypt_json(
#                         path = ".secrets/gcp_demos",
#                         key = 'GCS_AUTH_KEY'
#                 )
#         )

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# functions relating to bigquery
# tar_source(here::here("src", "data", "connect_to_bigquery.R"))

# functions to load data
tar_source(here::here("src", "data", "load_data.R"))

# functions for authenticating to big query
bigquery_authenticate = function(path = ".secrets/gcp_demos",
                                 key = "GCS_AUTH_KEY") {
        
        bq_auth(
                path = gargle::secret_decrypt_json(
                        path = path,
                        key = key
                )
        )
}

# establish database connection
bigquery_connect = function(gcp_project_id = Sys.getenv("GCS_PROJECT_ID"), 
                            bq_schema = "bgg",
                            ...) {
        
        bigquery_authenticate(...)
        
        bigrquery::dbConnect(
                bigrquery::bigquery(),
                project = gcp_project_id,
                dataset = bq_schema
        )
        
}

# function to write table
write_table = function(name, ...) {
        
        message(glue::glue("writing {name}..."))
        
        dbWriteTable(
                ...,
                name = name
        )
        
        message("done.")
        name
        
}


# targets
list(
        # load universe of ids courtesy of https://bgg.activityclub.org/bggdata/
        tar_target(
                name = bgg_ids,
                command = {
                        tmp = get_bgg_ids()
                        attr(tmp, "timestamp") <- Sys.time()
                        tmp
                },
                cue = tarchetypes::tar_cue_age(
                        name = bgg_ids,
                        age = as.difftime(7, units = "days")
                )
        ),
        # filter to game ids
        tar_target(
                name = game_ids,
                command = 
                        bgg_ids |>
                        filter(type == 'boardgame')
        ),
        # create batches of ids
        tar_plan(
                req_game_ids = game_ids$id,
                batch_numbers = ceiling(seq_along(req_game_ids) / 500)
        ),
        # append to ids and add groups
        tar_target(
                name = req_game_batches,
                command = 
                        game_ids |>
                        add_column(batch = batch_numbers) %>%
                        group_by(batch) %>%
                        tar_group(),
                iteration = "group"
        ),
        # submit these in batches to API
        tar_target(
                resp_game_batches,
                command = 
                        {
                                b = req_game_batches %>%
                                        pull(batch) %>%
                                        unique()
                                
                                message(paste("batch", b, "of", max(batch_numbers)))
                                
                                req_game_batches %>%
                                        pull(id) %>%
                                        bggUtils::get_bgg_games(
                                                batch_size = 500,
                                                simplify = T,
                                                tidy = T,
                                                toJSON = F
                                        )
                        },
                pattern = map(req_game_batches)
        ),
        # add in batch id
        tar_target(
                name = games_batch,
                command = {
                        batch_timestamp = attr(bgg_ids, "timestamp")
                        
                        resp_game_batches |>
                                unnest(data, keep_empty = F) %>%
                                select(game_id,
                                       type,
                                       info, 
                                       names,
                                       links, 
                                       statistics,
                                       ranks,
                                       polls) %>%
                                add_column(
                                        batch_id = rlang::hash(batch_timestamp),
                                        batch_ts = batch_timestamp
                                )
                }
        ),
        # load to bigquery
        tar_target(
                name = gcp_raw_games_api,
                command = {
                        
                        # write table
                        write_table(
                                bigquery_connect(),
                                name = "raw_games_api",
                                append = T,
                                value = games_batch |>
                                        add_column(
                                                load_ts = Sys.time()
                                        )
                        )
                }
        )
)