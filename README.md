
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

| game_id | name                                                                              | yearpublished |
|--------:|:----------------------------------------------------------------------------------|--------------:|
|  426713 | PRINCIPES                                                                         |          2025 |
|  426794 | Shadows Deep                                                                      |          2025 |
|  426798 | Shrine: Duel of Light                                                             |          2025 |
|  426799 | Gnock                                                                             |          2025 |
|  426868 | Quartermaster General: South Front                                                |          2025 |
|  426869 | Tikal Legend                                                                      |          2025 |
|  426912 | Tea Witches                                                                       |          2025 |
|  426945 | Baseball Highlights: 2045 – Bases Loaded Edition                                  |          2025 |
|  426964 | Waves                                                                             |          2025 |
|  427036 | Reef & Ruins                                                                      |          2025 |
|  427128 | The Proving Ground                                                                |          2025 |
|  427167 | The Battle of Vinegar Hill                                                        |          2025 |
|  427192 | River Rush                                                                        |          2025 |
|  427202 | La Pâtisserie Rococo                                                              |          2025 |
|  427246 | The Lady and the Tiger: Dragon’s Flight                                           |          2025 |
|  427248 | 大宋百商图：过年好！(A Dream of Splendor in Song Dynasty: Happy New Year!)        |          2025 |
|  427260 | Living Forest Duel                                                                |          2025 |
|  427277 | Mattergy                                                                          |          2025 |
|  427286 | Rook Requiem                                                                      |          2025 |
|  427288 | Nexus Rift: Battle of Dimensions                                                  |          2025 |
|  427292 | Pebbles                                                                           |          2025 |
|  427293 | Birds on Birds                                                                    |          2025 |
|  427297 | Ogrefish                                                                          |          2025 |
|  427335 | Billionaires and Guillotines                                                      |          2025 |
|  427338 | Cachamot                                                                          |          2025 |
|  427339 | Color Words                                                                       |          2025 |
|  427340 | Cocoons                                                                           |          2025 |
|  427351 | Tranquil Sky                                                                      |          2025 |
|  427361 | Flock!                                                                            |          2025 |
|  427380 | Tanares Expeditions: Central Sea                                                  |          2025 |
|  427388 | Tend                                                                              |          2025 |
|  427439 | Fear of the Dark                                                                  |          2025 |
|  427575 | Rokku                                                                             |          2025 |
|  427664 | Whisker Wars                                                                      |          2025 |
|  427692 | Limits of Glory: Donning the Sacred Heart                                         |          2025 |
|  427713 | Pathfinder Dice Conquest                                                          |          2025 |
|  427796 | Harbor of Blight                                                                  |          2025 |
|  425442 | Timebomb: Undercover                                                              |          2024 |
|  425856 | Touched by Darkness                                                               |          2024 |
|  426447 | Those Who Dig                                                                     |          2024 |
|  426643 | Al-Jabr!                                                                          |          2024 |
|  426647 | Port and Plunder                                                                  |          2024 |
|  426718 | Ghost Gate Chronicles: Part 1.5 – Skulk’s Brew                                    |          2024 |
|  426767 | Ordre de Veiel: Deckbuilding Tactique                                             |          2024 |
|  426768 | The Battle of Byeokjegwan                                                         |          2024 |
|  426774 | Tech Deck Legacy                                                                  |          2024 |
|  426778 | Smalltown Tales                                                                   |          2024 |
|  426796 | Stamp Swap                                                                        |          2024 |
|  426844 | Quickshot & Gun                                                                   |          2024 |
|  426852 | Unicorn Glitterluck: Game Collection                                              |          2024 |
|  426853 | Deeds of Daring: Individual Combat During the French and Indian War (1754 – 1763) |          2024 |
|  426861 | Card Sharks: Feeding Frenzy                                                       |          2024 |
|  426872 | Plunderlust: Revenants Raider Deck                                                |          2024 |
|  426873 | Jujutsu Kaisen: Fléaux! Le jeu de cartes                                          |          2024 |
|  426908 | Goldfield 1907                                                                    |          2024 |
|  426909 | BISTRO                                                                            |          2024 |
|  426948 | Merlin’s Crucible                                                                 |          2024 |
|  426957 | History of the World                                                              |          2024 |
|  426960 | Dust Race: Press Start                                                            |          2024 |
|  426962 | Final Fantasy: Moogle Bounty Mayhem                                               |          2024 |
|  426968 | Big Orange: Good Luck                                                             |          2024 |
|  426980 | D-Day Solitaire: Omaha Beach                                                      |          2024 |
|  426982 | Trick’n Treat                                                                     |          2024 |
|  426994 | Urbion (Second Edition)                                                           |          2024 |
|  426999 | Shiloh: The First Day                                                             |          2024 |
|  427005 | Haywire                                                                           |          2024 |
|  427006 | Time Trouble                                                                      |          2024 |
|  427007 | Heroes of Oktoberfest                                                             |          2024 |
|  427008 | Omok Chess: Hundred Years’ War                                                    |          2024 |
|  427027 | 99 Heroes                                                                         |          2024 |
|  427028 | Bajo Amenaza                                                                      |          2024 |
|  427044 | QIC                                                                               |          2024 |
|  427046 | Supermallows: Weniger frisst mehr                                                 |          2024 |
|  427060 | Batalla Elemental                                                                 |          2024 |
|  427062 | Inside the Net Soccer                                                             |          2024 |
|  427063 | EKKO                                                                              |          2024 |
|  427073 | The Shackleton Series: Interactive Puzzle Adventure                               |          2024 |
|  427084 | Superstore 3000                                                                   |          2024 |
|  427087 | Perspectives Blue                                                                 |          2024 |
|  427092 | Command & Cohesion World War II                                                   |          2024 |
|  427093 | IGNITOR -the Mystic Crystals-                                                     |          2024 |
|  427094 | The Wrong Herring                                                                 |          2024 |
|  427097 | Out of Sorts                                                                      |          2024 |
|  427102 | Qanqash                                                                           |          2024 |
|  427106 | Unlock! Kids: Histoire de l’Île d’Émeraude                                        |          2024 |
|  427108 | Squidbeard Island: A Treasure Hunting Game                                        |          2024 |
|  427109 | Toastie Toss Smash!                                                               |          2024 |
|  427110 | At the Mesas of Madness: a game of dares and dexterity                            |          2024 |
|  427111 | Creak… Clink… Clang… Bang!                                                        |          2024 |
|  427117 | Next Station The Singapore MRT Game                                               |          2024 |
|  427135 | E.L.E Crisis on Asteroid SV1                                                      |          2024 |
|  427140 | Happy Birthday to Me                                                              |          2024 |
|  427141 | Candyman: Farewell to the Flesh                                                   |          2024 |
|  427142 | 萬人之上 Beyond Thousands                                                         |          2024 |
|  427149 | 投骰写写: 聪明厨房 (Roll and Write: Smart Kitchen)                                |          2024 |
|  427150 | Blitz Bowl: Ultimate Second Edition                                               |          2024 |
|  427157 | SpyOuts                                                                           |          2024 |
|  427162 | Mini-Game Party                                                                   |          2024 |
|  427163 | Memo Lunch                                                                        |          2024 |
|  427164 | Havoc F1                                                                          |          2024 |
|  427165 | Evoloosen                                                                         |          2024 |
|  427175 | 拆弹对决 (Telebomb: Duel)                                                         |          2024 |
|  427177 | Snake Papel                                                                       |          2024 |
|  427197 | Slime Monster                                                                     |          2024 |
|  427200 | Lepra                                                                             |          2024 |
|  427205 | Minos: Daedalus’ Labyrinth                                                        |          2024 |
|  427208 | Order Up! Fish Market                                                             |          2024 |
|  427232 | Takoyaki                                                                          |          2024 |
|  427237 | Swashbuckle                                                                       |          2024 |
|  427238 | Werwölfe Kids                                                                     |          2024 |
|  427241 | Make ‘n’ Break: Around the World                                                  |          2024 |
|  427249 | Myth Mash                                                                         |          2024 |
|  427251 | Il Posto Fisso                                                                    |          2024 |
|  427253 | Warriors of Legend                                                                |          2024 |
|  427254 | Iron Future                                                                       |          2024 |
|  427257 | 1930中原大战 (1930 Central Plains War)                                            |          2024 |
|  427259 | 恐龍家族快樂西餐廳 (Happy Western Restaurant)                                     |          2024 |
|  427261 | Cat Horror Costume                                                                |          2024 |
|  427266 | Miramix                                                                           |          2024 |
|  427267 | Replica                                                                           |          2024 |
|  427272 | The Fractured Flat                                                                |          2024 |
|  427283 | A Hard Day’s Work: The Battle of Droop Mountain, November 6, 1863                 |          2024 |
|  427296 | Ultramons: The Ultimate Monster Battle                                            |          2024 |
|  427319 | Dark and Darker Mobile                                                            |          2024 |
|  427324 | Prize Fighter                                                                     |          2024 |
|  427325 | 推しセリフOshiSerihu (My Best Lines)                                              |          2024 |
|  427327 | No Dachi, No Dice                                                                 |          2024 |
|  427330 | The Powerlineboard analoge Spielkonsole                                           |          2024 |
|  427332 | Pubmill                                                                           |          2024 |
|  427341 | Trick or Bid                                                                      |          2024 |
|  427342 | Power Tricks                                                                      |          2024 |
|  427345 | Res Arcana Duo                                                                    |          2024 |
|  427353 | Mixart                                                                            |          2024 |
|  427354 | Hitster: 100% Franco                                                              |          2024 |
|  427357 | Night Thirst                                                                      |          2024 |
|  427375 | Quests Over Coffee: Solo Game Of The Month Edition                                |          2024 |
|  427376 | Race Day                                                                          |          2024 |
|  427382 | Silly Seance                                                                      |          2024 |
|  427384 | Dune: Shadow Emissary                                                             |          2024 |
|  427387 | Battle Sword                                                                      |          2024 |
|  427393 | Custodian Dice                                                                    |          2024 |
|  427432 | Murder in the Pines                                                               |          2024 |
|  427434 | Cartaventura: Cosmologia                                                          |          2024 |
|  427435 | Drag Racing Maximum                                                               |          2024 |
|  427445 | S.Mall                                                                            |          2024 |
|  427446 | Feed the Geckos                                                                   |          2024 |
|  427452 | Raindrop Forest                                                                   |          2024 |
|  427456 | Guildmasters of Aurelia                                                           |          2024 |
|  427459 | Sketch Artist                                                                     |          2024 |
|  427464 | Gangs of Kyoto                                                                    |          2024 |
|  427467 | 古战：三国志 (Ancient War: Heroes and the Three Kingdoms)                         |          2024 |
|  427469 | Who Murdered the Turtle?                                                          |          2024 |
|  427500 | Golpher                                                                           |          2024 |
|  427509 | Gamma Guild                                                                       |          2024 |
|  427520 | Snatching Pears                                                                   |          2024 |
|  427555 | Zipper                                                                            |          2024 |
|  427560 | Treat or Cheat                                                                    |          2024 |
|  427567 | Apparition                                                                        |          2024 |
|  427582 | Double-Cross Dungeon                                                              |          2024 |
|  427589 | Dice Raiders: Terracota Army                                                      |          2024 |
|  427590 | WIJA                                                                              |          2024 |
|  427596 | Castle Raisers                                                                    |          2024 |
|  427598 | Amazonia Park                                                                     |          2024 |
|  427599 | Is It!: Thai Dished                                                               |          2024 |
|  427603 | Himmapan: The Story of Agni Mani                                                  |          2024 |
|  427620 | Spy City                                                                          |          2024 |
|  427624 | Ich habe fertig                                                                   |          2024 |
|  427625 | Opalstone Kingdom                                                                 |          2024 |
|  427626 | Orcas: Yacht Rock                                                                 |          2024 |
|  427629 | Hoozhoo                                                                           |          2024 |
|  427635 | Mirianth Pets                                                                     |          2024 |
|  427638 | VLKNO                                                                             |          2024 |
|  427644 | Between Light & Shadow Chapter 2 Twilight                                         |          2024 |
|  427666 | Rock Island: 1812, Illinois                                                       |          2024 |
|  427674 | Bierfischen: Ein Spiel mit Bier                                                   |          2024 |
|  427699 | Don’t Be A Sheep                                                                  |          2024 |
|  427703 | Last One Laughing: Das Spiel – Mini Edition                                       |          2024 |
|  427707 | Lorepets                                                                          |          2024 |
|  427717 | Critter Rasslin                                                                   |          2024 |
|  427718 | Label Legends                                                                     |          2024 |
|  427728 | Dread Nought!                                                                     |          2024 |
|  427729 | Amazing Robot                                                                     |          2024 |
|  427748 | War is Our Homeland: Wargame Rules for Big Battles During the Age of the Tercio   |          2024 |
|  411139 | Destination Portsmouth: Day-Night Edition                                         |          2023 |
|  425967 | Dinosaur x Dinosaur                                                               |          2023 |
|  426843 | Pokémon Trading Card Game Classic                                                 |          2023 |
|  426885 | Mikkeller’s Beer Geek Bonanza                                                     |          2023 |
|  426923 | El legado de Ofiuco                                                               |          2023 |
|  426961 | uChi Gueva!: Minsei vs. Zenkyoto, Battle of the University of Tokyo Campus        |          2023 |
|  426965 | Інтенція. Епоха спраги (Intention)                                                |          2023 |
|  427061 | 迷子 (MAIGO)                                                                      |          2023 |
|  427095 | Mord bei Tisch: Dorfdisco                                                         |          2023 |
|  427122 | Backrooms TCG                                                                     |          2023 |
|  427137 | 史记：楚汉相争 (Shiji: The Chu–Han Contention)                                    |          2023 |
|  427179 | Time’s Up!: Festival International des Jeux                                       |          2023 |
|  427180 | Pictionary: Sketch Squad                                                          |          2023 |
|  427243 | Bocals to Bocals                                                                  |          2023 |
|  427247 | iFluence Land                                                                     |          2023 |
|  427265 | FireFight: Command Protocols                                                      |          2023 |
|  427275 | Twisted Tales                                                                     |          2023 |
|  427326 | toriteita-46                                                                      |          2023 |
|  427329 | ¡Princesas al rescate!                                                            |          2023 |
|  427643 | Koppie Koppie Unicorn                                                             |          2023 |
|  425477 | Mickey and Friends Walt Disney World: Memory Game                                 |          2022 |
|  426641 | Jump 1                                                                            |          2022 |
|  426758 | ¿Verdadero o falso?                                                               |          2022 |
|  426910 | Buen Camino                                                                       |          2022 |
|  426916 | Neighborhoodies                                                                   |          2022 |
|  426993 | Misty of Mood                                                                     |          2022 |
|  426997 | 西游释厄传 (Journey to the West: Odyssey)                                         |          2022 |
|  427000 | Dr Seuss Thing One and Thing Two Where Are You? Game                              |          2022 |
|  427099 | Galaxia Chess                                                                     |          2022 |
|  427161 | Trivial Pursuit: Hausparty                                                        |          2022 |
|  427174 | Multiplication Race                                                               |          2022 |
|  427225 | Alle mot alle                                                                     |          2022 |
|  427392 | Number Rods                                                                       |          2022 |
|  427528 | UNO: Star Wars – Technical Schematics                                             |          2022 |
|  427556 | Race to Escape: The Escape Room Board Game                                        |          2022 |
|  427558 | Race Across The World                                                             |          2022 |
|  427604 | What’s Your Problem?                                                              |          2022 |
|  426867 | Kings Island-Opoly                                                                |          2021 |
|  426949 | “I Would Buy Bitcoin”                                                             |          2021 |
|  426950 | “I Would Meet Jesus”                                                              |          2021 |
|  427039 | Logic 99                                                                          |          2021 |
|  427043 | Crew in a Stew                                                                    |          2021 |
|  427064 | Maailman arkkitehtuuri                                                            |          2021 |
|  427065 | MasterChef: Indian Game Night                                                     |          2021 |
|  427129 | Math Game Set 4-IN-1                                                              |          2021 |
|  427333 | Pop Shogi                                                                         |          2021 |
|  427561 | Word it out!                                                                      |          2021 |
|  427569 | Bordel Temporel                                                                   |          2021 |
|  426822 | Super Things: Rivals of Kaboom – Juego de cartas                                  |          2020 |
|  426848 | Babylon Rise                                                                      |          2020 |
|  426849 | Blitzkrieg BRS                                                                    |          2020 |
|  427002 | 三盗 (Three Thieves)                                                              |          2020 |
|  427068 | 穿越拆弹 (Telebomb)                                                               |          2020 |
|  427085 | STICKS Pick it                                                                    |          2020 |
|  427086 | STICKS Get it                                                                     |          2020 |
|  410110 | Disney Frozen II: Snowflake Catch                                                 |          2019 |
|  426725 | Finnelis                                                                          |          2019 |
|  426988 | Забытые Боги (Forgotten Gods)                                                     |          2019 |
|  427170 | Pandas in Space                                                                   |          2019 |
|  427185 | Pour combien?                                                                     |          2019 |
|  426644 | Uncle Beary’s Bedtime                                                             |          2018 |
|  426995 | Mince Spies                                                                       |          2018 |
|  427098 | Panjango Trumps: Future Jobs                                                      |          2018 |
|  427553 | E-motionz                                                                         |          2018 |
|  427605 | Pocket Realm Crafter                                                              |          2018 |
|  427623 | Otpisani: Belgrade Resistance 1941-45                                             |          2018 |
|  427648 | SSG Basketball                                                                    |          2018 |
|  427785 | The Legend of Korra: Pro-Bending Arena Deluxe Edition                             |          2018 |
|  427712 | Covarde                                                                           |          2017 |
|  426938 | Do It Again!                                                                      |          2016 |
|  426939 | Pickles’ Slide to Win                                                             |          2016 |
|  426941 | Watch My Wings                                                                    |          2016 |
|  426996 | The Forevergone                                                                   |          2016 |
|  427242 | Scribble Scramble                                                                 |          2016 |
|  426865 | Submultiple Game (腦王爭霸之超級因數)                                             |          2014 |
|  427159 | Marvel HeroClix: Iron Man 3                                                       |          2013 |
|  427262 | Le Pion des Trous                                                                 |          2013 |
|  427352 | Plankgas: Wie vindt, die wint!                                                    |          2013 |
|  427362 | Wendy Spillet                                                                     |          2007 |
|  427138 | Newton Spillet                                                                    |          2005 |
|  425073 | Travel Win, Lose or Draw Junior                                                   |          1988 |
|  427381 | Battlezones: Scenarios for Ultra Modern Period                                    |          1984 |
|  427366 | Wargaming Pike-and-Shot                                                           |          1977 |
|  427587 | Geviertspil                                                                       |          1977 |
|  427433 | Rokeeto                                                                           |          1965 |
|  427501 | Old Surehand                                                                      |          1965 |
|  285759 | One Night Werewolf: Madness                                                       |            NA |
|  402332 | Pirate Boat Balancing Game                                                        |            NA |
|  425561 | Plank: Krakatoa                                                                   |            NA |
|  426932 | Scratch and Scramble                                                              |            NA |
|  426953 | WEBB                                                                              |            NA |
|  426971 | Mana Spring                                                                       |            NA |
|  426977 | Thief                                                                             |            NA |
|  427001 | Three Kingdoms Go Go Chess                                                        |            NA |
|  427096 | Clarenville-Opoly                                                                 |            NA |
|  427105 | Grimdark Future: Warfleets                                                        |            NA |
|  427114 | Tatamgram                                                                         |            NA |
|  427127 | Mon Repos Print & Play                                                            |            NA |
|  427136 | Sabodeus                                                                          |            NA |
|  427156 | Bird Bash                                                                         |            NA |
|  427203 | Chow Pow                                                                          |            NA |
|  427234 | Three Kobolds in a Trench Coat                                                    |            NA |
|  427349 | Puppies with Powers                                                               |            NA |
|  427363 | Paw Patrol: My Treat                                                              |            NA |
|  427551 | Snack-Rifice                                                                      |            NA |
|  427601 | Trash Rush                                                                        |            NA |
|  427602 | ColorFit                                                                          |            NA |
|  427673 | Lignum: Раскол                                                                    |            NA |
