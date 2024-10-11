
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
| 428791 | Dope | 2026 |
| 428993 | Peking: 55 Days Of Fury | 2026 |
| 429033 | Bardsung: Tale of the Forsaken Glade | 2026 |
| 405811 | Far Far West | 2025 |
| 426651 | Ibyron: Island of Discovery 2nd Edition | 2025 |
| 427667 | Delivery Witches | 2025 |
| 427671 | Mighty Shot! | 2025 |
| 427788 | Rébus Mix | 2025 |
| 427800 | Pitch Out: Under Vs Aquilies | 2025 |
| 427828 | CATS & DRAGONS | 2025 |
| 427830 | Hantise | 2025 |
| 427831 | Fools’ Fuel | 2025 |
| 427840 | Free Solo | 2025 |
| 427886 | Fossilium | 2025 |
| 427942 | Stack O’ Cats | 2025 |
| 427989 | Escaping Reality | 2025 |
| 428018 | STASH Card Game | 2025 |
| 428022 | Hubble Run | 2025 |
| 428024 | River Rats | 2025 |
| 428080 | Big Spender | 2025 |
| 428099 | Revenant | 2025 |
| 428113 | Legends Odyssey | 2025 |
| 428127 | Galen’s Games Mint Tin Series | 2025 |
| 428148 | Pixie Trails | 2025 |
| 428149 | Bunker Down! | 2025 |
| 428150 | Rescate Animal | 2025 |
| 428196 | That’s my cat | 2025 |
| 428231 | Pulitzer | 2025 |
| 428241 | Dragonlings | 2025 |
| 428244 | DC Deck-Building Game: Arkham Asylum | 2025 |
| 428264 | 1899 DAIHAN | 2025 |
| 428280 | The G.O.A.T. | 2025 |
| 428282 | TimemiT | 2025 |
| 428284 | Here Lies | 2025 |
| 428296 | Holiday Hijinks \#10: The Leprechaun Larceny | 2025 |
| 428297 | Holiday Hijinks \#11: The New Year Nightmare | 2025 |
| 428298 | Holiday Hijinks \#12: The Krampus Caper | 2025 |
| 428308 | Unmatched: Muhammad Ali vs Bruce Lee | 2025 |
| 428351 | Yomi 2: Road to Morningstar | 2025 |
| 428359 | Roborover 2077: Last Hope | 2025 |
| 428423 | War of the Arcane | 2025 |
| 428440 | Shallow Sea | 2025 |
| 428441 | Terra Del Mar | 2025 |
| 428443 | Stax: Galaxy | 2025 |
| 428451 | The Wise Investor | 2025 |
| 428529 | Breakthrough Russia | 2025 |
| 428537 | Through the Zoo | 2025 |
| 428538 | Zoo and More | 2025 |
| 428540 | Skybirds | 2025 |
| 428580 | BRUTUS! | 2025 |
| 428582 | Dark Tomb: The Ice Chasers | 2025 |
| 428586 | Wild Side | 2025 |
| 428589 | Thief’s Market | 2025 |
| 428619 | Dungeons & Dragons: Builders of Baldur’s Gate | 2025 |
| 428629 | Goblin Party | 2025 |
| 428635 | Ruins | 2025 |
| 428636 | Oddland | 2025 |
| 428664 | Fantasy Realms: Greek Legends | 2025 |
| 428709 | CLANS | 2025 |
| 428717 | Huddle: The Fantasy Football Game | 2025 |
| 428721 | Echo Team: Spearhead | 2025 |
| 428735 | Unvention | 2025 |
| 428758 | Big Fish Card Game | 2025 |
| 428776 | Pirate King! | 2025 |
| 428787 | Presages | 2025 |
| 428792 | Common Earth | 2025 |
| 428827 | Sinking Yamato | 2025 |
| 428845 | Crisis 1962 | 2025 |
| 428848 | Legions of Kadmon | 2025 |
| 428908 | San Juan: The Card Game | 2025 |
| 428934 | Combat! Volume 4: Eastern Front | 2025 |
| 428939 | Pompeii | 2025 |
| 428992 | Dark Heists | 2025 |
| 429114 | Nova Era | 2025 |
| 429123 | Last Aurora: Frostlands | 2025 |
| 429130 | Invincible: The Card Game | 2025 |
| 429152 | Twilight Struggle: 20th Anniversary Hall of Fame Edition | 2025 |
| 425263 | ExCowl | 2024 |
| 427235 | 大行列 (Big Queue) | 2024 |
| 427269 | Pfad der Elemente | 2024 |
| 427278 | Roaring 20s | 2024 |
| 427336 | Banana Boy VS Uni-Cone | 2024 |
| 427584 | We Forlorn Few | 2024 |
| 427593 | Hive Ultimate | 2024 |
| 427646 | Indovina Burqi | 2024 |
| 427736 | The Atomic Builders | 2024 |
| 427737 | Mythoria: Clash of Legends | 2024 |
| 427738 | Shadow & Blade | 2024 |
| 427739 | Flucht aus Munich | 2024 |
| 427773 | Eternal Mist: Cursed of the Forsaken Forest | 2024 |
| 427787 | Murdle | 2024 |
| 427795 | Crowns & Consequences | 2024 |
| 427797 | Chemistry Set | 2024 |
| 427799 | Top Secret: Briefs | 2024 |
| 427807 | hololive: Official Card Game | 2024 |
| 427810 | Dixit Universe Access+ | 2024 |
| 427811 | Dungeon Up | 2024 |
| 427841 | Boulder Bluff | 2024 |
| 427865 | Souvenirs from Venice | 2024 |
| 427866 | Deep Sea Adventure Boost | 2024 |
| 427870 | Awaken the Ancients | 2024 |
| 427880 | turtles | 2024 |
| 427887 | Castle Builder | 2024 |
| 427894 | Expedition: Beyond | 2024 |
| 427899 | HandQuest: in-hand dungeon crawler | 2024 |
| 427900 | NINE | 2024 |
| 427904 | Hot Pot Holic | 2024 |
| 427907 | Gimbap | 2024 |
| 427908 | Zeta: Survival | 2024 |
| 427909 | Hello! Tea Time | 2024 |
| 427943 | Oganika Arcanum: Hex 16 | 2024 |
| 427944 | Making Honey Hunny | 2024 |
| 427957 | CORSAIR: DoTin Bay | 2024 |
| 428009 | Grave Keeper: A Victorian Roll & Write Game | 2024 |
| 428014 | Soulshards: Broken Alliance | 2024 |
| 428015 | Crimson Keep | 2024 |
| 428019 | Scrabble / Scrabble Together | 2024 |
| 428027 | Trouble at Hand | 2024 |
| 428029 | Doodle Puzzle | 2024 |
| 428030 | UNO Teams! | 2024 |
| 428031 | Let’s Go! To Japan: Matsuri Edition | 2024 |
| 428032 | 1789 | 2024 |
| 428055 | Football Feud! | 2024 |
| 428057 | Anno Domini: Eco | 2024 |
| 428058 | Up or Down? | 2024 |
| 428060 | Front Line: Strategy Edition | 2024 |
| 428061 | Stand or Starve | 2024 |
| 428062 | Camargue | 2024 |
| 428075 | レリック・レイダース：激流! – 大いなるビーストレリック(Relic Raiders: Raging Rapids! – The Great Beast Relic) | 2024 |
| 428076 | Kidnapping | 2024 |
| 428077 | Sideral: Fusão Galáctica | 2024 |
| 428081 | Quítate eso | 2024 |
| 428082 | Enlightened | 2024 |
| 428083 | Fil Rouge: En Chacun de Nous | 2024 |
| 428085 | In Extremis | 2024 |
| 428089 | Ghosts Can’t Draw | 2024 |
| 428094 | Uskoci: A Card Game about Croatian Pirates | 2024 |
| 428098 | Gliss | 2024 |
| 428100 | Back Whence Ye Came! | 2024 |
| 428104 | Wiki Histories | 2024 |
| 428106 | Catfé | 2024 |
| 428108 | Clash Of Steel: Tabletop Tank Battles | 2024 |
| 428109 | COINS: Whales | 2024 |
| 428114 | Soularis | 2024 |
| 428116 | TAROTUNA | 2024 |
| 428117 | Birdy Call | 2024 |
| 428123 | Pears | 2024 |
| 428140 | Holiday Rollout | 2024 |
| 428147 | Dragon vs. Kingdom | 2024 |
| 428151 | Whiskers AND Fins | 2024 |
| 428162 | Jogo Exploradores | 2024 |
| 428175 | Rate My Friends | 2024 |
| 428180 | SWOOP Card Game | 2024 |
| 428182 | Asterix & Compagnie | 2024 |
| 428185 | Vestiges of the Ancients | 2024 |
| 428191 | Seven Merry Monsters | 2024 |
| 428194 | Amalfi: Repubblica Marinara | 2024 |
| 428195 | BONO: The Numbers | 2024 |
| 428198 | Ice Hike: Beware of the Bears | 2024 |
| 428208 | The Keys to Happiness | 2024 |
| 428224 | 1 A.M. Jailbreak | 2024 |
| 428225 | CHEF! The Most Un-Balanced Card Game | 2024 |
| 428226 | O-Zone | 2024 |
| 428234 | La Ruina | 2024 |
| 428238 | Blizzard Blitz | 2024 |
| 428254 | Game of Gods | 2024 |
| 428256 | Centerpede | 2024 |
| 428257 | Sandpile Panic | 2024 |
| 428266 | A Tour of the Realm | 2024 |
| 428268 | Pariahs | 2024 |
| 428269 | Mumusok | 2024 |
| 428270 | Suspects Pocket: Hors-Jeu à Liverpool | 2024 |
| 428271 | Suspects Pocket: La Disparition du Pr. Fairchild | 2024 |
| 428279 | Trails of Tucana with Ferry Expansion | 2024 |
| 428281 | Keepsake | 2024 |
| 428283 | Monopoly: Wicked | 2024 |
| 428287 | Murder at Midnight | 2024 |
| 428288 | The Rock of Chickamauga | 2024 |
| 428294 | Draught Trick | 2024 |
| 428299 | Pantheon: A Deck Builder | 2024 |
| 428315 | Gangs of Rome | 2024 |
| 428317 | KADO | 2024 |
| 428319 | Capybara Cookie Club | 2024 |
| 428320 | Auf ein Wort! | 2024 |
| 428321 | Hexen Cocktail | 2024 |
| 428322 | Locus | 2024 |
| 428324 | Ninja Lite: Stealth & Tactics | 2024 |
| 428330 | Die!geon | 2024 |
| 428331 | In Memory Of | 2024 |
| 428336 | Bebê Diabo | 2024 |
| 428337 | Into the Pumpkin Patch We Go | 2024 |
| 428338 | Máquina dos Sonhos | 2024 |
| 428348 | The Best Medicine | 2024 |
| 428350 | Cocô, o Jogo | 2024 |
| 428352 | JAZZ | 2024 |
| 428353 | Ramen Extreme | 2024 |
| 428357 | Melissa Math | 2024 |
| 428361 | Don’t Flock Up | 2024 |
| 428363 | Blütentanz | 2024 |
| 428365 | Chaosphere: Black Hole | 2024 |
| 428366 | Operation Biting | 2024 |
| 428369 | Faith Battle | 2024 |
| 428376 | Cerro Gordo Silver Mines | 2024 |
| 428377 | Bastille | 2024 |
| 428381 | Vast Cosmos | 2024 |
| 428383 | Zama | 2024 |
| 428384 | Shapes of Play: Battle | 2024 |
| 428389 | Pocket Puffins | 2024 |
| 428393 | Survival: Scandinavia | 2024 |
| 428399 | Battlegroup: Bagration | 2024 |
| 428404 | Vita Luna | 2024 |
| 428419 | The Ants & The Grasshopper | 2024 |
| 428425 | Tricky Dragons | 2024 |
| 428429 | Draft’d | 2024 |
| 428431 | Traitor Tots | 2024 |
| 428444 | TROVE | 2024 |
| 428445 | Biscuits | 2024 |
| 428447 | Marimic: The Musical Time Machine | 2024 |
| 428449 | Warhammer Age of Sigmar: Beginner Set | 2024 |
| 428453 | Story Box: Polar | 2024 |
| 428457 | Refuge | 2024 |
| 428469 | Bloodline Leyend | 2024 |
| 428477 | Friends ‘n’ Foes | 2024 |
| 428479 | Charidice | 2024 |
| 428480 | Montrose Triumphs: The Battles of Auldearn and Alford, 1645 | 2024 |
| 428482 | The Tortoise & The Hare | 2024 |
| 428487 | Arctic Armies | 2024 |
| 428488 | BUM i BRUM: Rajd Malucha | 2024 |
| 428498 | Brain Line | 2024 |
| 428505 | Endgame: The Final Battle | 2024 |
| 428514 | Game of Traits | 2024 |
| 428515 | Varia: Angel vs. Demon | 2024 |
| 428518 | Snakers | 2024 |
| 428535 | Monopoly GO! | 2024 |
| 428539 | Dreidel Dash | 2024 |
| 428542 | Krampusnacht | 2024 |
| 428545 | Frog Pull | 2024 |
| 428556 | Farms Race: Deluxe Edition | 2024 |
| 428559 | Creature Caravan: Deluxe Edition | 2024 |
| 428560 | The 4 Elements | 2024 |
| 428573 | Time of War | 2024 |
| 428577 | Ananda | 2024 |
| 428578 | Die Trödler aus den Highlands | 2024 |
| 428579 | Beasty Bar: Down Under | 2024 |
| 428585 | Four Suit Dungeon Delve | 2024 |
| 428587 | Gestrudis | 2024 |
| 428588 | Circle of Friends: The Game | 2024 |
| 428590 | Hello | 2024 |
| 428603 | Match’n Lock! | 2024 |
| 428618 | Marcha Zombie | 2024 |
| 428621 | Respawn and Rumble | 2024 |
| 428622 | Book Surfers | 2024 |
| 428623 | Zachraň poklad | 2024 |
| 428626 | Mud & Blood | 2024 |
| 428628 | Drachentreppe | 2024 |
| 428630 | Wippe-lig! | 2024 |
| 428639 | Giraffe Raffe | 2024 |
| 428679 | Świętuj z Portalem | 2024 |
| 428682 | GROW SKY | 2024 |
| 428684 | Danger the Game: Whack a Moley | 2024 |
| 428691 | Cats and Caverns | 2024 |
| 428692 | Space Investors | 2024 |
| 428693 | Imwah | 2024 |
| 428696 | Rome Must Fall | 2024 |
| 428701 | Rafa koralowa | 2024 |
| 428707 | A Hard Day’s Work: The Battle of Droop Mountain, November 6, 1863 | 2024 |
| 428724 | SPIEKEROOG: Das Roll + Write Spiel | 2024 |
| 428725 | Asara (2nd Edition): Premium Edition | 2024 |
| 428747 | Epic Cat Christmas: Win the Holidays! | 2024 |
| 428751 | Postcard Solomons CVs | 2024 |
| 428752 | Temperance | 2024 |
| 428763 | Defactos: Istoria Romaniei I | 2024 |
| 428764 | Fifty Fifty | 2024 |
| 428766 | Boa Boa | 2024 |
| 428780 | Ref! O jogo da referência | 2024 |
| 428781 | Check PLEASE! | 2024 |
| 428782 | BOOM BOOM | 2024 |
| 428790 | Rabbit’s Potion | 2024 |
| 428796 | Am I Racist | 2024 |
| 428797 | Armor Up | 2024 |
| 428801 | Front Line: Tactics Edition | 2024 |
| 428816 | Monopoly: Flip Edition – Marvel | 2024 |
| 428818 | Bella Italia | 2024 |
| 428819 | Deadly Whisper: Feast of the Gods | 2024 |
| 428820 | Deadly Whisper: Asylum of Death | 2024 |
| 428834 | Worldwide Decathlon | 2024 |
| 428838 | Hockey Heroes | 2024 |
| 428844 | S.U.P.E.R. Héroes y villanos | 2024 |
| 428847 | Mango | 2024 |
| 428852 | The Horror: Possession | 2024 |
| 428886 | Only Love | 2024 |
| 428890 | Side Quest: The Isle of Cats | 2024 |
| 428891 | Hunted: North Pole (2nd Edition) | 2024 |
| 428892 | Devilry Afoot | 2024 |
| 428899 | Jelly Belly BeanBoozled: Taste the Truth Game | 2024 |
| 428903 | Numerica Fantastica | 2024 |
| 428904 | Desperate Oasis | 2024 |
| 428905 | Warning: This Game Farts! | 2024 |
| 428909 | Baby Bears Adventure Board Game | 2024 |
| 428910 | Robot Builders Board Game | 2024 |
| 428933 | Don’t Spill My Tea | 2024 |
| 428936 | Strange Rule | 2024 |
| 428937 | 曲奇加加樂 (Cookie Combo) | 2024 |
| 428942 | DRAK | 2024 |
| 428947 | Kaito & Diamond | 2024 |
| 428948 | Pixel Forts | 2024 |
| 428949 | Warleague | 2024 |
| 428951 | Dog Bone Dog | 2024 |
| 428967 | Kwiz | 2024 |
| 428989 | EcoLogic: Europe | 2024 |
| 429031 | Alien Sanctuary | 2024 |
| 429032 | Eradication | 2024 |
| 429034 | 開運コロシアム (Kaiun Coliseum) | 2024 |
| 429047 | Chirlito ROLL | 2024 |
| 429054 | Hoddog | 2024 |
| 429058 | Groopic Monsters’ Style | 2024 |
| 429060 | DIDAYO | 2024 |
| 429061 | TaleOrMem | 2024 |
| 429113 | Battle of Mekaverse | 2024 |
| 429121 | Battleship Tactical Strike! | 2024 |
| 429128 | Wicked: The Game | 2024 |
| 413181 | Pong Party! The Game | 2023 |
| 427280 | ALZH3IM3R | 2023 |
| 427559 | Family Judgement | 2023 |
| 427647 | Dragon Hero | 2023 |
| 427719 | Aquarium Trading | 2023 |
| 427740 | Lost Places | 2023 |
| 427808 | The Infinite Maze | 2023 |
| 427881 | 妖怪百奇八光 (Yokai Hyakkiyako) | 2023 |
| 427882 | Host Your Own Escape Room: Island Edition | 2023 |
| 428118 | Vilnius | 2023 |
| 428122 | Bangarang In the Gutterlands | 2023 |
| 428259 | Tornscape | 2023 |
| 428272 | Battle Requiem | 2023 |
| 428318 | Death Game Card: Coin | 2023 |
| 428442 | HACK | 2023 |
| 428508 | Chirlito RACE | 2023 |
| 428519 | ICE Civic Game | 2023 |
| 428541 | Sibley Birder’s Trivia | 2023 |
| 428627 | Plouf Canard | 2023 |
| 428678 | Zungenbrecher: Raus mit der Sprache! | 2023 |
| 428753 | The Dog’s Best Friend Game | 2023 |
| 428778 | Mentalista | 2023 |
| 428795 | Não Me Toca Seu Boboca! | 2023 |
| 428824 | Movie Mayhem: Buzzer Game | 2023 |
| 428906 | Cross Clues: Sample Pack | 2023 |
| 428935 | Timeline: ASI ed ESA | 2023 |
| 429062 | Speedy Monsters | 2023 |
| 428286 | Wobbly Edamame Balance | 2022 |
| 428484 | Onde foi parar meu Osso? | 2022 |
| 428500 | 15 Minute Cold War: Expansion Edition | 2022 |
| 428501 | 15 Minute Cold War: Six Day War Edition | 2022 |
| 428584 | Kalologos | 2022 |
| 428761 | Alias: Moomin kuvaselityspeli | 2022 |
| 428771 | SpeedBac | 2022 |
| 428773 | Austerity Card Game | 2022 |
| 428798 | PopSavvy: After Dark | 2022 |
| 429172 | Cut the Crop | 2022 |
| 428403 | ドラえもん ひみつ道具 ナイ！ナイ！ナ～イ！ゲーム (Doraemon Himitsu Dougu Nai! Nai! Na~i! Game) | 2021 |
| 428408 | 新米オーナー、見習いスタッフたちとレストランを救う。 (Save New Owners, Apprentice Staff and Restaurants) | 2021 |
| 428775 | Pay Day: Rivals Edition | 2021 |
| 428786 | Suuri Sienijahti | 2021 |
| 428940 | Dungeons of Numera | 2021 |
| 429052 | Top Dogs Card Game | 2021 |
| 416134 | Tombola delle Parole | 2020 |
| 425773 | Root: Jeu de base + La Rivière | 2020 |
| 428237 | Före eller efter? | 2020 |
| 428611 | Laäg | 2020 |
| 428680 | Curve Ball | 2020 |
| 428982 | Grandmaster | 2020 |
| 429053 | Cluedo: Pummel & Friends | 2020 |
| 427993 | Camp Macabre | 2019 |
| 428750 | 原チャリ番長 (Genchari Bancho) | 2019 |
| 428882 | Catastrophic | 2019 |
| 428481 | Like Totally 80s Pop Culture Trivia Game | 2018 |
| 428583 | SH!THEAD | 2018 |
| 428625 | Lap of the Gods | 2016 |
| 427988 | Starfire: 2nd Edition – PDF Rules | 2014 |
| 428128 | Μέτρο Μέτρο στο Μετρό (Metro Metro in the Metro) | 1998 |
| 165274 | Super Sea Battle | 1995 |
| 428415 | Zoo Logical | 1992 |
| 429059 | Trio | 1989 |
| 429042 | Panic! | 1987 |
| 427583 | Starfire (2nd Edition) | 1984 |
| 428839 | One Shot Yott | 1977 |
| 428768 | il Gioco dell’Iliade | 1976 |
| 427960 | graph-it | 1974 |
| 427983 | factor pairs | 1974 |
| 428177 | Factor Bridge | 1973 |
| 428178 | 1-Sum Fraction Game | 1973 |
| 428179 | 9… Make 10 | 1973 |
| 428681 | Milionário | 1970 |
| 428793 | Macadam | 1969 |
| 428267 | Gesundheitsmagazin | 1964 |
| 428088 | Span-it Space Maze | 1948 |
| 427557 | Classic Surf | NA |
| 427562 | Unpopular Opinions: The Card Game | NA |
| 427592 | The Thinning Veil: Red Mist | NA |
| 427714 | Cheesed Off! | NA |
| 427742 | Firelock 198X | NA |
| 428087 | Strigoy: A Social Deduction Game | NA |
| 428107 | Μάντεψε τι!! (Guess What!!) | NA |
| 428142 | Μάντεψε! Παντομίμα (Guess! Pantomime) | NA |
| 428263 | Felix der Kater auf der Weltreise | NA |
| 428546 | Trader’s Journey | NA |
| 428633 | Spout: Angel Edition | NA |
| 428677 | Doomsayers | NA |
| 428694 | Yuru Tarot | NA |
| 428697 | Die Entdeckung des Nordpols | NA |
| 428700 | Spout: Awful Edition | NA |
| 428723 | Banzai | NA |
| 428757 | Komm, kauf mit ein! | NA |
| 428769 | Vertical Garden | NA |
| 428799 | Barlòtt | NA |
| 428825 | The Hygge Game: Trivia Edition | NA |
| 428902 | Trick Market | NA |
| 429022 | Mini Seasons Lite | NA |
| 429024 | Draconis 8 | NA |
