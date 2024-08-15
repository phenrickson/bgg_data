
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
        knitr::kable(format = "markdown")
```

| game_id | name                                                                      | yearpublished |
|--------:|:--------------------------------------------------------------------------|--------------:|
|  402531 | Wolf & Schaf                                                              |            NA |
|  405877 | Abducktion: Base + Expansion                                              |          2023 |
|  411030 | Wankul                                                                    |          2023 |
|  418469 | Momiji: Deluxe Edition                                                    |          2021 |
|  424435 | Context                                                                   |          2024 |
|  424442 | Beatz’n’Catz                                                              |          2024 |
|  425020 | Bottle Shock: The Wine Game                                               |          2024 |
|  425202 | The Felonry                                                               |          2024 |
|  425240 | Merlinn                                                                   |            NA |
|  425335 | POP!                                                                      |          2025 |
|  425337 | Flea Market                                                               |          2025 |
|  425352 | ProSet                                                                    |          2020 |
|  425383 | Landkreuzer                                                               |          2025 |
|  425409 | Travel 20 Questions                                                       |          1994 |
|  425419 | Care Bears: Care-a-Lot Journey                                            |          2023 |
|  425420 | Sports Line-O                                                             |          1982 |
|  425421 | Stay Tuned                                                                |            NA |
|  425427 | Meine ersten Spiele: Wir verarzten Tiere                                  |          2024 |
|  425428 | Survive The Island                                                        |          2024 |
|  425429 | Meine ersten Spiele: Im Kindergarten Spielesammlung                       |          2024 |
|  425430 | Auweia, Frau Geier!                                                       |          2024 |
|  425431 | Knuckling Knights & The Big Dragon Spectacle                              |          2024 |
|  425432 | Streets of Tokyo                                                          |          2025 |
|  425433 | Unlock!: Risky Adventures                                                 |          2024 |
|  425434 | Socken Zocken: Anniversary Edition                                        |          2024 |
|  425435 | Kaze No Bochi                                                             |          2024 |
|  425436 | Game Meets Puzzle: Wo leben Löwe & Co.?                                   |          2024 |
|  425437 | Game Meets Puzzle: Schatzsuche im Ozean                                   |          2024 |
|  425438 | Schatzkarte Ahoi!                                                         |          2024 |
|  425439 | Jetzt schlägt’s 18!                                                       |          2024 |
|  425440 | Fast Factory                                                              |          2024 |
|  425443 | Sambiki Saru                                                              |          2024 |
|  425444 | Chess 2vs2: Faceoff & Surrounded                                          |          2024 |
|  425445 | Sweet Lands                                                               |          2025 |
|  425446 | For-Ex II: She Made Another One                                           |          2024 |
|  425448 | Oblique                                                                   |          2024 |
|  425462 | Eagles Over Bavaria 1809                                                  |          2017 |
|  425464 | Duel of The Princes 1809                                                  |          2017 |
|  425465 | Blood Along the Danube 1809                                               |          2018 |
|  425467 | Boule Rouge                                                               |          2024 |
|  425468 | The Roads to Vienna 1809                                                  |          2018 |
|  425469 | Game Creator Set                                                          |          2024 |
|  425475 | Scrap: Post-Apocalyptic Mayhem                                            |          2026 |
|  425479 | Order Master                                                              |          2023 |
|  425480 | Castelnuovo 1539                                                          |          2025 |
|  425484 | The Fetterman Fight or A Hundred in the Hands                             |          2023 |
|  425490 | Bounce-Off Duel                                                           |          2023 |
|  425494 | Coral Castle                                                              |          2025 |
|  425496 | Car Wars Two-Player Starter Set: Orange/Purple                            |          2024 |
|  425501 | Murder Mystery Party: Bullets and Brie                                    |          2023 |
|  425503 | Murder Mystery on the Dance Floor                                         |            NA |
|  425505 | Storyfold: Wildwoods                                                      |          2025 |
|  425511 | Terreign                                                                  |          2024 |
|  425525 | SundayQuest Adventures: Volume 9                                          |          2024 |
|  425529 | STAQS                                                                     |          2024 |
|  425531 | Dragon Tech                                                               |          2025 |
|  425532 | Otter                                                                     |          2025 |
|  425533 | Quick Stop                                                                |          2024 |
|  425534 | The Kittens of Mont Saint Michel                                          |          2025 |
|  425538 | Draky                                                                     |          2024 |
|  425539 | Mini Moons                                                                |          2025 |
|  425548 | Sheep Showdown                                                            |          2024 |
|  425549 | Moon Colony Bloodbath                                                     |          2024 |
|  425554 | Warhammer Age of Sigmar: Introductory Set                                 |          2024 |
|  425556 | Warhammer Age of Sigmar: Starter Set                                      |          2024 |
|  425558 | Warhammer Age of Sigmar: Ultimate Starter Set                             |          2024 |
|  425560 | Strange World Above the Clouds                                            |          2024 |
|  425562 | Veselé cestování Spejbla a Hurvínka                                       |            NA |
|  425565 | Die Reise                                                                 |          1900 |
|  425571 | Jahu Safari: Zwei Tierwelten – gemeinsam sind wir stark                   |          2023 |
|  425575 | A House Divided: Designer Edition                                         |            NA |
|  425588 | Go Bomb!                                                                  |          2024 |
|  425589 | Dead Man’s Hand                                                           |          2023 |
|  425592 | HACKT!CS                                                                  |          2022 |
|  425593 | Magic Jungle: The Board Game                                              |          2025 |
|  425602 | YUBIBO                                                                    |          2024 |
|  425603 | American Pursuit                                                          |          2024 |
|  425604 | FIXER                                                                     |          2024 |
|  425605 | Twilight City                                                             |          2024 |
|  425606 | Diceolated                                                                |          2024 |
|  425608 | Tetaki                                                                    |          2024 |
|  425610 | Backstories: Les Noces d’Émeraude                                         |          2024 |
|  425630 | Baghdad: The City of Peace                                                |          2025 |
|  425631 | Battle of Midway: The Board Game                                          |          2022 |
|  425632 | Racing Fun                                                                |          2024 |
|  425634 | Black Maze Deep                                                           |          2020 |
|  425635 | Rooster Chase                                                             |          2024 |
|  425636 | Nasi Lemak: The Game                                                      |          2023 |
|  425638 | Procesiones                                                               |          2024 |
|  425646 | Pickleball Blast!                                                         |          2024 |
|  425648 | Dip Dop                                                                   |          2024 |
|  425650 | Cluethulhu                                                                |          2024 |
|  425654 | Dogfight! 1939-40: WW2 Air Combat Game                                    |          2024 |
|  425655 | Mermaid Tide                                                              |          2022 |
|  425657 | Octopush                                                                  |          2024 |
|  425663 | Zauber-Karussell                                                          |          1967 |
|  425665 | Speedcicleta                                                              |            NA |
|  425666 | Key Enigma: FILE OID 173                                                  |          2023 |
|  425667 | 水浒传 天苍之星 (Water Margin: Celestial Star)                            |          2022 |
|  425670 | The Season: Love & Drama in the Regency Era (2nd Edition)                 |          2024 |
|  425673 | Love 2 Hate: Comics                                                       |          2016 |
|  425674 | Family Feud: Kids Vs Parents                                              |          2018 |
|  425676 | Italy ’43                                                                 |            NA |
|  425677 | Escape Room                                                               |            NA |
|  425679 | Kids vs Adults                                                            |          2018 |
|  425680 | The Perfect Match                                                         |            NA |
|  425681 | Space Days                                                                |          2024 |
|  425682 | Pirate Days                                                               |          2024 |
|  425683 | Name 5: Pop Culture Party Edition                                         |          2014 |
|  425685 | Dice Mission                                                              |          2024 |
|  425686 | Generic Board “Parallelo” Set                                             |          2022 |
|  425687 | The Great Commission: Strategic Card Game                                 |          2025 |
|  425690 | Jumbo Motor Rally                                                         |            NA |
|  425693 | Исторический детектив: Ставки сделаны (Historical Mystery: Bets are Made) |          2024 |
|  425703 | Rogue Warriors: A Modern Warfare Skirmish Game                            |          2024 |
|  425704 | Oishii: Food Stall Clash                                                  |          2024 |
|  425708 | Crazy Locust                                                              |          2023 |
|  425709 | Sandcastle & Otter                                                        |          2024 |
|  425710 | Romantic Zebra                                                            |          2024 |
|  425711 | Tower of Hercules                                                         |          2024 |
|  425712 | 1905: Mining Operations                                                   |          2025 |
|  425713 | The Ferryman: A Post-Apocalyptic Adventure                                |          2024 |
|  425714 | El Chiringuico                                                            |          2023 |
|  425717 | Next Play Football Edition Card Game                                      |          2024 |
|  425718 | Maritiles                                                                 |          2024 |
|  425723 | Llama Trek                                                                |          2019 |
|  425724 | One Deck Dungeon: Relics of the Forge                                     |          2025 |
|  425727 | Viiruveikot                                                               |            NA |
|  425728 | Golf                                                                      |            NA |
|  425729 | Beast Hunt                                                                |          2024 |
|  425730 | Elmeri-Juna                                                               |            NA |
|  425731 | TRAVESÍA                                                                  |          2024 |
|  425735 | トームくんのネコリリ (Tom’s Cat Lily)                                     |          2024 |
|  425736 | 水浒传 天苍之星2 (Water Margin: Celestial Star 2)                         |          2023 |
|  425737 | Mary Stuart, Queen of Scots                                               |          2022 |
|  425743 | Poseurs                                                                   |          2024 |
|  425744 | Spargeld macht das Kaufen leicht                                          |          1949 |
|  425745 | Blasphemous: The Board Game                                               |            NA |
|  425753 | 三國志之武將瘋雲錄 (Three Kingdoms: Chronicles of Warlords)               |          1992 |
|  425755 | 萌幻西游记 (Fantasy Journey to the West)                                  |          2020 |
|  425756 | Zoo-ography: Extended Edition                                             |          2025 |
|  425758 | Koala Kart 2nd Edition                                                    |          2024 |
|  425761 | Trama                                                                     |          1990 |
|  425763 | Yogi (Second Edition)                                                     |          2024 |
|  425765 | Ministry of Lost Things: Case 1 – Lint Condition                          |          2025 |
|  425766 | The Alamo                                                                 |          2024 |
|  425767 | Soulshards: Grand Tourney                                                 |          2024 |
|  425768 | 四面楚歌 (Besieged on All Sides)                                          |          2024 |
|  425769 | EcoFrenzy: The Pollination Game                                           |          2024 |
|  425771 | Destination Antwerp                                                       |          2020 |
|  425779 | Spell✅️ed                                                                 |            NA |
|  425787 | Guards & Goblins                                                          |          2024 |
|  425788 | King´s Decree                                                             |          2024 |
|  425789 | The Republic of Rome Remastered                                           |          2025 |
|  425790 | Star Wars: Power of the Sith                                              |            NA |
|  425792 | Midnight Retribution                                                      |          2023 |
|  425793 | Turboprší                                                                 |          2021 |
|  425796 | Tomb Raider: The Crypt of Chronos                                         |          2025 |
|  425798 | Moonlight Market                                                          |          2024 |
|  425799 | Tattered Flags: Into the Whirlpool                                        |          2024 |
|  425812 | The Pursuit of John Wilkes Booth                                          |          2024 |
|  425824 | Asalto al Japón ancestral. Kyüshü 1945                                    |          2024 |
|  425827 | Queen by Midnight: Quarter Past                                           |          2024 |
|  425828 | The Lost Lands of Verne                                                   |          2024 |
|  425831 | POLITICO: The board game                                                  |          2024 |
|  425833 | GOTA                                                                      |          2024 |
|  425835 | Forest Folk                                                               |          2024 |
|  425853 | Resistencia Nativa                                                        |          2024 |
|  425855 | Trivial Pursuit: D-DAY                                                    |          2024 |
|  425857 | Paleo Atacama                                                             |          2024 |
|  425858 | Fill in the Blanks                                                        |          2020 |
|  425859 | Anache                                                                    |          2024 |
|  425860 | Squirrels Gone WIld                                                       |          2025 |
|  425861 | Overs                                                                     |          2024 |
|  425867 | Schrottplatz Rally                                                        |          2024 |
|  425868 | People of the Isle                                                        |          2024 |
|  425870 | One, Two, Sing!                                                           |          2024 |
|  425872 | D6 MINIS                                                                  |          2015 |
|  425873 | Koala Rescue Club                                                         |          2024 |
|  425875 | The Way of Horse and Bow                                                  |            NA |
|  425876 | Bora Fruta                                                                |          2021 |
|  425884 | DUST Reclamation                                                          |          2024 |
|  425902 | Musta kuula                                                               |          2012 |
|  425912 | Mutually Assured Destruction                                              |          2025 |
|  425913 | Shin Megami Tensei: The Board Game                                        |          2025 |
|  425932 | Kilpikonna, jänis ja muutama muu                                          |          2024 |
|  425934 | Dragon Ball: Deckbuilding Game                                            |          2023 |
|  425935 | Roses and Betrayals                                                       |          2024 |
|  425936 | Phantom Fury: Second Edition                                              |          2024 |
|  425937 | Les Reines du Shopping                                                    |          2014 |
|  425939 | Tie Break Padel                                                           |          2024 |
|  425940 | COAL&GUNS big battles: Lissa 1866                                         |          2024 |
|  425941 | Tide & Tangle                                                             |          2024 |
|  425942 | Znáte Evropu?                                                             |          2019 |
|  425943 | Battle for Treas                                                          |          2024 |
|  425944 | Haifischen: Ein Spiel mit Biss                                            |          2024 |
|  425954 | Memory Master                                                             |          2020 |
|  425957 | Egg Hunt Homicide                                                         |          2024 |
|  425960 | A Deadly Roulette                                                         |          2024 |
|  425972 | Catalog of Suspicion                                                      |          2024 |
|  425977 | Order Up! Sushi                                                           |          2022 |
|  425978 | Modo tieso                                                                |          2024 |
|  425979 | Cazadores de serpientes                                                   |          1987 |
|  426009 | Monstrys Halloween                                                        |          2024 |
|  426011 | Asylum Escape                                                             |            NA |
|  426023 | Tournament of Power                                                       |          2024 |
|  426024 | Dr. Leichenberg’s Apothecary of Remedies                                  |          2025 |
|  426026 | 9lives: Don’t Kill the Cat                                                |          2018 |
|  426033 | Hunt A Killer Cold Case: Girl in the Well                                 |          2024 |
|  426034 | COINS: Bulls and Bears                                                    |          2024 |
|  426035 | Hitster: Volume 2                                                         |          2024 |
|  426039 | Feliz No Cumpleaños                                                       |          2024 |
|  426040 | Crimetime: Fall 1950 – Stimmen in meinem Kopf                             |          2023 |
|  426043 | DANGER: The High Voltage Game                                             |          2024 |
|  426044 | Tinder of Civilization                                                    |          2023 |
|  426045 | Rumblebots                                                                |          2024 |
|  426051 | My First Race                                                             |          2023 |
|  426066 | Risorgimento                                                              |          2024 |
|  426067 | ExonQuest                                                                 |            NA |
|  426070 | Let’s Go! Singapore Edition                                               |          2022 |
|  426073 | Longiquus                                                                 |          2024 |
|  426079 | +Sociable                                                                 |          2024 |
|  426082 | Spiky Go!                                                                 |          2024 |
|  426085 | Pets! On Board                                                            |          2024 |
|  426091 | DuoLex                                                                    |          2024 |
|  426095 | Necromunda: Hive Secundus                                                 |          2024 |
|  426097 | Dog Poker / Cat Poker                                                     |          2024 |
|  426098 | What Do you Meme? on the GO!                                              |          2018 |
|  426102 | Only Murders in the Building: The Game                                    |          2024 |
|  426103 | Stack the Cactus                                                          |            NA |
|  426104 | The Nya-Mens                                                              |            NA |
|  426105 | Rabbits Detective Usan                                                    |            NA |
|  426106 | Clue: Squishmallows                                                       |          2023 |
|  426119 | Mal ja, mal nein                                                          |          1958 |
|  426122 | The Mesol War                                                             |          2025 |
|  426123 | Star Wars Rivals – Series 2: Premier Set                                  |          2024 |
|  426125 | Champs de Bataille II                                                     |          2024 |
|  426126 | Rhin & Danube Alsace 44                                                   |          2024 |
|  426127 | Muumit Marjasssa                                                          |            NA |
|  426130 | Quadrupoley                                                               |          2024 |
|  426133 | ChessBriscola card game                                                   |          2024 |
|  426135 | Kabal: A Game of World Domination                                         |          2025 |
|  426136 | Word Wiz                                                                  |          2023 |
|  426137 | Sloppy Synopsis: Movie Edition                                            |          2021 |
|  426138 | 羽觞飞花 (Yushang Feihua)                                                 |          2019 |
|  426139 | Buccaneers of the Americas                                                |          2024 |
|  426140 | Wild Guess!                                                               |          2024 |
|  426146 | Tank Clash: Eastern Front                                                 |          2025 |
|  426147 | Murder in Miami                                                           |          2023 |
|  426148 | Snaffle: Original Edition                                                 |          2024 |
|  426150 | Hardwood Duel                                                             |          2025 |
|  426154 | Queen’s Blood                                                             |          2024 |
|  426159 | Super Basket                                                              |          1976 |
|  426160 | Girls vs Ghouls                                                           |          2025 |
|  426161 | Possenreißer                                                              |          2019 |
|  426162 | Thing Thing                                                               |          2024 |
|  426166 | In vino veritas: Das lateinische Weisheitenspiel                          |          2011 |
|  426167 | Tilelandia                                                                |          2025 |
|  426169 | Away Team Bingo                                                           |          2024 |
|  426170 | The Warlock of Firetop Mountain: A Fighting Fantasy Quest Game            |          2025 |
|  426173 | Battle Eternal                                                            |          2026 |
|  426174 | Panem et Circenses                                                        |          2025 |
|  426175 | Specter Secrets                                                           |          2020 |
|  426181 | L’eveil des SangDragons                                                   |          2023 |
|  426182 | Blau hat Anstoß                                                           |            NA |
|  426183 | Operation Rädda Danmark                                                   |          2022 |
|  426184 | Granfondo: Tempo, Taktik, Kettenfett                                      |          2024 |
|  426186 | CatCare                                                                   |          2023 |
|  426191 | Paranoia: The Uncooperative Board Game                                    |          2024 |
|  426208 | Word Roll                                                                 |            NA |
|  426225 | Work of the JCG                                                           |          2023 |
|  426226 | Battle of Wada                                                            |          2023 |
|  426228 | Monopoly: San Jose Edition                                                |          2023 |
|  426229 | Overparked                                                                |          2024 |
|  426230 | Trust Me                                                                  |          2024 |
|  426231 | Dicepen Family Collection                                                 |          2024 |
|  426235 | Borgia, le jeu malsain                                                    |          2012 |
|  426240 | Turn Up Sharks Returns: The super B-class shark strikes back!             |          2022 |
|  426241 | Hunt A Killer: A Wealth of Murder                                         |          2024 |
|  426242 | Chonker Party                                                             |          2024 |
|  426243 | Monopoly: Squishmallows                                                   |          2023 |
|  426249 | Warhamster The Game                                                       |          2024 |
|  426258 | HELL: Legends                                                             |          2025 |
|  426259 | Fuga da Orkatraz                                                          |          2022 |
|  426272 | Ryoan-ji                                                                  |          2023 |
|  426275 | Dungeon Kart (Gold Tier Kickstarter Edition)                              |          2024 |
|  426283 | Food Truck Race                                                           |          2025 |
|  426300 | Average Performers                                                        |          2024 |
|  426301 | Eclipse Realms: Rise of the Cosmic Sovereigns                             |          2024 |
|  426311 | Lewd Dungeon Adventures: The Card Game                                    |          2024 |
|  426313 | Normandy Tank Battle 1944                                                 |          2023 |
|  426314 | Betty Botter Bought Some Butter                                           |          2024 |
|  426316 | Voyage olfactif                                                           |          2022 |
|  426318 | 7th Inning Stretch                                                        |          2024 |
|  426319 | Thalamus                                                                  |          2025 |
|  426322 | Aventuria: Chalices of Power Campaign Box                                 |          2025 |
|  426323 | Paw War                                                                   |          2024 |
|  426329 | River Woods                                                               |          2024 |
|  426330 | Chartered: Building Amsterdam                                             |          2024 |
|  426333 | Monopoly: Edizione Monopoli                                               |          2019 |
|  426342 | Aventuria: Curse of the Desert                                            |          2025 |
|  426343 | Iràs i no tornaràs                                                        |          2024 |
|  426348 | Chrono Bibliotheca                                                        |          2023 |
|  426349 | Journey to Tír na nÓg                                                     |          2025 |
|  426350 | Guardian Super Force                                                      |          2024 |
|  426355 | Onoda                                                                     |          2025 |
|  426357 | David Sundins Oopzy!                                                      |          2022 |
|  426359 | Medicine Wheel                                                            |          2024 |
|  426360 | Spectra                                                                   |          2024 |
|  426362 | Gift Craft                                                                |          2024 |
|  426363 | Mermaid’s Song                                                            |          2024 |
|  426365 | Qube: Flaggor och länder                                                  |          2017 |
|  426368 | Liberation: 2024                                                          |          2024 |
|  426369 | Super Ski Jump                                                            |          2017 |
|  426379 | Tornado Force                                                             |            NA |
|  426390 | EuroQuiz                                                                  |          2000 |
|  426399 | House of the Dragon: Dark Dealings                                        |          2024 |
|  426400 | Guess My Ride! 2-Player Automotive Card Game!                             |          2024 |
|  426402 | CRU Trivia: Volume 1. Supercars                                           |          2024 |
|  426405 | Built Not Bought!                                                         |          2024 |
|  426406 | Walt Disney´s Kavalkad-spel                                               |            NA |
|  426408 | Match Up!                                                                 |          2018 |
|  426410 | SandLand Tactical Card Battle                                             |          2024 |
|  426411 | Helsinkipeli                                                              |            NA |
|  426412 | Sugarworks                                                                |          2025 |
|  426425 | One To Ten                                                                |          2023 |
|  426431 | Desolito                                                                  |          2024 |
|  426433 | É Pizza Memo!                                                             |          2024 |
|  426434 | That’s Donald!                                                            |            NA |
|  426438 | Console Wars: The Card Game                                               |          2024 |
|  426439 | Atkhtide TCG                                                              |          2026 |
|  426440 | 蟲神器 (Mushi Jingi)                                                      |          2022 |
|  426444 | My Life Be Like                                                           |          2024 |
|  426445 | Paperback Wordle                                                          |          2022 |
|  426446 | Etymology: The Card Game                                                  |          2024 |
|  426448 | Vi algo nas sombras                                                       |          2024 |
|  426449 | Pawvocados                                                                |          2023 |
|  426454 | Parole Quiz                                                               |          2021 |
|  426455 | Silvestre in the Rif                                                      |          2025 |
|  426458 | Monopoly: Čudesna Srbija                                                  |          2024 |
|  426460 | Trust Issues                                                              |            NA |
|  426461 | Taboo Horror                                                              |          2024 |
|  426465 | Wonderland Rush                                                           |          2022 |
|  426467 | Trekking the National Parks: Third Edition                                |          2024 |
|  426468 | Monster Palace                                                            |          2021 |
|  426469 | Kronos Epilogue Remastered: Kosmogonia 2086                               |          2024 |
|  426474 | Pirâmide Matemática                                                       |          2024 |
|  426476 | Donald Duck in Happy Camper                                               |          2024 |
|  426481 | Bring Out Your Men, Gentlemen: The Battle of Brawner’s Farm               |          2024 |
|  426482 | One Piece Nakama: Friends & Enemies                                       |          2024 |
|  426483 | Risk: Dune                                                                |          2024 |
|  426487 | VETO Card Game                                                            |          2023 |
|  426488 | Spells and Wizards                                                        |          2023 |
|  426489 | Ships and Sailors                                                         |          2023 |
|  426491 | Shots and Throws                                                          |          2023 |
|  426492 | Asteriated Adventures: Duel                                               |          2024 |
|  426498 | Southern Surf Stakes                                                      |          2024 |
|  426499 | Clue: The Muppets                                                         |          2024 |
|  426500 | Monopoly: Guy Fieri’s Flavortown                                          |          2024 |
|  426501 | Sweet Dreams                                                              |          2022 |
|  426502 | Connectables                                                              |          2024 |
|  426507 | Bugchums: Mini-Mart Merchant                                              |          2024 |
|  426509 | The itty bitty card game                                                  |          2024 |
|  426511 | Smyle                                                                     |          2024 |
|  426512 | Star Trek: Lower Decks – Buffer Time: The Card Game                       |          2024 |
|  426513 | Emberleaf                                                                 |          2025 |
|  426516 | C’est Carré                                                               |          2024 |
|  426519 | La Cour de Versailles                                                     |          2024 |
|  426521 | Wyld                                                                      |          2024 |
|  426522 | Cryptex                                                                   |          2024 |
|  426523 | HYVE                                                                      |          2024 |
|  426529 | The Lawns of Nome                                                         |          2024 |
|  426536 | 屁者先知 (Pizhe Xianzhi)                                                  |          2024 |
|  426547 | Tower Stack                                                               |            NA |
|  426555 | Color Climbers                                                            |          2024 |
|  426561 | Dynamic Circular Chess                                                    |          2024 |
|  426564 | Rebellion & Punishment: War Of The Alpujarras                             |          2026 |
|  426565 | Spooky Forest                                                             |          2024 |
|  426567 | Commodity Chain                                                           |          2024 |
|  426570 | Heroes of Might and Magic: Battles                                        |          2025 |
|  426572 | Il Gioco della Puglia                                                     |          2012 |
|  426578 | Panjango Trumps                                                           |          2018 |
|  426579 | SDGS industrial planner                                                   |          2022 |
|  426580 | Legendary: A Marvel Deck Building Game (Second Edition)                   |          2025 |
|  426581 | Cloudfall                                                                 |          2024 |
|  426583 | 房総 1894 (Bousou 1894)                                                   |          2024 |
|  426584 | Giocolieri di Parole                                                      |          2022 |
|  426585 | Wake Up Stars                                                             |          2019 |
|  426586 | Siclen Valley                                                             |          2025 |
|  426587 | Touhou Shisouroku: Touhou Chireiden Hen                                   |          2014 |
|  426589 | Touhou Shisouroku: Touhou Fuujinroku Hen                                  |          2013 |
|  426596 | Best in Show Dashing Dogs                                                 |          2025 |
|  426598 | Humboldt                                                                  |          2019 |
|  426599 | Verkehrsspiel ’69                                                         |          1969 |
|  426601 | Frying Master                                                             |          2024 |
|  426602 | Certamen: Dark Magic                                                      |          2025 |
|  426603 | Tip of the Diceberg                                                       |          2024 |
|  426604 | Gold Hustle                                                               |          2024 |
|  426608 | 地主来了: 大丰收 (Landlord’s Coming: Bumper Harvest)                      |          2023 |
|  426609 | Llengut                                                                   |          2023 |
|  426611 | Pispa                                                                     |          2022 |
|  426613 | Im Hexenkessel                                                            |            NA |
|  426619 | Questionable                                                              |          2021 |
|  426620 | Showdown 2                                                                |          2023 |
|  426622 | Reforged                                                                  |          2024 |
|  426623 | Terra Eterna                                                              |          2024 |
|  426626 | Coalition: Councils of the Republic                                       |          2025 |
|  426628 | Billionaire Bunker                                                        |          2024 |
|  426634 | Seafarers: Spice Islands                                                  |            NA |
|  426635 | Paladins of Glass                                                         |            NA |
|  426636 | Narrowboat Navigator                                                      |          2024 |
|  426640 | Check the Oven                                                            |            NA |
|  426645 | Lily Pond                                                                 |          2019 |
|  426657 | Red Flag of Heroes                                                        |          2023 |
|  426658 | FrogHop                                                                   |          2021 |
|  426659 | Don’t Touch My Booty!                                                     |          2021 |
|  426665 | Lunar Skyline                                                             |          2025 |
|  426669 | Iwo Jima 1945                                                             |          2024 |
|  426680 | Game of Drones                                                            |          2024 |
|  426689 | The Rainbow Fish Domino Game                                              |          1999 |
|  426691 | Weirdos Wanted                                                            |          2024 |
|  426692 | The Vibe                                                                  |          2025 |
|  426702 | MasterChef: Italian Game Night                                            |          2021 |
|  426710 | Rifle Squad: US at Omaha Beach – A Solitaire Wargame                      |          2024 |
|  426712 | Compitum                                                                  |          2024 |
|  426715 | Stacking Blocks Balancing Game                                            |          2022 |
|  426723 | Moon Shamans                                                              |          2025 |
|  426726 | Bank Robbery                                                              |          2024 |
|  426754 | Robot Raiders: Swarm of the Spider Titan                                  |            NA |
|  426755 | Wicked Christmas Card Game                                                |          2025 |
|  426762 | Speldown                                                                  |          1989 |
|  426763 | Du Bisch vo Zug                                                           |          2022 |
|  426764 | The Jane Austen Game                                                      |          2024 |
|  426765 | Dungeon Saga Origins: The Dice Game                                       |          2024 |
|  426803 | Otters to the Rescue                                                      |          2024 |
|  426805 | Rae Gunn and Rescue Rocket                                                |          2024 |
|  426807 | Star Gazers                                                               |          2024 |
|  426808 | Roll and Reanimate                                                        |          2024 |
|  426813 | Ich fahre Auto                                                            |          1978 |
|  426828 | Purple Heart Valley                                                       |            NA |
|  426836 | Cowpens 1781                                                              |          2024 |
|  426837 | 地主来了: 大团圆 (Landlord’s Coming: Grand Reunion)                       |          2024 |
|  426840 | In Harm’s Way: Naval Battles of the Dutch East Indies, 1942               |          2024 |
|  426847 | Askalotl                                                                  |          2024 |
