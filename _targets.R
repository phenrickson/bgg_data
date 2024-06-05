# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# required package for targets
library(targets)
library(tarchetypes)

# authenticate to gcp
googleCloudStorageR::gcs_auth(json_file = Sys.getenv('GCS_AUTH_FILE'))

# set default bucket
suppressMessages({googleCloudStorageR::gcs_global_bucket(bucket = "bgg_data")})

# packages
tar_option_set(
        packages = c("dplyr",
                     "tidyr", 
                     "readr",
                     "pins",
                     "DBI",
                     "bigrquery",
                     "bggUtils",
                     "here"),
        repository = "local",
        memory = "transient"
)

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# functions for api requests
tar_source("src/data/api.R")

# targets
list(
        # load universe of ids courtesy of https://bgg.activityclub.org/bggdata/
        tar_target(
                name = bgg_ids,
                command = {
                        tmp = bggUtils::get_bgg_ids()
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
        # create batches
        tar_target(
                name = batch_numbers,
                command = 
                        game_ids$id %>%
                        create_batches(
                                size = 500
                        )
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
                        req_game_batches |>
                        request_batch(max_tries = 10),
                pattern = map(req_game_batches)
        ),
        # add in batch id
        tar_target(
                name = games_batch,
                command = {
                        batch_timestamp = attr(bgg_ids, "timestamp")
                        
                        resp_game_batches |>
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
        ),
        # save games object in bucket
        tar_target(
                name = games,
                command = games_batch,
                format = "qs",
                repository = "gcp",
                resources = tar_resources(
                        gcp = tar_resources_gcp(
                                bucket = "bgg_data",
                                prefix = "raw"
                        )
                )
        ),
        # save games that have a geek rating
        tar_target(
                name = ranked_games,
                command = 
                        games_batch |>
                        get_ranked_games(),
                format = "qs",
                repository = "gcp",
                resources = tar_resources(
                        gcp = tar_resources_gcp(
                                bucket = "bgg_data",
                                prefix = "raw"
                        )
                )
        )
)
