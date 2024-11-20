
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
| 430490 | Lost Rendezvous | 2026 |
| 430533 | Formaggio | 2026 |
| 430860 | Toast The Most | 2026 |
| 431098 | Breakers | 2026 |
| 431159 | France Overseas, 1940 | 2026 |
| 427805 | New Greenland | 2025 |
| 429493 | Faunian | 2025 |
| 429645 | Magic Filler | 2025 |
| 429765 | SILOS | 2025 |
| 429766 | EGO | 2025 |
| 429767 | ORBIT | 2025 |
| 429895 | Vestige | 2025 |
| 429943 | Blood Dynasty | 2025 |
| 430116 | A New Order of Samurai: Clash of Sengoku Daimyos, 1570-1580 | 2025 |
| 430154 | Duke | 2025 |
| 430379 | OverPower | 2025 |
| 430401 | Battles for Quebec | 2025 |
| 430440 | Haunebu: Twilight of the Reich | 2025 |
| 430446 | DAVOS | 2025 |
| 430472 | Ocean Frenzy | 2025 |
| 430515 | Space Potato | 2025 |
| 430522 | Hunted: Transylvania / Escape from Route 52 | 2025 |
| 430524 | DNA: The New Origin of Species | 2025 |
| 430532 | Operation Dragoon 1944 | 2025 |
| 430534 | French & Indian War: Solitaire | 2025 |
| 430536 | Europe At War 1940: Solitaire | 2025 |
| 430537 | Shogun Solitaire | 2025 |
| 430554 | Legend Academy (Gamefound Edition) | 2025 |
| 430563 | Popcorn | 2025 |
| 430568 | A Normal Card Game | 2025 |
| 430585 | Dragoon Empire | 2025 |
| 430611 | Hyperstar Run | 2025 |
| 430614 | Valencia | 2025 |
| 430616 | Chichén Itzá | 2025 |
| 430628 | Guilty: Fontainebleau 1543 | 2025 |
| 430662 | Athos Bulcão: Master Pieces | 2025 |
| 430675 | The Devil´s Antiquarian | 2025 |
| 430679 | Videography | 2025 |
| 430694 | Zwai | 2025 |
| 430726 | The Peak Team | 2025 |
| 430727 | Das Hochbeet von Schalottenburg | 2025 |
| 430733 | Penitent | 2025 |
| 430734 | Cat Saga: Tangled Tails | 2025 |
| 430743 | Ayacucho 1824 | 2025 |
| 430755 | Bidder Battle | 2025 |
| 430761 | By the People | 2025 |
| 430769 | Survive the Tombs of the Cryptids | 2025 |
| 430780 | Grunling: Fantastic Fruits | 2025 |
| 430794 | Pathfinder Quest | 2025 |
| 430797 | Disco Heist Laundry | 2025 |
| 430807 | Survivors: The Board Game | 2025 |
| 430809 | The DUNGENERATOR: DIE in a Dungeon | 2025 |
| 430813 | Battle for the Deep: Powered by Axis & Allies | 2025 |
| 430814 | Diplomacy: Era of Empire | 2025 |
| 430816 | My Little Pony: Festival of Lanterns | 2025 |
| 430817 | Wraith & The Giants | 2025 |
| 430835 | The Twelfth Battle: Caporetto 1917 | 2025 |
| 430851 | Fable Fury | 2025 |
| 430869 | Cats Vs Dragons | 2025 |
| 430882 | The Chronicles of BERG | 2025 |
| 430902 | La Der des Ders: The War to End War | 2025 |
| 430918 | Star Trek: Picard – Murder on the Titan-A | 2025 |
| 430919 | Star Trek: Strange New Worlds – Mary Celeste | 2025 |
| 430921 | Quattro trick-taking | 2025 |
| 430938 | Tyr: Arena Sands | 2025 |
| 430967 | Dark Kingdoms | 2025 |
| 430970 | Moomoowa | 2025 |
| 430981 | Heroes of Might & Magic III: The Board Game – Big Box Expansion | 2025 |
| 431000 | Insecta: Facsimile Edition | 2025 |
| 431024 | Flush | 2025 |
| 431033 | La Bataille de Kulm | 2025 |
| 431038 | Azul Duel | 2025 |
| 431040 | Diluvio | 2025 |
| 431043 | 如鲠在喉：1940~1942年地中海战役 (A Stick in the Throat: Battle of the Mediterranean 1940-1942) | 2025 |
| 431081 | Knitten: Pawns and Yarns | 2025 |
| 431082 | Cluckaneers | 2025 |
| 431083 | Finding Calm | 2025 |
| 431087 | A Raccoon’s Game: Seven Saves the Notch | 2025 |
| 431093 | XSCAPE | 2025 |
| 431107 | Make your bubble tea | 2025 |
| 431157 | Battle for Finland: 1944 | 2025 |
| 431158 | The Path to Victory: Middle East, 1941 | 2025 |
| 431171 | Loose In The Library | 2025 |
| 431175 | D-Day Dice: Pacific | 2025 |
| 431185 | Molly | 2025 |
| 431200 | Staxxit | 2025 |
| 431205 | Kanata: The First Sacrament | 2025 |
| 431247 | Treacherous Trails | 2025 |
| 431248 | For a Crown | 2025 |
| 431256 | Notebook Knockout | 2025 |
| 431262 | City Tour | 2025 |
| 431266 | Roll a Gain | 2025 |
| 431280 | 2 Win | 2025 |
| 431281 | 20 Bucks for That?! | 2025 |
| 431284 | Fifty Fruity | 2025 |
| 431285 | Magicaboo | 2025 |
| 431290 | LINKX | 2025 |
| 431304 | Mythicals | 2025 |
| 431312 | Cakezilla | 2025 |
| 431324 | Umbra Morfes | 2025 |
| 431331 | Zurvivors Origem | 2025 |
| 431341 | Monster Gunslingers | 2025 |
| 431344 | Elenco | 2025 |
| 431368 | BloodFeud: Samurai versus Vikings | 2025 |
| 431396 | PlotWeaver: Cards of Creation | 2025 |
| 431399 | Abyss: The Board Game | 2025 |
| 431423 | Baltic Freikorps, 1919 | 2025 |
| 431453 | ConspiraSea | 2025 |
| 431458 | Monarch | 2025 |
| 431478 | Devious | 2025 |
| 431479 | ENTHRONE | 2025 |
| 431480 | OUTFOX the FOX | 2025 |
| 431481 | A Place for All My Books | 2025 |
| 431527 | Kangaroo Island | 2025 |
| 431548 | QUIZehn: Allgemeinwissen | 2025 |
| 431549 | QUIZehn: Natur & Nonsens | 2025 |
| 431551 | QUIZehn: Popkultur & Popcorn | 2025 |
| 431566 | Chronicles of Civilization | 2025 |
| 431582 | Dice Throne Outcasts | 2025 |
| 431585 | Trench Raid: Solitaire Patrol Command on the WW1 Western Front | 2025 |
| 431586 | Gladiator’s: Blood & Glory | 2025 |
| 431590 | Dungeons & Dragons: Edge of the Realms | 2025 |
| 431630 | MadMatix | 2025 |
| 413799 | Raging Wheels | 2024 |
| 421552 | El Mundo de Luka | 2024 |
| 426367 | Kotki Psotki | 2024 |
| 426566 | Dead Serious | 2024 |
| 429278 | Advent, Advent, ein Grablicht brennt | 2024 |
| 429303 | Sygil: The Mirrored Reality | 2024 |
| 429370 | Railian | 2024 |
| 429371 | Mindhell | 2024 |
| 429379 | We Need To Talk: A Trick-Taking and Shedding Game About Letting Go | 2024 |
| 429508 | Fuego | 2024 |
| 429771 | Arschlochmensch | 2024 |
| 429930 | Oikos | 2024 |
| 429963 | Texas Hold It | 2024 |
| 429993 | Electioneer: US Edition | 2024 |
| 430009 | Spelet om Barndomen | 2024 |
| 430046 | LavaRun | 2024 |
| 430047 | Island Escape | 2024 |
| 430053 | Hidden Games Tatort: Alle unter einem Dach | 2024 |
| 430081 | Metus | 2024 |
| 430083 | Raptor Race | 2024 |
| 430097 | Read the Room | 2024 |
| 430126 | Blocktivity: Partytime | 2024 |
| 430273 | OVER TOURISM Kyoto | 2024 |
| 430307 | Escaping Extinction: Based on a True Story | 2024 |
| 430321 | Pumpkin Rally | 2024 |
| 430327 | Rock & Roll Brouhaha | 2024 |
| 430336 | Crima de la Ospiciul Obreja | 2024 |
| 430341 | Dylan Dog: L’alba dei morti viventi | 2024 |
| 430354 | Hands Off My Pecker | 2024 |
| 430360 | Animal Words | 2024 |
| 430376 | Talismans in the Mist | 2024 |
| 430396 | Plundering Times | 2024 |
| 430403 | Age of Neighbors | 2024 |
| 430410 | 我是霸王龍 (Who’s Rex) | 2024 |
| 430415 | Cursed Hunter | 2024 |
| 430416 | Crown: War of Succession | 2024 |
| 430420 | Ta mère en slip | 2024 |
| 430423 | Esprit es-tu là? | 2024 |
| 430439 | Adventure Trek | 2024 |
| 430455 | Mafia | 2024 |
| 430456 | Überhol mich doch! | 2024 |
| 430460 | Flick Force | 2024 |
| 430461 | Allmoge | 2024 |
| 430474 | Dodecathlon | 2024 |
| 430478 | Electrify | 2024 |
| 430479 | Sci-Me! logic | 2024 |
| 430482 | Burst of Mana | 2024 |
| 430494 | Rotodo | 2024 |
| 430495 | Taco Tajm | 2024 |
| 430509 | Goghme | 2024 |
| 430513 | The Escape Room Game: Haunted Cinema Edition | 2024 |
| 430525 | Shake it! | 2024 |
| 430526 | Sorcery: Contested Realm – Arthurian Legends | 2024 |
| 430527 | The Final Defense | 2024 |
| 430539 | Without A Doubt? | 2024 |
| 430550 | Соображарий: Москва (Think It Up!: Moscow) | 2024 |
| 430562 | Polska Przyroda: Gra Edukacyjna | 2024 |
| 430570 | Cronocartas: Historia de Galicia | 2024 |
| 430572 | Horrible Therapist | 2024 |
| 430576 | Farewell | 2024 |
| 430578 | Butt What? | 2024 |
| 430586 | La Bataille d’ Eggmuhl 1809 | 2024 |
| 430589 | Silver Linings: Challenge each Season | 2024 |
| 430591 | Stibro | 2024 |
| 430592 | MANTIS: Grab & Game Edition | 2024 |
| 430593 | Exploding Kittens: Grab & Game Edition | 2024 |
| 430598 | Hula | 2024 |
| 430599 | Соображарий: Три кота (Think It Up!: Kid-E-Cats) | 2024 |
| 430603 | 7Dec41: Pearl Harbor! | 2024 |
| 430606 | Super Wild Rummitiles | 2024 |
| 430613 | Bloom | 2024 |
| 430630 | 五等分の花嫁 Card Game (5hanayome Card Game/Quintessential Quintuplets Card Game) | 2024 |
| 430631 | Pigeon Punch | 2024 |
| 430633 | Lava House | 2024 |
| 430634 | Park Life: People Deluxe | 2024 |
| 430635 | Wednesday: The Card Game | 2024 |
| 430637 | Casefile: Temptation & Trickery Game | 2024 |
| 430640 | Summer Camp: A Party Hack Game | 2024 |
| 430641 | Park Life: Hedgehog Deluxe | 2024 |
| 430643 | SAS: Rogue Regiment – Black Ops Special Edition | 2024 |
| 430644 | Little Secret | 2024 |
| 430646 | Watch Out Beetlejuice | 2024 |
| 430669 | Fate Of The Kingdom | 2024 |
| 430671 | Onze Gagnant | 2024 |
| 430676 | Madame Medora’s House of Curiosities | 2024 |
| 430690 | 一統中原 (Yi Tong Zhong Yuan) | 2024 |
| 430692 | Hidden Games Tatort: Campingkiller | 2024 |
| 430697 | Murder On The Moon | 2024 |
| 430698 | Snaptastic | 2024 |
| 430699 | Jungle Hustle | 2024 |
| 430703 | Heroes: LMS 10th Anniversary Edition | 2024 |
| 430728 | Mystria | 2024 |
| 430730 | Las Ligas de la Ñ: El juego de los muertos vivientes | 2024 |
| 430746 | Unsolved Case Files: Mini Case – Luna Knight | 2024 |
| 430747 | Rimini Libera | 2024 |
| 430750 | Swirls | 2024 |
| 430757 | Manacaster | 2024 |
| 430758 | Alien G | 2024 |
| 430759 | Bomber In A Book | 2024 |
| 430762 | Profiler | 2024 |
| 430763 | Sblocca la Porta: Freetime | 2024 |
| 430764 | Krach 29 | 2024 |
| 430765 | Exit: Das Spiel – Adventskalender 2024: Das intergalaktische Wettrennen | 2024 |
| 430779 | Unsolved Case Files: Photo Case – Angela Justice | 2024 |
| 430783 | Silk’s Trace | 2024 |
| 430790 | Ultraman Card Game | 2024 |
| 430791 | Friko Bestiale | 2024 |
| 430793 | coloWArs | 2024 |
| 430795 | Ode to Mare Nostrum: Conflicts of Western Europe 1212-1250 | 2024 |
| 430825 | ARDEVUR: The Game of Resources | 2024 |
| 430836 | Plaguefall | 2024 |
| 430850 | Backstage Business | 2024 |
| 430852 | Three Feudatories: Pingxi | 2024 |
| 430853 | Three Feudatories: Yanping | 2024 |
| 430856 | Gachapon Trick | 2024 |
| 430857 | Agency | 2024 |
| 430859 | Tritium | 2024 |
| 430866 | Mind me! | 2024 |
| 430867 | Funny Destination (La Quedaste…) | 2024 |
| 430875 | High Tide | 2024 |
| 430883 | Plants Against Veganity | 2024 |
| 430888 | Triplets Word Game | 2024 |
| 430889 | El Monstruo Debajo de la Cama: One Card | 2024 |
| 430926 | Customer Disservice | 2024 |
| 430939 | Demonuki | 2024 |
| 430951 | Lingarda | 2024 |
| 430952 | Crazy Basket Game | 2024 |
| 430953 | Under Tower | 2024 |
| 430954 | Long Story Short: Carmen & Carlos | 2024 |
| 430955 | Long Story Short: Le Trésor du Capitaine Boyle | 2024 |
| 430961 | Showdown: Championship Drag Racing – Top Fuel & Funny Car 2023 Season | 2024 |
| 430962 | Pilvax | 2024 |
| 430969 | Enfargar | 2024 |
| 430974 | Eylau-1807 Solitaire | 2024 |
| 430976 | Zodiac Stack | 2024 |
| 430977 | Felci | 2024 |
| 430978 | Q-Ra Code: A QR Code Manipulation Pen & Paper Game | 2024 |
| 430979 | Heroes of Might & Magic III: The Board Game – Big Box | 2024 |
| 430983 | Gyógypuszi | 2024 |
| 430985 | Ghost Blitz Mini | 2024 |
| 430991 | Exopets and Mimicrys | 2024 |
| 430993 | Raftul Jocurilor | 2024 |
| 430996 | The Ultimate 2 Player Game | 2024 |
| 430997 | Dice Dreams | 2024 |
| 431006 | Varázsösvény: Építs utat! Hátráltass másokat! Juss ki a mocsárból! | 2024 |
| 431019 | Vau | 2024 |
| 431021 | Summit or Plummet | 2024 |
| 431022 | Petir | 2024 |
| 431039 | Murder Mystery Cases: Death of an Influencer | 2024 |
| 431042 | Infinity N5: Core Rules | 2024 |
| 431044 | Swing Your Sausage | 2024 |
| 431046 | 21 Inches | 2024 |
| 431047 | Help I S\*xted My Boss | 2024 |
| 431049 | Hack & Slash Deluxe | 2024 |
| 431053 | Behold: Rome | 2024 |
| 431054 | Kippkopp kvartett | 2024 |
| 431055 | Duck Duck What | 2024 |
| 431062 | Csend Apó kertje | 2024 |
| 431079 | Исторический детектив: Ведьма (Historical Mystery: The Witch) | 2024 |
| 431092 | Dreams of Empire | 2024 |
| 431097 | Five Parsecs From Home: Bug Hunt | 2024 |
| 431100 | La Casa | 2024 |
| 431103 | OrthoGnomes | 2024 |
| 431104 | The Bear Hunter | 2024 |
| 431106 | Bee Chess | 2024 |
| 431110 | Showdown: Championship Drag Racing – Pro Stock & Pro Mod 2023 Season | 2024 |
| 431121 | Rivales: Capítulo 2 – Ciencia | 2024 |
| 431152 | Opetellaan Liikennepeli | 2024 |
| 431153 | Pollinators | 2024 |
| 431155 | PAKU PACK (パクパック) | 2024 |
| 431163 | High & Low: Card Game | 2024 |
| 431168 | Busy Buses | 2024 |
| 431169 | Stokerverse | 2024 |
| 431170 | Red Herrings | 2024 |
| 431183 | Wednesday: The Hyde’s Attack | 2024 |
| 431197 | Roaring River | 2024 |
| 431202 | Talvisota | 2024 |
| 431203 | Silentalk | 2024 |
| 431208 | Purple Haze: Tunnel Rats | 2024 |
| 431225 | Inscryption IRL: 2 Player Adaptation | 2024 |
| 431226 | Buttload of Dice Dungeon | 2024 |
| 431230 | Korea: The Fight Across the 38th | 2024 |
| 431231 | Hampshire Battle Royale | 2024 |
| 431237 | Five Seasons | 2024 |
| 431240 | Four Corner Detective | 2024 |
| 431243 | Gravity Three | 2024 |
| 431244 | Point Art | 2024 |
| 431257 | Micromend | 2024 |
| 431258 | Bigotes en Caos | 2024 |
| 431292 | Box Two | 2024 |
| 431295 | DIGCODE | 2024 |
| 431307 | Krakkakviss 4 | 2024 |
| 431311 | Ham Fisted | 2024 |
| 431319 | 乱戦空域 (Fighter in Gun Sight) | 2024 |
| 431323 | Amazongo | 2024 |
| 431334 | Kinder Bunnies: Their Second Adventure | 2024 |
| 431337 | Heroes: LMS 10th Anniversary card game | 2024 |
| 431360 | Wurfel Wedding | 2024 |
| 431366 | Hedged In | 2024 |
| 431367 | Bet the Line! | 2024 |
| 431369 | インサイドアウト (Inside Out) | 2024 |
| 431370 | Demonslayer: Solo Adventure Game | 2024 |
| 431371 | Rattenkrieg 2: Battle for the Barrikady Factory | 2024 |
| 431379 | Biodio | 2024 |
| 431402 | Adventure in a Box: Finsterwacht | 2024 |
| 431410 | Quack Heads | 2024 |
| 431419 | アクオチクエスト(Fallen Quest) | 2024 |
| 431420 | প্যাঁচফোড়ন (Pyachforon) | 2024 |
| 431422 | Three D-Days: 1942, 1943 & 1944 | 2024 |
| 431424 | Dieren Stapelen | 2024 |
| 431428 | Panots | 2024 |
| 431432 | Tiki Taka | 2024 |
| 431439 | Bremer Stadtmusikanten | 2024 |
| 431447 | Easter Egg Hunt: A family token memory game | 2024 |
| 431449 | Embezzlement: Honesty Never Pays | 2024 |
| 431450 | Colonise | 2024 |
| 431451 | Flucht aus der Bahn | 2024 |
| 431454 | Seoul Night | 2024 |
| 431456 | The Great Pyramid | 2024 |
| 431482 | 雞不可失 (Chicken’t) | 2024 |
| 431561 | Rabbit Rock Racing | 2024 |
| 431581 | Poll & Write USA | 2024 |
| 431591 | Word Whiz | 2024 |
| 431594 | Castle of the Vampire | 2024 |
| 431596 | MRBLS | 2024 |
| 431613 | Kabutar | 2024 |
| 431614 | Rock Paper Spirits | 2024 |
| 431615 | Battlefront Valkyrie | 2024 |
| 431616 | Pippi Långstrump Tjolahoppspelet | 2024 |
| 431622 | Jujutsu Kaisen: The Cursed Spirits Escape – Shibuya Incident- | 2024 |
| 417564 | Red Flag Green Flag | 2023 |
| 430158 | Crima de la Circul Radovan | 2023 |
| 430480 | Begurk | 2023 |
| 430542 | The Escape Room Game: Cabin in the Woods Edition | 2023 |
| 430632 | Catharsis Sagas: Chapter 2 – Soverign | 2023 |
| 430744 | Emblem Five | 2023 |
| 430756 | 暁のナイル (Nile in the dawn) | 2023 |
| 430804 | 西安繁华录 (Splendor of Xi’an) | 2023 |
| 430929 | Три пирога (Three pies) | 2023 |
| 430950 | Edaraz | 2023 |
| 430958 | 上海风云 (Turbulence of Shanghai) | 2023 |
| 430959 | 我在成都养熊猫 (Raising Pandas in Chengdu) | 2023 |
| 430972 | Tenorimadori | 2023 |
| 430994 | Murder Mystery: Murder on the Express | 2023 |
| 431026 | Lost in Nurmijärvi | 2023 |
| 431051 | Rhymin Time | 2023 |
| 431052 | Anti Draft | 2023 |
| 431089 | Over Crest Rally | 2023 |
| 431165 | A Purrfect Murder | 2023 |
| 431167 | The Roswell Incident | 2023 |
| 431172 | Brickskrieg | 2023 |
| 431173 | The CHD Game | 2023 |
| 431179 | Scoop Mania: Sundae Makers Wanted | 2023 |
| 431180 | Hungry Hoppers: Tile Placement Game | 2023 |
| 431394 | Sandy Diggs in the Pyramids of Madness | 2023 |
| 431405 | Rock Paper Scissors: Logic. Memory. Luck. | 2023 |
| 431406 | Secret Santa: A family token bluffing game. | 2023 |
| 431407 | Icecread | 2023 |
| 431412 | Double Done 151 | 2023 |
| 431418 | Fairness and Equality | 2023 |
| 431448 | Selling the Dream | 2023 |
| 431563 | Ronny Roller | 2023 |
| 431609 | Manatliq | 2023 |
| 431617 | Denkprofi: Das Brettspiel mit App | 2023 |
| 431620 | Haikyu!! YELL!! | 2023 |
| 430517 | WWE Road to Wrestlemania Board Game | 2022 |
| 430691 | Push Off | 2022 |
| 430705 | War of the Pacific: 1879-1881 | 2022 |
| 430768 | De Influence | 2022 |
| 430777 | Waterloo: Napoleon’s Last Battle | 2022 |
| 430868 | 君到姑苏见 (Scenes of Suzhou) | 2022 |
| 430928 | 金陵风华 (Grandeur of Nanjing) | 2022 |
| 430956 | 最忆是杭州 (Memories of Hangzhou) | 2022 |
| 430957 | 重庆迷宫 (Labyrinth of Chongqing) | 2022 |
| 430966 | UNO: All Wild! Grogu! | 2022 |
| 431003 | T-Rex Topple! | 2022 |
| 431145 | The Golden Journey | 2022 |
| 431239 | Vanished in Vegas | 2022 |
| 431282 | CreatureCrush: Dice Card Game | 2022 |
| 431388 | Spielspaß im Kindergarten | 2022 |
| 431608 | The Price of Coal | 2022 |
| 431618 | One Piece Vivre Rush | 2022 |
| 431619 | Bleach Songs of the Soul | 2022 |
| 431625 | Candy Necklace | 2022 |
| 430150 | Kronologik | 2021 |
| 430377 | Hellfire over Kraljevo | 2021 |
| 430609 | こちら異世界転生局 (Isekai Reincarnation Bureau) | 2021 |
| 430642 | Santa’s Helper | 2021 |
| 431149 | TrapBall | 2021 |
| 431217 | Portal Block | 2021 |
| 431238 | Murder on the Istanbul Express | 2021 |
| 431246 | Savango | 2021 |
| 431310 | Lombard: Życie pod zastaw | 2021 |
| 431400 | Shabada | 2021 |
| 431421 | Mauseschlau & Bärenstark: Naturdetektive | 2021 |
| 431484 | Śledztwo w Białym Domu | 2021 |
| 430330 | Stories of the Three Coins | 2020 |
| 430751 | Spooky Boo! | 2020 |
| 430973 | SPARK The Magic of Storytelling | 2020 |
| 431016 | Stadt Land Seriös | 2020 |
| 431433 | El Tonto del Pueblo | 2020 |
| 431437 | Danganronpa: The First Class Trial | 2020 |
| 431624 | Reunion with Death | 2020 |
| 430732 | Party & Co: Ultimate | 2019 |
| 430827 | にゃんけんぽん (Nyankenpon) | 2019 |
| 430992 | 이스케이프 룸: 2탄 (Escape Room: The Game 2) | 2019 |
| 431211 | ING | 2019 |
| 431385 | Copper Creek | 2019 |
| 430100 | E-motionz: Wersja Light | 2018 |
| 430101 | E-motionz: Wersja Exclusive | 2018 |
| 430320 | Cubattle | 2018 |
| 430344 | Бестиарий Сигиллума. Коллекционное издание (Bestiary of Sigillum: Collector’s Edition) | 2018 |
| 430815 | Мотлох або Скарб (Trash or Treasure) | 2017 |
| 430920 | Ам Ням К’ю (OmnIQ) | 2017 |
| 431008 | Книга чаклуна (Wizard’s book) | 2017 |
| 431014 | Escape Room: The Game | 2017 |
| 431017 | Escape room: Το παιχνίδι | 2017 |
| 429330 | Cabinet Shuffle | 2016 |
| 431181 | Story Time: Infinite Stories | 2016 |
| 431403 | Unnützes Quizzen: Fußball | 2016 |
| 431088 | Termik | 2014 |
| 430540 | Buzz Word / Buzz Word Junior | 2012 |
| 430833 | W.I.T.C.H.: Návrat Nerissy | 2010 |
| 431398 | L’Assedio! 1312 Firenze | 2010 |
| 424366 | Casino Boudoir | 2003 |
| 431251 | Räknespel | 2001 |
| 431393 | Quiz mit ? | 1997 |
| 429961 | Argad ! | 1996 |
| 431429 | Son Goku Dragon Ball | 1991 |
| 430879 | 7x7 Oktató játék | 1988 |
| 429846 | Party Joy Series 84 Saint Seiya Gold Saint Daikessen | 1987 |
| 430738 | Wir würfeln um die Brandschutz-“Eins” | 1980 |
| 431378 | International Rescue Thunderbirds | 1967 |
| 430670 | Towards Soviet America | 1934 |
| 431306 | An Adventure Around Sydney | 1929 |
| 431340 | Ringkampf | 1928 |
| 429439 | Amoriax | NA |
| 430317 | Fantasy Wars | NA |
| 430337 | Crima din Balta Vrajitoarelor | NA |
| 430338 | Crima din Hotelul Cismigiu | NA |
| 430339 | Crima din Padurea Hoia-Baciu | NA |
| 430340 | Ultimul Jurnal de Expeditie | NA |
| 430350 | Enormity | NA |
| 430400 | Bellicus | NA |
| 430551 | Aschenbrödl | NA |
| 430584 | Our Flower | NA |
| 430588 | Γνωρίζω την Ευρώπη (Learn about Europe) | NA |
| 430594 | Pantoffel-Jagd | NA |
| 430674 | Skyland: Adventure’s Dawn | NA |
| 430741 | In der Märchenstadt | NA |
| 430806 | Bastard | NA |
| 430828 | Quadro | NA |
| 430927 | Abenteuer Weltraum | NA |
| 431018 | 이스케이프 룸 방 탈출 게임 (Escape Room: The Game) | NA |
| 431025 | Fuga dalla Giungla | NA |
| 431027 | Frolic Bears | NA |
| 431064 | Gastonia-Opoly | NA |
| 431134 | Chopper Pilot Vietnam | NA |
| 431143 | Mister Mix | NA |
| 431216 | Echo from the Dark | NA |
| 431241 | Les Mystères de Pékin Junior | NA |
| 431254 | Rompe el Silencio | NA |
| 431259 | Calypto | NA |
| 431313 | CreatureCrush: Neu-Babylon | NA |
| 431386 | Beetown Beatdown | NA |
| 431387 | Früher oder später? | NA |
| 431389 | Die Krachmacher | NA |
| 431397 | Half Byte | NA |
| 431434 | Torero vs Dinosaurio | NA |
| 431436 | República Bananera: La Vacuna Española | NA |
| 431446 | Das Wehr-Lehr-Spiel | NA |
| 431457 | Osmosis | NA |
| 431593 | Stepping Into Hell | NA |
| 431621 | Ready Steady Pack | NA |
