
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
| 436795 | Partisan: Faith & Factions | 2028 |
| 439207 | Ironworks: melt, mold, master | 2027 |
| 440149 | Agricola: Dead Harvest | 2027 |
| 433640 | Cthulhu: Death May Die – Forbidden Reaches | 2026 |
| 433840 | Hell Raisers in Kanawha County | 2026 |
| 433856 | Micro Pirates | 2026 |
| 434001 | Scurry Up! | 2026 |
| 434430 | Battle Monsters: Godzilla vs. King Ghidorah | 2026 |
| 434546 | Battle Monsters: Kong vs Mechagodzilla | 2026 |
| 435311 | River Market | 2026 |
| 435396 | Bloodlines | 2026 |
| 435645 | Honey Queen | 2026 |
| 435817 | Seize the Seas | 2026 |
| 436194 | Apartment Architects | 2026 |
| 436394 | Trickster Gods | 2026 |
| 436585 | Edge Quest | 2026 |
| 436812 | Cassette Zombies! | 2026 |
| 436907 | Crits & Tricks | 2026 |
| 436908 | Thieves of Eldris | 2026 |
| 436909 | Tug of Roar | 2026 |
| 436938 | Paper Terrains | 2026 |
| 436960 | Omega Roboto | 2026 |
| 437002 | Shadows of Ruin | 2026 |
| 437060 | Gnome Ore | 2026 |
| 437347 | Chasseur de coeur | 2026 |
| 437356 | Scales of Fate | 2026 |
| 437702 | Native Spirit | 2026 |
| 437709 | Ninja Ki | 2026 |
| 437875 | Cats vs Cucumbers | 2026 |
| 438173 | Mazing | 2026 |
| 438179 | Jarren’s Outpost | 2026 |
| 438272 | Astro Out | 2026 |
| 438438 | Sprites & Sprouts | 2026 |
| 438440 | Threshold | 2026 |
| 438479 | La Serenissima | 2026 |
| 438531 | Reindeer Games | 2026 |
| 438586 | Biomes of Nilgiris: The Card Game | 2026 |
| 438689 | Cultured Swines | 2026 |
| 438884 | Kastle | 2026 |
| 438900 | Wax Packs | 2026 |
| 439002 | Diceverse | 2026 |
| 439044 | Cannabiz | 2026 |
| 439090 | Space Lion 2: Leon Strife | 2026 |
| 439093 | Red Dog Junction | 2026 |
| 439094 | PDX | 2026 |
| 439183 | Era of Pioneers | 2026 |
| 439189 | Low Tide | 2026 |
| 439225 | Trailblazer: the Colorado Trail | 2026 |
| 439226 | Garage Rock | 2026 |
| 439372 | Adventure Time Card Wars: Flame Princess vs. Fern | 2026 |
| 439373 | Adventure Time Card Wars: Prismo vs. The Lich | 2026 |
| 439374 | Adventure Time Card Wars: Peppermint Butler vs. Magic Man | 2026 |
| 439492 | Snake-o-Nauts | 2026 |
| 439742 | Dewan | 2026 |
| 439813 | Hollow Pact | 2026 |
| 439881 | Mythiko | 2026 |
| 439940 | Mythic Wars | 2026 |
| 439974 | The Pirate Code | 2026 |
| 440087 | Linky Lines | 2026 |
| 440136 | Labyrinth: Chronicles | 2026 |
| 440144 | Fart of War | 2026 |
| 440146 | This War of Mine: The Board Game – Second Edition | 2026 |
| 440147 | Agricola: Special Edition | 2026 |
| 440148 | B.E.L.O.W.: Asylum | 2026 |
| 440151 | Dragon Eclipse: The Grand Quest | 2026 |
| 440159 | Mirror Agents | 2026 |
| 425784 | Kingless: the Festival of Explosions | 2025 |
| 429159 | Stadt Land Vollpfosten: Levels – Party Edition | 2025 |
| 430165 | Killer Academy | 2025 |
| 430660 | Broken Fate | 2025 |
| 431392 | The Bestiary | 2025 |
| 432705 | Ofrenda | 2025 |
| 432950 | 20 Strong: Tanglewoods | 2025 |
| 432993 | Barnburners and Noblemen | 2025 |
| 433015 | Matcha: Strategy and Memory game | 2025 |
| 433121 | Ketupat Rendang | 2025 |
| 433216 | Spire of Dioronna | 2025 |
| 433225 | Adventurer | 2025 |
| 433226 | Homestead Hyperjump! | 2025 |
| 433239 | AutoMint: Wave 1 | 2025 |
| 433244 | Desolation: Beyond Stalingrad Z | 2025 |
| 433250 | Overgrown | 2025 |
| 433258 | LIFT | 2025 |
| 433283 | Daydream | 2025 |
| 433284 | Crown & Courage | 2025 |
| 433317 | CODO Berlin 63 | 2025 |
| 433318 | Space Driller | 2025 |
| 433337 | Fae Village | 2025 |
| 433338 | Schatz des Phönix | 2025 |
| 433339 | 6 nimmt! Baron Oxx | 2025 |
| 433340 | Fischfutter | 2025 |
| 433348 | Disco Island Escape | 2025 |
| 433378 | 50 Heroes | 2025 |
| 433380 | Minecraft: Builders & Biomes – Junior | 2025 |
| 433382 | The Sandcastles of Burgundy | 2025 |
| 433384 | Rival Cities | 2025 |
| 433386 | Gloomies | 2025 |
| 433388 | Labyrinth Go! | 2025 |
| 433404 | KeyForge: Prophetic Visions | 2025 |
| 433409 | Age of Colors | 2025 |
| 433424 | Alpha Team Mechanized Battle Force Go! | 2025 |
| 433432 | Town Squared: Goblin Folk | 2025 |
| 433449 | T10: Animals | 2025 |
| 433466 | Animals Around the World BINGO | 2025 |
| 433467 | Dragonella | 2025 |
| 433468 | My Very First Games to Go: Leo the Party Lion | 2025 |
| 433470 | My Very First Games to Go: Pete Ahoy! | 2025 |
| 433471 | My Very First Games to Go: Mine or Yours? | 2025 |
| 433474 | Flipkins | 2025 |
| 433476 | Robbi Gelato | 2025 |
| 433479 | Coco Ninja | 2025 |
| 433480 | Bronze Island | 2025 |
| 433502 | Our Secret Society | 2025 |
| 433505 | The World Crisis: First World War in Europe | 2025 |
| 433517 | Froggos | 2025 |
| 433518 | Mixalotl | 2025 |
| 433519 | Quiz Challenge Europa | 2025 |
| 433520 | Sebastian Seastar | 2025 |
| 433521 | Forest Festival | 2025 |
| 433523 | Snack Jack! | 2025 |
| 433524 | Spike & Pop | 2025 |
| 433536 | Love Conquers All | 2025 |
| 433540 | A volta ao mundo em 80 dias: A grande corrida! | 2025 |
| 433554 | TerraForge | 2025 |
| 433560 | Trigger Warning | 2025 |
| 433614 | Dutch Flower Auction | 2025 |
| 433617 | Lord of Conspiracy: Light and Darkness | 2025 |
| 433620 | Community Garden | 2025 |
| 433656 | Suriya: The Last Horizon | 2025 |
| 433676 | BULL’S EYE: Strategic Air Combat Board Game | 2025 |
| 433679 | Sneaky Supper | 2025 |
| 433735 | Believe | 2025 |
| 433786 | Fishy Fables | 2025 |
| 433794 | Triple Gem | 2025 |
| 433797 | Dino Trix: Tarot Adventures | 2025 |
| 433823 | Polar Vortex: The Battle for Alaska’s North Slope | 2025 |
| 433826 | Spellcrafter | 2025 |
| 433887 | Burger Master | 2025 |
| 433891 | Urban Sketchers | 2025 |
| 433892 | Dangerous Space: 2025 Year-Long Adventure Set | 2025 |
| 433908 | Gatsby | 2025 |
| 433920 | Timetable Tag | 2025 |
| 433925 | Life and Beyond | 2025 |
| 433927 | Hibachi: Fired Up! | 2025 |
| 433931 | Twist | 2025 |
| 433954 | Time and the Coyote | 2025 |
| 433963 | Jujuman | 2025 |
| 433970 | Gemmage Festival | 2025 |
| 433987 | DeCrypt | 2025 |
| 434027 | Food Chain Magnate: Deluxe Edition | 2025 |
| 434052 | The Witch, the Scoop, and the Magic Soup | 2025 |
| 434082 | Hexslayer | 2025 |
| 434087 | Ruinwood | 2025 |
| 434097 | Moby Dick: Wrath of the Seas | 2025 |
| 434099 | Treasure Cove | 2025 |
| 434117 | Boucaniers | 2025 |
| 434131 | Tolleno | 2025 |
| 434134 | Battlegroup Clash: Baltics | 2025 |
| 434135 | Supervolcano | 2025 |
| 434142 | Dictator for Life | 2025 |
| 434143 | Bango | 2025 |
| 434146 | Gundam Card Game | 2025 |
| 434149 | Reedride | 2025 |
| 434152 | Entrenched: Kaiser Kompanie | 2025 |
| 434154 | Kill Chain | 2025 |
| 434169 | Florasphere | 2025 |
| 434170 | Burglar’s Blitz | 2025 |
| 434172 | Excalibur | 2025 |
| 434174 | Taiwan’s Largest War: Hakka | 2025 |
| 434176 | Taiwan’s Largest War: Hokkien | 2025 |
| 434180 | Bismarck’s Wars: Wargaming Rules for the Period leading to the Franco-Prussian War, 1859-1871 | 2025 |
| 434191 | Regulus High-Fantasy Arena-Sports | 2025 |
| 434203 | Stadt, Land, Exmatrikulation: Der Spieleklassiker für Student\*innen | 2025 |
| 434204 | Stadt, Land, Fernweh: Der Spieleklassiker für alle Urlauber\*innen | 2025 |
| 434205 | Stadt, Land, Extreme: Das Spiel Potter-Fans | 2025 |
| 434207 | Das Quiz für Harry Potter-Fans | 2025 |
| 434209 | Das inoffizielle Quiz für Star Wars-Fans | 2025 |
| 434211 | Stadt Land: Das Spiel für Marvel-Fans | 2025 |
| 434213 | Die Olchis: Schleime-Schlamm und Käsefuß! | 2025 |
| 434216 | Nenne drei: schon vorbei! – für Kids! | 2025 |
| 434222 | Gwent: The Legendary Card Game | 2025 |
| 434229 | Heroes Aren’t Born | 2025 |
| 434233 | Hexblem | 2025 |
| 434283 | Habemus Papam | 2025 |
| 434287 | Heiho The art of war: Wargames rules for large battles of Sengoku period Japan, 1560-1615 | 2025 |
| 434291 | Swords of God: Wargaming Battles of the Crusades | 2025 |
| 434300 | Dungeon Map Maker | 2025 |
| 434318 | Rummathon Royale | 2025 |
| 434333 | Champions of Rokugan | 2025 |
| 434343 | Uncharted Passage | 2025 |
| 434348 | Bei dir piept’s wohl! | 2025 |
| 434349 | Mission: Wild Life | 2025 |
| 434350 | Biotope: Wer schafft den besten Lebensraum? | 2025 |
| 434353 | G.I. JOE: Operation Cobra | 2025 |
| 434356 | Micro Hero: Hercules | 2025 |
| 434357 | Legacy: Heroes of Asco’Lah | 2025 |
| 434367 | Nippon: Zaibatsu | 2025 |
| 434385 | A Song of Ice & Fire: Tabletop Miniatures Game – Brotherhood Without Banners Starter Set | 2025 |
| 434386 | 1813: The Struggle for Germany | 2025 |
| 434415 | Aqueducks | 2025 |
| 434418 | Card Stock | 2025 |
| 434422 | Celestia Duo | 2025 |
| 434424 | Your Village People: Card Game | 2025 |
| 434425 | General Orders: Sengoku Jidai | 2025 |
| 434433 | Frantic Antics | 2025 |
| 434434 | It’s Giving | 2025 |
| 434435 | Broken Paths | 2025 |
| 434436 | MonsDRAWsity: My Lil’ Monsters | 2025 |
| 434442 | 13 Leaves | 2025 |
| 434443 | Pigeon Explosion | 2025 |
| 434510 | Gooooal!!! | 2025 |
| 434576 | Haereo | 2025 |
| 434654 | Toy Battle | 2025 |
| 434660 | Coloro | 2025 |
| 434663 | Forest Gangs | 2025 |
| 434683 | Verso | 2025 |
| 434706 | Prosper with Dragons | 2025 |
| 434848 | Adventurous | 2025 |
| 434852 | Converge: Bastions of Tradition | 2025 |
| 434857 | Converge: Emissaries of Tomorrow | 2025 |
| 434858 | Converge: Champions of Nature | 2025 |
| 434860 | Dionysia | 2025 |
| 434861 | Downtown Las Palmas | 2025 |
| 434862 | Embers | 2025 |
| 434865 | Lands of Amazement | 2025 |
| 434866 | Leaping Lions | 2025 |
| 434868 | Phantasmic | 2025 |
| 434870 | Shallow Regrets | 2025 |
| 434871 | Apropos: Of Board Games II | 2025 |
| 434872 | Apropos: Of Movies II | 2025 |
| 434875 | Intricatus | 2025 |
| 434906 | Tag Team | 2025 |
| 434915 | Deckay: The Postapocalyptic Card Game | 2025 |
| 434947 | Space Qubes | 2025 |
| 435009 | Operation Barbarossa: A WW2 Roll & Write Game | 2025 |
| 435024 | Revenant: Kickstarter Edition | 2025 |
| 435061 | Snow Drift | 2025 |
| 435066 | Scrabble Slots | 2025 |
| 435115 | War Fields | 2025 |
| 435131 | Judgemint of the Realm Lords | 2025 |
| 435210 | HandMaze | 2025 |
| 435261 | Valedictorian | 2025 |
| 435289 | Cathedroll | 2025 |
| 435290 | The Wayfarer | 2025 |
| 435295 | Szepty na strychu | 2025 |
| 435296 | Modern Mint | 2025 |
| 435330 | Pondscape | 2025 |
| 435341 | Sly Mole | 2025 |
| 435346 | Mooki Island | 2025 |
| 435356 | For The Emperor | 2025 |
| 435357 | Slambo | 2025 |
| 435360 | Waddle | 2025 |
| 435367 | Survivor: The Tribe Has Spoken | 2025 |
| 435379 | Digital Frontiers | 2025 |
| 435395 | Pocket Train Game | 2025 |
| 435422 | Ahoy Shipwrecked | 2025 |
| 435423 | Alibis | 2025 |
| 435425 | Kebab | 2025 |
| 435426 | Cosmic Odyssey | 2025 |
| 435427 | A Forlorn Hope | 2025 |
| 435435 | A Dam Too Far: 617 Squadon’s Dam Buster Raid, May 1943 | 2025 |
| 435461 | The Cast List | 2025 |
| 435494 | Наследие старой Руси: Легенда о Змее (Legacy of Old Rus: Legends of the Serpent) | 2025 |
| 435498 | Zilight Wild West | 2025 |
| 435500 | TETO | 2025 |
| 435502 | Feel Like a Fool | 2025 |
| 435518 | Dice Apocalypse | 2025 |
| 435527 | Marathon Mayhem | 2025 |
| 435535 | Wardens | 2025 |
| 435625 | ORIGINE | 2025 |
| 435627 | Fear Pong | 2025 |
| 435630 | Barrel of Monkeys Dropple | 2025 |
| 435648 | FateFlip: By Royal Decree | 2025 |
| 435651 | Slime Quest | 2025 |
| 435652 | Ptit Pois | 2025 |
| 435653 | Mimic Mind | 2025 |
| 435665 | Roll or Stand: Jurassic Adventures | 2025 |
| 435678 | Magnate: The Anarcho-Capitalist Card Game | 2025 |
| 435686 | Шестерёнки (Gears) | 2025 |
| 435687 | Трик-н-Шеф (Trick-n-Chef) | 2025 |
| 435700 | KNJO | 2025 |
| 435703 | With The Hammer | 2025 |
| 435704 | Kaijus From Space! | 2025 |
| 435747 | Best Shot | 2025 |
| 435757 | Shell We? | 2025 |
| 435759 | Beaver House | 2025 |
| 435760 | Purrfect Place | 2025 |
| 435778 | Wild Pong | 2025 |
| 435796 | Tournament Arc | 2025 |
| 435806 | Heure de Colle | 2025 |
| 435810 | Legions | 2025 |
| 435825 | Hanbok Runway | 2025 |
| 435833 | Diggers’ Resolve: The Battle of Milne Bay, August-September, 1942 | 2025 |
| 435838 | Bear w/ Me | 2025 |
| 435839 | Evoke | 2025 |
| 435861 | Furnace Duel | 2025 |
| 435871 | Gambetto | 2025 |
| 435873 | Sadhana | 2025 |
| 435876 | Oganika Arcanum: Diamonds & Duals | 2025 |
| 435877 | Forfort | 2025 |
| 435908 | Who Said That? | 2025 |
| 435920 | Iwo Jima: Hell On Earth | 2025 |
| 435921 | Natural Killer: El Cuerpo Bajo Ataque | 2025 |
| 435926 | Tear-a-Part | 2025 |
| 435930 | That’s Not a Hat: Incognito | 2025 |
| 435953 | Evokers | 2025 |
| 435959 | Tamagotchi Collections | 2025 |
| 435964 | Soldier’s Chess | 2025 |
| 435967 | Petits Complots entre Amis | 2025 |
| 436010 | Crystalla | 2025 |
| 436038 | Hercules and the 12 Labors | 2025 |
| 436039 | Fair Food Frenzy | 2025 |
| 436046 | One Round? | 2025 |
| 436047 | For One: Mensch ärgere Dich nicht | 2025 |
| 436055 | Чёрная книга (Black Book: The Board Game) | 2025 |
| 436090 | Quarks the Board Game | 2025 |
| 436116 | Sky Totems | 2025 |
| 436121 | 春秋 (Spring and Autumn) | 2025 |
| 436126 | Finspan | 2025 |
| 436127 | Three Sisters Harvest Edition | 2025 |
| 436129 | Strawberry Shortcake: Berry Besties Bakeoff Card Game | 2025 |
| 436130 | Welcome to Susberg | 2025 |
| 436134 | Deckscape: Dungeon | 2025 |
| 436135 | Until Proven Guilty: Thirst for Justice | 2025 |
| 436146 | Capybara Crush | 2025 |
| 436150 | Backstories: L’Embrasement | 2025 |
| 436157 | Lost in Adventure: The Curse of Jack Parrot | 2025 |
| 436161 | Koi | 2025 |
| 436182 | Kirlo | 2025 |
| 436195 | Foreshadow | 2025 |
| 436198 | Uttarayan | 2025 |
| 436204 | Blanc Manger Coco DUO: Plaisir à deux | 2025 |
| 436205 | Rewild: South America | 2025 |
| 436217 | The Lord of the Rings: Fate of the Fellowship | 2025 |
| 436218 | Medium: Testing Fate | 2025 |
| 436221 | Solacia 2: The Ice Demon – A Solitaire Fantasy Game | 2025 |
| 436222 | Wally Drag Racing | 2025 |
| 436257 | CATATAC | 2025 |
| 436262 | Eneda | 2025 |
| 436263 | Villos Komposta Arxidia Mple Karamele | 2025 |
| 436292 | Yummy Kitchen | 2025 |
| 436304 | LUCHA LUCHA | 2025 |
| 436305 | Drawing to The West | 2025 |
| 436306 | Werewolf: Duel! | 2025 |
| 436308 | Dispel The Darkness 2E | 2025 |
| 436323 | Dangerous Space: 2025 Core Set | 2025 |
| 436324 | Power Creep: Year-Long Adventure Set | 2025 |
| 436336 | Pékin-Paris 1907 | 2025 |
| 436368 | Ichor: Reinforcements & Gates Expansion | 2025 |
| 436400 | Abra Chadabra | 2025 |
| 436401 | Good & Evil | 2025 |
| 436416 | Detention | 2025 |
| 436418 | Star Trek: Tribble Match | 2025 |
| 436431 | Chakravyuha | 2025 |
| 436442 | Happy Haven | 2025 |
| 436445 | Tricky Dragons | 2025 |
| 436446 | DC Super Heroes United: Batman Hush | 2025 |
| 436448 | The Six | 2025 |
| 436476 | Chess-a-tete, Classic Edition | 2025 |
| 436478 | De zoete mix | 2025 |
| 436480 | Duetwoorden | 2025 |
| 436482 | Guardians of the Abyss | 2025 |
| 436483 | Pizzachef: Mijn pizzafeestje | 2025 |
| 436489 | Mankind Madness | 2025 |
| 436503 | Mime Battle | 2025 |
| 436504 | REFINED | 2025 |
| 436505 | Shapely | 2025 |
| 436507 | Under the Mango Tree | 2025 |
| 436511 | Compania | 2025 |
| 436515 | The Office: Paper Paranoia | 2025 |
| 436516 | Merchants of Andromeda | 2025 |
| 436528 | Hippo Hero | 2025 |
| 436534 | Rad Pirates of the Toxic Sands | 2025 |
| 436543 | Flicking H\*ck | 2025 |
| 436552 | Cantankerous Cats (Third Edition) | 2025 |
| 436554 | The Mint Edition | 2025 |
| 436560 | Project K: The League of Legends Trading Card Game | 2025 |
| 436561 | Timber Town | 2025 |
| 436572 | Tricky Treats | 2025 |
| 436577 | Detectives Vs Criminals | 2025 |
| 436578 | Kaiser Cucumber and the Gangs of McChanicle Corners | 2025 |
| 436584 | ZooJourn | 2025 |
| 436587 | Moonlight | 2025 |
| 436590 | 3-2-1 Countdown | 2025 |
| 436592 | Lying Pirates: Cities of Greed Expansion | 2025 |
| 436622 | Couch Kingdom | 2025 |
| 436623 | Sports Dice: Basketball | 2025 |
| 436634 | Cobogó | 2025 |
| 436638 | Tanbo | 2025 |
| 436650 | Kingdom of Dice | 2025 |
| 436652 | Chartres | 2025 |
| 436655 | Exposure | 2025 |
| 436691 | Capivárias | 2025 |
| 436708 | Pickleball Dice | 2025 |
| 436751 | Under the Leaves | 2025 |
| 436756 | Archibald, Certainly Not! | 2025 |
| 436759 | Massive Darkness: Dungeons of Shadowreach | 2025 |
| 436765 | Captain Phillip | 2025 |
| 436774 | Seiðruna | 2025 |
| 436781 | Neo SNL: Tilelized Snakes and Ladders | 2025 |
| 436787 | 365 Adventures: Cthulhu 1926 | 2025 |
| 436788 | Monkey Thieves | 2025 |
| 436790 | Believe in Me! (Please) | 2025 |
| 436794 | Malabares | 2025 |
| 436804 | Opération Zèbre | 2025 |
| 436813 | Corazón MultiColor | 2025 |
| 436814 | Trollbooth | 2025 |
| 436817 | D-Day into Normandy, then …? | 2025 |
| 436820 | Deal With Your S#!t | 2025 |
| 436821 | Everdell Silverfrost | 2025 |
| 436823 | OOrtum: A seasonal folk horror skirmish wargame | 2025 |
| 436824 | Four Fleets | 2025 |
| 436825 | Timewinder | 2025 |
| 436826 | Pacifica | 2025 |
| 436827 | Second World War at Sea: North Cape | 2025 |
| 436842 | The Wondrous Museum | 2025 |
| 436843 | Wolf Street | 2025 |
| 436844 | Rumian | 2025 |
| 436851 | Name it! | 2025 |
| 436861 | Seven Secret Supervillains | 2025 |
| 436869 | Midnight Stalker | 2025 |
| 436894 | Yonmoque Hex | 2025 |
| 436917 | Robot Quest Arena: Bot Battle Promo Pack | 2025 |
| 436922 | Time Hammer: The Dual | 2025 |
| 436931 | Trinket Trove | 2025 |
| 436932 | First-Class Letters | 2025 |
| 436935 | Corgi Pileup | 2025 |
| 436936 | No Loose Ends | 2025 |
| 436939 | Rolling Bears | 2025 |
| 436950 | Apis Mellifera: The Bee Game | 2025 |
| 436966 | Artist Alley | 2025 |
| 436967 | Monopoly: Neopets 25th Anniversary Edition | 2025 |
| 436968 | Pesky Island | 2025 |
| 436990 | The Ultimate Breakfast Scramble! | 2025 |
| 436991 | Space Dogs: Galactic Strike | 2025 |
| 436994 | Photobomb | 2025 |
| 436995 | Group Chat | 2025 |
| 437008 | Foolish Fool | 2025 |
| 437010 | Abacus | 2025 |
| 437027 | Reaper’s Hideout | 2025 |
| 437051 | Das wurmt | 2025 |
| 437053 | Kleiner Drache Wirbelwind | 2025 |
| 437055 | Mach die Flatter | 2025 |
| 437056 | Dangerous Skies: WWI Air Rules | 2025 |
| 437058 | Gigi Gacker am Würfelacker | 2025 |
| 437066 | Fireblade: As Simple and Fair as Possible – Tabletop Wargame Rulebook | 2025 |
| 437073 | Rising Cultures | 2025 |
| 437099 | Kilia | 2025 |
| 437101 | The Royal Society of Archeology | 2025 |
| 437105 | Match Me If You Can! | 2025 |
| 437106 | Simsala Spin | 2025 |
| 437108 | Hokus Pictus | 2025 |
| 437109 | Makoto | 2025 |
| 437110 | WTF: Write Things Fast | 2025 |
| 437113 | Aliens Unboxed | 2025 |
| 437115 | City Flip: Roma | 2025 |
| 437117 | Waschsalon | 2025 |
| 437118 | Hands off! | 2025 |
| 437130 | Wool Street | 2025 |
| 437152 | The Haunted Glass | 2025 |
| 437157 | Kurnik 2: Cztery pory roku | 2025 |
| 437164 | Soul Dice | 2025 |
| 437166 | Where is That: South America | 2025 |
| 437167 | Where is That: Europe | 2025 |
| 437168 | Paradox Island | 2025 |
| 437170 | Hunt A Killer: Lakeside Slaughter – The Last Vacation | 2025 |
| 437172 | Salsacia vs Conservia | 2025 |
| 437177 | Arizona: Great Buy! 99 The Game | 2025 |
| 437181 | Jurassic World: Shaky Volcano | 2025 |
| 437182 | Mini Dungeons: The Mines and the Towers | 2025 |
| 437183 | Jurassic World: Cage Breaker | 2025 |
| 437186 | Punch! Kick! Block! | 2025 |
| 437187 | Super Mario Cap Stacker | 2025 |
| 437189 | Urban Operations: Second Edition | 2025 |
| 437199 | Contrive Five | 2025 |
| 437205 | Fight Deck | 2025 |
| 437213 | Guadalcanal Diary | 2025 |
| 437214 | EXIT: The Game – Adventures on Catan | 2025 |
| 437217 | Sapling Scramble | 2025 |
| 437219 | Grand Army of the Republic: Designer Signature Edition | 2025 |
| 437228 | Pond: A Froggy Board Game | 2025 |
| 437230 | Forever Island: An Eco-Apocalyptic War Game | 2025 |
| 437243 | Las Ligas de la Ñ: La Ciudad de las Damas | 2025 |
| 437245 | Kingdom Crossing | 2025 |
| 437248 | Dice Words | 2025 |
| 437252 | 365 Adventures: The Dungeon 2026 | 2025 |
| 437253 | Masha and the Bear: Memory Match | 2025 |
| 437254 | Masha and The Bear: Hide-and-Seek | 2025 |
| 437255 | OverSoul’d | 2025 |
| 437256 | Coexist | 2025 |
| 437261 | MicroMacro: Kids – Crazy City Park | 2025 |
| 437262 | Underleaf | 2025 |
| 437267 | Las Ligas de la Ñ: Reinas Arcanas | 2025 |
| 437268 | Twosocks | 2025 |
| 437272 | Baseball Highlights 2045: Dad Bresnan Promo Card | 2025 |
| 437273 | Brilliant | 2025 |
| 437276 | Tier Up | 2025 |
| 437278 | Axis & Allies: Stalingrad | 2025 |
| 437280 | Zjvoltis | 2025 |
| 437287 | Dungeon Dynasty | 2025 |
| 437289 | Transecopia | 2025 |
| 437290 | Ashes Ascendancy | 2025 |
| 437301 | INK | 2025 |
| 437304 | Whiskers & Tails | 2025 |
| 437306 | Parks (Second Edition) | 2025 |
| 437313 | Flip Voyage | 2025 |
| 437318 | Rollin’ Campus | 2025 |
| 437322 | Order Rush!! | 2025 |
| 437323 | CyberSiege | 2025 |
| 437331 | Roll’n’Coaster: Bau dir deinen Freizeitpark | 2025 |
| 437332 | Adventure Games: Mission Mars | 2025 |
| 437334 | The Hanging Gardens | 2025 |
| 437337 | Abroad | 2025 |
| 437342 | SCRxBBLE: Print and Play Words Games using Scrabble Tiles | 2025 |
| 437370 | This Game Is Killer: FROZEN HORROR | 2025 |
| 437372 | Turbo Tiere | 2025 |
| 437382 | Neuroshima Hex: Battle | 2025 |
| 437383 | Age of Galaxy (Second Edition) | 2025 |
| 437384 | Bohemians | 2025 |
| 437385 | Race to Berlin (Second Edition) | 2025 |
| 437405 | Full Throttle Drag Racing | 2025 |
| 437409 | Pete’s Plaice | 2025 |
| 437470 | Чёрная книга: Дурак (Black Book: Durak) | 2025 |
| 437477 | Whalemen Wanted | 2025 |
| 437478 | IYE | 2025 |
| 437500 | Macaraccoon | 2025 |
| 437537 | Potions Master Tournament | 2025 |
| 437538 | Emporio | 2025 |
| 437579 | Pocket Drafters | 2025 |
| 437581 | La Cuenta | 2025 |
| 437584 | Widget’s Workshop | 2025 |
| 437590 | Isle of Thrift | 2025 |
| 437610 | Black Skin Black Shirt | 2025 |
| 437621 | Planeten Springer | 2025 |
| 437622 | Wasser Marsch! | 2025 |
| 437623 | Schwarzwälder Kirsch | 2025 |
| 437624 | Rabbit Run | 2025 |
| 437635 | Merk dir Meer | 2025 |
| 437637 | La Garde Veille! | 2025 |
| 437645 | Hagamos una Expo | 2025 |
| 437648 | Quanta 5 | 2025 |
| 437650 | ReminiSéance | 2025 |
| 437653 | Patchistory: The Fabric of Ages | 2025 |
| 437654 | Disney Villainous Unstoppable! | 2025 |
| 437658 | Fistful of Lead: Glorious Adventures in the Age of Steam | 2025 |
| 437662 | Конотопська відьма (The Witch of Konotop) | 2025 |
| 437663 | Storybook Battles: Dan Shamble Adventures | 2025 |
| 437665 | Rust & Rebellion | 2025 |
| 437666 | Bark Magic: Ultimutt Edition | 2025 |
| 437668 | Arborius | 2025 |
| 437669 | Last Flag WWII: Premium | 2025 |
| 437676 | Hey Feelings | 2025 |
| 437680 | Magicarta | 2025 |
| 437685 | Limits of Glory: Jersey New Jersey | 2025 |
| 437695 | Two Types of People | 2025 |
| 437697 | Be$`t Offer                                                                                                   |          2025|
|  437698|Between Two Castles Essential Edition                                                                        |          2025|
|  437705|Horrified: Dungeons & Dragons                                                                                |          2025|
|  437706|Rolling Fates: Origin                                                                                        |          2025|
|  437713|Kaleid-O!                                                                                                    |          2025|
|  437769|Love Letter Stories                                                                                          |          2025|
|  437772|The Dawn of the Civilization                                                                                 |          2025|
|  437777|The Keymaster                                                                                                |          2025|
|  437779|LoveLive! Series Official Card Game                                                                          |          2025|
|  437781|Digit Code                                                                                                   |          2025|
|  437821|Sir Ocelot's Cave                                                                                            |          2025|
|  437822|Goliath                                                                                                      |          2025|
|  437833|Tir Janag                                                                                                    |          2025|
|  437872|Detour Deluxe                                                                                                |          2025|
|  437879|Cup the Crab                                                                                                 |          2025|
|  437882|Grimgrove                                                                                                    |          2025|
|  437886|Fl!p52                                                                                                       |          2025|
|  437919|Instinkt                                                                                                     |          2025|
|  437920|Forest Floor                                                                                                 |          2025|
|  437927|Brutal Beatdown: Infestation                                                                                 |          2025|
|  437938|Top Ten Adventures                                                                                           |          2025|
|  437939|Double Seven                                                                                                 |          2025|
|  437941|The Hood Game                                                                                                |          2025|
|  437958|Cat In 8                                                                                                     |          2025|
|  437972|Shadows Over Europe 1920                                                                                     |          2025|
|  437974|Die Legenden von Andor: Das ferne Land                                                                       |          2025|
|  437977|Glade                                                                                                        |          2025|
|  437985|Card Game Traders                                                                                            |          2025|
|  437986|REMOUS                                                                                                       |          2025|
|  437997|TIC TAC TOP                                                                                                  |          2025|
|  437999|Taco Phở Cá Đá Trà Đào                                                                                       |          2025|
|  438005|Dyson Sphere                                                                                                 |          2025|
|  438010|Emergency Exit Only                                                                                          |          2025|
|  438018|Kanal                                                                                                        |          2025|
|  438025|Adorable Demons: An Infernally Cute Card Game                                                                |          2025|
|  438037|T10 Collection                                                                                               |          2025|
|  438039|Alphabet Loop                                                                                                |          2025|
|  438081|Ovelha em Pele de Lobo                                                                                       |          2025|
|  438089|Little Kingdoms                                                                                              |          2025|
|  438103|Word Fluxx                                                                                                   |          2025|
|  438104|Jurassic Roll                                                                                                |          2025|
|  438108|Jurassic Memory                                                                                              |          2025|
|  438110|Farm Inc.                                                                                                    |          2025|
|  438112|Dr Gribouille                                                                                                |          2025|
|  438116|Equation Lo-Hi                                                                                               |          2025|
|  438119|Please Don't Burn My Village!                                                                                |          2025|
|  438138|Hydro Power Boat Drag Racing                                                                                 |          2025|
|  438140|Circadians: Prima Alba “Big Box”                                                                             |          2025|
|  438149|Escape from Earth                                                                                            |          2025|
|  438161|Kingdoms: The Battle of Five Realms                                                                          |          2025|
|  438169|F*ck Around/Find Out!                                                                                        |          2025|
|  438172|Legends of Gadia                                                                                             |          2025|
|  438180|Dragon Eyes                                                                                                  |          2025|
|  438195|Volle Kanne!                                                                                                 |          2025|
|  438196|Bivì                                                                                                         |          2025|
|  438207|Lambada                                                                                                      |          2025|
|  438210|Juven Isle                                                                                                   |          2025|
|  438212|Strife and Valor                                                                                             |          2025|
|  438213|Farmer's Market                                                                                              |          2025|
|  438214|Animal Rescue Team                                                                                           |          2025|
|  438239|Colorful Farm                                                                                                |          2025|
|  438263|Lem-Tori                                                                                                     |          2025|
|  438277|Filmriss                                                                                                     |          2025|
|  438278|Voll Verschätzt!: Classic Edition                                                                            |          2025|
|  438279|Voll Verschätzt!: Junior Edition                                                                             |          2025|
|  438280|Voll Verschätzt!: Rotlicht Edition                                                                           |          2025|
|  438287|Battlefields of the Napoleonic Wars                                                                          |          2025|
|  438295|Paws Up                                                                                                      |          2025|
|  438354|Burnout                                                                                                      |          2025|
|  438385|Twittens                                                                                                     |          2025|
|  438391|Pinkuins                                                                                                     |          2025|
|  438402|Forest Shuffle: Dartmoor                                                                                     |          2025|
|  438416|Clichés Criminels                                                                                            |          2025|
|  438417|Les Derniers Droïdes                                                                                         |          2025|
|  438442|Feya's Swamp                                                                                                 |          2025|
|  438443|Terratory Card Game                                                                                          |          2025|
|  438448|Hausta                                                                                                       |          2025|
|  438451|Collectionomics                                                                                              |          2025|
|  438457|Push Push Penguin                                                                                            |          2025|
|  438462|Montaña Pingüino                                                                                             |          2025|
|  438464|Warts and All! Easy and Fast playing Rules to Battle and Campaign during the English Civil war!              |          2025|
|  438465|Tacoloco                                                                                                     |          2025|
|  438466|Bugs Buddy                                                                                                   |          2025|
|  438467|Chit Chat                                                                                                    |          2025|
|  438473|March of the Ants: Evolved Edition – Deluxe Edition                                                          |          2025|
|  438474|Kingdom Reborn                                                                                               |          2025|
|  438478|echoes: Die Titanic-Affäre                                                                                   |          2025|
|  438480|Wargames Rules for Armoured Warfare at Company and Battalion Level 1925 to 1950                              |          2025|
|  438481|Happy Mochi                                                                                                  |          2025|
|  438490|Time Hammer Free 4 All                                                                                       |          2025|
|  438495|1001: 40 Thieves                                                                                             |          2025|
|  438496|The Wanderer: Strategy Card Game                                                                             |          2025|
|  438507|Riftlands: The War Within                                                                                    |          2025|
|  438512|Scream!                                                                                                      |          2025|
|  438519|Azardtia: First Impact                                                                                       |          2025|
|  438520|Fast Fables                                                                                                  |          2025|
|  438526|Slowpoke                                                                                                     |          2025|
|  438530|INKtentions                                                                                                  |          2025|
|  438534|Papyria                                                                                                      |          2025|
|  438536|Mi museo fenicio                                                                                             |          2025|
|  438554|Fantasy: Wargaming World Solo – The Ancient Land of Lexium                                                   |          2025|
|  438555|Israel 1948: The First Arab-Israeli War                                                                      |          2025|
|  438573|Harbustaz                                                                                                    |          2025|
|  438584|Siege Works                                                                                                  |          2025|
|  438594|ODICEY                                                                                                       |          2025|
|  438595|The Vietnam War                                                                                              |          2025|
|  438597|PorazMonster                                                                                                 |          2025|
|  438621|Best Eleven                                                                                                  |          2025|
|  438622|Star Heroes: Trading Card Game                                                                               |          2025|
|  438623|Big Wave                                                                                                     |          2025|
|  438626|Sugarrr!                                                                                                     |          2025|
|  438627|Dueling Horns                                                                                                |          2025|
|  438629|Battle Captains: Company Level Combined Arms Maneuver from WWII to the 21st Century                          |          2025|
|  438636|Little Pig Little Pig                                                                                        |          2025|
|  438648|By the End                                                                                                   |          2025|
|  438649|Deck EXPRESS: Tennessee Central                                                                              |          2025|
|  438654|Cricket Champions                                                                                            |          2025|
|  438657|Minecraft Labyrinth                                                                                          |          2025|
|  438660|Black Flight                                                                                                 |          2025|
|  438669|Happy Heights                                                                                                |          2025|
|  438675|Bishop of Myra                                                                                               |          2025|
|  438679|Drums of War: Conquest                                                                                       |          2025|
|  438685|Mundo Abierto: Elria                                                                                         |          2025|
|  438687|Makara 90'lar                                                                                                |          2025|
|  438691|Order Up! Diner                                                                                              |          2025|
|  438692|Dungeon Date: Roll With Style                                                                                |          2025|
|  438700|Chios 2025                                                                                                   |          2025|
|  438710|Friedland, Heilsberg, Mohrungen 1807                                                                         |          2025|
|  438727|Marvel Dice Throne: X-Men – Iceman v. Psylocke v. Storm v. Wolverine                                         |          2025|
|  438729|Marvel Dice Throne: X-Men – Cyclops v. Gambit v. Rogue v. Jean Grey                                          |          2025|
|  438732|Camino a Xibalba: La senda del sacerdote                                                                     |          2025|
|  438733|Sauros                                                                                                       |          2025|
|  438735|KONIVRER                                                                                                     |          2025|
|  438736|Alebrijes                                                                                                    |          2025|
|  438738|Grasse (Second Edition)                                                                                      |          2025|
|  438753|Persuasion: a Journey of Two Hearts                                                                          |          2025|
|  438773|Barbarity                                                                                                    |          2025|
|  438781|Harry Estate                                                                                                 |          2025|
|  438800|On The Clock                                                                                                 |          2025|
|  438801|REFIVO die flinke Monsterjagd                                                                                |          2025|
|  438808|The Yanks Are Here! The Saint Mihiel Campaign, September 1918                                                |          2025|
|  438827|Carrot Boom!                                                                                                 |          2025|
|  438831|Oniria                                                                                                       |          2025|
|  438839|Hot Dog                                                                                                      |          2025|
|  438840|Numberwang                                                                                                   |          2025|
|  438843|Auctions of Alchemists                                                                                       |          2025|
|  438844|Chrono Team Go!                                                                                              |          2025|
|  438845|Tic Tac BOOM                                                                                                 |          2025|
|  438846|Ages of War: Battle for the Bronze Age                                                                       |          2025|
|  438855|Subito                                                                                                       |          2025|
|  438858|Cut It                                                                                                       |          2025|
|  438866|Croterra                                                                                                     |          2025|
|  438867|Trumped!                                                                                                     |          2025|
|  438883|Lord of Entertainment                                                                                        |          2025|
|  438899|Acres                                                                                                        |          2025|
|  438904|Blob Party: Neon Nights                                                                                      |          2025|
|  438923|Pre-existing Conditions                                                                                      |          2025|
|  438926|A Long Confinement                                                                                           |          2025|
|  438928|A Lethal Fix                                                                                                 |          2025|
|  438930|Paranormal                                                                                                   |          2025|
|  438932|Zoology                                                                                                      |          2025|
|  438933|Storie a bivi                                                                                                |          2025|
|  438936|The White Castle Duel                                                                                        |          2025|
|  438939|Greentown                                                                                                    |          2025|
|  438940|Tic Tac Trek                                                                                                 |          2025|
|  438942|Fantozzi batti lei                                                                                           |          2025|
|  438948|Dispatch Unit                                                                                                |          2025|
|  438956|Supershazam!                                                                                                 |          2025|
|  438961|Joker's Court                                                                                                |          2025|
|  438962|Forest Leader                                                                                                |          2025|
|  438975|Sail Legacy                                                                                                  |          2025|
|  438994|SEBANGAU                                                                                                     |          2025|
|  438995|WW2 Air War: 'Target Ahead'                                                                                  |          2025|
|  438997|Slicery                                                                                                      |          2025|
|  439004|Desolation Terra                                                                                             |          2025|
|  439007|COBR                                                                                                         |          2025|
|  439009|Split Stories #1                                                                                             |          2025|
|  439011|Cold Comfort: Hospitality in the Yukon Gold Rush                                                             |          2025|
|  439013|Flocking Goats                                                                                               |          2025|
|  439018|Once Upon a Time in Phlogiston                                                                               |          2025|
|  439031|Cookie Party                                                                                                 |          2025|
|  439038|Village Pillage: Big Box                                                                                     |          2025|
|  439048|Dice Batter                                                                                                  |          2025|
|  439055|Tortilla Takedown                                                                                            |          2025|
|  439056|What's Under Your Bed?                                                                                       |          2025|
|  439059|The Case of the Curiously Correct Blueprints                                                                 |          2025|
|  439066|Passage                                                                                                      |          2025|
|  439076|FloraVista                                                                                                   |          2025|
|  439083|Blackjack Golf                                                                                               |          2025|
|  439085|Gridmon                                                                                                      |          2025|
|  439099|Torpedo Los!                                                                                                 |          2025|
|  439100|mAIndset                                                                                                     |          2025|
|  439107|Santorini: Second Edition                                                                                    |          2025|
|  439110|Phase                                                                                                        |          2025|
|  439129|Omission                                                                                                     |          2025|
|  439130|Build-a-Cult                                                                                                 |          2025|
|  439131|Field Day                                                                                                    |          2025|
|  439132|The Last Guardian                                                                                            |          2025|
|  439133|Block-A-Shot                                                                                                 |          2025|
|  439134|Rowin                                                                                                        |          2025|
|  439135|Popular                                                                                                      |          2025|
|  439144|Protocole IOMV2236472L                                                                                       |          2025|
|  439145|Die Tempel der Götter                                                                                        |          2025|
|  439146|Die Abfahrt                                                                                                  |          2025|
|  439147|Habanero                                                                                                     |          2025|
|  439149|Absurd Obstacles                                                                                             |          2025|
|  439168|The Face of Battle: Second Edition                                                                           |          2025|
|  439169|Movie Fight                                                                                                  |          2025|
|  439190|Hímes tojások                                                                                                |          2025|
|  439193|Invasion Normandy                                                                                            |          2025|
|  439206|Domino Drop                                                                                                  |          2025|
|  439209|Figment                                                                                                      |          2025|
|  439211|Stealing the Horizons                                                                                        |          2025|
|  439212|VANEA: Guardians of the Eldertree                                                                            |          2025|
|  439216|Ofuda Slap!                                                                                                  |          2025|
|  439220|Der Glückselefant                                                                                            |          2025|
|  439221|Criss Cross Categories                                                                                       |          2025|
|  439224|Rasanto Wortale                                                                                              |          2025|
|  439228|Belts of the Blossomed                                                                                       |          2025|
|  439229|Quiz Me 5                                                                                                    |          2025|
|  439235|Gentle Jack                                                                                                  |          2025|
|  439237|Crazy Heads                                                                                                  |          2025|
|  439239|Loops & Lines                                                                                                |          2025|
|  439244|Battlecry: A Game of Fantasy Battles in a Wondrous Age                                                       |          2025|
|  439246|Das Geheimnis der 7 Kontinente                                                                               |          2025|
|  439252|Interstellar Adventures: The Sincerest Form of Flattery                                                      |          2025|
|  439265|Medieval Realms: The Card Game                                                                               |          2025|
|  439268|Mystery Fluxx                                                                                                |          2025|
|  439270|Delegate Dash                                                                                                |          2025|
|  439283|Black Stories: Cold Cases                                                                                    |          2025|
|  439284|Dare to Consent                                                                                              |          2025|
|  439285|Mega Monster Meals                                                                                           |          2025|
|  439286|Stamps                                                                                                       |          2025|
|  439293|Poules Pirates                                                                                               |          2025|
|  439305|Flamecraft Duals                                                                                             |          2025|
|  439306|Limit                                                                                                        |          2025|
|  439310|Brick Like This!                                                                                             |          2025|
|  439311|Sqwürmish                                                                                                    |          2025|
|  439315|Snapcat                                                                                                      |          2025|
|  439322|Nordic Theater Winter War 1939-1940                                                                          |          2025|
|  439359|Blightwatch: Reconnaissance                                                                                  |          2025|
|  439361|Cozy Cat Cafe                                                                                                |          2025|
|  439363|Bingo: The Mind                                                                                              |          2025|
|  439367|Pulp Romance                                                                                                 |          2025|
|  439370|Baghdad: The City of Peace – Deluxe Edition                                                                  |          2025|
|  439375|Hashtag Hustle                                                                                               |          2025|
|  439380|The Way to My Heart                                                                                          |          2025|
|  439396|Tekton Dash                                                                                                  |          2025|
|  439403|Stack City                                                                                                   |          2025|
|  439409|Arkham Travel Guide                                                                                          |          2025|
|  439412|S3PSYS                                                                                                       |          2025|
|  439421|Cosmic Arena                                                                                                 |          2025|
|  439426|Gettysburg: The First Day                                                                                    |          2025|
|  439437|Steel Wolves and German Fleet Boats: Deluxe Edition                                                          |          2025|
|  439438|Energetic 2.0                                                                                                |          2025|
|  439444|Robot Recharge                                                                                               |          2025|
|  439448|Hand of Cthulhu                                                                                              |          2025|
|  439452|XOXO                                                                                                         |          2025|
|  439453|Toadgeon                                                                                                     |          2025|
|  439454|Words of Magic                                                                                               |          2025|
|  439455|Battles of the American Civil War June 1861: July 1862 – A Solitaire Wargame                                 |          2025|
|  439463|Subspace                                                                                                     |          2025|
|  439467|Fanzone: Soccer Trivia                                                                                       |          2025|
|  439473|Who killed Ace?                                                                                              |          2025|
|  439482|Wizard's Court                                                                                               |          2025|
|  439496|simple earth                                                                                                 |          2025|
|  439511|Tabletop Smack Darts                                                                                         |          2025|
|  439512|Bad Apples                                                                                                   |          2025|
|  439519|Last Lantern                                                                                                 |          2025|
|  439520|Dragonarium                                                                                                  |          2025|
|  439525|Mini Crimes: Deadly Summer                                                                                   |          2025|
|  439526|Dice Dunkers                                                                                                 |          2025|
|  439527|Goat Simulator: The Card Game                                                                                |          2025|
|  439528|Wickens: The Deckbuilding Game                                                                               |          2025|
|  439544|Crab Bucket                                                                                                  |          2025|
|  439547|The Battle of the Divas                                                                                      |          2025|
|  439554|AmaZoom                                                                                                      |          2025|
|  439555|Frost Shelter                                                                                                |          2025|
|  439556|Pool Party Stars                                                                                             |          2025|
|  439561|Gruntz                                                                                                       |          2025|
|  439583|La Quintrala                                                                                                 |          2025|
|  439585|Trivial Pursuit: Gilmore Girls – Quick Play                                                                  |          2025|
|  439586|Tiny Epic Dungeons Adventures                                                                                |          2025|
|  439591|Taïki                                                                                                        |          2025|
|  439595|Cat Vs Human                                                                                                 |          2025|
|  439605|Impellere                                                                                                    |          2025|
|  439606|True Command                                                                                                 |          2025|
|  439611|Elden Ring: Weeping Peninsula                                                                                |          2025|
|  439612|Elden Ring: Stormveil Castle                                                                                 |          2025|
|  439629|La Torre de Babel                                                                                            |          2025|
|  439630|Milord / Milady: One Card                                                                                    |          2025|
|  439631|Pinball Builder: Tower of the Wizard                                                                         |          2025|
|  439643|Tiny Tina's Wonderlands: The Chaos Chamber                                                                   |          2025|
|  439644|Iraqi Freedom: Thirty Days to Baghdad                                                                        |          2025|
|  439645|Doggy Style: Segunda Edición                                                                                 |          2025|
|  439646|Squirrel Away                                                                                                |          2025|
|  439654|Trick Tac Toe: A Cat's Game                                                                                  |          2025|
|  439662|Ham Helsing                                                                                                  |          2025|
|  439673|Normandia 6 Giugno 1944                                                                                      |          2025|
|  439684|WunderWaffen                                                                                                 |          2025|
|  439685|Pacts                                                                                                        |          2025|
|  439686|What's The Best Thing?                                                                                       |          2025|
|  439703|2001: A Space Odyssey &#124; The Board Game                                                                  |          2025|
|  439708|Cat Burglars                                                                                                 |          2025|
|  439724|Sci-Me! Aritmetika                                                                                           |          2025|
|  439728|LifeShip                                                                                                     |          2025|
|  439729|Space Battles: A Spacefarers Guide                                                                           |          2025|
|  439739|Delta                                                                                                        |          2025|
|  439743|Jirafas y Chacales 3                                                                                         |          2025|
|  439745|Fairytale                                                                                                    |          2025|
|  439746|Formula 5                                                                                                    |          2025|
|  439747|Spray                                                                                                        |          2025|
|  439756|Escape From Tibbles Tower                                                                                    |          2025|
|  439758|Monkey Mayhem!                                                                                               |          2025|
|  439765|Unmatched: Battle of Legends, Volume Three                                                                   |          2025|
|  439771|Charge the Circle                                                                                            |          2025|
|  439785|Rift Domination                                                                                              |          2025|
|  439787|Trick Tac Toe                                                                                                |          2025|
|  439803|L'oaf                                                                                                        |          2025|
|  439804|Goblin Laundromat                                                                                            |          2025|
|  439805|Medievallons                                                                                                 |          2025|
|  439807|Masterland                                                                                                   |          2025|
|  439817|Cthulhu e os Segredos Arcanos                                                                                |          2025|
|  439826|Six Sojourns                                                                                                 |          2025|
|  439827|Rudicus                                                                                                      |          2025|
|  439828|Relic Knights: Radiant vs Void Two Player Starter Set                                                        |          2025|
|  439876|Baja Sardinia                                                                                                |          2025|
|  439877|Geaux Parade                                                                                                 |          2025|
|  439880|Through Spring and Autumn                                                                                    |          2025|
|  439907|Luxor: Big Box                                                                                               |          2025|
|  439908|Fallout: Miniatures – Wilds of Applachia                                                                     |          2025|
|  439909|Fantasy Zoo                                                                                                  |          2025|
|  439933|Fetchez la Vache!                                                                                            |          2025|
|  439934|Würfelakrobat Brüche                                                                                         |          2025|
|  439935|Traces of the polar bear                                                                                     |          2025|
|  439943|UPPLES                                                                                                       |          2025|
|  439951|Qui est-ce?: McDonald's Happy Meal                                                                           |          2025|
|  439953|Sur la Route                                                                                                 |          2025|
|  439957|Dungeon Crawl                                                                                                |          2025|
|  439960|Family Dinner: More or Less                                                                                  |          2025|
|  439962|Postcard Monocacy Junction, 9-11 July 1864                                                                   |          2025|
|  439970|Kero Kero Pond                                                                                               |          2025|
|  439971|The Coil                                                                                                     |          2025|
|  439983|The Voynich Puzzle                                                                                           |          2025|
|  439989|Malagasy                                                                                                     |          2025|
|  440000|Hidden Leaders Duel                                                                                          |          2025|
|  440002|Baskaria Challengers                                                                                         |          2025|
|  440007|The Druids of Edora                                                                                          |          2025|
|  440008|Rush of Ikorr                                                                                                |          2025|
|  440014|Ohio Bob                                                                                                     |          2025|
|  440015|Darkleaf Gambit                                                                                              |          2025|
|  440016|Harvest Valley                                                                                               |          2025|
|  440022|Aliens Attack!                                                                                               |          2025|
|  440023|Gazebo                                                                                                       |          2025|
|  440024|Gingham                                                                                                      |          2025|
|  440025|Burum                                                                                                        |          2025|
|  440029|Meow meow dice                                                                                               |          2025|
|  440030|Kudos                                                                                                        |          2025|
|  440032|Angel's Share                                                                                                |          2025|
|  440035|Propeller Island                                                                                             |          2025|
|  440039|HISTORY: Through the Years                                                                                   |          2025|
|  440040|HISTORY: Stats and Facts                                                                                     |          2025|
|  440042|Virtus!                                                                                                      |          2025|
|  440055|Rabbits and the Tortoise: The Great Race                                                                     |          2025|
|  440058|Tiny Epic Dungeons Adventures: Deluxe Edition                                                                |          2025|
|  440060|InfiniBrix                                                                                                   |          2025|
|  440065|Trial by Fire                                                                                                |          2025|
|  440071|Lifeliners                                                                                                   |          2025|
|  440072|Scavengers                                                                                                   |          2025|
|  440080|Garbage Gobblers                                                                                             |          2025|
|  440086|Horizonte                                                                                                    |          2025|
|  440106|KNOTS & NOBS                                                                                                 |          2025|
|  440133|Take One                                                                                                     |          2025|
|  440139|Хто зверху? (Who is on top?)                                                                                 |          2025|
|  440142|Prelude to Leipzig: Napoleon's Spring 1813 Campaign                                                          |          2025|
|  440153|Los Banditos: The Train Heist Card Game                                                                      |          2025|
|  440154|Cross Spin                                                                                                   |          2025|
|  440155|Synthetic Sins                                                                                               |          2025|
|  440157|Quickdraw: Battle for Silver City                                                                            |          2025|
|  440161|Catchpair                                                                                                    |          2025|
|  440168|Void Ventures                                                                                                |          2025|
|  409914|A Guide to Dream Travel                                                                                      |          2024|
|  410680|Kabuto Sumo: Sakura Slam                                                                                     |          2024|
|  427570|Uno Elite NFL: 2024 Core Edition                                                                             |          2024|
|  428250|Steel Psalm                                                                                                  |          2024|
|  429595|Labores de Bizâncio                                                                                          |          2024|
|  430119|No puc! Tinc assaig                                                                                          |          2024|
|  430995|6 Forces                                                                                                     |          2024|
|  431861|Bolt Action: Third Edition                                                                                   |          2024|
|  432592|Le jeu du Ven-dé Globe 2024                                                                                  |          2024|
|  432897|Smart10 Red-Light Edition                                                                                    |          2024|
|  432900|STRATE9Y GAME                                                                                                |          2024|
|  433182|Mystery Cube: Mystery_Rätsel: Lost Places – Schlafsaal                                                       |          2024|
|  433183|Mystery Cube: Mystery_Rätsel – Lost Places: Arzt-Zimmer                                                      |          2024|
|  433184|Mystery Cube: Mystery_Rätsel – Lost Places: Röntgen-Raum                                                     |          2024|
|  433228|Might & Mettle: Rules for Tabletop Medieval Battles                                                          |          2024|
|  433229|Monstrosity                                                                                                  |          2024|
|  433232|Micro Disturblings                                                                                           |          2024|
|  433233|Koalas On Broadway                                                                                           |          2024|
|  433255|Gastro Dash                                                                                                  |          2024|
|  433257|Popularity                                                                                                   |          2024|
|  433261|The Debutante's Ball at Dramaton Hall                                                                        |          2024|
|  433277|How I Met Your Series                                                                                        |          2024|
|  433279|Don't Press That Mine Turtle                                                                                 |          2024|
|  433285|Crazy Corgi                                                                                                  |          2024|
|  433294|Pyramids of Dice                                                                                             |          2024|
|  433295|Sever                                                                                                        |          2024|
|  433301|Smacked Down                                                                                                 |          2024|
|  433302|Hex Hive: Swarm                                                                                              |          2024|
|  433305|Designers                                                                                                    |          2024|
|  433311|Influencer                                                                                                   |          2024|
|  433320|Berggeister                                                                                                  |          2024|
|  433323|DERBI                                                                                                        |          2024|
|  433342|RPage!: The Lair of the Adorned Worm                                                                         |          2024|
|  433344|Betyárvilág                                                                                                  |          2024|
|  433346|Clever Crowns                                                                                                |          2024|
|  433347|SIXEM Sour Patch Kids                                                                                        |          2024|
|  433355|Taking Space                                                                                                 |          2024|
|  433356|Waging Peace                                                                                                 |          2024|
|  433357|Sauna Masters: They Just Don't Get It                                                                        |          2024|
|  433365|Fly for Pie                                                                                                  |          2024|
|  433366|Power Bulletin!                                                                                              |          2024|
|  433368|Poesía a la Carta: León Gieco                                                                                |          2024|
|  433370|A Most Resolute Action: The Battle of Fort Meigs, May 5, 1813                                                |          2024|
|  433377|Chris Kemp's Not Quite Mechanised: Tabletop Operational Wargaming 1914-1945                                  |          2024|
|  433379|Blossoms of Blood: A game of immortal conflicts in the Desired Land                                          |          2024|
|  433383|Wonderland Words                                                                                             |          2024|
|  433387|Blazing Wheels                                                                                               |          2024|
|  433390|Flieg Schweinchen, flieg!: Lass sie fliegen                                                                  |          2024|
|  433392|Kreisel durch die Welt                                                                                       |          2024|
|  433398|Hitster: Magyar kiadás                                                                                       |          2024|
|  433406|Live and Let Pie                                                                                             |          2024|
|  433407|Joint All Domain Operation                                                                                   |          2024|
|  433408|Sharpening the Sword 01: The Battle of New Taipei City                                                       |          2024|
|  433411|Fork Milk Kidnap                                                                                             |          2024|
|  433413|Monopoly Białystok                                                                                           |          2024|
|  433414|Air Force Wargame: Indo-Pacific                                                                              |          2024|
|  433422|Atlantic Convoys 1939-45                                                                                     |          2024|
|  433425|Fractal Tricks (フラクタル-トリック )                                                                        |          2024|
|  433427|Deep Sea Mines                                                                                               |          2024|
|  433433|Tatort Meer Junior: Rätsel um die Robbenbilder                                                               |          2024|
|  433436|Triple Scoops with a Cherry on Top                                                                           |          2024|
|  433437|Future Invaders                                                                                              |          2024|
|  433440|Quermesse                                                                                                    |          2024|
|  433445|Animal Duel                                                                                                  |          2024|
|  433447|Drizzle                                                                                                      |          2024|
|  433450|Frontier Gambit                                                                                              |          2024|
|  433457|Con eso no se jode: Edición – Indigentes                                                                     |          2024|
|  433459|Oversized Sandwich                                                                                           |          2024|
|  433460|Subtropical Japan                                                                                            |          2024|
|  433461|Split Realms                                                                                                 |          2024|
|  433462|Manekinecollection                                                                                           |          2024|
|  433463|GEAR                                                                                                         |          2024|
|  433464|Utsuke                                                                                                       |          2024|
|  433473|DECK 52: Final Bus                                                                                           |          2024|
|  433477|拼拼看 (Puzzle Snap Match)                                                                                   |          2024|
|  433481|Fraudville                                                                                                   |          2024|
|  433490|Talent Jam                                                                                                   |          2024|
|  433495|Sjørøverkamp                                                                                                 |          2024|
|  433509|Vil Du Hellere?                                                                                              |          2024|
|  433510|Er Du Typen?                                                                                                 |          2024|
|  433511|CATSS: Combined Arms Tactical Simulation System                                                              |          2024|
|  433514|Wombo: Deckbuilder                                                                                           |          2024|
|  433515|Escape Game: Allein im Spielzeug-Laden                                                                       |          2024|
|  433526|Quick Hangman                                                                                                |          2024|
|  433528|Same Brain                                                                                                   |          2024|
|  433529|As One!                                                                                                      |          2024|
|  433547|Toy Story: Toy Overload                                                                                      |          2024|
|  433550|Bon Voyage, Voyager!                                                                                         |          2024|
|  433553|Crowns & Cutthroats                                                                                          |          2024|
|  433568|Chocolate Favorers                                                                                           |          2024|
|  433583|Fleece the Hobbits                                                                                           |          2024|
|  433584|Snail Antennae                                                                                               |          2024|
|  433587|Alhambra: Family & Friends Compact Edition                                                                   |          2024|
|  433602|Builders of Sungrave: King's Advisors                                                                        |          2024|
|  433624|Lee's Last Offensive                                                                                         |          2024|
|  433631|Magic Pen                                                                                                    |          2024|
|  433658|Barbaric: Into the Lost Jungle                                                                               |          2024|
|  433659|Barbaric: Heart of the Grand Canyon                                                                          |          2024|
|  433661|Ninjazas                                                                                                     |          2024|
|  433673|Edrala                                                                                                       |          2024|
|  433682|Scribble City                                                                                                |          2024|
|  433683|LakeFinity: Fish Cards                                                                                       |          2024|
|  433686|Final Exam: Grow Up Not a Cheat, Growing Good                                                                |          2024|
|  433687|Secret Hunt                                                                                                  |          2024|
|  433689|The Square                                                                                                   |          2024|
|  433699|ツチノコドコノコ (Tsuchinoko Dokonoko)                                                                       |          2024|
|  433700|カエルサイクル (Frog Cycle)                                                                                  |          2024|
|  433701|Market Day                                                                                                   |          2024|
|  433705|Color Chord                                                                                                  |          2024|
|  433706|そすーと (Sosuto)                                                                                            |          2024|
|  433710|NAM '68: Tour of Duty                                                                                        |          2024|
|  433725|SkyCraft                                                                                                     |          2024|
|  433727|66 fleurs de printemps                                                                                       |          2024|
|  433733|Gardens                                                                                                      |          2024|
|  433742|Beychella                                                                                                    |          2024|
|  433743|Super Ludo                                                                                                   |          2024|
|  433744|Tripleto                                                                                                     |          2024|
|  433745|Соображарий: Чебурашка (Think It Up!: Cheburashka)                                                           |          2024|
|  433747|Альтушка для скуфа (An alt girl for skoof)                                                                   |          2024|
|  433788|Where on the scale?                                                                                          |          2024|
|  433793|Legend of the Unbound Star                                                                                   |          2024|
|  433811|Lost Pirate                                                                                                  |          2024|
|  433812|Put A Finger Down                                                                                            |          2024|
|  433813|Spitfyre: Eagles over Branz-Hûm                                                                              |          2024|
|  433814|Clue: What We Do In The Shadows                                                                              |          2024|
|  433819|Heist Night                                                                                                  |          2024|
|  433824|Borrowing The Army Campaign: Campaign wargames rules for campaigns in the American Civil War Eastern Theater |          2024|
|  433828|bad advice                                                                                                   |          2024|
|  433849|Yog-Sothothery Trick Taking Game                                                                             |          2024|
|  433854|Christmas Chaos                                                                                              |          2024|
|  433860|I Served with Heroes                                                                                         |          2024|
|  433863|Ferro Sequence                                                                                               |          2024|
|  433864|Sunday Manager                                                                                               |          2024|
|  433872|Guanga: Tejidos Andinos                                                                                      |          2024|
|  433886|Escape the Living Library                                                                                    |          2024|
|  433893|いきものボックス (IKIMONO BOX) Vol.1                                                                         |          2024|
|  433894|Uncrossing Stars- a solitaire roll & write survival game                                                     |          2024|
|  433895|What's Eating the Danish Prince?: A solitaire roll & write crisis management game                            |          2024|
|  433896|FACER                                                                                                        |          2024|
|  433897|Cheese Security, Inc.: A solitaire movement puzzle game                                                      |          2024|
|  433898|Dino Mites: A solitaire skirmish puzzle game                                                                 |          2024|
|  433900|Truel                                                                                                        |          2024|
|  433901|Labyrint Zločinu: Devadesátky                                                                                |          2024|
|  433907|I Want to Talk to the Manager!                                                                               |          2024|
|  433909|Decolar Corp.                                                                                                |          2024|
|  433910|Poltergeist                                                                                                  |          2024|
|  433911|Cryptid Hunter                                                                                               |          2024|
|  433919|It Flies, It Spies                                                                                           |          2024|
|  433928|Overlords in Training                                                                                        |          2024|
|  433962|Chicken in the Kitchen                                                                                       |          2024|
|  433964|Crop Circles Roll & Write Game                                                                               |          2024|
|  433967|DOGS                                                                                                         |          2024|
|  433971|PinchBowl                                                                                                    |          2024|
|  433972|Revolução dos Bichos                                                                                         |          2024|
|  433973|Feluś i Gucio grają w emocje                                                                                 |          2024|
|  433975|Bleven                                                                                                       |          2024|
|  433983|That's Crypto Bro                                                                                            |          2024|
|  433984|Cuiquindi                                                                                                    |          2024|
|  433990|Lâche pas la savonette Extra Large                                                                           |          2024|
|  434006|Zostań prowadzącym MaturaToBzdura                                                                            |          2024|
|  434026|Zauberhafte Rätselpost                                                                                       |          2024|
|  434035|Doorz                                                                                                        |          2024|
|  434054|The World: a Tarot Solitaire                                                                                 |          2024|
|  434069|Canyon Diablo                                                                                                |          2024|
|  434070|Data Fortress: 2060                                                                                          |          2024|
|  434071|Minihex                                                                                                      |          2024|
|  434075|36                                                                                                           |          2024|
|  434084|Nivon Natuurvrienden Spel                                                                                    |          2024|
|  434086|Rock Stars                                                                                                   |          2024|
|  434092|Temple Dice                                                                                                  |          2024|
|  434093|TGI Fishing Classic                                                                                          |          2024|
|  434094|Tripped                                                                                                      |          2024|
|  434096|The A List                                                                                                   |          2024|
|  434098|Toppa                                                                                                        |          2024|
|  434106|Propaganda                                                                                                   |          2024|
|  434107|CLOSE THE CASE: Wo ist David M.?                                                                             |          2024|
|  434108|Ultraman: Spirit of Light                                                                                    |          2024|
|  434111|Mini Meeple Melee: Fire and Ice                                                                              |          2024|
|  434114|Chapolin Colorado em: Pepe, Já Tirei a Vela!                                                                 |          2024|
|  434120|Match the Dots                                                                                               |          2024|
|  434123|Where & Which                                                                                                |          2024|
|  434124|Imhre: Ophiuchus' Legacy                                                                                     |          2024|
|  434136|Call of Yeti                                                                                                 |          2024|
|  434139|Armoured Clash                                                                                               |          2024|
|  434140|Slaughter the Dragon                                                                                         |          2024|
|  434141|Flow                                                                                                         |          2024|
|  434147|Square Deal                                                                                                  |          2024|
|  434151|Sent By The Gods                                                                                             |          2024|
|  434158|Thank you, Santa                                                                                             |          2024|
|  434164|Forty Crowns                                                                                                 |          2024|
|  434167|Sengoku Folio 11: The Battle of Okitanawate                                                                  |          2024|
|  434189|Legions of Heimland                                                                                          |          2024|
|  434190|На Слово На Слово (On the Word on the Word)                                                                  |          2024|
|  434192|Tinka og Ensomhedens Tårn                                                                                    |          2024|
|  434193|Subscribe!                                                                                                   |          2024|
|  434195|¡PLASH!                                                                                                      |          2024|
|  434198|Der Rätsel- und Kreativblock für Taylor Swift-Fans                                                           |          2024|
|  434199|Nenne drei: schon vorbei! – für Taylor Swift-Fans!                                                           |          2024|
|  434219|Liflina                                                                                                      |          2024|
|  434226|Zew Prehistorii                                                                                              |          2024|
|  434230|Monty Hall                                                                                                   |          2024|
|  434235|Farmoony                                                                                                     |          2024|
|  434241|Take That Toy!                                                                                               |          2024|
|  434242|Loud Rock Spa                                                                                                |          2024|
|  434244|Arc-en-Ciel                                                                                                  |          2024|
|  434246|BUBBLE GUM                                                                                                   |          2024|
|  434247|Hex Hive: Larvae                                                                                             |          2024|
|  434285|Fishy Squishy Crusty Quirky                                                                                  |          2024|
|  434289|COSMOS                                                                                                       |          2024|
|  434293|Blast Radius                                                                                                 |          2024|
|  434296|Kalashnikov Tribal: Multi-Battalion                                                                          |          2024|
|  434299|Alphabet Crossing                                                                                            |          2024|
|  434301|Peatris                                                                                                      |          2024|
|  434306|Roll4Rum                                                                                                     |          2024|
|  434310|Blackout Bar Brawl                                                                                           |          2024|
|  434319|American Civil War Commander                                                                                 |          2024|
|  434326|Cardinal                                                                                                     |          2024|
|  434331|Destek Köstek                                                                                                |          2024|
|  434340|Lauba                                                                                                        |          2024|
|  434341|Lefe                                                                                                         |          2024|
|  434347|dug2ngan                                                                                                     |          2024|
|  434354|SEPAK                                                                                                        |          2024|
|  434366|Jellyfish Eyes: Trading Card Game                                                                            |          2024|
|  434391|Control de Plagas                                                                                            |          2024|
|  434400|Kobold Quest: Orbital Heist                                                                                  |          2024|
|  434404|Beset                                                                                                        |          2024|
|  434405|When We Were Kings                                                                                           |          2024|
|  434406|OMG: Operation Market Garden                                                                                 |          2024|
|  434411|Vietnam: Section by Section – Take that Village                                                              |          2024|
|  434421|Up Too High                                                                                                  |          2024|
|  434426|Coucou la Girafe                                                                                             |          2024|
|  434466|A Very Merry Made-for-TV Movie                                                                               |          2024|
|  434481|Gleipnir                                                                                                     |          2024|
|  434484|Hex Hive: Syzygy                                                                                             |          2024|
|  434486|ClamBake                                                                                                     |          2024|
|  434491|Butts in Space Galactic Edition                                                                              |          2024|
|  434495|The Werewolves bEat Robbers' Horror                                                                          |          2024|
|  434496|The Hotel at the End of the Universe                                                                         |          2024|
|  434499|Mystic Codes                                                                                                 |          2024|
|  434500|Slayers and Dragons                                                                                          |          2024|
|  434501|IRWM                                                                                                         |          2024|
|  434503|Kissat kalassa                                                                                               |          2024|
|  434506|Dungeon Ballers                                                                                              |          2024|
|  434509|Letter League Classic                                                                                        |          2024|
|  434549|Railage                                                                                                      |          2024|
|  434568|Luchamania                                                                                                   |          2024|
|  434569|Showdown                                                                                                     |          2024|
|  434572|Heraldry                                                                                                     |          2024|
|  434653|My Little Horrors                                                                                            |          2024|
|  434655|Hex Hive: Bumbling Bees                                                                                      |          2024|
|  434656|Détective Charlie: Calendrier de l'Avent – Qui a volé l'étoile de Noël?                                      |          2024|
|  434657|Crime Files: Fallakte – Das dunkle Geheimnis der Influencerin                                                |          2024|
|  434658|SokkoTuristi                                                                                                 |          2024|
|  434661|Caleçons & Dragon                                                                                            |          2024|
|  434662|Cashflowpoly: Entrepreneur Edition                                                                           |          2024|
|  434664|El Regalo No Prometido: Two Cards                                                                            |          2024|
|  434665|Funny Destination (La Quedaste...): One Card                                                                 |          2024|
|  434707|GUARDS: Version 2                                                                                            |          2024|
|  434830|Texas Demons                                                                                                 |          2024|
|  434832|Duile                                                                                                        |          2024|
|  434837|NIKKE: Duel Encounter                                                                                        |          2024|
|  434842|Forbidden Psalm: The End Times Edition                                                                       |          2024|
|  434847|Hotsperm                                                                                                     |          2024|
|  434856|Ruby and Onyx                                                                                                |          2024|
|  434877|Uprising                                                                                                     |          2024|
|  434944|Omnigaea                                                                                                     |          2024|
|  435020|Ninja Hamster Apocalypse Disco                                                                               |          2024|
|  435021|IronFlight: A Rustlands Adventure                                                                            |          2024|
|  435027|Name That Headliner                                                                                          |          2024|
|  435028|白と黒でトリテ　見えない数字 (Trick-Taking in Black and White, Hidden Numbers)                               |          2024|
|  435029|French Goats in Trench Coats                                                                                 |          2024|
|  435038|カケルカケルカ 拡張同梱版 (Kakeruka Keruka)                                                                  |          2024|
|  435039|Pirmoji pagalba                                                                                              |          2024|
|  435050|Club Sandwich                                                                                                |          2024|
|  435058|Mystery Riddles: Adventskalender – Der magische Wald                                                         |          2024|
|  435062|Santa Sumo                                                                                                   |          2024|
|  435063|Correfoc                                                                                                     |          2024|
|  435064|Gremios                                                                                                      |          2024|
|  435067|Die drei ???: Stadt – Land – Rocky Beach                                                                     |          2024|
|  435070|Music Trivia                                                                                                 |          2024|
|  435073|Horde of Presents                                                                                            |          2024|
|  435081|Slicron                                                                                                      |          2024|
|  435087|軌跡 Trading Card Game (Kiseki Trading Card Game)                                                            |          2024|
|  435092|City Line                                                                                                    |          2024|
|  435142|Shucos: El juego de mesa                                                                                     |          2024|
|  435154|Stitch the Stars                                                                                             |          2024|
|  435159|Carteros de Villacolmillo                                                                                    |          2024|
|  435291|Spy Guy: Card Game                                                                                           |          2024|
|  435292|Spy Guy: Paw Patrol                                                                                          |          2024|
|  435293|Detective Meow                                                                                               |          2024|
|  435294|Mookao                                                                                                       |          2024|
|  435325|1855: Lu Trinittu                                                                                            |          2024|
|  435347|Menú                                                                                                         |          2024|
|  435350|Who Stole My Cheese?                                                                                         |          2024|
|  435352|Lupin III: The Italian Adventure                                                                             |          2024|
|  435353|3, 2, 1 Piñata!                                                                                              |          2024|
|  435366|La Battaglia di Pavia febbraio 1525                                                                          |          2024|
|  435380|Color Cats                                                                                                   |          2024|
|  435381|Merchants of the Bazaar                                                                                      |          2024|
|  435382|Nossete Catamquero                                                                                           |          2024|
|  435383|Choice a Gift                                                                                                |          2024|
|  435384|The Second                                                                                                   |          2024|
|  435394|Nay Saga                                                                                                     |          2024|
|  435444|I am Stardust                                                                                                |          2024|
|  435468|Kansas City Christmas Trick-Taking Game 2024                                                                 |          2024|
|  435470|My First Theme Park Board Game                                                                               |          2024|
|  435479|Vadrantir                                                                                                    |          2024|
|  435488|Hex Hive: Skirmish                                                                                           |          2024|
|  435496|Guarida Goblin                                                                                               |          2024|
|  435497|Retropedalage                                                                                                |          2024|
|  435503|Pangu                                                                                                        |          2024|
|  435511|Hostile Space                                                                                                |          2024|
|  435512|A Herança de Cthulhu: Board Game                                                                             |          2024|
|  435548|La Clef: Les Chutes d'Est-Rive                                                                               |          2024|
|  435579|Tirioga                                                                                                      |          2024|
|  435591|Sinfrid                                                                                                      |          2024|
|  435592|Meuda                                                                                                        |          2024|
|  435605|Pavlova                                                                                                      |          2024|
|  435611|Shiratama Jong                                                                                               |          2024|
|  435624|Dalen                                                                                                        |          2024|
|  435626|Fuga do Sanatório Moreau                                                                                     |          2024|
|  435628|Cichociemni: Spadochroniarze AK                                                                              |          2024|
|  435629|Skunked!                                                                                                     |          2024|
|  435654|CATOrCAT                                                                                                     |          2024|
|  435664|Marbanta                                                                                                     |          2024|
|  435668|Launiz                                                                                                       |          2024|
|  435670|Fate: Defenders of Grimheim (Kickstarter Edition)                                                            |          2024|
|  435672|Forgotten Ruin: The Adventure Wargame                                                                        |          2024|
|  435673|Instant Hero Squadron                                                                                        |          2024|
|  435681|Atlantic War, 1914-18                                                                                        |          2024|
|  435682|TKG ARENA: The Seal Bearers                                                                                  |          2024|
|  435683|Panomachea                                                                                                   |          2024|
|  435690|Murder on Mount Mortimer                                                                                     |          2024|
|  435698|Welcome to Africa                                                                                            |          2024|
|  435709|Knights of the Air                                                                                           |          2024|
|  435712|Operazione C3                                                                                                |          2024|
|  435748|The Stack                                                                                                    |          2024|
|  435754|Fengros                                                                                                      |          2024|
|  435762|Az Árulók: Gyilkosság a kastélyban                                                                           |          2024|
|  435795|Catching Jack Frost                                                                                          |          2024|
|  435798|Who Framed Santa Claus?                                                                                      |          2024|
|  435801|Merry Mischief                                                                                               |          2024|
|  435805|Summer 1960                                                                                                  |          2024|
|  435807|Skyline                                                                                                      |          2024|
|  435816|Roll-Over!                                                                                                   |          2024|
|  435818|Gangsters! A Complete Gangster-Era Tabletop Game                                                             |          2024|
|  435822|Monopoly: Iron Maiden                                                                                        |          2024|
|  435836|Hirdalan                                                                                                     |          2024|
|  435841|The War of the Rohirrim: Battle of Edoras                                                                    |          2024|
|  435847|Black Dragon                                                                                                 |          2024|
|  435849|Esgros                                                                                                       |          2024|
|  435853|Skurkarnas Skurk sällskapsspel                                                                               |          2024|
|  435857|Trick King                                                                                                   |          2024|
|  435859|Lidalan                                                                                                      |          2024|
|  435860|Не бях аз! (It wasn't me!)                                                                                   |          2024|
|  435864|Sgibun                                                                                                       |          2024|
|  435869|Как победить дракона (How to Defeat a Dragon)                                                                |          2024|
|  435875|Гарри Поттер: Кубок факультетов (Harry Potter: House Cup)                                                    |          2024|
|  435881|Paragliding Hike & Fly                                                                                       |          2024|
|  435885|Kollide                                                                                                      |          2024|
|  435887|Tirnabun                                                                                                     |          2024|
|  435888|Eatz-A-Lotl!                                                                                                 |          2024|
|  435890|Sliglube                                                                                                     |          2024|
|  435892|The Completist                                                                                               |          2024|
|  435893|Опознай България (Discover Bulgaria)                                                                         |          2024|
|  435910|Mini UNO Bullseye                                                                                            |          2024|
|  435911|Scandal: The Game                                                                                            |          2024|
|  435915|Disaster Tour                                                                                                |          2024|
|  435918|Wondrous                                                                                                     |          2024|
|  435919|Murder in Tinseltown                                                                                         |          2024|
|  435922|Average Joe                                                                                                  |          2024|
|  435931|Liga F: El Juego                                                                                             |          2024|
|  435934|Mexican Train Dominoes: Double 18                                                                            |          2024|
|  435944|Exploding Kittens: Duels                                                                                     |          2024|
|  435946|Rolldown                                                                                                     |          2024|
|  435958|Infinity: Operation Sandtrap                                                                                 |          2024|
|  435963|The Worst-Case Scenario Card Game: Apocalypse                                                                |          2024|
|  435974|Murdio Island: The Panda Panic                                                                               |          2024|
|  435976|HITSTER: Swiss Edition                                                                                       |          2024|
|  435979|HIT! Extreme                                                                                                 |          2024|
|  435991|Murder Mystery: Murder at Lake Como                                                                          |          2024|
|  436006|Alien Signs                                                                                                  |          2024|
|  436008|Rotvärlden: Realms of Carnage                                                                                |          2024|
|  436016|Blast Off!!                                                                                                  |          2024|
|  436017|The Emperor's New Tricks                                                                                     |          2024|
|  436022|Restoria                                                                                                     |          2024|
|  436024|Die halbe Wahrheit                                                                                           |          2024|
|  436036|Happy Habitat                                                                                                |          2024|
|  436037|Fourcast                                                                                                     |          2024|
|  436041|Drawing From Memory                                                                                          |          2024|
|  436044|Cropa                                                                                                        |          2024|
|  436045|サバンナテン(Savanna Ten)                                                                                    |          2024|
|  436051|Táboření v čase                                                                                              |          2024|
|  436062|Ferabun                                                                                                      |          2024|
|  436066|Der Vegas Fall Krimi-Adventskalender                                                                         |          2024|
|  436067|Paper Apps: Galaxy                                                                                           |          2024|
|  436073|カニナリエビ (Kani nari Ebi)                                                                                 |          2024|
|  436081|Vediic Cosmic Strategy Game                                                                                  |          2024|
|  436089|Fossilian                                                                                                    |          2024|
|  436100|Draw My Face                                                                                                 |          2024|
|  436104|Byte Club                                                                                                    |          2024|
|  436110|Battle of Kandahar Game                                                                                      |          2024|
|  436139|Pack O Game: Set 3                                                                                           |          2024|
|  436158|Hostage Negotiator: Ultimate Box                                                                             |          2024|
|  436165|Azvaltya: Les anges gardiens                                                                                 |          2024|
|  436168|Chytré kostky: Doprava                                                                                       |          2024|
|  436170|Monopoly W:O:A                                                                                               |          2024|
|  436175|Dead Air                                                                                                     |          2024|
|  436176|Halftime Homicide                                                                                            |          2024|
|  436177|Clash Of Steel: War of Unification – Soviet vs British Complete Starter Set                                  |          2024|
|  436178|Bid Coin                                                                                                     |          2024|
|  436179|Depth Charges                                                                                                |          2024|
|  436203|Snow Battle Card Game                                                                                        |          2024|
|  436211|Ink & Clues: Secrets of the Holloway Manor                                                                   |          2024|
|  436220|Kombat Kangaroo!                                                                                             |          2024|
|  436237|The Ultimate Date Night Game for Fun Couples                                                                 |          2024|
|  436247|Basketball Chess                                                                                             |          2024|
|  436266|BiznessWiz                                                                                                   |          2024|
|  436268|Surmount                                                                                                     |          2024|
|  436269|Help Your Neighbor                                                                                           |          2024|
|  436272|Space Hunt                                                                                                   |          2024|
|  436290|The grand prophecy of Asuholov                                                                               |          2024|
|  436295|Mörka vatten                                                                                                 |          2024|
|  436296|Bröllopsmordet                                                                                               |          2024|
|  436297|Den okända stalkern                                                                                          |          2024|
|  436312|Death Game Card: Hack                                                                                        |          2024|
|  436316|Remember?                                                                                                    |          2024|
|  436325|Nuh-Uh!                                                                                                      |          2024|
|  436335|PROFILER: I Fantasmi Di Brandonsbury                                                                         |          2024|
|  436337|Movie Quiz                                                                                                   |          2024|
|  436338|Mamutensão                                                                                                   |          2024|
|  436339|Greek Island Conquerors                                                                                      |          2024|
|  436353|Карта сокровищ (Treasure Map)                                                                                |          2024|
|  436363|A Game Called Birds                                                                                          |          2024|
|  436377|Número Perdido                                                                                               |          2024|
|  436383|Regalitos de Navidad                                                                                         |          2024|
|  436385|はらぺこオバケは料理がまてない (Hungry ghost can't wait for food)                                            |          2024|
|  436387|Cards For Christianity                                                                                       |          2024|
|  436406|Kircholm: Riga in the Blance 27 September 1605                                                               |          2024|
|  436407|クイズ　トリックテイキング (Quiz Trick Taking)                                                               |          2024|
|  436420|Yeet the Rich                                                                                                |          2024|
|  436432|Neural Connection                                                                                            |          2024|
|  436433|Reel-Time Pro Fishin' Game                                                                                   |          2024|
|  436441|Host Your Own Murder Mystery: At the Circus                                                                  |          2024|
|  436447|Elements Tricks                                                                                              |          2024|
|  436449|Spela Snabbare!                                                                                              |          2024|
|  436451|最善 (Saizen)                                                                                                |          2024|
|  436452|明暗 (Meian)                                                                                                 |          2024|
|  436453|Services Spéciaux: Opération HUMINT                                                                          |          2024|
|  436454|寝返りふれんず (Negaeri Friends)                                                                             |          2024|
|  436455|Starnim                                                                                                      |          2024|
|  436457|Raise the Risk                                                                                               |          2024|
|  436463|Trick Taking Dungeon                                                                                         |          2024|
|  436467|Hypershot                                                                                                    |          2024|
|  436471|Pirates of Perfidy                                                                                           |          2024|
|  436486|SherBlock: Uno Scandalo in Boemia                                                                            |          2024|
|  436487|SherBlock: Lo Spettro di Londra                                                                              |          2024|
|  436513|Universe A1                                                                                                  |          2024|
|  436522|Gambler × Gamble!!                                                                                           |          2024|
|  436527|SideQuest: Aquí no hay Héroes                                                                                |          2024|
|  436530|Mov-It                                                                                                       |          2024|
|  436531|Patitos                                                                                                      |          2024|
|  436555|S for Startup                                                                                                |          2024|
|  436562|Ink & Clues: The Ferryman                                                                                    |          2024|
|  436563|Ink & Clues: The Ghost of Crimson Sky Ranch                                                                  |          2024|
|  436564|Ink & Clues: The Organ Harvester                                                                             |          2024|
|  436571|Orbital: The Chemical Card Game                                                                              |          2024|
|  436591|Brightcast                                                                                                   |          2024|
|  436594|Blaster Magnets                                                                                              |          2024|
|  436621|Focusi                                                                                                       |          2024|
|  436632|A Happy New Semester                                                                                         |          2024|
|  436635|Deck of Carts                                                                                                |          2024|
|  436649|Dominion of the Spear                                                                                        |          2024|
|  436690|Trivial Pursuit: Schitt's Creek Edition                                                                      |          2024|
|  436692|Il Gomitolo di Solevento: Il gioco da tavolo                                                                 |          2024|
|  436700|The Great Goblin Argle-Bargle                                                                                |          2024|
|  436755|Flip Chess                                                                                                   |          2024|
|  436758|Backgammon Dice                                                                                              |          2024|
|  436762|Guess the Gibberish                                                                                          |          2024|
|  436773|Paint It Black                                                                                               |          2024|
|  436775|紙ペントリテ (Kami Pen Torite)                                                                               |          2024|
|  436776|VIVA! Woodwork                                                                                               |          2024|
|  436841|ツナワタリ (Tunawatari)                                                                                      |          2024|
|  436845|Letterprik                                                                                                   |          2024|
|  436848|Emperor of the Battlefield:   Napoleonic Wargame Rules for the Revolutionary and Empire Years                |          2024|
|  436892|Fierro Viejo                                                                                                 |          2024|
|  436923|Liberation of the Colonised Planet                                                                           |          2024|
|  436929|Merchants of the Caliphate                                                                                   |          2024|
|  436942|Phrasium                                                                                                     |          2024|
|  436945|Kōshodō                                                                                                      |          2024|
|  436956|Body Be Gone                                                                                                 |          2024|
|  437029|Ringbahn Roulette                                                                                            |          2024|
|  437030|ButtChess                                                                                                    |          2024|
|  437037|Charadium                                                                                                    |          2024|
|  437038|One Liners                                                                                                   |          2024|
|  437042|Hydra's Voyage                                                                                               |          2024|
|  437052|Churn                                                                                                        |          2024|
|  437062|Raksha Bandhan: Celebrating the Bond of Siblings                                                             |          2024|
|  437102|Assemblea de Majaras                                                                                         |          2024|
|  437119|Paper Apps: Golf                                                                                             |          2024|
|  437127|Sushi Sushi                                                                                                  |          2024|
|  437139|Ouija Manor                                                                                                  |          2024|
|  437142|Supply and Steel:  A WW2 Logistics Micro Wargame                                                             |          2024|
|  437154|Telepaattori                                                                                                 |          2024|
|  437160|Daga                                                                                                         |          2024|
|  437197|Ciucioi                                                                                                      |          2024|
|  437211|De Zoektocht naar El Dorado: Big Box                                                                         |          2024|
|  437236|Panambí                                                                                                      |          2024|
|  437281|Platzy                                                                                                       |          2024|
|  437296|Erupei                                                                                                       |          2024|
|  437307|Sankei                                                                                                       |          2024|
|  437309|Dragon Face-Off                                                                                              |          2024|
|  437350|Bug Tracer                                                                                                   |          2024|
|  437358|What the Cluck?                                                                                              |          2024|
|  437359|Blockhunters: The Bitcoin Board Game                                                                         |          2024|
|  437360|Ghostwatcher                                                                                                 |          2024|
|  437361|Duelyst II: The Board Game                                                                                   |          2024|
|  437421|Táhni! Česko: Kvízový souboj                                                                                 |          2024|
|  437467|Jealy Jellies: Sea Greed                                                                                     |          2024|
|  437472|The Element of Surprise                                                                                      |          2024|
|  437495|Щенячий патруль: Герої Бухти Пригод (Paw Patrol: Heroes of Adventure Bay)                                    |          2024|
|  437542|Lista de Santa                                                                                               |          2024|
|  437556|Syndicate: Котики и Власть (Syndicate Cats and Power)                                                        |          2024|
|  437563|Monopoly: Rybnik                                                                                             |          2024|
|  437589|Top Trumps Quiz: One Piece                                                                                   |          2024|
|  437595|Ye Xian                                                                                                      |          2024|
|  437660|Super Duper Superhero                                                                                        |          2024|
|  437694|Nice Steak                                                                                                   |          2024|
|  437724|5 Second Bomb                                                                                                |          2024|
|  437725|Ami Dungeon                                                                                                  |          2024|
|  437726|境界線の果ての果てにて (At the very end of the boundary line)                                                |          2024|
|  437727|Balonismo                                                                                                    |          2024|
|  437728|Opermech: Battle Go Outs                                                                                     |          2024|
|  437729|みんなでバースデー (Birthday for everyone)                                                                   |          2024|
|  437730|Choice A Gift                                                                                                |          2024|
|  437731|だるまさんがころんだ (Daruma Fell Down)                                                                      |          2024|
|  437733|Flip Galaxy                                                                                                  |          2024|
|  437735|フォッシリアン (Fossilian)                                                                                   |          2024|
|  437736|Yokai Parade                                                                                                 |          2024|
|  437737|GOTTUN                                                                                                       |          2024|
|  437739|業アウト (Gou Out)                                                                                           |          2024|
|  437740|GyozaTaking                                                                                                  |          2024|
|  437742|メモリクエスト (Note Request)                                                                                |          2024|
|  437743|Might be an ALIEN                                                                                            |          2024|
|  437745|NINEKEYS                                                                                                     |          2024|
|  437746|ノッセーテカタムケーロ (Nossetekatamukero)                                                                   |          2024|
|  437747|にゃんこ×ぷりてぃ (Kitty x Pretty)                                                                           |          2024|
|  437748|Over Million                                                                                                 |          2024|
|  437749|Slam and Showdown                                                                                            |          2024|
|  437751|The second                                                                                                   |          2024|
|  437752|The Werewolves                                                                                               |          2024|
|  437753|陰陽符戦 (Yin Yang Sign Battle)                                                                              |          2024|
|  437754|おまえのアプデもおれのもの (Your updates are mine too)                                                       |          2024|
|  437812|Zumo de Fetos                                                                                                |          2024|
|  437870|The Tab                                                                                                      |          2024|
|  437960|Cra`$h | 2024 |
| 437976 | Letter Duel | 2024 |
| 437983 | トライアングルコネクター (Triangle Connector) | 2024 |
| 438007 | Időhurok | 2024 |
| 438016 | Make it Quick | 2024 |
| 438017 | Sushi Stax | 2024 |
| 438045 | Tales of Blood Island Game | 2024 |
| 438046 | Alabín: Memory Game | 2024 |
| 438047 | Lemonade Stand Board Game | 2024 |
| 438071 | Joke’s On Who | 2024 |
| 438078 | Road-Trip à la Découverte de l’Ardèche | 2024 |
| 438090 | Go Go UFO! | 2024 |
| 438093 | Да, но это другое (Yes, But not the Same) | 2024 |
| 438096 | CAT-egories | 2024 |
| 438160 | Murdio Island: Vom Erdboden verschluckt | 2024 |
| 438163 | Rummikub Gdańsk | 2024 |
| 438165 | Playbill Broadway Trivia | 2024 |
| 438182 | Leaf: Deluxe Edition | 2024 |
| 438194 | Expedición Marítima | 2024 |
| 438215 | Jó a szó! | 2024 |
| 438261 | Tali e Squali | 2024 |
| 438266 | Va Mourir Sur Mars | 2024 |
| 438267 | Warhammer Age of Sigmar: Spearhead – Fire & Jade Gaming Pack | 2024 |
| 438289 | Loyalty TCG | 2024 |
| 438307 | ASL: Journal – Issue Fifteen | 2024 |
| 438320 | LaLaLa | 2024 |
| 438375 | Match Tac Toe | 2024 |
| 438414 | Pizz’Arène | 2024 |
| 438452 | Combo Up | 2024 |
| 438460 | Im Laufe der Zeit | 2024 |
| 438470 | Wars of Eagles and Empires | 2024 |
| 438502 | Splatterkins | 2024 |
| 438510 | Rensaw Bingo | 2024 |
| 438516 | The Fate Experiment | 2024 |
| 438521 | Harry Potter: défense contre les forces du mal | 2024 |
| 438523 | ツクル10テン(Tsukuru Ten Ten) | 2024 |
| 438525 | Poison Ville | 2024 |
| 438572 | Do You Even Know Me? | 2024 |
| 438590 | Ona jest 10 na 10, ale… | 2024 |
| 438591 | On jest 10 na 10, ale… | 2024 |
| 438592 | Jestem… to oczywiste, że… | 2024 |
| 438593 | Jestem… to oczywiste, że… bez cenzury | 2024 |
| 438616 | Ace Run | 2024 |
| 438646 | Eleitos: O Jogo da Democracia | 2024 |
| 438658 | Murdio Island: Sabotage im Freizeitpark | 2024 |
| 438690 | ÜBERmorgen: Ein Spiel um die Zukunft | 2024 |
| 438705 | Suwałki Gap 2025 | 2024 |
| 438708 | 21st Century Battles 2 | 2024 |
| 438711 | Bornholm 2025 | 2024 |
| 438713 | Pultusk 1702 | 2024 |
| 438726 | Piskorzowice 1945 | 2024 |
| 438728 | Glowno 1939 | 2024 |
| 438737 | Arboro | 2024 |
| 438793 | Disney Encanto: Magical Super Game | 2024 |
| 438794 | Top Brass | 2024 |
| 438795 | Punchy Kicky | 2024 |
| 438832 | ME IO | 2024 |
| 438836 | Paris Pastries | 2024 |
| 438847 | Lincoln 1141 | 2024 |
| 438848 | La Corunna 1809 | 2024 |
| 438853 | Stab Your Friends | 2024 |
| 438879 | Ostroleka 1807 | 2024 |
| 438887 | Intergalactic Plumber | 2024 |
| 438902 | Wrong Answers Only | 2024 |
| 438935 | Hex General: Fantasy Edition | 2024 |
| 438964 | Jibber Jabble | 2024 |
| 438988 | Quint | 2024 |
| 439010 | Stadt Land Vollpfosten: Levels – Classic Edition | 2024 |
| 439016 | Helheim: Strategic and Educational Board/Card Game | 2024 |
| 439021 | Nähdään Granissa | 2024 |
| 439022 | Nähdään Hämptonissa! | 2024 |
| 439034 | Catchables: Caterina & Catastrophe | 2024 |
| 439077 | Suomalainen sulkapallopeli | 2024 |
| 439091 | Monopoly: Pokemon Edition | 2024 |
| 439111 | Triangle Chess | 2024 |
| 439137 | Partitions | 2024 |
| 439184 | On s’fait un Panacloc | 2024 |
| 439213 | Obscure Battles 7: Forgotten Garrison | 2024 |
| 439223 | Nivel Arena | 2024 |
| 439259 | Raise Your Red Flag: Original edition | 2024 |
| 439260 | Raise Your Red Flag: Not Safe For Work Edition | 2024 |
| 439262 | Quickly | 2024 |
| 439264 | Fuzzy Butts | 2024 |
| 439274 | Soccer 54 | 2024 |
| 439287 | Iwo Jima: Lite Edition | 2024 |
| 439307 | Doggerland Hunt: Rules for Stone Age Miniature Gaming | 2024 |
| 439313 | Monopoly: The Shelock Holmes Museum | 2024 |
| 439321 | Scaffolding | 2024 |
| 439357 | Губка Боб Квадратні Штани (SpongeBob SquarePants) | 2024 |
| 439422 | Dispersion: The Great Commission of the 12 Apostles | 2024 |
| 439433 | No Cap! | 2024 |
| 439440 | Shocking Deal | 2024 |
| 439466 | Arkham Horror: The Card Game – Pistols and Pearls: Parallel Investigator | 2024 |
| 439472 | Cellular Powerhouse | 2024 |
| 439474 | A Rogue on the High Seas | 2024 |
| 439475 | Galea | 2024 |
| 439476 | Stikeout | 2024 |
| 439477 | Strong Star: Volume One | 2024 |
| 439478 | Strong Star Volume Two | 2024 |
| 439479 | Toward The Top | 2024 |
| 439480 | Warlock’s Brew | 2024 |
| 439481 | Color Factory | 2024 |
| 439503 | Bottom Out | 2024 |
| 439593 | Catchables: Cat Wearing A Cat & Catcus | 2024 |
| 439594 | Catchables: Donut Cat & Lumber Cat | 2024 |
| 439613 | Déblok!: McDonald’s Happy Meal | 2024 |
| 439623 | Shit Happens: Parenting Edition | 2024 |
| 439680 | Successió | 2024 |
| 439707 | Crushin’ & Crunchin’ | 2024 |
| 439711 | Dark Deeds (2nd Edition) | 2024 |
| 439731 | Seastrike 1905: Naval and Coastal Warfare in the Predreadnought era | 2024 |
| 439735 | Basket Case: Horror at Hotel Broslin | 2024 |
| 439736 | Zombie Raid | 2024 |
| 439801 | ARSCHMALLOWS XXL | 2024 |
| 439806 | Du kommst aus Köln, wenn | 2024 |
| 439819 | Atlanta Traffic: The Card Game | 2024 |
| 439874 | Elemana Chronicles: Shrine Wars | 2024 |
| 439939 | Jack and the Beanstalk | 2024 |
| 439946 | Black Diamond | 2024 |
| 439950 | Mille Bornes Rush | 2024 |
| 440006 | Book It! Battle Royal | 2024 |
| 440011 | Neopets Battledome Trading Card Game: Starry Acara Starter Deck | 2024 |
| 440020 | 7 Magias | 2024 |
| 440021 | Queremos Show | 2024 |
| 440034 | Insolite avventure | 2024 |
| 440066 | Keikalla | 2024 |
| 440074 | Cidade Dorme | 2024 |
| 440078 | Blast Radius Party Card Game | 2024 |
| 440079 | Blind Mouse Bluff | 2024 |
| 440083 | SADDLE | 2024 |
| 440084 | Cards Against Humanity: Cards of Humor and Whimsy expansion | 2024 |
| 440135 | Xmas Xpress | 2024 |
| 440137 | Quizduell Olymp: Das Brettspiel | 2024 |
| 440140 | Tinny Tactics | 2024 |
| 440156 | A Wolf In The Night | 2024 |
| 440160 | USS Lox | 2024 |
| 400724 | The Final Commander | 2023 |
| 410281 | Smart10: Astrid Lindgren | 2023 |
| 411217 | Abdec | 2023 |
| 430187 | LOGOS DIVINÆ: The Occult Classic | 2023 |
| 430272 | Salento | 2023 |
| 433032 | Knock It Off | 2023 |
| 433186 | Mystery Cube: Mystery_Rätsel – Geheimagenten: Agentenbüro | 2023 |
| 433187 | Mystery Cube: Mystery_Rätsel – Geheimagenten: Agentenzentrale | 2023 |
| 433188 | Mystery Cube: Mystery_Rätsel – Geheimagenten: Agentenlabor | 2023 |
| 433362 | Ciche dni | 2023 |
| 433456 | Con eso no se jode: Para Pobres | 2023 |
| 433630 | Craft my Agenda | 2023 |
| 433677 | Sengoku Folio 9: The Battle of Hasedo Castle | 2023 |
| 433741 | BelloLudi: Spellbound | 2023 |
| 433756 | The Inner Circle | 2023 |
| 433792 | Dead Belt | 2023 |
| 433809 | Channel Up | 2023 |
| 433914 | Paper Putt | 2023 |
| 434156 | UpMath Multiplication | 2023 |
| 434178 | Muskets and Springfields: Wargaming the American Civil War 1861-1865 | 2023 |
| 434179 | Bushidan: Miniatures rules for small unit warfare in Japan, 1543 to 1615 AD | 2023 |
| 434185 | Тайны и клады (Secrets and Treasures) | 2023 |
| 434279 | Le Ndem ! | 2023 |
| 434332 | Kallanpa & Kallaquinto | 2023 |
| 434399 | セブングレイヴ (Seven Grave) | 2023 |
| 434423 | Cards vs Gravity: Pro | 2023 |
| 434827 | Brutal Space | 2023 |
| 435035 | Uno: Seinfeld | 2023 |
| 435082 | Cayo Igloo Island | 2023 |
| 435089 | Bounce | 2023 |
| 435469 | Harmijan | 2023 |
| 435604 | IKINOKOORI | 2023 |
| 435619 | Management Strategy Board Game Camp President | 2023 |
| 435679 | I have The Numbers! | 2023 |
| 435714 | Junior Escape Game: Flucht aus dem Zoo | 2023 |
| 435773 | Bird Call | 2023 |
| 435813 | Mr. Popokpok: Disposable Diaper Waste Management | 2023 |
| 435840 | Genius Square XL | 2023 |
| 435858 | Smart10: Lëtzebuerg | 2023 |
| 435862 | Agents | 2023 |
| 435882 | Psychotest | 2023 |
| 435965 | Poop Attack! | 2023 |
| 435992 | Sgropin: Queo che no sofega ingrassa | 2023 |
| 436001 | EXIT Adventskalender: Die Polarstation in der Arktis | 2023 |
| 436004 | Cattle Barons of the Great Plains 1860 to 1884 | 2023 |
| 436005 | Pirates and Privateers of the Caribbean 1640 to 1679 | 2023 |
| 436011 | Blaster Archives: Mystic Skies | 2023 |
| 436042 | Line of Battle: Clear the Decks! Duel | 2023 |
| 436072 | Screwball Scramble Level Up | 2023 |
| 436074 | Magi Kidz | 2023 |
| 436095 | I Saw It First! Danger | 2023 |
| 436105 | Sblocca la porta Junior | 2023 |
| 436125 | Erste\*r sein! Gefährliche Tiere | 2023 |
| 436136 | Date Fate Eliminate | 2023 |
| 436208 | Tos přehnal! Česko | 2023 |
| 436298 | Försvunnen | 2023 |
| 436299 | Författarens egna öde | 2023 |
| 436300 | Seriemördaren på Highway 56 | 2023 |
| 436402 | イジンデン(Ijin-den) | 2023 |
| 436438 | Fun food bingo | 2023 |
| 436439 | Wasted Worms | 2023 |
| 436469 | How The Grinch Stole Christmas: Memory Master | 2023 |
| 436510 | Dzieci kontra Rodzice: Zimowe Zagadki | 2023 |
| 436588 | Cloud Race | 2023 |
| 436698 | Geobrasil | 2023 |
| 436699 | “Tanks” for the Apocalypse | 2023 |
| 436789 | Age of Moon | 2023 |
| 436868 | Alice’s Time Labyrinth | 2023 |
| 436944 | Rollpa: A Quest for Happiness | 2023 |
| 436969 | Nice Buns | 2023 |
| 437259 | Match-Up College Football | 2023 |
| 437345 | Call of Duty: K/D Party Game | 2023 |
| 437437 | Council of Bees | 2023 |
| 437444 | What? | 2023 |
| 437588 | Tajemství Býčí skály | 2023 |
| 437591 | Date Night | 2023 |
| 437594 | The Sparrow’s Knot | 2023 |
| 437686 | CATCH and RUN | 2023 |
| 437760 | Clue: My Hero Academia | 2023 |
| 437878 | Flagbearer Expandable Card Game | 2023 |
| 437923 | Up and Down: Ein Familienspiel | 2023 |
| 437937 | Brothers, Sisters, Thieves | 2023 |
| 437979 | 偏見プロフィール (Henken Profile) | 2023 |
| 438014 | Yunnan (Second Edition) | 2023 |
| 438027 | Rock Paper Scissors Word | 2023 |
| 438087 | Emberdire | 2023 |
| 438095 | Measure Me This! | 2023 |
| 438164 | Rummikub Polska | 2023 |
| 438324 | Quem do casal? | 2023 |
| 438415 | Yell Spell | 2023 |
| 438522 | Harry Potter: Quidditch Le Match | 2023 |
| 438615 | PUZL IT | 2023 |
| 438645 | Vår planet | 2023 |
| 438730 | Mount Cleverest: Original Edition | 2023 |
| 438779 | Bor 2013 | 2023 |
| 438830 | Marcher: Empires at War | 2023 |
| 438849 | Jakowiecki Las 1709 | 2023 |
| 439139 | Murder In Prague | 2023 |
| 439204 | Nähdään Linnalla! | 2023 |
| 439236 | Infinidungeon | 2023 |
| 439258 | Go Farm! | 2023 |
| 439261 | ʻĀina | 2023 |
| 439491 | Sport ist Mord | 2023 |
| 439665 | Travel Bug: Abroad | 2023 |
| 439767 | Peppa Pig: Funny Photo Game | 2023 |
| 439905 | Cluedo: Jim Henson’s Labyrinth | 2023 |
| 439910 | Eat/Paint | 2023 |
| 439938 | Ice Cream Meltdown | 2023 |
| 439948 | Оказія (Occasion) | 2023 |
| 439993 | КотоКульт (CatCult) | 2023 |
| 440108 | István a király? | 2023 |
| 440167 | Piritorin Ylitys | 2023 |
| 397738 | LOK | 2022 |
| 429803 | Scotland Mystery | 2022 |
| 433303 | Shit Happens: Familie Editie | 2022 |
| 433358 | Coextinction: World War | 2022 |
| 433371 | Skid Markz | 2022 |
| 433393 | Mimix | 2022 |
| 433478 | I Win Phonic Card Game | 2022 |
| 433736 | Mukbang …the Game | 2022 |
| 434028 | Поэзиум (Poetrium) | 2022 |
| 434157 | Space Invaders: Invincible Boardgame | 2022 |
| 434182 | ハムログ (Ham-Log) | 2022 |
| 435428 | Bird Tree | 2022 |
| 435499 | DIF-Spelet | 2022 |
| 435677 | Stadt Land Vollpfosten: Job Edition | 2022 |
| 435680 | Politikus | 2022 |
| 435689 | Mengenal Emosi | 2022 |
| 435814 | Lindungi Tubuhku | 2022 |
| 435855 | Laiva on lastattu | 2022 |
| 435878 | Clue: Bridgerton | 2022 |
| 435929 | Christmas Tree Game | 2022 |
| 435947 | Qui a triché ? | 2022 |
| 436003 | Great Northeastern Railroads of the United States and Canada 1840 to 1889 | 2022 |
| 436186 | UNO Junior Move! | 2022 |
| 436189 | A game about quickly grabbing creatures that are totally different & counting your BEETROOTS | 2022 |
| 436301 | Hotellmordet | 2022 |
| 436302 | Mannen på åkern | 2022 |
| 436343 | Incohearent: On the Go! | 2022 |
| 436360 | Minus vs Plus | 2022 |
| 436405 | Mágikus erdő | 2022 |
| 436509 | Unicorn Fun | 2022 |
| 436628 | The Couples Game That’s Actually Fun | 2022 |
| 436831 | Onder de tien 10 | 2022 |
| 436833 | Launch Party | 2022 |
| 436867 | Crack The Code | 2022 |
| 436870 | Millionaire Liberty Produce! | 2022 |
| 436999 | The Burning of Kingston Card Game | 2022 |
| 437438 | Spellpath | 2022 |
| 437908 | Zilch | 2022 |
| 438013 | Obama Llama | 2022 |
| 438038 | Racket: Sugar Rush | 2022 |
| 438097 | Der Räuber Hotzenplotz: Das Kartenspiel | 2022 |
| 438107 | Beweg dich! | 2022 |
| 438459 | Hamburg: Wem gehört die Stadt? | 2022 |
| 438461 | All Time Wrestling: All or Nothing | 2022 |
| 438477 | Справа Ноя (Noah’s quest) | 2022 |
| 438508 | Deliver Eats | 2022 |
| 438524 | Harry Potter: Potions magiques | 2022 |
| 438528 | Don’t Wreck the Deck | 2022 |
| 438583 | Nostromo: The Last Survivor | 2022 |
| 438620 | Landscape X: Das Erbe des Stahlbarons | 2022 |
| 438672 | Nomenclutter | 2022 |
| 438716 | Commonagrams | 2022 |
| 438734 | Spellebration | 2022 |
| 438770 | Critter Cards: Gnomes vs Merfolk | 2022 |
| 438869 | From 1 to Z | 2022 |
| 438963 | Mare Istra | 2022 |
| 439084 | Castle Panic: Big Box (Second Edition) | 2022 |
| 439148 | Color Field: Master Painter’s Edition | 2022 |
| 439203 | Nähdään Vesijärven satamassa! | 2022 |
| 439464 | Landscape X: Der Tanz des Geheimbundes | 2022 |
| 439710 | Le Mistigrouille de Cornebidouille | 2022 |
| 439926 | Astro Asterid’s Quick Shuttle Repair | 2022 |
| 439975 | Timeout Blue Edition | 2022 |
| 440062 | Mostkala | 2022 |
| 440165 | A Patrióta | 2022 |
| 254548 | Air Flix: El Alamein | 2021 |
| 358680 | Diabolik: La lama della vendetta | 2021 |
| 429847 | Il Gioco è Tratto | 2021 |
| 433350 | Masterchef Family Cooking Game | 2021 |
| 433444 | Aprendices de Druida | 2021 |
| 433453 | Con eso no se jode 3 | 2021 |
| 433455 | Con eso no se jode: Edición Morboluxe | 2021 |
| 433558 | Last Call at the Crowbar | 2021 |
| 433688 | Morbopoly | 2021 |
| 433737 | PoCon! | 2021 |
| 433795 | Clue Junior Marvel Avengers | 2021 |
| 434029 | Grouille série 2 | 2021 |
| 435385 | Heikai | 2021 |
| 435501 | Arkitektur i hela världen | 2021 |
| 435824 | Uniekies | 2021 |
| 435851 | White Elephant Game | 2021 |
| 435883 | Cat Tower Defense | 2021 |
| 435897 | Encrypted | 2021 |
| 435932 | What Do You Meme?: UK Edition | 2021 |
| 435962 | Boss Babe The Game | 2021 |
| 435966 | Clue: Brooklyn Nine-Nine | 2021 |
| 436096 | Mida võtta, mida jätta? | 2021 |
| 436118 | Риболови (Fishermen) | 2021 |
| 436163 | Schiscèta | 2021 |
| 436291 | Krimispiel 2: Tödliche Weihnachten | 2021 |
| 436388 | Tancas | 2021 |
| 436927 | Naval Battle in the European Seas | 2021 |
| 436982 | Totika Kohatu | 2021 |
| 437257 | Word It Out | 2021 |
| 437311 | Sound Check | 2021 |
| 437315 | Sevens: A Dice Game | 2021 |
| 437357 | Colourbrain Free Mini Game | 2021 |
| 437432 | no TABOO! | 2021 |
| 437534 | Paw Patrol: Path Game | 2021 |
| 437566 | Slimy Rhymes | 2021 |
| 437598 | Poleana | 2021 |
| 437606 | Buzzy Bear | 2021 |
| 437655 | The Ultimate TV Trivia Game: Bingeworthy | 2021 |
| 437656 | Blast from the Past Trivia Game: 2000s | 2021 |
| 437657 | Bucket Full of Kindness | 2021 |
| 437659 | Red Herring | 2021 |
| 437661 | Hoodwinked | 2021 |
| 437664 | The Metaphor Game | 2021 |
| 437732 | エリスの算盤 (Eris’s Abacus) | 2021 |
| 437762 | Naval Battle in European Waters | 2021 |
| 438222 | Escape Quest: Superbohaterowie | 2021 |
| 438662 | Memo-Schach 3170 | 2021 |
| 438941 | Date ’Em or Hate ’Em | 2021 |
| 439101 | Gott Gisk | 2021 |
| 439121 | Disney Princess Treats & Sweets Party Game | 2021 |
| 439192 | DiagnosTHIS | 2021 |
| 439202 | Nähdään Vanhalla raatihuoneella! | 2021 |
| 439214 | Trivial Pursuit: Sciences & Vie | 2021 |
| 439504 | Världens hjältar | 2021 |
| 439751 | Scene it: Heard it | 2021 |
| 440051 | See Shout Spell | 2021 |
| 440089 | Digit and Dot | 2021 |
| 440090 | Hector’s Nectar | 2021 |
| 440091 | Helda’s Spells | 2021 |
| 440109 | A Misszió | 2021 |
| 318724 | Соображарий: Супер (Think It Up!: Super) | 2020 |
| 426493 | Myth Quest: Hero’s Beginning | 2020 |
| 433256 | Lucky 7 Mining Company | 2020 |
| 433415 | Die Schule der magischen Tiere: Auf die Plätze! | 2020 |
| 433704 | We Didn’t Build Decks at All | 2020 |
| 433810 | Städquiz | 2020 |
| 433918 | Сборная солянка (Hotchpotch) | 2020 |
| 434078 | Tic Tac Toe 3D | 2020 |
| 434401 | UNDO: Rien n’est eternel | 2020 |
| 434820 | Paper Pinball: Season 2 – Space Marines vs. Dragons | 2020 |
| 434821 | Paper Pinball: Season 2 – Cretaceous Skate Park | 2020 |
| 434822 | Paper Pinball: Season 2 – Mall Bats | 2020 |
| 434824 | Paper Pinball: Season 2 – Boss Battle | 2020 |
| 434825 | Paper Pinball: Season 2 – Ski ’93 | 2020 |
| 435688 | Linimasa Card Game: 25 Nabi & Rasul | 2020 |
| 435843 | Paper Pinball: Season 2 – Miasma | 2020 |
| 435844 | Paper Pinball: Season 2 – Little Ghost | 2020 |
| 435845 | Paper Pinball: Season 2 – Combat Clash | 2020 |
| 435846 | Paper Pinball: Season 2 – Esape the Vent | 2020 |
| 436131 | Totally 90’s Board Game | 2020 |
| 436187 | Cincogó Egérfogó | 2020 |
| 436225 | Strašák | 2020 |
| 436229 | Trivial Pursuit: Party! – Bite Size | 2020 |
| 436307 | Swear Snap: A Card Game for Unashamed Adults | 2020 |
| 436333 | Wissen & Quizzen: Wunder der Natur | 2020 |
| 436422 | Four | 2020 |
| 436456 | Zadventure | 2020 |
| 436508 | Dzieci kontra rodzice: Czego o sobie nie wiecie? | 2020 |
| 436978 | ReactSee Card Game | 2020 |
| 437141 | The State of Play | 2020 |
| 437251 | Rook & Raiders ルーク＆レイダーズ | 2020 |
| 438142 | Einhorn Lama Ananas FUCK | 2020 |
| 438471 | Wars of Ozz | 2020 |
| 439012 | Nähdään Kompassilla! | 2020 |
| 439271 | For Reign or Ruin: Fantasy Mass Combat Rules | 2020 |
| 439371 | Duck Duck Dance | 2020 |
| 439458 | Ordexpressen | 2020 |
| 439533 | Jewel Hunt | 2020 |
| 439653 | National Park Adventure Game | 2020 |
| 439814 | The Great Simac Game | 2020 |
| 439823 | Summon & Magic | 2020 |
| 440088 | Dungeon Blitz: Den of Goblins | 2020 |
| 440094 | Mimes intenses et tordus | 2020 |
| 433351 | Boneless Chicken Launch Action Game | 2019 |
| 433391 | Hoppla Hoppel | 2019 |
| 433405 | Answer the Internet Card Game | 2019 |
| 433452 | Con eso no se jode 2 | 2019 |
| 433694 | Dreadnought: Mini | 2019 |
| 433890 | Король Лев (The Lion King) | 2019 |
| 434355 | Der Räuber Hotzenplotz: So ein Theater | 2019 |
| 434570 | CONSENT | 2019 |
| 435052 | Escape Box: Rick et Morty – Panique dans le Minivers | 2019 |
| 435622 | Linimasa Card Game: STEAM | 2019 |
| 435663 | Vegan Not Vegan | 2019 |
| 436160 | Blackbeard | 2019 |
| 436378 | Аладдин (Aladdin) | 2019 |
| 436413 | Monster Mambo | 2019 |
| 436959 | Die Eiskönigin: Völlig unverfroren – Das verdrehte Wettlaufspiel | 2019 |
| 437009 | Stacktopus | 2019 |
| 437564 | Traq mo | 2019 |
| 437565 | Holiday Bingo | 2019 |
| 437592 | 新版中文拼字遊戲-上下組合 (Chinese Character Puzzle Game: Top-Bottom Combinations) | 2019 |
| 437599 | 新版中文拼字遊戲-左右組合 (Chinese Character Puzzle Game: Left-Right Combination) | 2019 |
| 437600 | 新版中文拼詞遊戲 (New Chinese Spelling Game) | 2019 |
| 437626 | Gæt en Ramasjang | 2019 |
| 438230 | Österreich Quiz 4 Kids | 2019 |
| 438535 | Незабываемые (Unforgettable) | 2019 |
| 439057 | Catventures | 2019 |
| 439956 | Bobail | 2019 |
| 430801 | Still Just Kidding: Card Game | 2018 |
| 432648 | Operation Crusader Battle for Tobruk | 2018 |
| 434508 | Melyik történetből jöttem? | 2018 |
| 435492 | Linimasa Card Game: Sejarah Kemerdekaan Indonesia | 2018 |
| 435623 | Batman: Le Sauveur de Gotham City | 2018 |
| 435699 | Slalom | 2018 |
| 435750 | Drink! Fifty Beer Games | 2018 |
| 435751 | Drinkin’ with Lincoln | 2018 |
| 435808 | Nuna Universe | 2018 |
| 435971 | Clue: Bob’s Burgers | 2018 |
| 436940 | Детектор правды (Truth Detector) | 2018 |
| 436964 | Imperius: Kickstarter Edition | 2018 |
| 437007 | Double Dribble | 2018 |
| 437573 | Magic Spelling | 2018 |
| 438211 | Token Collection | 2018 |
| 438552 | Sniper: Stalingrad 1942 | 2018 |
| 438678 | KALAS | 2018 |
| 439142 | Ancient Grudges: Bonefields | 2018 |
| 439505 | Sports Geek! Baseball Trivia | 2018 |
| 439523 | The VOC Treasure | 2018 |
| 433439 | Fais-moi confiance | 2017 |
| 433451 | Con eso no se jode | 2017 |
| 433816 | Operation: Fallout S.P.E.C.I.A.L. Edition | 2017 |
| 434066 | Bird Dog | 2017 |
| 434074 | Race to Base | 2017 |
| 434292 | BLDR Card game | 2017 |
| 435057 | Stock Trading Guru | 2017 |
| 435923 | Stuff Happens | 2017 |
| 436924 | Carrier Battle! South Pacific 1942 | 2017 |
| 436926 | Solomon Night Naval Battle | 2017 |
| 437135 | Pizza Panic | 2017 |
| 437569 | Monster Bingo | 2017 |
| 437571 | Post Box Game | 2017 |
| 437572 | Farm Compendium | 2017 |
| 438094 | Der Maulwurf und die Kullerblumen | 2017 |
| 438628 | Armoured Strike: Wargame Rules for Combined Arms Warfare 1950-2000 | 2017 |
| 438642 | Ucieczka z lochu | 2017 |
| 438986 | Grüll | 2017 |
| 439075 | Attack on Werewolf | 2017 |
| 439316 | Monopoly: Uncharted | 2017 |
| 439411 | Accelerate and Attack!: Aeons of War | 2017 |
| 439494 | ABC-Zauberei | 2017 |
| 439647 | Warmaster Revolution | 2017 |
| 440028 | Дуэль Двух Миров (Duel of Two Worlds) | 2017 |
| 433394 | S.O.S. Minion-Alarm | 2016 |
| 435863 | Playpension | 2016 |
| 436216 | La Bella Gigogin | 2016 |
| 436359 | Top 2000 Pop Quiz | 2016 |
| 436937 | Stocklab | 2016 |
| 437570 | Alphabet Lotto | 2016 |
| 438073 | Gasolina de Sangue Board Game | 2016 |
| 439073 | 1836 Hessen and Nassau | 2016 |
| 432801 | Zubatá | 2015 |
| 434150 | シャルロッテの秘密 (Charlotte’s Secret) | 2015 |
| 438647 | Dinomino | 2015 |
| 438951 | Shields: The Dice Game | 2015 |
| 438998 | Commonspoly | 2015 |
| 434410 | Timeline Pocket | 2014 |
| 436475 | Aladdin’s Heads and Tails Game | 2014 |
| 438317 | Quem disse isso? | 2014 |
| 439846 | Who? What? Where? | 2014 |
| 439963 | Heroes Placement | 2014 |
| 433412 | Das Länder-Quiz | 2013 |
| 435086 | Hail, Agrippa! | 2013 |
| 435948 | Toby Malito | 2013 |
| 436191 | HCG Professional Bowling | 2013 |
| 436963 | Filly Witchy: Zauber der 13. Stunde | 2013 |
| 433815 | Dick Garrison: Rapid Launch | 2012 |
| 436419 | FLICK\[BALL\] 7 | 2012 |
| 438030 | Word Wizard | 2012 |
| 439000 | Pszczyna 1939 | 2012 |
| 439086 | Bohnanza+ | 2012 |
| 439088 | Bohniläum | 2012 |
| 439181 | Roulette-18 Dice | 2012 |
| 439376 | Pikes Peak Racers | 2012 |
| 434413 | Raclette Party | 2011 |
| 435450 | Stand and Deliver! | 2011 |
| 438082 | Death Front: Bloody Europe | 2011 |
| 438085 | The Legend of Novoland | 2011 |
| 438086 | History of the Party | 2011 |
| 439952 | Contes à la carte | 2011 |
| 435973 | Clue: Family Guy Collector’s Edition | 2010 |
| 438084 | War of Novoland | 2010 |
| 435975 | Clue: Seinfeld Collector’s Edition | 2009 |
| 438043 | Spell Wizard | 2009 |
| 438154 | Pocket Battles: Mobile Suit Gundam Land War | 2009 |
| 438156 | Pocket Battles: Mobile Suit Zeta Gundam | 2009 |
| 438158 | Pocket Battles: Armored Trooper Votoms | 2009 |
| 438159 | Pocket Battles: Legend of the Galactic Heroes | 2009 |
| 403177 | Scatter | 2008 |
| 437049 | Project Revolution | 2007 |
| 437924 | Das Oldtimerspiel | 2007 |
| 438380 | Star: Il Gioco del Cinema | 2007 |
| 439266 | Lost in the City: The Game | 2007 |
| 439379 | Six-Tac-Toe | 2007 |
| 439325 | Knight Fight | 2006 |
| 439327 | Layout | 2006 |
| 439329 | Beyond Sudoku | 2006 |
| 439330 | The Emperor’s Suit | 2006 |
| 439014 | Sudoku Challenge | 2005 |
| 436928 | The Decisive Battle! “A Baoa Qu” | 2004 |
| 438570 | Ships and Tactics | 2004 |
| 439064 | Crow & Trash | 2004 |
| 439772 | One Piece: El Juego | 2003 |
| 437208 | Tapa Monstros | 2002 |
| 438062 | Giant Word Game | 2002 |
| 438468 | McNugget Buddies Bingo | 2002 |
| 436346 | Dungeoneer: Customizable Fantasy Board Game | 2001 |
| 437140 | 5 senses lotto | 2000 |
| 436209 | Goede Tijden Slechte Tijden Party Quiz | 1998 |
| 438288 | Go, Miffy Go! | 1998 |
| 89950 | Trivial Pursuit: 1997 Edition | 1996 |
| 393882 | Chess on a really big board | 1996 |
| 433522 | Mit Mose durch die Wüste | 1996 |
| 439766 | ROTTA! | 1996 |
| 436415 | Hell in Microcosm | 1995 |
| 436877 | 18/12: Reindeer Rivals | 1995 |
| 437560 | Das große Piratenspiel mit der Maus | 1995 |
| 436626 | Капитал (Capital) | 1994 |
| 439008 | Het grote Koekie Monster vloerspel | 1993 |
| 429809 | Kaiki no Yakata (怪奇の館) | 1992 |
| 437316 | Legend of the Galactic Heroes: Attack of the Empire | 1992 |
| 439954 | Super Chinese Checkers | 1991 |
| 436849 | Go Green! | 1990 |
| 439138 | Wad-Speur-Spel | 1990 |
| 429812 | Ring Master: Godlanta no Hasha (リング・マスター： ～ゴドランタの覇者～) | 1989 |
| 434115 | AD&D Dragonlance Official Card Game | 1989 |
| 439186 | Chantstation | 1988 |
| 433862 | Hometown Monopoly: Detroit | 1987 |
| 438739 | Championship Drag Racing | 1987 |
| 439087 | Redcoats & Rangers | 1987 |
| 433513 | Atlantic Trivia | 1985 |
| 438101 | Siceron | 1985 |
| 437137 | Canadian Style Football | 1984 |
| 438009 | Reutlingen Kreuz und Quer Heimatspiel | 1984 |
| 433818 | Groot Internationaal Saunaspel | 1982 |
| 438068 | Cilada | 1981 |
| 437631 | Cosmomanager | 1980 |
| 438063 | Futebol Club | 1979 |
| 433665 | Peace Conference | 1977 |
| 433668 | Search | 1977 |
| 433671 | Round ‘N’ Round | 1977 |
| 435969 | Slide and Tackle | 1977 |
| 439587 | Ghetto! Rated G | 1976 |
| 435706 | Castle Rock | 1975 |
| 438162 | Alphabet the new card game | 1973 |
| 440037 | Rumpelstilz und seine Freunde spielen Verstecken | 1972 |
| 437533 | Family Pastimes Cards | 1971 |
| 438072 | The Game of Space A Family Game | 1969 |
| 438075 | Cosmos | 1962 |
| 436119 | Vita nel mondo | 1960 |
| 438118 | Cosmil | 1959 |
| 436770 | Satellite | 1958 |
| 439514 | Tell Time Quizmo | 1957 |
| 436620 | Knorr-Ski Spiel | 1950 |
| 439058 | Super Bobs | 1944 |
| 436184 | Victory Rummy | 1942 |
| 437023 | Im grünen Walde | 1941 |
| 437018 | Farmerleben in Afrika | 1940 |
| 437020 | Fliege, wenn ich dich kriege! | 1939 |
| 436357 | Soccatome | 1938 |
| 438304 | My Word | 1938 |
| 438102 | Jugglegrams | 1934 |
| 434095 | Kampf | 1933 |
| 438049 | Duit | 1933 |
| 437014 | Die Jagd nach dem Millionendieb | 1921 |
| 419355 | Illustrated Hungarian Tarokk | 1920 |
| 438130 | Fangt ihn! | 1912 |
| 436468 | Trix Card Game | 1904 |
| 438229 | Debits and Credits | 1904 |
| 436625 | Eisenbahn-Spiel | 1897 |
| 438449 | Progressive Logomachy | 1890 |
| 433352 | Mother Hubbard | 1875 |
| 426485 | Sungka | 1617 |
| 378173 | Grande Acedrex | 1283 |
| 438780 | Liw 1831 | 203 |
| 172282 | Admin Test Item 2 | NA |
| 414446 | Zanzi | NA |
| 430120 | Super Bowling | NA |
| 430121 | Chopstick Barrel Battle | NA |
| 430262 | Tavern Ball | NA |
| 430342 | Rainbow Unicorn Rescue | NA |
| 430887 | Pialógus | NA |
| 431395 | Run and Fun | NA |
| 431452 | Three Days of Gettysburg: Deluxe Edition | NA |
| 433215 | Little Shopper | NA |
| 433315 | Vigormon | NA |
| 433397 | Wir kämpfen gegen Engeland | NA |
| 433428 | Amalgam | NA |
| 433429 | Wir bauen eine neue Stadt | NA |
| 433431 | FRIENDS: Trivia Quiz 2nd Edition | NA |
| 433434 | Sleuth! | NA |
| 433532 | Elements: The Great Tournament | NA |
| 433636 | Rescue | NA |
| 433637 | Life’s A Pitch | NA |
| 433674 | Divorced Dads | NA |
| 433692 | MS. “Europa”-Kreuzfahrt | NA |
| 433752 | Augen auf! | NA |
| 433847 | Kinder Postspiel | NA |
| 433858 | Le Tour | NA |
| 433924 | Trifle | NA |
| 433930 | Koinobia | NA |
| 434073 | Nuclear Family | NA |
| 434280 | Der Frosch- und Mäusekrieg | NA |
| 434281 | Stella Monolith | NA |
| 434437 | Hamleys Monopoly | NA |
| 434438 | Marmite: The Game – Love It or Hate It | NA |
| 434485 | 大氷瀑 (D-ice Fall) | NA |
| 434834 | Did I Win? | NA |
| 435022 | Pin Ball See Saw | NA |
| 435056 | Fast Track: The Speed Reaction Card Game | NA |
| 435065 | L’archer médiéval | NA |
| 435288 | Cnuno | NA |
| 435362 | La Guerra per la Sicilia 264-241 A.C. | NA |
| 435363 | Operazione Fall Blau 1942 | NA |
| 435430 | Magliana 1943: L’attacco della Legione Allievi Carabinieri al caposaldo n.5 | NA |
| 435431 | Afghanistan 1979-1989 | NA |
| 435433 | La battaglia di Poitiers: Ottobre 732 | NA |
| 435490 | Cesare nelle Gallie 57-52 A.C. | NA |
| 435491 | La Battaglia di Eluet el Asel 1941 | NA |
| 435493 | Ermine: Battles in the War of the Breton Succession, 1342-1364 | NA |
| 435522 | YOUR MOVE! | NA |
| 435618 | Eigo Dake | NA |
| 435685 | Homeostasis | NA |
| 435702 | Kurs Nord-West | NA |
| 435708 | Vom Werden Des Brotes | NA |
| 435788 | The Social Media Game | NA |
| 435809 | Inflection Point: The Battle for Kalach and the Battle of Chir | NA |
| 435811 | No Turning Back: The Battle of the Wilderness 5-6 May 1864 | NA |
| 435829 | Harry Potter Quintett | NA |
| 435854 | Identikit | NA |
| 435870 | Route 66 Mystery | NA |
| 435898 | Racing Game | NA |
| 435909 | Loteria the Card Game | NA |
| 435916 | Musket & Pike: Dual Pack 2 | NA |
| 435924 | Spindoodle | NA |
| 435957 | Infer | NA |
| 435960 | Sailing Dreams | NA |
| 435968 | Jeu de Pompier | NA |
| 436052 | JINX | NA |
| 436069 | Pali Się | NA |
| 436114 | Guess the Sum (or Plus or Minus) | NA |
| 436122 | Signal and Noise | NA |
| 436162 | Crystales Storia | NA |
| 436172 | The Game of Power | NA |
| 436210 | Únikovka: Rychlé šípy – Tleskač | NA |
| 436213 | Csaták ösvénye | NA |
| 436238 | Blockbuster: New Movie Hero Round | NA |
| 436289 | Novel: The Board Game | NA |
| 436294 | Magiskolan: Jakten på elixiret | NA |
| 436322 | Keliaujame po Lietuvą | NA |
| 436340 | Shaffle | NA |
| 436374 | Rat King | NA |
| 436386 | Summoner’s Rift | NA |
| 436440 | Asinel | NA |
| 436443 | Soul Pickers | NA |
| 436473 | The Fate of the 9 Worlds | NA |
| 436485 | Steam Cities | NA |
| 436506 | Equestrian | NA |
| 436517 | Fußballspiel Schwarz-Weiß: Rot-Weiß | NA |
| 436653 | Run Around Hamster | NA |
| 436654 | Tidy the Library | NA |
| 436766 | Face Cube | NA |
| 436767 | Word Teasers: Road Trip America | NA |
| 436779 | Lumecon | NA |
| 436782 | The Secret Alien Message | NA |
| 436792 | The 1% Club: The Board Game | NA |
| 436818 | Complementary Game | NA |
| 436881 | Re;MATCH: Marble Puzzle Fighter | NA |
| 436930 | Colorful Checkers | NA |
| 436943 | Daqin | NA |
| 436955 | Happy Horses | NA |
| 436957 | Happy Tails | NA |
| 436958 | Find me! | NA |
| 436961 | Tsar | NA |
| 436974 | Movies + Entertainment Trivia Game | NA |
| 436979 | Gundam Assemble | NA |
| 436984 | Claws Out | NA |
| 436986 | Joinery | NA |
| 437001 | Kelele | NA |
| 437006 | Taxi | NA |
| 437021 | Carver’s Park | NA |
| 437033 | História | NA |
| 437039 | Collecto | NA |
| 437103 | Crab Clash | NA |
| 437107 | Kreuz und quer zu jeder Stadt, die ein C&A-Haus hat | NA |
| 437165 | Masquerade | NA |
| 437246 | Catvale | NA |
| 437314 | Swords and Stones | NA |
| 437319 | Mediaeval Circular Chess | NA |
| 437344 | AWARWAR | NA |
| 437422 | Golden Pig | NA |
| 437540 | Get The Picture | NA |
| 437567 | Hoppels Abenteuer | NA |
| 437585 | House of Wisdom | NA |
| 437587 | Crete: Death From The Sky | NA |
| 437593 | Party Alias: Wielki Zakład | NA |
| 437644 | Mormon Memes | NA |
| 437764 | Time of Crisis: The Roman Empire in Turmoil, 235-284 AD – Deluxe Edition | NA |
| 437881 | Advantage | NA |
| 437942 | Dreamwood | NA |
| 437981 | Host Your Own Escape Room: Jungle Edition | NA |
| 438008 | The Curse of Saltash Mine | NA |
| 438091 | Eltern Lernspiel: Verkehrsspiel | NA |
| 438092 | Funny Duck | NA |
| 438106 | Ludimino | NA |
| 438113 | Farm Inc Junior | NA |
| 438145 | Wild Side: Number Sense Cards | NA |
| 438146 | Les Maldives | NA |
| 438151 | Abenteuer Tour | NA |
| 438166 | Microbes or Yours? | NA |
| 438167 | Street Library | NA |
| 438175 | Mejor Pais del Mundo | NA |
| 438183 | Trings | NA |
| 438268 | 7 blox up | NA |
| 438269 | Brew Buddies | NA |
| 438274 | Fosteringo | NA |
| 438281 | Disney: Guess the film | NA |
| 438282 | Sneaky Goose | NA |
| 438283 | Cursed Tides | NA |
| 438285 | A Little Slice of History | NA |
| 438290 | Jurassic Park: Path Game | NA |
| 438303 | The Big Buzz Off | NA |
| 438305 | OMG! Trivia Game | NA |
| 438315 | Chomping Shark | NA |
| 438316 | If You Dare | NA |
| 438322 | Baby Shark’s Big Show: Wooden Balancing Game | NA |
| 438323 | Peppa Pig Grandpa Pig Balancing Boat | NA |
| 438329 | Thunderbolt: Deluxe Edition | NA |
| 438331 | Mental Maths Games | NA |
| 438458 | Der kleine Braumeister | NA |
| 438644 | てか、ただのゆるい日常じゃないですか! (Isn’t this just a relaxed daily life?) | NA |
| 438861 | Weather Warz | NA |
| 438878 | Histopol: Od Piasta do Piłsudskiego | NA |
| 438893 | Wise Fries | NA |
| 438943 | Tangoes Expert | NA |
| 439035 | Catchables: DJ Cat & Cat-tle | NA |
| 439068 | 自由惑星同盟軍の夜 (Night of the Free Planets Alliance Force) | NA |
| 439097 | Admit One | NA |
| 439251 | Заповедник (Reserve) | NA |
| 439298 | Fight For Inheritance | NA |
| 439326 | Angria | NA |
| 439333 | Joklons | NA |
| 439362 | The Horse and The Squirrel Flippables Game | NA |
| 439439 | Primordial | NA |
| 439441 | Train a Guide Dog game | NA |
| 439507 | Horror Trivia | NA |
| 439570 | The Stones of Nuria | NA |
| 439713 | Trivia Traitor | NA |
| 439732 | Macross: Valkyrie Spirits | NA |
| 439734 | Yang and Reinhard: The Legend of the Undefeated | NA |
| 439744 | Petals & Perils | NA |
| 439800 | Nun schlägt’s aber 13 | NA |
| 439824 | 4 to Score Tower Shot | NA |
| 439932 | Puppet Charades Sticks | NA |
| 439994 | BONESWAY: Luminis Refuge | NA |
| 440026 | Domara: The Fight for Power | NA |
| 440063 | SNAP 2 IT | NA |
