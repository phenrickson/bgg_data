# bgg_data

loading data from bgg's api to bigquery

requires authentication to bigquery warehouse

## jobs

1. scrape game_ids from bgg (scrape_ids)
2. push game_ids to bgg's api, return results, and load to bigquery tables (get_games_api)
