
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
    xf1522833a4d242c5([""Up to date""]):::uptodate --- xb6630624a7b3aa0f([""Dispatched""]):::dispatched
    xb6630624a7b3aa0f([""Dispatched""]):::dispatched --- xd03d7c7dd2ddda2b([""Stem""]):::none
    xd03d7c7dd2ddda2b([""Stem""]):::none --- x6f7e04ea3427f824[""Pattern""]:::none
    x6f7e04ea3427f824[""Pattern""]:::none --- xeb2d7cac8a1ce544>""Function""]:::none
  end
  subgraph Graph
    direction LR
    xf9107f40574e0688>"parse_bgg_xml"]:::uptodate --> xb7d8ed75429dd2d3>"request_games"]:::uptodate
    xfa47bc4f9b7ff9d4>"request_bgg_api"]:::uptodate --> xb7d8ed75429dd2d3>"request_games"]:::uptodate
    x7df7644c63b276a4>"tidy_bgg_xml"]:::uptodate --> xb7d8ed75429dd2d3>"request_games"]:::uptodate
    xb7d8ed75429dd2d3>"request_games"]:::uptodate --> x2fa7a9263b0c6d5b>"request_batch"]:::uptodate
    xfee87d03ded1f217(["gcp_raw_games_api"]):::uptodate --> xc11069275cfeb620(["readme"]):::dispatched
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xbfb25272bc64f3d1(["ranked_games"]):::uptodate
    x2cf794a60330f53b>"get_ranked_games"]:::uptodate --> xbfb25272bc64f3d1(["ranked_games"]):::uptodate
    x7dbf8de746cff5f0>"create_batches"]:::uptodate --> xba75b35d0a8e6e78(["batch_numbers"]):::uptodate
    x2d4f1c2653f94fa0(["game_ids"]):::uptodate --> xba75b35d0a8e6e78(["batch_numbers"]):::uptodate
    xac4cca784f3ed72c(["bgg_ids"]):::uptodate --> x9dece1c65ecb5028(["games_batch"]):::uptodate
    x52391527f3798836["resp_game_batches"]:::uptodate --> x9dece1c65ecb5028(["games_batch"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> x574e5c623f867900(["games"]):::uptodate
    x3b8eb25aed2fb160(["req_game_batches"]):::uptodate --> x52391527f3798836["resp_game_batches"]:::uptodate
    x2fa7a9263b0c6d5b>"request_batch"]:::uptodate --> x52391527f3798836["resp_game_batches"]:::uptodate
    xba75b35d0a8e6e78(["batch_numbers"]):::uptodate --> x3b8eb25aed2fb160(["req_game_batches"]):::uptodate
    x2d4f1c2653f94fa0(["game_ids"]):::uptodate --> x3b8eb25aed2fb160(["req_game_batches"]):::uptodate
    xac4cca784f3ed72c(["bgg_ids"]):::uptodate --> x2d4f1c2653f94fa0(["game_ids"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xfee87d03ded1f217(["gcp_raw_games_api"]):::uptodate
    x82de3cade2b2f46e>"write_table"]:::uptodate --> xfee87d03ded1f217(["gcp_raw_games_api"]):::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef dispatched stroke:#000000,color:#000000,fill:#DC863B;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 2 stroke-width:0px;
  linkStyle 3 stroke-width:0px;
```

## data

batches of games requested from API

``` r
games_objs = 
        googleCloudStorageR::gcs_list_objects(detail ='full') |>
        filter(name == 'raw/objects/games') |>
        select(name, bucket, generation, size, updated)

games_objs |>
        arrange(desc(updated))
```

    ##                name   bucket       generation  size             updated
    ## 1 raw/objects/games bgg_data 1718727954502104 70 Mb 2024-06-18 16:25:54
