
# bgg_data

loading historical data from BGG for predictive modeling and analysis

1.  loads universe of game ids from [bgg activity
    club](http://bgg.activityclub.org/bggdata/thingids.txt%5D)
2.  submits batches of requests via
    [bggUtils](https://github.com/phenrickson/bggUtils)
3.  stores responses on BigQuery and Google Cloud Storage

## targets

uses [targets](https://github.com/ropensci/targets) package to create
pipeline

## setup

``` r
library(dplyr)
library(tibble)

googleCloudStorageR::gcs_auth(
        json_file = Sys.getenv("GCS_AUTH_FILE")
)

googleCloudStorageR::gcs_global_bucket("bgg_data")
```

    ## Set default bucket name to 'bgg_data'

## data

batches of game ids

    ##                   name     size             updated
    ## 1 raw/objects/game_ids 299.8 Kb 2024-02-23 15:50:51
    ## 2 raw/objects/game_ids 298.8 Kb 2024-02-14 23:28:57

most recent batch of game ids submitted to API:

    ## # A tibble: 1 × 3
    ##   batch_ts            type           n
    ##   <dttm>              <chr>      <int>
    ## 1 2024-02-23 09:50:50 boardgame 119918

games retrieved from API:

    ##                name    size             updated
    ## 1 raw/objects/games 68.6 Mb 2024-02-26 20:48:15

most recent batch of games:

    ## # A tibble: 1 × 3
    ##   batch_ts            type           n
    ##   <dttm>              <chr>      <int>
    ## 1 2024-02-23 09:50:50 boardgame 119918
