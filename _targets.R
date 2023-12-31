# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# required package for targets
library(targets)
library(tarchetypes)

# packages
tar_option_set(
        packages = c("dplyr",
                     "tidyr", 
                     "readr",
                     "pins",
                     "DBI",
                     "bigrquery",
                     "reticulate",
                     "here")
)

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# functions relating to bigquery
tar_source(here::here("src", "data", "connect_to_bigquery.R"))

# functions to load data
tar_source(here::here("src", "data", "load_data.R"))

# get external file
thing_ids =  read.table('https://bgg.activityclub.org/bggdata/thingids.txt')
write.csv(thing_ids,
          file = here::here("data", "raw", "ids", "thing_ids.csv"),
          row.names = FALSE)

# load ids
get_ids <- function(file) {
        read_csv(file, col_types = cols()) %>%
                purrr::set_names(., c("id", "type"))
}

list(
        # load universe of ids courtesy of https://bgg.activityclub.org/bggdata/
        tar_target(
                name = ids_file,
                command = here::here("data", "raw", "ids", "thing_ids.csv"),
                format = "file"
        ),
        # load ids
        tar_target(
                name = ids,
                command = get_ids(ids_file)
        ),
        # filter to game ids
        tar_target(
                name = req_bgg_ids,
                command = ids |> filter(type == 'boardgame') |> pull(id)
        ),
        # submit ids to api in batches
        tar_target(
                name = bgg_games_resp,
                command =
                        bggUtils::get_bgg_games(req_bgg_ids,
                                                batch_size = 500,
                                                tidy = T,
                                                toJSON = F)
        ),
        # get api data from pin
        tar_target(
                name =
                        bgg_api,
                command =
                        bgg_games_resp$bgg_games_data
        ),
        ### raw datasets for bigquery
        # info
        tar_target(
                name = game_info,
                command =
                        bgg_api |>
                        get_game_info()
        ),
        # expansions
        tar_target(
                name = game_expansions,
                command = bgg_api |>
                        get_game_expansions()
        ),
        # game names
        tar_target(
                name = game_names,
                command = bgg_api |>
                        get_game_names()
        ),
        # game links
        tar_target(
                name = game_links,
                command = bgg_api |>
                        get_game_links()
        ),
        # game ranks
        tar_target(
                name = game_ranks,
                command = bgg_api |>
                        get_game_ranks()
        ),
        # game playercounts
        tar_target(
                name = game_playercounts,
                command = bgg_api |>
                        get_game_playercounts()
        ),
        # gqme images
        tar_target(
                name = game_images,
                command = bgg_api |>
                        get_game_images()
        ),
        # game descriptions
        tar_target(
                name = game_descriptions,
                command = bgg_api |>
                        get_game_descriptions()
        ),
        ### analysis layer for bigquery
        # analysis
        tar_target(
                name = analysis_games,
                command = bgg_api %>%
                        get_analysis_games()
        ),
        # unreleased
        tar_target(
                name = unreleased_games,
                command = bgg_api |>
                        get_unreleased_games()
        ),
        # drop
        tar_target(
                name = drop_games,
                command = bgg_api |>
                        get_drop_games()
        ),
        # families
        tar_target(
                name = game_families,
                command = bgg_api |>
                        get_game_families()
        ),
        # categories
        tar_target(
                name = game_categories,
                command = bgg_api |>
                        get_game_categories()
        ),
        # compilations
        tar_target(
                name = game_compilations,
                command = bgg_api |>
                        get_link_type(link_type = 'compilation')
        ),
        # implementations
        tar_target(
                name = game_implementations,
                command = bgg_api |>
                        get_link_type(link_type = 'implementation')

        ),
        # designers
        tar_target(
                name = game_designers,
                command = bgg_api |>
                        get_link_type(link_type = 'designer')
        ),
        # publishers
        tar_target(
                name = game_publishers,
                command = bgg_api |>
                        get_link_type(link_type = 'publisher')
        ),
        # mechanics
        tar_target(
                name = game_mechanics,
                command = bgg_api |>
                        get_link_type(link_type = 'mechanic')
        ),
        # artists
        tar_target(
                name = game_artists,
                command = bgg_api |>
                        get_link_type(link_type = 'artist')
        ),
        # game info
        tar_target(
                name = bq_game_info,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "api_game_info",
                                     append = T,
                                     value = game_info)
        ),
        # game names
        tar_target(
                name = bq_game_names,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "api_game_names",
                                     overwrite = T,
                                     value = game_names)
        ),
        # game expansions
        tar_target(
                name = bq_game_expansions,
                command = dbWriteTable(bigquery_connect(),
                                       name = "api_game_expansions",
                                       overwrite = T,
                                       value = game_expansions)
        ),
        # game links
        tar_target(
                name = bq_game_links,
                command = dbWriteTable(bigquery_connect(),
                                       name = "api_game_links",
                                       overwrite = T,
                                       value = game_links)
        ),
        # game ranks
        tar_target(
                name = bq_game_ranks,
                command = dbWriteTable(bigquery_connect(),
                                       name = "api_game_ranks",
                                       overwrite = T,
                                       value = game_ranks)
        ),
        # game playercounts
        tar_target(
                name = bq_game_playercounts,
                command =  dbWriteTable(bigquery_connect(),
                                        name = "api_game_playercounts",
                                        overwrite = T,
                                        value = game_playercounts)
        ),
        # game images
        tar_target(
                name = bq_game_images,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "api_game_images",
                                     overwrite = T,
                                     value = game_images)
        ),
        # game descriptions
        tar_target(
                name = bq_game_descriptions,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "api_game_descriptions",
                                     overwrite = T,
                                     value = game_descriptions)
        ),
        ### analysis tables
        tar_target(
                name = bq_analysis_games,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_games",
                                     overwrite = T,
                                     value = analysis_games)
        ),
        # unreleased games
        tar_target(
                name = bq_unreleased_games,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_unreleased_games",
                                     append = T,
                                     value = unreleased_games)
        ),
        # games flagged to drop
        tar_target(
                name = bq_drop_games,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_drop_games",
                                     append = T,
                                     value = drop_games)
        ),
        # descriptions in analysis layer
        # not sure why im storing this twice...
        tar_target(
                name = bq_analysis_game_descriptions,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_descriptions",
                                     append = T,
                                     value = game_descriptions)
        ),
        # ditto for images
        tar_target(
                name = bq_analysis_game_images,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_images",
                                     append = T,
                                     value = game_images)
        ),
        # analysis categories
        tar_target(
                name = bq_analysis_game_categories,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_categories",
                                     append = T,
                                     value = game_categories)
        ),
        # analysis compilations
        tar_target(
                name = bq_analysis_game_compilations,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_compilations",
                                     append = T,
                                     value = game_compilations)
        ),
        # analysis designers
        tar_target(
                name = bq_analysis_game_designers,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_designers",
                                     append = T,
                                     value = game_designers)
        ),
        # analysis families
        tar_target(
                name = bq_analysis_game_families,
                command =
                        # families
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_families",
                                     append = T,
                                     value = game_families)
        ),
        # analysis implementations
        tar_target(
                name = bq_analysis_implementations,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_implementations",
                                     append = T,
                                     value = game_implementations)
        ),
        # analysis publishers
        tar_target(
                name = bq_analysis_publishers,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_publishers",
                                     append = T,
                                     value = game_publishers)

        ),
        # analysis artists
        tar_target(
                name = bq_analysis_artists,
                command =
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_artists",
                                     append = T,
                                     value = game_artists)
        ),
        # analysis mechanics
        tar_target(
                name = bq_analysis_mechanics,
                command =
                        # mechanics
                        dbWriteTable(bigquery_connect(),
                                     name = "analysis_game_mechanics",
                                     append = T,
                                     value = game_mechanics)
        )
)