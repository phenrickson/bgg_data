
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
    xac4cca784f3ed72c(["bgg_ids"]):::uptodate --> x9dece1c65ecb5028(["games_batch"]):::uptodate
    x52391527f3798836["resp_game_batches"]:::uptodate --> x9dece1c65ecb5028(["games_batch"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xc11069275cfeb620(["readme"]):::dispatched
    x7dbf8de746cff5f0>"create_batches"]:::uptodate --> xba75b35d0a8e6e78(["batch_numbers"]):::uptodate
    x2d4f1c2653f94fa0(["game_ids"]):::uptodate --> xba75b35d0a8e6e78(["batch_numbers"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xbfb25272bc64f3d1(["ranked_games"]):::uptodate
    x2cf794a60330f53b>"get_ranked_games"]:::uptodate --> xbfb25272bc64f3d1(["ranked_games"]):::uptodate
    xba75b35d0a8e6e78(["batch_numbers"]):::uptodate --> x3b8eb25aed2fb160(["req_game_batches"]):::uptodate
    x2d4f1c2653f94fa0(["game_ids"]):::uptodate --> x3b8eb25aed2fb160(["req_game_batches"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> x574e5c623f867900(["games"]):::uptodate
    xac4cca784f3ed72c(["bgg_ids"]):::uptodate --> x2d4f1c2653f94fa0(["game_ids"]):::uptodate
    x9dece1c65ecb5028(["games_batch"]):::uptodate --> xfee87d03ded1f217(["gcp_raw_games_api"]):::uptodate
    x82de3cade2b2f46e>"write_table"]:::uptodate --> xfee87d03ded1f217(["gcp_raw_games_api"]):::uptodate
    x3b8eb25aed2fb160(["req_game_batches"]):::uptodate --> x52391527f3798836["resp_game_batches"]:::uptodate
    x2fa7a9263b0c6d5b>"request_batch"]:::uptodate --> x52391527f3798836["resp_game_batches"]:::uptodate
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
        googleCloudStorageR::gcs_list_objects(prefix = "raw/objects/games", versions = T, detail = "full") |>
        filter(name == 'raw/objects/games') |>
        select(bucket, name, generation, size, updated)

games_objs |>
        arrange(desc(updated)) |>
        knitr::kable(format = "markdown")
```

| bucket   | name              | generation       | size    | updated             |
|:---------|:------------------|:-----------------|:--------|:--------------------|
| bgg_data | raw/objects/games | 1741629678449522 | 73.6 Mb | 2025-03-10 18:01:18 |
| bgg_data | raw/objects/games | 1740875193707566 | 73.5 Mb | 2025-03-02 00:26:33 |
| bgg_data | raw/objects/games | 1732133366577344 | 72.1 Mb | 2024-11-20 20:09:26 |
| bgg_data | raw/objects/games | 1730333447804461 | 71.8 Mb | 2024-10-31 00:10:47 |
| bgg_data | raw/objects/games | 1728676924892464 | 71.5 Mb | 2024-10-11 20:02:04 |
| bgg_data | raw/objects/games | 1726869993009335 | 71.2 Mb | 2024-09-20 22:06:33 |
| bgg_data | raw/objects/games | 1724967426023865 | 70.9 Mb | 2024-08-29 21:37:06 |
| bgg_data | raw/objects/games | 1723671710966893 | 70.8 Mb | 2024-08-14 21:41:51 |
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
        arrange(desc(yearpublished)) |>
        knitr::kable(format = "markdown")
```

| game_id | name | yearpublished |
|---:|:---|---:|
| 440204 | Wormhole: Dimensional Rift | 2026 |
| 440214 | Grendel: The Game of Crime and Mayhem | 2026 |
| 440216 | Match Hatchery | 2026 |
| 440313 | Oniréa | 2026 |
| 440530 | Hollow | 2026 |
| 439608 | Place the Pips | 2025 |
| 439609 | Pass the Pips | 2025 |
| 439721 | Swindler’s Chest | 2025 |
| 439778 | EcoLogic: Europe (Gamefound Edition) | 2025 |
| 440033 | 도토리 원정대 (Fellowships of Acorn ) | 2025 |
| 440105 | I Don’t Like Onions | 2025 |
| 440107 | The Spiritualists | 2025 |
| 440170 | Save Us All | 2025 |
| 440176 | Stellar Descent | 2025 |
| 440221 | Blubbern | 2025 |
| 440249 | Слово за слово: Замес (Word by Word: The Mess) | 2025 |
| 440251 | Unanimo Cannes Part | 2025 |
| 440253 | Bravest | 2025 |
| 440254 | Taco Loco | 2025 |
| 440257 | Benjamins Cash Cards | 2025 |
| 440258 | Dominion of Pike and Shot | 2025 |
| 440264 | Protect the Mothership | 2025 |
| 440265 | Vibes | 2025 |
| 440267 | Les Nominés du Néombre | 2025 |
| 440269 | Trek Taking | 2025 |
| 440279 | 30 to Go | 2025 |
| 440282 | Centipede | 2025 |
| 440289 | Upland | 2025 |
| 440290 | Words to Die By | 2025 |
| 440295 | Opération Noisettes | 2025 |
| 440296 | Homing | 2025 |
| 440301 | Cathedroll: Young Artisans | 2025 |
| 440304 | Mythic Arena | 2025 |
| 440321 | Paws, Paper, Scissors | 2025 |
| 440322 | Shape Me!: What shape is this? | 2025 |
| 440323 | Crack Story | 2025 |
| 440347 | Linyo | 2025 |
| 440356 | Goblin Bargins | 2025 |
| 440371 | Landfall: A Cozy Volcano Island-Building Game | 2025 |
| 440376 | Surviving Stalingrad | 2025 |
| 440377 | Mystery Squad Detective Series Case 1: An Unmarked Grave | 2025 |
| 440378 | Gauntlets of Glory | 2025 |
| 440381 | Even the Oddities | 2025 |
| 440382 | A Shadow Serenade | 2025 |
| 440390 | Blanco | 2025 |
| 440391 | Gun Dodge | 2025 |
| 440395 | Reichbusters Reloaded | 2025 |
| 440397 | Forest First | 2025 |
| 440432 | Katz Fatz | 2025 |
| 440433 | Search for a Giant Squid: The Game | 2025 |
| 440437 | Disney in Character | 2025 |
| 440438 | Urban Battle: Main Square Junior Edition | 2025 |
| 440440 | Urban Battle: Main Square | 2025 |
| 440444 | Outflanked | 2025 |
| 440446 | Rough Shapes | 2025 |
| 440447 | Tranquility: The Descent | 2025 |
| 440448 | You’ve Got Junk | 2025 |
| 440449 | Kouba | 2025 |
| 440451 | Beat the Parents: Bluey | 2025 |
| 440453 | SPQR: The Battle of Alesia 52 BC | 2025 |
| 440457 | De Bellis Fantasiae: The Wars of Fantasy | 2025 |
| 440458 | How Many What?! | 2025 |
| 440464 | Gems of Antwerp | 2025 |
| 440474 | Duelgeon | 2025 |
| 440482 | Paw by Paw | 2025 |
| 440500 | Nexus | 2025 |
| 440502 | Borobudur The Golden Era | 2025 |
| 440507 | Zeo Genesis | 2025 |
| 440509 | Fountains | 2025 |
| 440513 | Coffee Break Battles: Preset 1.1 | 2025 |
| 440514 | Vibes | 2025 |
| 440517 | Christian Charades | 2025 |
| 440523 | Final Binary | 2025 |
| 440526 | Yosemite Trick | 2025 |
| 440534 | Dreyfall | 2025 |
| 440540 | Take Time | 2025 |
| 440543 | トリック帝王-氷結の雪女 (Trick Emperor: The Frozen Snow Woman) | 2025 |
| 440544 | トリック帝王-秩序の魔女 (Trick Emperor: The Witch of Order) | 2025 |
| 440554 | Surplus of Sloths | 2025 |
| 440561 | POH! : 2nd Edition | 2025 |
| 440563 | Takeover: Ladder Climbing Tactics | 2025 |
| 440573 | Flippers | 2025 |
| 440580 | うさぎ幼稚園 (Usagi Kindergarten) | 2025 |
| 440592 | The Goatfather | 2025 |
| 440593 | Biathlon Sprint | 2025 |
| 440598 | Garden Canasta | 2025 |
| 440644 | Frontline: The Miniature Game – Core Rulebook: Rules for Tabletop Battles in Vietnam and South East Asia 1965-1975 | 2025 |
| 440652 | Werewolf in the Dark: Monster Box | 2025 |
| 440693 | Word Colony Kids: My First Words | 2025 |
| 439812 | Otterwood | 2024 |
| 440095 | Little Demons | 2024 |
| 440171 | Super Trivia | 2024 |
| 440205 | Echoes in the Airlock | 2024 |
| 440263 | ミニミニシヴィライゼーション (Mini Mini Civilization) | 2024 |
| 440350 | Clockwork Carnival | 2024 |
| 440351 | Bees! | 2024 |
| 440353 | The Darkling Veil | 2024 |
| 440354 | Ælderwood | 2024 |
| 440374 | Drunk Imposters | 2024 |
| 440380 | UNO: Disney – Moana 2 | 2024 |
| 440394 | Bannish | 2024 |
| 440436 | Toy Mini Brands!: Add to Cart Game | 2024 |
| 440445 | Standoff | 2024 |
| 440450 | Monopoly: Дива України (Monopoly: Wonders of Ukraine) | 2024 |
| 440480 | アポロワイアル (Appointment Royal) | 2024 |
| 440481 | Cosmic Sheep | 2024 |
| 440483 | ツギハギキングダム (Patchwork Kingdom) | 2024 |
| 440484 | まるっとフィッシング (Marutto Fishing) | 2024 |
| 440501 | Lipowo. Kto zabił? | 2024 |
| 440522 | Papat: Birds of Indonesia | 2024 |
| 440524 | Bad Girl Era | 2024 |
| 440533 | Bokken | 2024 |
| 440569 | Kattenkwaad | 2024 |
| 440570 | Call Me Crazy: Jeder Anruf ein Brüller | 2024 |
| 440574 | TRUMPFSTARS Fußball Weltstars | 2024 |
| 440590 | 三神姫 (Three Goddess Princesses) | 2024 |
| 440683 | ¡Nos vamos de viaje! Destino: España | 2024 |
| 440184 | Savor | 2023 |
| 440283 | Take Take Boom | 2023 |
| 440294 | Zungenbrecher: Raus mit der Sprache! | 2023 |
| 440443 | Cornered | 2023 |
| 440572 | Safe!: Das Original – Ganz sicher idiotensicher! | 2023 |
| 440575 | SAFE!: Kids Edition – Ganz sicher kindersicher! | 2023 |
| 440222 | Чарівний світ: Джерело сили (Magic World: Source of Power) | 2022 |
| 440576 | Dig ’Em Up Dinos | 2022 |
| 438123 | Devabhaasha: A game of Sanskrit | 2021 |
| 440231 | Jungle Race | 2020 |
| 440284 | 妖怪臺灣 (Monster Taiwan) | 2020 |
| 440288 | Duellen | 2020 |
| 440310 | Салон Пана Фарта (Salon of Mr. Fortune) | 2020 |
| 440670 | Monopoly: Baku City | 2017 |
| 440215 | Blocks Rock! | 2016 |
| 440318 | Quillico | 2016 |
| 440172 | De Beste Belegger | 2010 |
| 440230 | Tour of Duty: USS Barney – Greyhound of the Fleet, Cutting Edge of the Sword of Freedom | 1992 |
| 440506 | Kugelblitz | 1986 |
| 438631 | Jounce | NA |
| 440073 | Stadt Land Vollpfosten: 3 in 1 - Kartenspiel Trio | NA |
| 440164 | Praestigium | NA |
| 440213 | Hill Country Fare | NA |
| 440223 | Mini Market | NA |
| 440224 | HOP HOP | NA |
| 440226 | Little Builder | NA |
| 440233 | Mickey’s Stuff for Kids: Memory Match Game | NA |
| 440252 | Smarty Puzzle: Star Words | NA |
| 440273 | Challenge Accepted | NA |
| 440293 | Equalizer | NA |
| 440370 | Point | NA |
| 440426 | Dino Go! | NA |
| 440439 | Slingers | NA |
| 440441 | Twilight Peaks | NA |
| 440475 | Necronite | NA |
| 440504 | Norse Horizons | NA |
| 440599 | Erdők játéka | NA |
| 440600 | Ki jut a várba? | NA |
| 440601 | Abrakadabra | NA |
| 440651 | Ra Ra Tuin | NA |
| 440671 | Go Higher: The Great Game of BASE | NA |
