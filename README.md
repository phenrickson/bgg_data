
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
| 429125 | Travail | 2026 |
| 429239 | Rupert’s Land | 2026 |
| 429301 | Insania | 2026 |
| 429373 | Cola Wars | 2026 |
| 429394 | Shiver | 2026 |
| 429578 | West Front ’44 | 2026 |
| 429579 | Maikop to Baku | 2026 |
| 424785 | Crafting the Cosmos | 2025 |
| 427263 | Line of Fire: Burnt Moon | 2025 |
| 428638 | Vegas Strip | 2025 |
| 428889 | Lore: Second Edition | 2025 |
| 429020 | Paper World | 2025 |
| 429124 | Last Aurora: Firelands | 2025 |
| 429129 | The Souls | 2025 |
| 429149 | Showboating | 2025 |
| 429150 | Panopticon | 2025 |
| 429167 | Sunshine Cities | 2025 |
| 429169 | Redsky | 2025 |
| 429203 | Nutty Space Adventure | 2025 |
| 429218 | World War 3: 1989, East Asia Front | 2025 |
| 429231 | Heroes of Serendall | 2025 |
| 429234 | Rejig | 2025 |
| 429266 | Dicker & Dice | 2025 |
| 429275 | Göbeklitepe: Dawn of Human | 2025 |
| 429293 | The Fellowship of the Ring: Trick-Taking Game | 2025 |
| 429329 | Melding Snow | 2025 |
| 429333 | Treat, Please! | 2025 |
| 429369 | Yuyutsu | 2025 |
| 429378 | Malediction | 2025 |
| 429380 | Solomons Campaign 1942-43 | 2025 |
| 429381 | Invasion Australia | 2025 |
| 429401 | Manhattan Project: Energy Empire | 2025 |
| 429405 | Orloj: The Prague Astronomical Clock | 2025 |
| 429413 | Operation Ironclad: Battle for Madagascar, 1942 | 2025 |
| 429423 | Postcards | 2025 |
| 429431 | Miskatonic Tales: Journey to Innsmouth | 2025 |
| 429438 | Ayar: Children of the Sun | 2025 |
| 429446 | Moirai | 2025 |
| 429477 | King of the Forest | 2025 |
| 429483 | Cannibal World | 2025 |
| 429539 | Joymundo: Travel the World Game | 2025 |
| 429580 | Skirmish: Battle for Glavia | 2025 |
| 429587 | Dragon Cantina | 2025 |
| 429644 | Atakaba | 2025 |
| 429650 | The Treasure Ship of Zheng He | 2025 |
| 429657 | Chess Rivals | 2025 |
| 429669 | Limpopo | 2025 |
| 429717 | Railroad Tiles: Collector’s Edition | 2025 |
| 429770 | Into The Dark Dungeon: Silver Mine | 2025 |
| 429797 | The Bad Karmas and the Curse of Cthulhu | 2025 |
| 429810 | Rex Atlantis | 2025 |
| 429827 | Bôken | 2025 |
| 429836 | Hubworld: Aidalon | 2025 |
| 429840 | Twisted Cryptids | 2025 |
| 429842 | Twisted Cryptids: Exclusive Edition | 2025 |
| 429845 | Jisogi: Anime Studio Tycoon | 2025 |
| 429849 | Red Carpet | 2025 |
| 429851 | Quorum | 2025 |
| 429853 | Deep Dreams | 2025 |
| 429854 | That House by the Lake | 2025 |
| 429860 | Transgalactica | 2025 |
| 429861 | Ace of Spades | 2025 |
| 429863 | Covenant | 2025 |
| 429864 | The Guest | 2025 |
| 429865 | Ring Ring | 2025 |
| 429866 | Dungeon Duel: Monsters and Heroes | 2025 |
| 429889 | Magnus Protocol Mysteries: The Last Supper | 2025 |
| 429890 | Magnus Protocol Mysteries: Six Feet Under | 2025 |
| 429891 | Magnus Protocol Mysteries: The Grinning Corpse | 2025 |
| 429892 | Magnus Protocol Mysteries: The Doppelganger | 2025 |
| 429893 | Magnus Protocol Mysteries: The Woman on Fire | 2025 |
| 429894 | Magnus Protocol Mysteries: Blackout | 2025 |
| 429911 | Circle the Wagons: Essential Collection | 2025 |
| 429939 | Interregnum | 2025 |
| 429940 | Avec Infini Regret IV | 2025 |
| 429956 | Advanced Fighting Fantasy: Dark Dungeons – The Boardgame | 2025 |
| 429962 | Pax Porfiriana: Ultimate Edition | 2025 |
| 429970 | Frankezen | 2025 |
| 430010 | Power Creep | 2025 |
| 430017 | The Waste of Parts | 2025 |
| 430023 | Catopomp | 2025 |
| 430041 | Reinos Oníricos de Lovecraft | 2025 |
| 430062 | Blood & Treasure | 2025 |
| 430067 | Mystic Manor | 2025 |
| 430068 | The Lions of El Alamein | 2025 |
| 430082 | Elemental Clash | 2025 |
| 430170 | An Honorable Peace? | 2025 |
| 430243 | Vineyard: A Winemaking Game | 2025 |
| 430247 | Stability Island | 2025 |
| 430293 | I C E: Unlimited Box | 2025 |
| 430319 | Kilauea | 2025 |
| 430349 | Usolli: The Strategic Board Game About Salah | 2025 |
| 427618 | Tiny Epic Game of Thrones: Deluxe Edition | 2024 |
| 427651 | Spice Ships | 2024 |
| 428813 | Bright Yacht Cup Upwind Downwind | 2024 |
| 428870 | Alpaca Fiesta | 2024 |
| 429019 | Froots | 2024 |
| 429097 | Tyrannical | 2024 |
| 429132 | What The Fog?! | 2024 |
| 429148 | Denizens: The Hero-War | 2024 |
| 429153 | totoANIMO | 2024 |
| 429155 | Chiron | 2024 |
| 429157 | Element of Fun | 2024 |
| 429166 | Keyforge Event Pack: Martian Civil War | 2024 |
| 429176 | Never Mind the Billhooks: Here’s the Ruckus | 2024 |
| 429178 | Mixtopian Saga RPS | 2024 |
| 429186 | Герои (Heroes) | 2024 |
| 429230 | Astrorum | 2024 |
| 429241 | Palmodyssey | 2024 |
| 429243 | Nomads: A Game of Survival | 2024 |
| 429245 | Expellere | 2024 |
| 429250 | Metropolis | 2024 |
| 429254 | Smart10: L’impertinent | 2024 |
| 429262 | Warhammer 40,000: Kill Team – Hivestorm | 2024 |
| 429264 | Dingo Duel | 2024 |
| 429272 | Guess in 10: American History | 2024 |
| 429305 | モントゴメリーの憂鬱：孤高のアルンヘム1944 (Solitaire Monty 1944) | 2024 |
| 429306 | 孤高の曹操：建安元年 (Solitaire Cao Cao) | 2024 |
| 429307 | クロニクル・オブ・ジャパン ～邪馬台国から明治維新まで～ (Chronicle of Japan) | 2024 |
| 429332 | Pup Idols | 2024 |
| 429340 | Storm Clouds | 2024 |
| 429341 | Touch the Moon | 2024 |
| 429347 | Duck & Dive | 2024 |
| 429349 | Herbivores | 2024 |
| 429367 | Lux Nova | 2024 |
| 429374 | Butter Crime | 2024 |
| 429376 | The Pi Game | 2024 |
| 429385 | Les Ribauds: Aventures solo en Austerion | 2024 |
| 429386 | Une chauchette chachant chacher | 2024 |
| 429388 | Tokyo Big Sight Card Game | 2024 |
| 429389 | Potato Party: Mashterworks | 2024 |
| 429390 | AOITRT | 2024 |
| 429402 | Top Cat | 2024 |
| 429403 | Lonja | 2024 |
| 429404 | The Secret Relics of Wizards | 2024 |
| 429406 | Wednesday Raven’s Truth | 2024 |
| 429411 | Kitsu | 2024 |
| 429414 | Imperfect Crimes: Pop-Up Escape Book | 2024 |
| 429416 | Number Explorers: A Space Adventure | 2024 |
| 429427 | Spain Rails | 2024 |
| 429443 | Dicionautas | 2024 |
| 429450 | Talavera | 2024 |
| 429452 | La Légende du Colibri | 2024 |
| 429453 | Poetry for Neanderthals: Pop Culture Edition | 2024 |
| 429454 | Nevermind The Distraction: Abstract Edition | 2024 |
| 429455 | Nevermind The Distraction: Life Edition | 2024 |
| 429456 | Halloween II | 2024 |
| 429457 | Echo of the Predator | 2024 |
| 429458 | Hexemony | 2024 |
| 429459 | Name Game | 2024 |
| 429461 | しゃてきーや (Syateki Ya) | 2024 |
| 429462 | Entice | 2024 |
| 429464 | Bolicheros de Barrio | 2024 |
| 429465 | Ascensor of Braga | 2024 |
| 429467 | DOTS | 2024 |
| 429476 | Fly for Fight | 2024 |
| 429478 | Mirages: Formation Series \#1 | 2024 |
| 429488 | Big Fish Card Game | 2024 |
| 429491 | Celestia: Big Box | 2024 |
| 429496 | Monopoly: Spirit | 2024 |
| 429515 | Immortal | 2024 |
| 429516 | TROLLympics | 2024 |
| 429517 | Trick 100 | 2024 |
| 429518 | Failure Mode Racing | 2024 |
| 429531 | サンサンダイス (San San Dice) | 2024 |
| 429532 | Dropping Drops | 2024 |
| 429537 | Sheng Xiao | 2024 |
| 429549 | Brewfest Buzz | 2024 |
| 429554 | Happy Garden | 2024 |
| 429582 | Hail Caesar Epic Battles: Hannibal Battle-Set | 2024 |
| 429585 | Метнись кабанчиком! (Run like a hog!) | 2024 |
| 429597 | Herring reAction | 2024 |
| 429604 | Crete, 20 – 22nd May 1941 | 2024 |
| 429605 | Das kleine böse Kartenspiel: Monster Mogeln | 2024 |
| 429608 | Mü & more: Revised Edition | 2024 |
| 429622 | Tiskijukka | 2024 |
| 429631 | Dumpling Defenders (Захисники пельменів) | 2024 |
| 429632 | Терем-теремок (Terem-Teremok) | 2024 |
| 429635 | Electioneer: UK Edition | 2024 |
| 429636 | Risk: Stranger Things | 2024 |
| 429639 | Monopoly: Sonic the Hedgehog | 2024 |
| 429640 | Strawman Struggle | 2024 |
| 429641 | Monopoly: Hello Kitty | 2024 |
| 429646 | Bomb Alley | 2024 |
| 429648 | The Game of Life: Hello Kitty and Friends | 2024 |
| 429651 | Clue: Goosebumps | 2024 |
| 429652 | バクチはアクマでツいてから (Gambling King) | 2024 |
| 429653 | Andromeda’s Edge: Deluxe Edition | 2024 |
| 429661 | Tofu Shifu | 2024 |
| 429662 | Poodle Taxi | 2024 |
| 429663 | 百家 (Schools of Thought) | 2024 |
| 429667 | Volatile Vintage | 2024 |
| 429668 | Драконоборцы (Dragon-Slayers) | 2024 |
| 429670 | Who\`s Next | 2024 |
| 429677 | Tatort Meer Weihnachten in Gefahr | 2024 |
| 429687 | みんなでトリックビーノ (Minna de Torikku Bīno) | 2024 |
| 429699 | Wish Upon a Star | 2024 |
| 429700 | Vamos Dia | 2024 |
| 429709 | Noble Escape | 2024 |
| 429710 | Todos contra a Dengue Roll and Write ! | 2024 |
| 429718 | Gone! | 2024 |
| 429749 | Crypt Crawler | 2024 |
| 429751 | Survival of the Fattest: Deluxe Kickstarter Edition | 2024 |
| 429758 | Not for me | 2024 |
| 429763 | Remember The Music: All Time Edition | 2024 |
| 429768 | Entrenched: Gallia Guards | 2024 |
| 429777 | The Fast and the Curious | 2024 |
| 429779 | Clues in Twos | 2024 |
| 429804 | Tank Commander | 2024 |
| 429805 | Miasmatic Mayhem | 2024 |
| 429807 | kaleiDOS | 2024 |
| 429816 | Unlock!: Short Adventures – Dans la tête de Sherlock Holmes | 2024 |
| 429838 | SongFest! | 2024 |
| 429844 | Monopoly: Board Crawl | 2024 |
| 429852 | YAHS | 2024 |
| 429855 | Pyrrhus: Le modèle d’hannibal | 2024 |
| 429856 | Ice Hockey with Dice | 2024 |
| 429858 | Baseball with Dice | 2024 |
| 429862 | Cast Your Nets | 2024 |
| 429874 | Candy Land: Bluey | 2024 |
| 429886 | Syllabuster | 2024 |
| 429900 | I’m Kind of a Big Dill | 2024 |
| 429913 | High-Rise | 2024 |
| 429926 | The Tracker: Postapocalyptic Ranger | 2024 |
| 429941 | CORSAIR: Mississippi Bay | 2024 |
| 429942 | CORSAIR: Shantou Bay | 2024 |
| 429960 | Age of the Moon | 2024 |
| 429972 | Irmã Nuna | 2024 |
| 429974 | Vineyard Run | 2024 |
| 429983 | Emergency Operations Center Board Game: Wildfire Mayhem | 2024 |
| 429992 | Berlin 1945 | 2024 |
| 429994 | Siege: Asedio | 2024 |
| 430000 | Kopfkino à la carte | 2024 |
| 430007 | Gratte le Ciel | 2024 |
| 430020 | Flip and Find: Pet Detectives | 2024 |
| 430022 | Clash Of Steel: Operation Unthinkable – German vs British Complete Starter Set | 2024 |
| 430026 | Build That Wall | 2024 |
| 430039 | 文明源记：上古传说 (The Roots of Civilization) | 2024 |
| 430117 | Die Schule der magischen Tiere: Zutritt verboten! | 2024 |
| 430147 | Tic Tac Rally | 2024 |
| 430159 | Scope: Eurooppa | 2024 |
| 430160 | SMASK! | 2024 |
| 430161 | Dreamteam | 2024 |
| 430162 | Toilet Divers | 2024 |
| 430191 | Lair: Yanar’s Vault | 2024 |
| 430205 | In a Dark Wood | 2024 |
| 430207 | Thief Rush | 2024 |
| 430265 | Yowie Kapowie | 2024 |
| 430275 | Adh Mor | 2024 |
| 430277 | Apiary | 2024 |
| 430288 | Trombone Champ | 2024 |
| 430291 | Up Dog | 2024 |
| 430343 | Armas Salvajes | 2024 |
| 430345 | Batalha dos Cookies | 2024 |
| 430368 | Heaven’s Will: The Attack on Ulithi Atoll, November 1944 | 2024 |
| 430378 | Snack-O-Saurus Rex | 2024 |
| 430394 | Connect-o-Mania | 2024 |
| 430399 | Mall Cop | 2024 |
| 430402 | Masterpiece: The Third Battle of Kharkov | 2024 |
| 430404 | Britskrieg!: Operation Brevity, May 15-16, 1941 | 2024 |
| 430444 | Munchkin Shadowrun | 2024 |
| 430445 | Hauntsville | 2024 |
| 430451 | Хата Багата (Rich House) | 2024 |
| 430454 | Monopoly: SLO CAL Edition | 2024 |
| 406914 | Nekojima: Collector’s Edition | 2023 |
| 429190 | Midrash | 2023 |
| 429396 | Death Game Card: Bomb | 2023 |
| 429398 | Death Game Card: Fire | 2023 |
| 429400 | Death Game Card: Duel | 2023 |
| 429463 | Copy Cat Meow | 2023 |
| 429492 | Crime Scene: Luxor 1932 | 2023 |
| 429523 | Unbearable Bears | 2023 |
| 429529 | Merchants of Haniwa | 2023 |
| 429589 | Полный порядок (Very Orderly) | 2023 |
| 429607 | Guess My Animal!: Endangered Species Charades | 2023 |
| 429654 | Blood Recall | 2023 |
| 429857 | Craft My Coast | 2023 |
| 429859 | Happy Village | 2023 |
| 429879 | Carbon Neutrality | 2023 |
| 430308 | Kawarimi | 2023 |
| 430334 | Chicken Fight | 2023 |
| 430397 | Zavod: The Runners | 2023 |
| 405732 | TTMC: Format de Voyage, vol. 2 | 2022 |
| 429249 | 西遊記之花果山 (Mount Huaguo Journey to the West) | 2022 |
| 429621 | Tengo Duo | 2022 |
| 429671 | Meidum | 2022 |
| 429950 | The Hunt for Eritrea | 2022 |
| 429173 | 1,2,3 Glisse ! | 2021 |
| 429273 | Family Feud: Disney Edition | 2021 |
| 429328 | Funb3rs: Fun with Numbers | 2021 |
| 429475 | Monopoly: Naruto | 2021 |
| 429494 | Erik Eikel | 2021 |
| 429935 | Around the World Travel Game | 2021 |
| 429224 | Mysteres a Paris | 2020 |
| 429225 | La Casa de Papel: Het Spel | 2020 |
| 429393 | UNO: The Office | 2020 |
| 429469 | Ding Dong! | 2020 |
| 429596 | Fireside Story Dice | 2020 |
| 429633 | Escape Box: Casino | 2020 |
| 429535 | Das kuriose Österreich Quiz | 2019 |
| 429951 | The Brigade without Color | 2019 |
| 429991 | Happy Sheep: Das Wilde Kartenspiel | 2019 |
| 430096 | Mountaineers: Deluxe Edition | 2019 |
| 430125 | That Flipping Word Game | 2019 |
| 429952 | Battle of Mukden | 2018 |
| 430138 | Lumber Merchant | 2018 |
| 430348 | Fields of Blue & Grey | 2018 |
| 429471 | Crown Hearts | 2017 |
| 429506 | Guess What? (你猜怎么着) | 2017 |
| 429947 | Operation Konrad: Budapest 1945 – The Bitter End | 2017 |
| 429953 | Night Attack on Slim | 2017 |
| 430256 | Forged Realms: Fields of Flame | 2017 |
| 428854 | Rebenta a Bolha | 2016 |
| 430383 | Wave To The Missionaries | 2016 |
| 430139 | Fear Vier | 2015 |
| 430353 | Zodiac | 2015 |
| 430425 | The Bridge | 2014 |
| 430435 | Fuer | 2014 |
| 430134 | Wise Man’s Stones | 2013 |
| 430137 | Whose Foods | 2013 |
| 430429 | The King of Rings | 2013 |
| 430132 | OKI 24 | 2012 |
| 429302 | Abbey Road Studios: Music Trivia Game | 2011 |
| 429780 | Boribon és Annipanni: A nagy szamóca-vadászat | 2011 |
| 429781 | Kippkopp Rakosgató | 2011 |
| 429415 | Beugró 2 | 2010 |
| 430419 | Dr. Sue | 2010 |
| 430421 | Jump | 2009 |
| 430355 | R&B-Dual | 2008 |
| 430424 | Skips | 2008 |
| 430427 | Check it | 2008 |
| 430426 | Dice4 | 2007 |
| 430045 | Crab Dice Game | 2006 |
| 430028 | The King’s Ear | 2005 |
| 429348 | UNO Slam | 1996 |
| 429271 | The Energy Resource Game | 1995 |
| 429514 | Word Tango | 1990 |
| 429748 | Horror Night | 1989 |
| 430145 | Vegas Nite Casino Games | 1988 |
| 430130 | Farben-Trendel | 1949 |
| 430457 | Anteportas 1915 | 1915 |
| 429206 | Verlorene Fahrkarte | NA |
| 429209 | Fuß-Ball: Der Sport von Heute | NA |
| 429260 | Water War: La Guerra per l’Acqua | NA |
| 429268 | Little Bluebird’s Matching Game | NA |
| 429269 | Fishing Game | NA |
| 429352 | Empire: TCG | NA |
| 429466 | The Mystery Experiences Company: The Lost City | NA |
| 429474 | Power Well | NA |
| 429612 | PEI-opoly | NA |
| 429774 | Mistakos: Paint | NA |
| 429776 | Mistakos: Platform | NA |
| 429808 | Schäfchenspiel | NA |
| 429944 | Gnomy | NA |
| 429955 | Kampf um die Fahne | NA |
| 429986 | Flightpath | NA |
| 430209 | El Castillo: The Temple of Kukulcán | NA |
