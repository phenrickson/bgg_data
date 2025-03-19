# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# required package for targets
library(targets)
library(tarchetypes)
library(crew)
library(logger)

# Get environment from command line or default to "default"
env <- Sys.getenv("R_CONFIG_ACTIVE", "default")
cfg <- config::get(config = env)

# Set up logging based on environment
log_threshold(cfg$log_level)
log_appender(appender_file(
        paste0("logs/bgg_pipeline_", env, ".log"),
        append = TRUE
))
log_info(paste("Starting pipeline in", env, "environment"))

# authenticate to gcp
googleCloudStorageR::gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))

# set default bucket
# suppressMessages({
googleCloudStorageR::gcs_global_bucket(bucket = cfg$bucket)
# })

# packages
tar_option_set(
        packages = c(
                "dplyr",
                "tidyr",
                "readr",
                "pins",
                "DBI",
                "bigrquery",
                "bggUtils",
                "here",
                "logger"
        ),
        repository = "local",
        memory = "transient",
        resources = tar_resources(
                gcp = tar_resources_gcp(
                        bucket = cfg$bucket,
                        prefix = cfg$prefix
                )
        ),
        workspace_on_error = TRUE,
        workspaces = ".targets/workspaces"
)

# Set environment-specific store
# This needs to be separate from tar_option_set to avoid issues with tar_glimpse
Sys.setenv(TAR_PROJECT = paste0("_targets_", env))

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# functions for api requests
tar_source("src/data/api.R")

# set workers for crew based on config
tar_option_set(
        controller = crew_controller_local(workers = cfg$workers)
)

# targets
list(
        # load universe of ids courtesy of https://bgg.activityclub.org/bggdata/
        tar_target(
                name = bgg_ids,
                command = {
                        tmp <- bggUtils::get_bgg_ids()
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
                command = bgg_ids |>
                        filter(type == "boardgame")
        ),
        # create batches
        tar_target(
                name = batch_numbers,
                command = game_ids$id %>%
                        create_batches(
                                size = 20
                        )
        ),
        # append to ids and add groups
        tar_target(
                name = req_game_batches,
                command = game_ids |>
                        add_column(batch = batch_numbers) %>%
                        group_by(batch) %>%
                        targets::tar_group(),
                iteration = "group"
        ),
        # submit these in batches to API
        tar_target(
                resp_game_batches,
                command = req_game_batches |>
                        request_batch(max_tries = 10),
                pattern = map(req_game_batches)
        ),
        # add in batch id
        tar_target(
                name = games_batch,
                command = {
                        batch_timestamp <- attr(bgg_ids, "timestamp")

                        resp_game_batches |>
                                select(
                                        game_id,
                                        type,
                                        info,
                                        names,
                                        links,
                                        statistics,
                                        ranks,
                                        polls
                                ) %>%
                                add_column(
                                        batch_id = rlang::hash(batch_timestamp),
                                        batch_ts = batch_timestamp
                                )
                }
        ),
        # save games object in bucket
        tar_target(
                name = games,
                command = games_batch,
                format = "qs",
                repository = "gcp"
        ),
        # save games that have a geek rating
        tar_target(
                name = ranked_games,
                command = games_batch |>
                        get_ranked_games(),
                format = "qs",
                repository = "gcp"
        ),
        # Render Quarto document instead of R Markdown
        tar_target(
                name = readme,
                command = {
                        # Render Quarto document
                        quarto::quarto_render("index.qmd")
                        # Return the output file path
                        "docs/index.html"
                },
                cue = tar_cue(mode = "always")
        )
)
