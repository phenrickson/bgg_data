
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

## pipeline

``` mermaid
graph LR
  style Legend fill:#FFFFFF00,stroke:#000000;
  style Graph fill:#FFFFFF00,stroke:#000000;
  subgraph Legend
    direction LR
    x0a52b03877696646([""Outdated""]):::outdated --- x7420bd9270f8d27d([""Up to date""]):::uptodate
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- xbf4603d6c2c2ad6b([""Stem""]):::none
    xbf4603d6c2c2ad6b([""Stem""]):::none --- x70a5fa6bea6f298d[""Pattern""]:::none
    x70a5fa6bea6f298d[""Pattern""]:::none --- xf0bce276fe2b9d3e>""Function""]:::none
  end
  subgraph Graph
    direction LR
    x4bb830a688852d8d>"bigquery_authenticate"]:::uptodate --> x7caac6022ef34a66>"bigquery_connect"]:::uptodate
    xb8813b801dfbb37d(["bgg_ids"]):::outdated --> x890dd267a7f272d6(["game_ids"]):::outdated
    xb8813b801dfbb37d(["bgg_ids"]):::outdated --> x89a75fc9787e4551(["games_batch"]):::outdated
    x8bcc16a0a814cf48["resp_game_batches"]:::outdated --> x89a75fc9787e4551(["games_batch"]):::outdated
    x07f403e5660d4aa2(["batch_numbers"]):::outdated --> x8bcc16a0a814cf48["resp_game_batches"]:::outdated
    x137069f8bf026eca(["req_game_batches"]):::outdated --> x8bcc16a0a814cf48["resp_game_batches"]:::outdated
    x07f403e5660d4aa2(["batch_numbers"]):::outdated --> x137069f8bf026eca(["req_game_batches"]):::outdated
    x890dd267a7f272d6(["game_ids"]):::outdated --> x137069f8bf026eca(["req_game_batches"]):::outdated
    x89a75fc9787e4551(["games_batch"]):::outdated --> x80d94f4f242b8556(["games"]):::outdated
    x7caac6022ef34a66>"bigquery_connect"]:::uptodate --> xe225e12f9baa6aac(["gcp_raw_games_api"]):::outdated
    x89a75fc9787e4551(["games_batch"]):::outdated --> xe225e12f9baa6aac(["gcp_raw_games_api"]):::outdated
    x15726cccffa31d0b>"write_table"]:::uptodate --> xe225e12f9baa6aac(["gcp_raw_games_api"]):::outdated
    x890dd267a7f272d6(["game_ids"]):::outdated --> x6c2141f9438cc75c(["req_game_ids"]):::outdated
    x6c2141f9438cc75c(["req_game_ids"]):::outdated --> x07f403e5660d4aa2(["batch_numbers"]):::outdated
  end
  classDef outdated stroke:#000000,color:#000000,fill:#78B7C5;
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 2 stroke-width:0px;
  linkStyle 3 stroke-width:0px;
```

## data

last batch of game ids

    ##                   name     size             updated
    ## 1 raw/objects/game_ids 301.3 Kb 2024-03-27 14:32:39

most recent batch of game ids submitted to API:

    ## # A tibble: 1 × 3
    ##   batch_ts            type           n
    ##   <dttm>              <chr>      <int>
    ## 1 2024-03-27 09:32:38 boardgame 120420

most recent batch of games data loaded to GCS:

    ## # A tibble: 1 × 3
    ##   batch_ts            type           n
    ##   <dttm>              <chr>      <int>
    ## 1 2024-03-27 09:32:38 boardgame 120417
