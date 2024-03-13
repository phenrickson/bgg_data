
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

## data

batches of game ids:

    ##                   name     size             updated
    ## 1 raw/objects/game_ids 300.5 Kb 2024-03-10 15:33:13
    ## 2 raw/objects/game_ids 300.2 Kb 2024-03-01 16:21:57
    ## 3 raw/objects/game_ids 299.8 Kb 2024-02-23 15:50:51
    ## 4 raw/objects/game_ids 298.8 Kb 2024-02-14 23:28:57

most recent batch of game ids submitted to API:

    ## # A tibble: 1 × 3
    ##   batch_ts            type           n
    ##   <dttm>              <chr>      <int>
    ## 1 2024-03-10 15:33:12 boardgame 120176

most recent batch of games data loaded to GCS:

    ## # A tibble: 1 × 3
    ##   batch_ts            type           n
    ##   <dttm>              <chr>      <int>
    ## 1 2024-03-10 15:33:12 boardgame 120173

new games in most recent batch:

    ## # A tibble: 262 × 3
    ##    game_id yearpublished name                             
    ##      <int>         <int> <chr>                            
    ##  1  415472          2025 Tango                            
    ##  2  415493          2025 Revamp: the haunted mansion      
    ##  3  415524          2025 Super Boss Monster               
    ##  4  415829          2025 The Dead Keep                    
    ##  5  415843          2025 Puerto Rico 1897: Special Edition
    ##  6  415845          2025 Grimcoven                        
    ##  7  415848          2025 Lands of Evershade               
    ##  8  415885          2025 Napoleon’s Counterstrike         
    ##  9  416079          2025 March of the Ants: Second Edition
    ## 10  416528          2025 Yield                            
    ## # ℹ 252 more rows
