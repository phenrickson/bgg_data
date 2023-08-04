# bgg_data

loading data from bgg's api to bigquery

requires authentication to bigquery warehouse

## targets

uses targets package to create pipeline

1. scrape game ids from bgg (via selenium with python)
2. submit batches of requests for scraped game ids to bgg's api
3. create tables from responses 
4. store tables on bigquery