
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

- The project is out-of-sync – use `renv::status()` for details.

``` mermaid
graph LR
  style Legend fill:#FFFFFF00,stroke:#000000;
  style Graph fill:#FFFFFF00,stroke:#000000;
  subgraph Legend
    direction LR
    xf1522833a4d242c5([""Up to date""]):::uptodate --- xb6630624a7b3aa0f([""Dispatched""]):::dispatched
    xb6630624a7b3aa0f([""Dispatched""]):::dispatched --- x2db1ec7a48f65a9b([""Outdated""]):::outdated
    x2db1ec7a48f65a9b([""Outdated""]):::outdated --- xd03d7c7dd2ddda2b([""Stem""]):::none
    xd03d7c7dd2ddda2b([""Stem""]):::none --- x6f7e04ea3427f824[""Pattern""]:::none
    x6f7e04ea3427f824[""Pattern""]:::none --- xeb2d7cac8a1ce544>""Function""]:::none
  end
  subgraph Graph
    direction LR
    xf9107f40574e0688>"parse_bgg_xml"]:::uptodate --> xb7d8ed75429dd2d3>"request_games"]:::uptodate
    xfa47bc4f9b7ff9d4>"request_bgg_api"]:::uptodate --> xb7d8ed75429dd2d3>"request_games"]:::uptodate
    x7df7644c63b276a4>"tidy_bgg_xml"]:::uptodate --> xb7d8ed75429dd2d3>"request_games"]:::uptodate
    xb7d8ed75429dd2d3>"request_games"]:::uptodate --> x2fa7a9263b0c6d5b>"request_batch"]:::uptodate
    xac4cca784f3ed72c(["bgg_ids"]):::uptodate --> x9dece1c65ecb5028(["games_batch"]):::uptodate
    x52391527f3798836["resp_game_batches"]:::uptodate --> x9dece1c65ecb5028(["games_batch"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xc11069275cfeb620(["readme"]):::dispatched
    x7dbf8de746cff5f0>"create_batches"]:::uptodate --> xba75b35d0a8e6e78(["batch_numbers"]):::uptodate
    x2d4f1c2653f94fa0(["game_ids"]):::uptodate --> xba75b35d0a8e6e78(["batch_numbers"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xbfb25272bc64f3d1(["ranked_games"]):::outdated
    x2cf794a60330f53b>"get_ranked_games"]:::uptodate --> xbfb25272bc64f3d1(["ranked_games"]):::outdated
    xba75b35d0a8e6e78(["batch_numbers"]):::uptodate --> x3b8eb25aed2fb160(["req_game_batches"]):::uptodate
    x2d4f1c2653f94fa0(["game_ids"]):::uptodate --> x3b8eb25aed2fb160(["req_game_batches"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> x574e5c623f867900(["games"]):::dispatched
    xac4cca784f3ed72c(["bgg_ids"]):::uptodate --> x2d4f1c2653f94fa0(["game_ids"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xfee87d03ded1f217(["gcp_raw_games_api"]):::dispatched
    x82de3cade2b2f46e>"write_table"]:::uptodate --> xfee87d03ded1f217(["gcp_raw_games_api"]):::dispatched
    x3b8eb25aed2fb160(["req_game_batches"]):::uptodate --> x52391527f3798836["resp_game_batches"]:::uptodate
    x2fa7a9263b0c6d5b>"request_batch"]:::uptodate --> x52391527f3798836["resp_game_batches"]:::uptodate
  end
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef dispatched stroke:#000000,color:#000000,fill:#DC863B;
  classDef outdated stroke:#000000,color:#000000,fill:#78B7C5;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 2 stroke-width:0px;
  linkStyle 3 stroke-width:0px;
  linkStyle 4 stroke-width:0px;
```

## data

batches of games requested from API

``` r
games_objs = 
        googleCloudStorageR::gcs_list_objects(prefix = "raw/objects/games", versions = T, detail = "full") |>
        filter(name == 'raw/objects/games') |>
        select(bucket, name, generation, size, updated)

games_objs |>
        arrange(desc(updated)) |>
        knitr::kable(format = "markdown")
```

| bucket   | name              | generation       | size    | updated             |
|:---------|:------------------|:-----------------|:--------|:--------------------|
| bgg_data | raw/objects/games | 1721888393714463 | 70.5 Mb | 2024-07-25 06:19:53 |
| bgg_data | raw/objects/games | 1721147850023745 | 70.3 Mb | 2024-07-16 16:37:30 |
| bgg_data | raw/objects/games | 1720538619978866 | 70.3 Mb | 2024-07-09 15:23:40 |
| bgg_data | raw/objects/games | 1719427179309064 | 70.1 Mb | 2024-06-26 18:39:39 |
| bgg_data | raw/objects/games | 1718727954502104 | 70 Mb   | 2024-06-18 16:25:54 |
| bgg_data | raw/objects/games | 1717875919368938 | 69.9 Mb | 2024-06-08 19:45:19 |
| bgg_data | raw/objects/games | 1717195700015761 | 69.8 Mb | 2024-05-31 22:48:20 |
| bgg_data | raw/objects/games | 1716489185536915 | 69.6 Mb | 2024-05-23 18:33:05 |
| bgg_data | raw/objects/games | 1715797632435985 | 69.5 Mb | 2024-05-15 18:27:12 |
| bgg_data | raw/objects/games | 1715108438703699 | 69.4 Mb | 2024-05-07 19:00:38 |
| bgg_data | raw/objects/games | 1714158379364878 | 69.3 Mb | 2024-04-26 19:06:19 |
| bgg_data | raw/objects/games | 1713464380724452 | 69.1 Mb | 2024-04-18 18:19:40 |
| bgg_data | raw/objects/games | 1711561705858375 | 68.9 Mb | 2024-03-27 17:48:25 |
| bgg_data | raw/objects/games | 1710336954503166 | 68.7 Mb | 2024-03-25 16:45:31 |
| bgg_data | raw/objects/games | 1708980495752949 | 68.6 Mb | 2024-02-26 20:48:15 |

``` r
# get last two generations
gens =
        games_objs |>
        arrange(desc(updated)) |>
        head(2) |>
        pull(generation)

# most recent gen
active_games = gcs_get_object("raw/objects/games", generation = gens[1]) |> qs::qdeserialize()
previous_games = gcs_get_object("raw/objects/games", generation = gens[2]) |> qs::qdeserialize()

# find games only in most recent batch
active_games |>
        anti_join(
                previous_games |>
                        select(game_id)
        ) |>
        bggUtils:::unnest_info() |>
        select(game_id, name, yearpublished) |>
        knitr::kable(format = "markdown")
```

| game_id | name                                                         | yearpublished |
|--------:|:-------------------------------------------------------------|--------------:|
|  374897 | Walpurgisnacht: la danza de las brujas                       |          2022 |
|  405292 | Gra z jajem: Wersja rozszerzona                              |          2023 |
|  405617 | Mystery at Monster Mansion                                   |          2020 |
|  407411 | Popdarts                                                     |          2020 |
|  407700 | Imagem & Ação: Edição Especial                               |          2019 |
|  408669 | Take-A-Letter                                                |          1953 |
|  410392 | Warhammer Age of Sigmar: Warcry – Core Book (Second Edition) |          2022 |
|  411838 | Contando Ovejas                                              |          2024 |
|  412220 | Warhammer: The Old World Rulebook                            |          2024 |
|  413116 | ABC Warriors: Increase The Peace Starter Game                |          2024 |
|  413522 | Killers: The Card Game – Speed Kills                         |          2022 |
|  413676 | Battlespace: Deluxe Edition                                  |          2024 |
|  413921 | Heart of Crown: Second Edition                               |          2024 |
|  418470 | Endeavor: Deep Sea Deluxe Edition                            |          2024 |
|  421134 | Nuss voraus!                                                 |          2019 |
|  421186 | HALMETTE: An interesting Game for Two Players                |          1900 |
|  421492 | Billionaire                                                  |            NA |
|  422443 | Fantomatrouille                                              |          2023 |
|  422606 | Endowed Chairs: Neurology                                    |          2023 |
|  422721 | Ultimate Rivals: MYSTIC                                      |          2024 |
|  423618 | Un metro de risa                                             |          1980 |
|  424171 | ShyCon: Denver 2024                                          |          2024 |
|  424172 | Mile High City                                               |          2024 |
|  424174 | Downhill Drop                                                |          2024 |
|  424175 | NyteLyfe Solitaire: Old West                                 |          2024 |
|  424603 | Mini Rogue: Literature-Inspired Lore Cards                   |          2025 |
|  424629 | Richard Scarry’s Busytown Seek and Find Adventure Game       |          2023 |
|  424631 | Run the Rails                                                |            NA |
|  424745 | Vines and Flowers                                            |          2024 |
|  424826 | Whimsy                                                       |          2024 |
|  424868 | Spy Code                                                     |          2024 |
|  424877 | Sparks                                                       |          2020 |
|  424881 | Catfish                                                      |          2025 |
|  424885 | Sprout                                                       |          2025 |
|  424951 | What’s Under The Carpet?                                     |          2018 |
|  424957 | milkuro                                                      |          2024 |
|  424958 | 1804                                                         |          2024 |
|  424960 | LasseMajas detektivbyrå: Mysteriespelet                      |          2022 |
|  424961 | Galebari: 18th Anniversary Edition                           |          2024 |
|  424962 | Massacards                                                   |            NA |
|  424963 | LOL: Die ultimative NICHT LACHEN Challenge – Das Kartenspiel |          2024 |
|  424964 | Chemicards                                                   |            NA |
|  424968 | Isles of Odd                                                 |          2025 |
|  424973 | Clash of the Cryptids                                        |          2020 |
|  424974 | That Escalated Quickly Mini                                  |          2024 |
|  424975 | Wilmot’s Warehouse                                           |          2024 |
|  424977 | Shat on a Cat                                                |          2024 |
|  424981 | Eternal Decks                                                |          2024 |
|  424984 | Bitter Rivals                                                |          2024 |
|  424985 | Dragon’s Domain                                              |          2026 |
|  424991 | Garden Variety                                               |          2024 |
|  424994 | SKIDZ                                                        |          2024 |
|  424995 | Night Sky Explorers                                          |          2024 |
|  424996 | Warboad                                                      |          2024 |
|  425000 | Tacticus Romanus                                             |            NA |
|  425001 | Звёздные войны: Spyfall                                      |          2016 |
|  425002 | Zonewreck                                                    |          2023 |
|  425003 | Florentynka Muu w podróży                                    |          2024 |
|  425004 | Spy Guy: Junior – Zwierzaki                                  |          2024 |
|  425005 | Everdell Duo                                                 |          2024 |
|  425009 | Monster Smash                                                |          2024 |
|  425012 | Fashion Competition                                          |          2024 |
|  425017 | Deceiver After Dark                                          |          2021 |
|  425018 | Paragon: Monsters & Mayhem                                   |          2025 |
|  425024 | FALLING                                                      |          2025 |
|  425026 | The Expedition: Wild Space                                   |          2024 |
|  425028 | Wishland: The Card Game                                      |          2024 |
|  425032 | Mecklenburg-Vorpommern: Entdecken und Lieben                 |          2004 |
|  425033 | 5 Second Rule: Relay                                         |          2023 |
|  425036 | DC Forever                                                   |          2025 |
|  425037 | Extraction                                                   |          2024 |
|  425042 | Operation Isabella. What If? Spain, 1942                     |          2024 |
|  425044 | Joy’s Bakery                                                 |          2024 |
|  425046 | 8 Gates                                                      |          2024 |
|  425047 | COIN                                                         |          2024 |
|  425050 | Elevate Island                                               |            NA |
|  425051 | 抜歯歯デスゲーム (Tooth Extraction Death Game)               |          2024 |
|  425055 | Give ’em The Finger                                          |          2024 |
|  425056 | CONIC                                                        |          2024 |
|  425060 | ADELLA: The Maritime Strategy Board Game                     |          2024 |
|  425064 | Kingsburg (Third Edition)                                    |          2024 |
|  425070 | Monopoly: Harry Potter – A Magical Adventure at Hogwarts     |          2024 |
|  425074 | Feudalism                                                    |          2025 |
|  425075 | Don’t Wake the Dragon                                        |          2024 |
|  425076 | Monopoly: Jeff Foxworthy Edition                             |          2020 |
|  425077 | Zombie Burrito                                               |          2024 |
|  425078 | You Little Stinker                                           |          2024 |
|  425079 | Why Are You Like This?                                       |          2024 |
|  425080 | Climate Change: Take Action!                                 |          2023 |
|  425081 | Oopsy Poopsy, Litterbox Edition!                             |          2024 |
|  425084 | Conexio                                                      |          2024 |
|  425085 | Drinking game Kooma!                                         |            NA |
|  425086 | CyberStrike24: Smart City Takedown, Hacker Heist             |          2025 |
|  425090 | Nestašne čarape                                              |          2024 |
|  425091 | Warhammer Age Of Sigmar (Fourth Edition): Core Rules         |          2024 |
|  425092 | The Land of Revelation                                       |            NA |
|  425094 | Harvest Town                                                 |          2024 |
|  425095 | Kaizoku-samurai                                              |            NA |
|  425101 | ¡Qué dice Chile!                                             |          2023 |
|  425106 | PoBody’s Nerfect                                             |          2024 |
|  425108 | What can I say?                                              |          2024 |
|  425110 | Kingdom of Tetrahexia                                        |          2022 |
|  425111 | Dragon Roost                                                 |          2025 |
|  425114 | The Time Whisperers                                          |          2024 |
|  425116 | Space Freight                                                |          2025 |
|  425117 | Drops and Lobbers: Pickleball the Board Game                 |          2022 |
|  425121 | Khufu                                                        |          2024 |
|  425122 | Catchables                                                   |          2024 |
|  425123 | The Cursed Castle                                            |          2024 |
|  425125 | Hundred Acre Wood Fluxx                                      |          2024 |
|  425142 | Camping Season                                               |          2025 |
|  425144 | Promotion the Game                                           |            NA |
|  425146 | Mutarum                                                      |          2024 |
|  425148 | Warfig                                                       |          2025 |
|  425162 | Crash Team Rumble: Crash Collector Card Game                 |          2023 |
|  425164 | Memory Matching Card Game: Washington, D.C. Landmarks        |          2024 |
|  425165 | Mickey and Friends Walt Disney World: Clap Game              |          2022 |
|  425170 | Tank Board Game II                                           |          2024 |
|  425172 | Where is the bug?                                            |            NA |
|  425204 | 100 Limit                                                    |          2023 |
|  425205 | Awake Heroes                                                 |          2024 |
|  425207 | DAMA                                                         |          2024 |
|  425208 | Recruit Madness                                              |          2024 |
|  425209 | Afrika Korps 41                                              |            NA |
|  425213 | Thunder On The Baltic: Scandinavian Wars at Sea, 1676-1814   |            NA |
|  425216 | Sær                                                          |          2024 |
|  425218 | Chess Infinitum                                              |          2000 |
|  425219 | Квароль Лягушек (Quarol of the Frogs)                        |            NA |
|  425220 | ФотоПташки (PhotoBirds)                                      |            NA |
|  425222 | Unclaimed Valley                                             |          2025 |
|  425224 | FxCx                                                         |          2024 |
|  425225 | Stawn                                                        |          2023 |
|  425226 | Tilt and Shout                                               |          2024 |
|  425227 | Nanatsu no Hihou (Seven Treasures)                           |          2022 |
|  425228 | Spanish Ulcer                                                |          2025 |
|  425230 | Match Madness Junior                                         |          2023 |
|  425231 | Dog Man: Twenty Thousand Fleas Under the Sea                 |          2023 |
|  425232 | Ragu Italian Festival                                        |          1980 |
|  425233 | シンエンをノゾクとき (Shinen Game)                           |          2023 |
|  425234 | Transcribe: The Art of Alchemy                               |          2024 |
|  425235 | Point of View: Lost Places                                   |          2024 |
|  425236 | Point Of View: Spooky Festival                               |          2024 |
|  425237 | MADZEMATICZ!                                                 |          2024 |
|  425238 | Point of View Mini-Testspiel                                 |          2024 |
|  425239 | Space Marine Adventures: Tyranid Attack!                     |          2024 |
|  425241 | Reporter                                                     |          2025 |
|  425244 | Wörtersalat                                                  |          2022 |
|  425248 | Game of HAM: The Punishing Board                             |          2024 |
|  425252 | Was ist das denn?                                            |          2022 |
|  425253 | Niwashi                                                      |          2024 |
|  425254 | Ninjan                                                       |          2024 |
|  425255 | Eden: The New World                                          |            NA |
|  425256 | IDOLS TCG                                                    |          2023 |
|  425257 | Hunt A Killer: The Final Act – Murder at the Talent Show     |          2024 |
|  425260 | Pitfall                                                      |            NA |
|  425261 | Do You Know Your Peeps?                                      |          2023 |
|  425264 | Poland’39                                                    |          2025 |
|  425275 | Shadow and Rune                                              |            NA |
|  425276 | Unmatched Adventures: Teenage Mutant Ninja Turtles           |          2025 |
|  425283 | Wild Flowers                                                 |          2024 |
|  425285 | Alchemagica                                                  |            NA |
|  425288 | Cháteau Gardens                                              |          2024 |
|  425292 | Crash the Party                                              |          2024 |
|  425293 | The Starlings                                                |          2023 |
|  425297 | Chromatic Decoder                                            |          2024 |
|  425298 | Club vidéo                                                   |          2021 |
|  425299 | Half Truth: Second Guess                                     |          2025 |
|  425302 | NENDORITE                                                    |          2024 |
|  425307 | Park Ranger                                                  |          2024 |
|  425320 | Bastion Run                                                  |          2024 |
|  425321 | Sagascade                                                    |          2024 |
|  425338 | すりすりあんこう (Sliced Anglerfish)                         |          2023 |
|  425340 | Bamboo Rally Cup                                             |          2024 |
|  425341 | おんぷとりて (Onpu Torite)                                   |          2024 |
|  425364 | Vesta                                                        |          2025 |
|  425395 | Formula POP                                                  |          2024 |
|  425399 | The Worst Among Us                                           |          2024 |
|  425410 | Goal Zone Board Game                                         |          2024 |
