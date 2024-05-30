
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
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- xbf4603d6c2c2ad6b([""Stem""]):::none
    xbf4603d6c2c2ad6b([""Stem""]):::none --- x70a5fa6bea6f298d[""Pattern""]:::none
    x70a5fa6bea6f298d[""Pattern""]:::none --- xf0bce276fe2b9d3e>""Function""]:::none
  end
  subgraph Graph
    direction LR
    x39b6812ed242d611>"parse_bgg_xml"]:::uptodate --> x0ebe8341a2442c16>"request_games"]:::uptodate
    x609b87dc2634ad1d>"request_bgg_api"]:::uptodate --> x0ebe8341a2442c16>"request_games"]:::uptodate
    x5d06fedf30b364d1>"tidy_bgg_xml"]:::uptodate --> x0ebe8341a2442c16>"request_games"]:::uptodate
    x0ebe8341a2442c16>"request_games"]:::uptodate --> xfba0da78c0be6556>"request_batch"]:::uptodate
    x137069f8bf026eca(["req_game_batches"]):::uptodate --> x8bcc16a0a814cf48["resp_game_batches"]:::uptodate
    xfba0da78c0be6556>"request_batch"]:::uptodate --> x8bcc16a0a814cf48["resp_game_batches"]:::uptodate
    xb8813b801dfbb37d(["bgg_ids"]):::uptodate --> x89a75fc9787e4551(["games_batch"]):::uptodate
    x8bcc16a0a814cf48["resp_game_batches"]:::uptodate --> x89a75fc9787e4551(["games_batch"]):::uptodate
    x89a75fc9787e4551(["games_batch"]):::uptodate --> xbbcfc6254425a416(["ranked_games"]):::uptodate
    xc47c45fc9f8662c0>"get_ranked_games"]:::uptodate --> xbbcfc6254425a416(["ranked_games"]):::uptodate
    x89a75fc9787e4551(["games_batch"]):::uptodate --> x80d94f4f242b8556(["games"]):::uptodate
    x5fee1b5b1808a5a5>"create_batches"]:::uptodate --> x07f403e5660d4aa2(["batch_numbers"]):::uptodate
    x890dd267a7f272d6(["game_ids"]):::uptodate --> x07f403e5660d4aa2(["batch_numbers"]):::uptodate
    xb8813b801dfbb37d(["bgg_ids"]):::uptodate --> x890dd267a7f272d6(["game_ids"]):::uptodate
    x07f403e5660d4aa2(["batch_numbers"]):::uptodate --> x137069f8bf026eca(["req_game_batches"]):::uptodate
    x890dd267a7f272d6(["game_ids"]):::uptodate --> x137069f8bf026eca(["req_game_batches"]):::uptodate
    x89a75fc9787e4551(["games_batch"]):::uptodate --> xe225e12f9baa6aac(["gcp_raw_games_api"]):::uptodate
    x15726cccffa31d0b>"write_table"]:::uptodate --> xe225e12f9baa6aac(["gcp_raw_games_api"]):::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 2 stroke-width:0px;
```

## data

batches of games requested from API

``` r
games_objs = 
        googleCloudStorageR::gcs_list_objects(versions = T, detail ='full') |>
        filter(name == 'raw/objects/games') |>
        select(name, bucket, generation, size, updated)

games_objs
```

    ##                name   bucket       generation    size             updated
    ## 1 raw/objects/games bgg_data 1708980495752949 68.6 Mb 2024-02-26 20:48:15
    ## 2 raw/objects/games bgg_data 1710336954503166 68.7 Mb 2024-03-25 16:45:31
    ## 3 raw/objects/games bgg_data 1711561705858375 68.9 Mb 2024-03-27 17:48:25
    ## 4 raw/objects/games bgg_data 1713464380724452 69.1 Mb 2024-04-18 18:19:40
    ## 5 raw/objects/games bgg_data 1714158379364878 69.3 Mb 2024-04-26 19:06:19
    ## 6 raw/objects/games bgg_data 1715108438703699 69.4 Mb 2024-05-07 19:00:38
    ## 7 raw/objects/games bgg_data 1715797632435985 69.5 Mb 2024-05-15 18:27:12
    ## 8 raw/objects/games bgg_data 1716489185536915 69.6 Mb 2024-05-23 18:33:05

<!-- ```{r batches of ids, message = F, echo = F} -->
<!-- games_objs =  -->
<!--         googleCloudStorageR::gcs_list_objects(versions =T, detail = "full") |> -->
<!--         filter(name == 'raw/objects/games')  -->
<!-- games_objs |> -->
<!--         select(name, bucket, generation, size, updated) |> -->
<!--         arrange(desc(updated)) -->
<!-- ``` -->
<!-- games in most recent batch -->
<!-- ```{r batches of ids, message = F, echo = T} -->
<!-- generations = games_objs$generation -->
<!-- current_games = bggUtils::get_games_from_gcp(object_name = "raw/objects/games", generation = generations[1]) -->
<!-- ``` -->
