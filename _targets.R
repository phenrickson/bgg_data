# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# required package for targets
library(targets)
library(tarchetypes)

# authenticate to 
googleCloudStorageR::gcs_auth(
        json_file = Sys.getenv('GCS_AUTH_FILE')
)

# set default bucket
suppressMessages({googleCloudStorageR::gcs_global_bucket(
        bucket = "bgg_data"
)})

# packages
tar_option_set(
        packages = c("dplyr",
                     "tidyr", 
                     "readr",
                     "pins",
                     "DBI",
                     "bigrquery",
                     "bggUtils",
                     #     "googleCloudStorageR",
                     "here"),
        repository = "local"
        # resources = tar_resources(
        #         gcp = tar_resources_gcp(
        #                 bucket = "bgg_data",
        #                 prefix = "raw"
        #         )
        # ),
        # repository = "gcp"
)

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# function to create batches out of game ids
create_batches = function(x, size = 250) {
        ceiling(seq_along(x) / size)
}

# functions for api requests
request_batch = function(games_batch, max_tries = 5) {
        
        b = unique(games_batch$batch)
        
        message(paste("batch", b, sep = ": "))
        
        games_batch |>
                pull(id) |>
                request_games(max_tries = max_tries)
        
}

request_games = function(game_ids, max_tries = 5) {
        
        # submit request
        resp = game_ids |>
                request_bgg_api(max_tries = max_tries)
        
        # parse response
        xml = resp |>
                parse_bgg_xml()
        
        # tidy xml
        xml |>
                tidy_bgg_xml()
}

request_bgg_api = function(game_ids, max_tries = 5) {
        
        # if duplicated
        if (identical(game_ids, unique(game_ids)) == F) {
                # warning
                warning("duplicated game ids in request. submitting only unique game ids")
                # deduplicate
                game_ids <- unique(game_ids)
        }
        
        # request to bgg api
        # submit game ids in comma delimited to api
        req <- request(paste("https://www.boardgamegeek.com/xmlapi2/thing?id=", paste(game_ids, collapse = ","), "&stats=1", sep = ""))
        
        # submit request and get response
        resp <-
                req %>%
                # throttle rate of request
                req_throttle(15 / 60) %>%
                # set policies for retry
                req_retry(
                        max_tries = max_tries
                ) %>%
                # perform
                req_perform()
        
        return(resp)
}

parse_bgg_xml = function(resp) {
        
        # check status 
        if (resp$status_code == 200) {
                message("request status ok...")
        } else {
                stop("request status not ok")
        }
        
        # parse
        bggUtils:::parse_bgg_api(resp)
        
}

tidy_bgg_xml= function(xml) {
        
        # extract data
        game_data <- furrr::future_map(xml, bggUtils:::extract_bgg_data)
        
        # convert to to data frame
        game_info <- lapply(
                game_data, "[",
                c(
                        "type",
                        "ids",
                        "yearpublished",
                        "minplayers",
                        "maxplayers",
                        "playingtime",
                        "minplaytime",
                        "maxplaytime",
                        "minage",
                        "description",
                        "thumbnail",
                        "image"
                )
        ) %>%
                bind_rows() %>%
                unnest(everything(), keep_empty = T) %>%
                nest(info = c(
                        yearpublished,
                        minplayers,
                        maxplayers,
                        playingtime,
                        minplaytime,
                        maxplaytime,
                        minage,
                        description,
                        thumbnail,
                        image
                ))
        
        # game names
        game_names <- 
                lapply(game_data, "[[", "names") %>%
                bind_rows(., .id = "game_id") %>%
                as_tibble() %>%
                mutate(
                        game_id = as.integer(game_id),
                        sortindex = as.integer(sortindex)
                ) %>%
                nest(names = one_of(c("type", "sortindex", "value")))
        
        # game links
        game_links <- 
                lapply(game_data, "[[", "links") %>%
                bind_rows(., .id = "game_id") %>%
                mutate(
                        game_id = as.integer(game_id),
                        id = as.integer(id)
                ) %>%
                nest(links = one_of("type", "id", "value"))
        
        # game statistics
        game_statistics <- 
                lapply(game_data, "[[", "statistics") %>%
                bind_rows(., .id = "game_id") %>%
                as_tibble() %>%
                mutate_at(
                        c(
                                "game_id",
                                "usersrated",
                                "median",
                                "owned",
                                "trading",
                                "wanting",
                                "wishing",
                                "numcomments",
                                "numweights"
                        ),
                        as.integer
                ) %>%
                mutate_at(
                        c(
                                "averageweight",
                                "average",
                                "bayesaverage",
                                "stddev"
                        ),
                        as.numeric
                ) %>%
                nest(statistics = c(
                        averageweight,
                        usersrated,
                        average,
                        bayesaverage,
                        stddev,
                        median,
                        owned,
                        trading,
                        wanting,
                        wishing,
                        numcomments,
                        numweights
                ))
        
        # game ranks
        game_ranks <- lapply(game_data, "[[", "ranks") %>%
                bind_rows(., .id = "game_id") %>%
                mutate_at(
                        c(
                                "game_id",
                                "id"
                        ),
                        as.integer
                ) %>%
                nest(ranks = c(
                        type,
                        id,
                        name,
                        friendlyname,
                        value,
                        bayesaverage
                ))
        
        # game polls
        game_polls <- lapply(game_data, "[[", "polls") %>%
                bind_rows(., .id = "game_id") %>%
                mutate(
                        game_id = as.integer(game_id),
                        numvotes = as.integer(numvotes)
                ) %>%
                nest(polls = c(
                        value,
                        numvotes,
                        numplayers
                ))
        
        # join up
        tidy_bgg_data <-
                game_info %>%
                left_join(.,
                          game_names,
                          by = c("game_id")
                ) %>%
                left_join(.,
                          game_links,
                          by = c("game_id")
                ) %>%
                left_join(.,
                          game_statistics,
                          by = c("game_id")
                ) %>%
                left_join(.,
                          game_ranks,
                          by = c("game_id")
                ) %>%
                left_join(.,
                          game_polls,
                          by = c("game_id")
                )
        
        tidy_bgg_data 
        
}

# get top games
get_ranked_games = function(games) {
        
        ranked = 
                games |>
                bggUtils:::unnest_outcomes() |>
                filter(!is.na(bayesaverage)) |>
                arrange(desc(bayesaverage))
        
        ranked |>
                select(game_id) |>
                inner_join(
                        games
                )
}


# function to write table to gcp
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
                        request_batch(),
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
                repository = "gcp",
                resources = tar_resources(
                        gcp = tar_resources_gcp(
                                bucket = "bgg_data",
                                prefix = "raw"
                        )
                )
        )
)
