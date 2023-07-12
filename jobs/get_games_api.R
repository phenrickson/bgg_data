# who: phil henrickson
# what: load scraped bgg ids to GCP
# when: 10/24/2022


# packages ----------------------------------------------------------------

library(dplyr)
library(tidyr)
library(readr)
library(pins)
library(DBI)
library(bigrquery)


# functions ---------------------------------------------------------------

# functions relating to bigquery
source(here::here("src", "data", "connect_to_bigquery.R"))

# functions to load data
source(here::here("src", "data", "load_data.R"))

# run  --------------------------------------------------------------------

# load most recently scraped bgg ids file
bgg_ids =
        here::here("data", "raw") |>
        load_most_recent_bgg_ids()

# get unique bgg ids (possibility of some duplicates across scraped pages)
req_bgg_ids = 
        unique(bgg_ids$game_id)

# submit ids to api in batches
bgg_games_raw = bggUtils::get_bgg_games(req_bgg_ids,
                                        batch_size = 500,
                                        tidy = T,
                                        toJSON = F)

# second pass for any batches missed
if (length(bgg_games_raw$problem_game_ids) > 0) {
        
        bgg_games_second_pass = 
                bggUtils::get_bgg_games(bgg_games_raw$problem_game_ids)
        
        bgg_games_out = 
                list(
                        game_ids = 
                                unique(c(bgg_games_raw$game_ids,
                                         bgg_games_second_pass$game_ids)),
                        problem_game_ids = 
                                bgg_games_second_pass$problem_game_ids,
                        bgg_games_data = 
                                bind_rows(bgg_games_raw$bgg_games_data,
                                          bgg_games_second_pass$bgg_games_data)
                )
        
        bgg_games_raw = bgg_games_out
}

# pin locally
bgg_games_raw$bgg_games_data |>
        pins::pin_write(
                board = pins::board_folder(here::here("data", "raw")),
                name = "games_api",
                versioned = T,
                tags = c("raw", "api"),
                description = paste("bgg ids from upload_ts", bgg_ids[1]$upload_ts)
        )

# # read locally
# bgg_api = 
#         pins::pin_read(
#                         board = pins::board_folder(here::here("data", "raw")),
#                         name = "games_api"
#         )
# 

# pull data from function
bgg_api = bgg_games_raw$bgg_games_data

# # pin read
# bgg_api =
#         pins::pin_read(
#                 board = pins::board_folder(here::here("data", "raw")),
#                 name = "games_api"
#         )

# get tables from api data ------------------------------------------------------------------

game_info = 
        bgg_api %>%
        get_game_info()

game_ids = 
        bgg_api %>%
        get_game_ids()

game_expansions = 
        bgg_api %>%
        get_game_expansions()

game_names = 
        bgg_api %>%
        get_game_names()

game_links = 
        bgg_api %>%
        get_game_links()

game_ranks = 
        bgg_api %>%
        get_game_ranks()

game_playercounts = 
        bgg_api %>%
        get_game_playercounts()

game_images = 
        bgg_api %>%
        get_game_images()

game_descriptions = 
        bgg_api %>%
        get_game_descriptions()

## analysis layer
analysis_games = 
        bgg_api %>%
        get_analysis_games()

unreleased_games = 
        bgg_api %>%
        get_unreleased_games()

drop_games = 
        bgg_api %>%
        get_drop_games()

game_families = 
        bgg_api %>%
        get_game_families()

game_categories = 
        bgg_api %>%
        get_game_categories()

game_compilations = 
        bgg_api %>%
        get_link_type(link_type = 'compilation')

game_implementations = 
        bgg_api %>%
        get_link_type(link_type = 'implementation')

game_designers = 
        bgg_api %>%
        get_link_type(link_type = 'designer')

game_publishers = 
        bgg_api %>%
        get_link_type(link_type = 'publisher')

game_mechanics = 
        bgg_api %>%
        get_link_type(link_type = 'mechanic')

game_artists = 
        bgg_api %>%
        get_link_type(link_type = 'artist')

# load tables to bigquery ---------------------------------------------------------------


# game info
dbWriteTable(bigquery_connect(),
             name = "api_game_info",
             append = T,
             value = game_info)

# game ids
dbWriteTable(bigquery_connect(),
             name = "api_game_ids",
             overwrite = T,
             value = game_ids)

# game expansions
dbWriteTable(bigquery_connect(),
             name = "api_game_expansions",
             overwrite = T,
             value = game_expansions)

# game expansions
dbWriteTable(bigquery_connect(),
             name = "api_game_names",
             overwrite = T,
             value = game_names)

# game links
dbWriteTable(bigquery_connect(),
             name = "api_game_links",
             overwrite = T,
             value = game_links)

# game ranks
dbWriteTable(bigquery_connect(),
             name = "api_game_ranks",
             overwrite = T,
             value = game_ranks)

# game playercounts
dbWriteTable(bigquery_connect(),
             name = "api_game_playercounts",
             overwrite = T,
             value = game_playercounts)

# game images
dbWriteTable(bigquery_connect(),
             name = "api_game_images",
             overwrite = T,
             value = game_images)

# game descriptions
dbWriteTable(bigquery_connect(),
             name = "api_game_descriptions",
             overwrite = T,
             value = game_descriptions)

### analysis
dbWriteTable(bigquery_connect(),
             name = "analysis_games",
             overwrite = T,
             value = analysis_games)

# load to analysis layer
# unreleased games
dbWriteTable(bigquery_connect(),
             name = "analysis_unreleased_games",
             append = T,
             value = unreleased_games)

# drop games
dbWriteTable(bigquery_connect(),
             name = "analysis_drop_games",
             append = T,
             value = drop_games)

# descriptions
dbWriteTable(bigquery_connect(),
             name = "analysis_game_descriptions",
             append = T,
             value = game_descriptions)

# images
dbWriteTable(bigquery_connect(),
             name = "analysis_game_images",
             append = T,
             value = game_images)

# categories
dbWriteTable(bigquery_connect(),
             name = "analysis_game_categories",
             append = T,
             value = game_categories)

# compilations
dbWriteTable(bigquery_connect(),
             name = "analysis_game_compilations",
             append = T,
             value = game_compilations)

# designers
dbWriteTable(bigquery_connect(),
             name = "analysis_game_designers",
             append = T,
             value = game_designers)

# families
dbWriteTable(bigquery_connect(),
             name = "analysis_game_families",
             append = T,
             value = game_families)

# implementations
dbWriteTable(bigquery_connect(),
             name = "analysis_game_implementations",
             append = T,
             value = game_implementations)

# publishers
dbWriteTable(bigquery_connect(),
             name = "analysis_game_publishers",
             append = T,
             value = game_publishers)

# artists
dbWriteTable(bigquery_connect(),
             name = "analysis_game_artists",
             append = T,
             value = game_artists)

# mechanics
dbWriteTable(bigquery_connect(),
             name = "analysis_game_mechanics",
             append = T,
             value = game_mechanics)

message("done.")
