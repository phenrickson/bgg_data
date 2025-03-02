
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
| 432037 | Tales From the Skald: Legends of Aramyth | 2026 |
| 432039 | Legends of the Arena | 2026 |
| 432281 | Canals of Windcrest | 2026 |
| 432577 | Scarab Sands | 2026 |
| 424784 | Arkham Horror: Lovecraft Letter | 2025 |
| 430044 | Katz: The Card Game | 2025 |
| 431305 | Great Western Trail: El Paso | 2025 |
| 431493 | Forestry | 2025 |
| 431504 | Foraglings | 2025 |
| 431652 | Komm zum Punkt | 2025 |
| 431680 | DiceKeepers EndHaven | 2025 |
| 431692 | 1811: Albuera Second Edition | 2025 |
| 431710 | Catharsis: Second Edition | 2025 |
| 431795 | Duel of Chaos | 2025 |
| 431803 | Carrier: Hidden Within | 2025 |
| 431805 | Road to Academia | 2025 |
| 431820 | Reckless Sloths: Madness Unleashed | 2025 |
| 431830 | Champions of Wind & Fire | 2025 |
| 431837 | Coming of Age | 2025 |
| 431838 | Spot it!: GIANT | 2025 |
| 431872 | KARAHEX | 2025 |
| 431906 | Revolution: Paris | 2025 |
| 431994 | Propolis | 2025 |
| 431998 | Point Galaxy | 2025 |
| 432012 | Dreamworld TCG | 2025 |
| 432015 | Squishy Grip | 2025 |
| 432056 | Principati Duello | 2025 |
| 432062 | The Shadow Theater: The Legend of the Monkey King | 2025 |
| 432067 | Assyria: Second Edition | 2025 |
| 432068 | Shadowed Venture | 2025 |
| 432078 | Suit and Tie | 2025 |
| 432083 | Chronofiends!! | 2025 |
| 432146 | Valkyrie: A Black Orchestra Game | 2025 |
| 432218 | The Smoky Valley | 2025 |
| 432235 | Super Fantasy Brawl: Reborn | 2025 |
| 432261 | Trench Crusade | 2025 |
| 432264 | Biblical Connections | 2025 |
| 432302 | Murder on the Rocks | 2025 |
| 432303 | Terrible Influence | 2025 |
| 432345 | Funkloch | 2025 |
| 432351 | Oddities | 2025 |
| 432352 | Yes, But | 2025 |
| 432374 | Illyriad Empires: the Board Game | 2025 |
| 432387 | HERD: The Dinosaur Survival Card Game | 2025 |
| 432388 | Bad Eggs | 2025 |
| 432392 | Tales of the Arabian Nights: 40th Anniversary | 2025 |
| 432407 | Illyriad Empires | 2025 |
| 432417 | Splash! | 2025 |
| 432451 | Symbiose | 2025 |
| 432458 | Perfect Health Company | 2025 |
| 432459 | Mala Suerte | 2025 |
| 432463 | HAA! | 2025 |
| 432475 | Legends of ShenZhou | 2025 |
| 432489 | Gate Legend: Throne Of Void | 2025 |
| 432491 | Johari Bazaar | 2025 |
| 432492 | Synthesis: The Molecular Journey | 2025 |
| 432493 | Habitopia | 2025 |
| 432512 | Magic Number: The Party Game of Wild Guesstimation | 2025 |
| 432520 | Karnak | 2025 |
| 432522 | Night Hunt | 2025 |
| 432525 | Japanese Civil War: Aizu | 2025 |
| 432526 | Japanese Civil War: Hakodate | 2025 |
| 432528 | Vanguard: Normandy | 2025 |
| 432541 | Gamemaster: Battle Royale | 2025 |
| 432542 | Acuarella | 2025 |
| 432545 | Fishing for Compliments | 2025 |
| 432555 | Pájaros en Celaya | 2025 |
| 432570 | Spirit Path | 2025 |
| 432576 | Teppanyaki Fever! | 2025 |
| 432578 | Tundra | 2025 |
| 432581 | Parallel Stories: The Rift | 2025 |
| 432584 | Hair Color Game: Colorology | 2025 |
| 432585 | Cats & Steak | 2025 |
| 432666 | Star Chart | 2025 |
| 432669 | The UFO Disclosure Game: We are not alone | 2025 |
| 432671 | Fú: Red Envelopes | 2025 |
| 432675 | The Battle of the Hook, October 3rd 1781 | 2025 |
| 432701 | The League Of The Extraordinary Collectors | 2025 |
| 432709 | Severton | 2025 |
| 432711 | Garden Lake | 2025 |
| 432715 | Dirt & Dust | 2025 |
| 432716 | Leaders | 2025 |
| 432734 | Trixx | 2025 |
| 432766 | The Big Squeeze | 2025 |
| 432768 | Panots | 2025 |
| 432783 | Cereal Spiller | 2025 |
| 432789 | Mars Escape Party Rumble | 2025 |
| 432792 | Mech Bunny | 2025 |
| 432797 | Addam’s Family Cemetery Drag Racing | 2025 |
| 432800 | Last Shot | 2025 |
| 432802 | Schattenwald | 2025 |
| 432804 | Right on Time | 2025 |
| 432805 | Get That Cat | 2025 |
| 432808 | Tai Chi Tiger | 2025 |
| 432811 | Color Craze | 2025 |
| 432823 | Oh My Word | 2025 |
| 432826 | Blütenreich | 2025 |
| 432841 | Jure Grando: The First Vampire | 2025 |
| 432858 | Artistry | 2025 |
| 432890 | Good Riddance: Booted From the Bash! | 2025 |
| 432912 | Building Babel | 2025 |
| 432915 | Doom Pilgrim Pocket | 2025 |
| 432916 | Good Puppers Too | 2025 |
| 432932 | Djibouti: Guess where it’s hottest | 2025 |
| 432939 | Lucerna | 2025 |
| 432940 | Chrono Core Trading Card Game | 2025 |
| 432985 | Bloody Hollow | 2025 |
| 433007 | Cascadia Junior | 2025 |
| 433030 | A Matter Of Taste | 2025 |
| 433031 | Katua | 2025 |
| 433065 | No More Kings | 2025 |
| 433080 | Sentando a Pua | 2025 |
| 433120 | Mystic Potions | 2025 |
| 409911 | Unhappy Birthday at Castle Slogar | 2024 |
| 409912 | Cryptid Hunt | 2024 |
| 427118 | That’s Not a Dick | 2024 |
| 429806 | The Tale of the Disappearing Beauty | 2024 |
| 429811 | Crazy Shapes | 2024 |
| 429885 | Stabbin’ in the Cabin | 2024 |
| 429908 | Miniwars: Navíos de Línea | 2024 |
| 429914 | BLASTER: Game Magazine 06 – Slip Runners | 2024 |
| 429921 | BLASTER: Game Magazine 07 – Arsenal | 2024 |
| 429997 | Jeu de la galette | 2024 |
| 430016 | Tatort Meer Junior Robben in Gefahr | 2024 |
| 430054 | Wings over the Sea | 2024 |
| 430702 | Black Rose Wars: Duel – Void | 2024 |
| 431045 | Spacegom | 2024 |
| 431286 | Explore! Indonesia | 2024 |
| 431308 | Hitster: Rock Edition | 2024 |
| 431359 | Wer lacht, verliert!: Das Brettspiel | 2024 |
| 431455 | The Not-So-Neighborly Christmas Lights Competition | 2024 |
| 431486 | Croâ! 25th anniversary | 2024 |
| 431543 | L00ser | 2024 |
| 431550 | \#Banagifu (Banana gift) | 2024 |
| 431569 | Memorias de Julio Verne | 2024 |
| 431631 | Coconut Cannon | 2024 |
| 431634 | Uncheckered | 2024 |
| 431635 | Roll 4 Ruins | 2024 |
| 431636 | Eisenhower | 2024 |
| 431637 | Munster’s Swamp Drag Racing | 2024 |
| 431639 | Bombs Away! | 2024 |
| 431670 | Numerica | 2024 |
| 431674 | Sveaborg Viapori 1855 | 2024 |
| 431679 | Wings over the Sea: WWII Naval Air Campaigns | 2024 |
| 431695 | Ali Baba and the Forty Thieves | 2024 |
| 431717 | Verhext! | 2024 |
| 431718 | The Isle of Cats Duel | 2024 |
| 431724 | Dungeon Cuisine Reviewers | 2024 |
| 431727 | Jumping Dice | 2024 |
| 431728 | Theewun: Free Version | 2024 |
| 431731 | Midgard: Heroic Battles | 2024 |
| 431735 | Dark Humor | 2024 |
| 431743 | Fire & Sword: Battles for Hungary 1944 | 2024 |
| 431775 | Forest Floor | 2024 |
| 431778 | FREAKZ! Mutant Murder Machines | 2024 |
| 431781 | 왓김치(What Kimchi) | 2024 |
| 431783 | 원두원두(Beani Beani) | 2024 |
| 431794 | Data Theft: \>BotNet\< vs /Phishing-Welle/ – Das Starter Set | 2024 |
| 431797 | Nature Elements | 2024 |
| 431836 | Big Fish Little Fish | 2024 |
| 431839 | Hitster: Radio Italia | 2024 |
| 431856 | Thirst | 2024 |
| 431858 | BelloLudi: Kalashnikov – Skirmish Game 1970-20XX | 2024 |
| 431859 | The Liberation of South Vietnam: War Rules | 2024 |
| 431860 | Rifle Squad: The British Home Guard – A Solitaire Wargame | 2024 |
| 431948 | Gli ultimi saranno i primi | 2024 |
| 431960 | It’s About Time | 2024 |
| 431990 | Dino Might | 2024 |
| 431991 | Palabretto | 2024 |
| 432014 | Mythic Warzone | 2024 |
| 432016 | Crumbling Kingdom | 2024 |
| 432033 | One Hour World War II | 2024 |
| 432049 | Dossiers Criminels: Mystère dans la Vallée des Rois | 2024 |
| 432050 | Dossiers Criminels: Le Secret des Yakuzas | 2024 |
| 432052 | tornei | 2024 |
| 432080 | New games with bingo cards (Vol. 1-2) | 2024 |
| 432086 | Das Monster aus dem Eis | 2024 |
| 432089 | Alzuhra | 2024 |
| 432137 | Adventure Cats | 2024 |
| 432145 | Sword of Orthodoxy: The Rise and Fall of Byzantium 420-1453 | 2024 |
| 432147 | Queteb | 2024 |
| 432148 | Würfelpyramiden schmieden | 2024 |
| 432149 | Gleis um Gleis | 2024 |
| 432150 | アトリエ・ウィズ・ジニーズ (Atelier with Jinnees) | 2024 |
| 432151 | Pet Worlds | 2024 |
| 432152 | Tiki Knockout | 2024 |
| 432176 | Dread Nights | 2024 |
| 432182 | The Graveyard Shift | 2024 |
| 432199 | Stratheós: Les origines de la mythologie | 2024 |
| 432207 | Conect | 2024 |
| 432208 | Hyde & Peek | 2024 |
| 432209 | Dragon Eyes | 2024 |
| 432210 | Hens and Chicks | 2024 |
| 432214 | Mimic | 2024 |
| 432220 | Take | 2024 |
| 432223 | Cattlers of Satan | 2024 |
| 432229 | Nains | 2024 |
| 432243 | We Go Way Back | 2024 |
| 432248 | Donde Las Papas Queman: APAPALIPSIS | 2024 |
| 432250 | 52 Realms: Adventures | 2024 |
| 432255 | Kangaroo Rush | 2024 |
| 432257 | Northern Fleet: A Proper Naval Game | 2024 |
| 432258 | Please write DEATH name | 2024 |
| 432259 | Flower Marche | 2024 |
| 432260 | Chicago Shuffle: Battle Solitaire | 2024 |
| 432262 | Scauver | 2024 |
| 432263 | Telluride | 2024 |
| 432265 | Wagoner of the Rodentale | 2024 |
| 432267 | Tasty Korea | 2024 |
| 432272 | 0-100 Party: Mini | 2024 |
| 432278 | Malumière | 2024 |
| 432280 | Secret Tribe | 2024 |
| 432283 | San Jacinto: April 20-21, 1836 | 2024 |
| 432304 | Contrarium | 2024 |
| 432305 | Dino Delivery | 2024 |
| 432311 | Deep Space Pest Control | 2024 |
| 432319 | Mini-Golf In Hell | 2024 |
| 432322 | Merchant of Goldfish | 2024 |
| 432324 | The Rail on the Hill | 2024 |
| 432327 | Fakin’ It! | 2024 |
| 432328 | Fakin’ It! All Night Long | 2024 |
| 432330 | Roshi | 2024 |
| 432338 | Gold Panners | 2024 |
| 432348 | Team Zoo | 2024 |
| 432350 | Cábalas | 2024 |
| 432354 | V8: Death racing game in a post apocalyptic world | 2024 |
| 432355 | Burgemeesters van Woberg | 2024 |
| 432359 | Burning Galletitas | 2024 |
| 432365 | Path of the Necromancer | 2024 |
| 432390 | Papagotchi | 2024 |
| 432391 | Astromycology | 2024 |
| 432393 | Rock ’N Roll Fantasy | 2024 |
| 432401 | Terra Fantasia: A Map to Encounter Monsters | 2024 |
| 432405 | Deckfish | 2024 |
| 432408 | Rackare! 4 | 2024 |
| 432409 | Fyr | 2024 |
| 432410 | Marramiau | 2024 |
| 432413 | Pisando Fundo | 2024 |
| 432425 | The Hobbit: Hunt For The Arkenstone | 2024 |
| 432426 | New York Zombies! | 2024 |
| 432446 | Recipe Rumble | 2024 |
| 432447 | Wings of Destiny | 2024 |
| 432456 | Revolve! | 2024 |
| 432474 | Hobson’s Horses | 2024 |
| 432487 | Trickarus | 2024 |
| 432488 | 13 Animals | 2024 |
| 432498 | Parasite | 2024 |
| 432503 | Madcap Knights | 2024 |
| 432505 | Bugsnax: The Card Game | 2024 |
| 432506 | Papatada | 2024 |
| 432527 | Ethnos: 2nd Edition | 2024 |
| 432530 | Barbette and Battery! | 2024 |
| 432536 | Virus! Marvel | 2024 |
| 432546 | Barista | 2024 |
| 432548 | Prospect Detective: Caso 0056 – Il delitto della Motocicletta | 2024 |
| 432551 | PelNyan | 2024 |
| 432552 | Tribun | 2024 |
| 432561 | Lublache | 2024 |
| 432566 | Ancient Animals | 2024 |
| 432579 | Daupun | 2024 |
| 432580 | Würdest du lieber …? für Potter-Fans | 2024 |
| 432590 | Quatuor | 2024 |
| 432605 | Stickers: Promo ! | 2024 |
| 432621 | Dicebound Heroes: A roll & write adventure | 2024 |
| 432661 | HACK! Simple rules for large-scale fantasy battles with miniatures | 2024 |
| 432663 | Skuttled! | 2024 |
| 432665 | Hinge | 2024 |
| 432670 | 罗盘与宝藏（Compass Quest） | 2024 |
| 432676 | Warhammer 40,000: Kill Team – Starter Set | 2024 |
| 432681 | Play Hit: El Viaje Musical | 2024 |
| 432684 | GGBGNSSG | 2024 |
| 432717 | Robot Hospital | 2024 |
| 432723 | Kunersdorf 1759 | 2024 |
| 432735 | Kooksville The Game | 2024 |
| 432786 | Spelde | 2024 |
| 432795 | Village Emporium | 2024 |
| 432796 | Salami | 2024 |
| 432799 | The Unknown: Tödliche Auszeit | 2024 |
| 432806 | Alabín | 2024 |
| 432807 | Live Evil | 2024 |
| 432809 | FRIK: A Failpunk Skirmish Game | 2024 |
| 432813 | La Feliz | 2024 |
| 432815 | Red Ops 5: Urban Warfare | 2024 |
| 432824 | Fighter Alley: The Ghost of Kyiv – Special edition | 2024 |
| 432831 | The Campaign | 2024 |
| 432839 | TRICQ SHOT | 2024 |
| 432843 | Hit Me! | 2024 |
| 432845 | Collateral Checkers | 2024 |
| 432861 | Quiltable: Christmas Quilting | 2024 |
| 432870 | ヴァルトビルダー (Wald Builder) | 2024 |
| 432873 | Hex Hive: Buzzerker | 2024 |
| 432878 | Sgolte | 2024 |
| 432914 | Siege of the Molten Mountain | 2024 |
| 432918 | Stratego: Lost Island | 2024 |
| 432936 | Krieg Am Gardasee! | 2024 |
| 432941 | Etevät etsivät | 2024 |
| 432943 | Ready for Christmas | 2024 |
| 432944 | Fényes díszek | 2024 |
| 432945 | Best Snowman Wins | 2024 |
| 432946 | Spy Guy Fantasy | 2024 |
| 432947 | Spy Guy Pyramid | 2024 |
| 432964 | VRRRoomit | 2024 |
| 432973 | Hostile Actions: Warriors Clash Under Alien Suns | 2024 |
| 432974 | The Executives | 2024 |
| 432984 | Eternøl: 15mm Sci-Fi warfare across the Void Horizon | 2024 |
| 432991 | Lethalpalooza | 2024 |
| 433055 | トゥルーマリンショーＲ (True Marine Show R) | 2024 |
| 433056 | Branch Out! | 2024 |
| 433059 | Bronze Shield Silver Coin: Ancient Greek Mercenary Skirmish Wargaming | 2024 |
| 433062 | A Lotta Axolotls | 2024 |
| 433064 | Hexcrement | 2024 |
| 433070 | Tricky Christmas Gnomes | 2024 |
| 433073 | Suspects: Gefährliche Strömung | 2024 |
| 433075 | TRND | 2024 |
| 433076 | Villawar | 2024 |
| 433078 | Strange But True | 2024 |
| 433079 | Rolling Slimes | 2024 |
| 433081 | Get Tammy | 2024 |
| 433082 | Circus Puncta Maximus | 2024 |
| 433083 | The Wall | 2024 |
| 433084 | Two times | 2024 |
| 433085 | Colonade | 2024 |
| 433086 | Mystic Rememberland | 2024 |
| 433087 | Merchants of La Tranche | 2024 |
| 433088 | Toad knights | 2024 |
| 433089 | Fishing for Compliments | 2024 |
| 433091 | Mückenwetter | 2024 |
| 433097 | Rocket Roll | 2024 |
| 433099 | Warhammer Underworlds Embergard | 2024 |
| 433102 | Ritterspiele | 2024 |
| 433103 | Counting Colors | 2024 |
| 433104 | Klack | 2024 |
| 433106 | Mole Poker | 2024 |
| 433107 | Nabe-Bugyo | 2024 |
| 433108 | Kara-age Lemon Princess | 2024 |
| 433109 | Memento Online | 2024 |
| 433110 | Pizza Zombie | 2024 |
| 433113 | Moderately Elite | 2024 |
| 433114 | Rise of the Metro TOKYO | 2024 |
| 433123 | Scrap & Write | 2024 |
| 433126 | robo | 2024 |
| 433127 | Rae Gunn and Rescue Rocket | 2024 |
| 433137 | Not So Secret Santa | 2024 |
| 433139 | Dungeon Foury | 2024 |
| 433153 | Secret Recipes | 2024 |
| 433179 | Skirmish Kids: Small Battles for Young Minds | 2024 |
| 433180 | Mystery Cube: Mystery_Rätsel: Lost Places – OP-Raum | 2024 |
| 433181 | Mecha Fire | 2024 |
| 433185 | Killer Questions | 2024 |
| 433202 | No Soup For You! | 2024 |
| 433205 | Torchlit | 2024 |
| 433211 | 10-Card Moose Evolution Simulator | 2024 |
| 433212 | Vizzard | 2024 |
| 433213 | Cat Butler’s Dice | 2024 |
| 390495 | Recaditos Siderales | 2023 |
| 402761 | Escape-Adventskalender für Minecrafter: Der Angriff des Winter-Withers | 2023 |
| 406545 | The Unknown: Krimi Adventskalender | 2023 |
| 408766 | The Unknown: Eisige Intrigen | 2023 |
| 431513 | El Dictador | 2023 |
| 431734 | Wer lacht, verliert!: KARTENKARAMBA 3000 | 2023 |
| 431782 | دایره شناسایی (Circle of Identification) | 2023 |
| 431853 | Super Mega Ultra Dreidel | 2023 |
| 431946 | Never House | 2023 |
| 431988 | Flesh and Blood: Outsiders | 2023 |
| 432036 | Toll Of The Minotaur | 2023 |
| 432188 | Sparring Dragons: A Postcard Taiwan Conflict | 2023 |
| 432211 | Hexagonal Y | 2023 |
| 432268 | Black Stories Junior: Spitzenreiter | 2023 |
| 432340 | Running Silent | 2023 |
| 432341 | Vampires in the Air | 2023 |
| 432395 | Noir Street | 2023 |
| 432396 | Night Party | 2023 |
| 432397 | B.I.G.: 12 Days of Terror | 2023 |
| 432398 | dANS | 2023 |
| 432457 | Tribal Conquest | 2023 |
| 432521 | Quick Words | 2023 |
| 432547 | Prospect Detective: Caso 0090 – La carpa di via Catamone | 2023 |
| 432565 | Back Tracks | 2023 |
| 432582 | Pass auf, was du sagst: Die Teenieedition | 2023 |
| 432602 | MapGoMap | 2023 |
| 432683 | Puzzle Dungeon Intro Deck | 2023 |
| 432788 | Pilgrims of Life | 2023 |
| 433048 | トゥルーマリンショーＸ (True Marine Show X) | 2023 |
| 433053 | Crack Word | 2023 |
| 433057 | FORK: Deluxe Edition | 2023 |
| 433071 | Lista Zakupów | 2023 |
| 433189 | Mystery Cube: Mystery_Rätsel – Geheimagenten: Ausrüstungskammer | 2023 |
| 433204 | Missionary Crusades | 2023 |
| 431942 | Depth Charge: A Micgame of Submarine Warfare on the Open Ocean | 2022 |
| 431984 | Flesh and Blood: Uprising | 2022 |
| 432042 | Wizard Omnibus | 2022 |
| 432051 | Dossiers Criminels: Le Maestro Assassiné | 2022 |
| 432288 | Unify | 2022 |
| 432376 | Laboratory of Death | 2022 |
| 432574 | Würdest du lieber …? für Potter-Fans | 2022 |
| 432609 | Little Secret Demo | 2022 |
| 432610 | Sunflower Seeds | 2022 |
| 432733 | F.C. De Kampioenen: Gezelschapsspel | 2022 |
| 433060 | Contra Cubes | 2022 |
| 433210 | 1x1 Drachen | 2022 |
| 408534 | Mein Escape-Adventskalender: Fahrschein ins Ungewisse | 2021 |
| 431851 | Squillo Deluxe: Time Travel Edition | 2021 |
| 431862 | Pío | 2021 |
| 431882 | Szacun | 2021 |
| 431980 | Flesh and Blood: Monarch | 2021 |
| 432079 | Cosechas | 2021 |
| 432212 | Lox | 2021 |
| 432293 | Simple Territory Game | 2021 |
| 432343 | Wine Cellar’d | 2021 |
| 432540 | Pontifex | 2021 |
| 432567 | 5 sekund po bandzie | 2021 |
| 432640 | Jeb & Lily op avontuur | 2021 |
| 433061 | That’s Dope: The Party Game for Strong Opinions | 2021 |
| 431784 | Death in Venice | 2020 |
| 431785 | The Food is to Die For | 2020 |
| 431826 | Flash God | 2020 |
| 432084 | Le Petit Composteur | 2020 |
| 432143 | Knight Light | 2020 |
| 432291 | Itsy | 2020 |
| 432295 | Sllug | 2020 |
| 431733 | Wer lacht, verliert! | 2019 |
| 431944 | The Reality is Murder | 2018 |
| 432081 | Foodles | 2018 |
| 433209 | Trappers and Traders | 2018 |
| 432553 | Energiepoker | 2016 |
| 432969 | Teenage Mutant Ninja Turtles: Battlesnap Sewer Slam | 2016 |
| 432201 | Death on the Rocks | 2015 |
| 432573 | The Pier | 2015 |
| 432575 | The Neighbourhood | 2015 |
| 431757 | Dodekatheon | 2014 |
| 391292 | Bombix | 2013 |
| 432507 | Double Exposure | 2012 |
| 433124 | Имаджинариум: Таро | 2011 |
| 432215 | Query | 2010 |
| 433090 | Duo Coup: Sudoku For Two | 2008 |
| 431915 | Never Mind! | 2004 |
| 433067 | Unicef Wereldspel | 2003 |
| 432130 | Balance Seesaw Move it! | 2002 |
| 432205 | Buku | 2001 |
| 406886 | TORX | 2000 |
| 394284 | Virtue Bingo | 1997 |
| 432017 | Golfin’ Chicks | 1997 |
| 431764 | Kurios & verblüffend: Quiz | 1994 |
| 432662 | Fantasy Hack: Rules for Fantasy Miniature Wargaming | 1993 |
| 394283 | The Greatest Adventure: Stories from the Bible – Noahs’ Ark | 1988 |
| 406878 | The Great Australian International Car Race Game | 1985 |
| 431750 | Relocation | 1984 |
| 432070 | Inawapa | 1983 |
| 430688 | Celles: the Battle Before the Meuse | 1978 |
| 431293 | St. Vith: The Sixth Panzer Army Attack | 1978 |
| 431300 | Clervaux: Breakout of the 5th Panzer Army | 1978 |
| 431302 | Sedan, 1940: Guderian Across the Meuse | 1978 |
| 388426 | Marvel Super Heroes Card Game | 1977 |
| 432138 | Guandan | 1960 |
| 431854 | Stock Car Road Race | 1956 |
| 432698 | Lustige 99 | 1947 |
| 432696 | Das hat mal wieder hingehauen | 1940 |
| 405709 | Lourche | 1586 |
| 401922 | Vimanam | NA |
| 410223 | Gioco dei 5 | NA |
| 413051 | Egara Guti | NA |
| 430014 | Truth Detector: The Game | NA |
| 431552 | Chexil | NA |
| 431709 | Murder Mystery Getaway | NA |
| 431712 | Verkehrsspiel | NA |
| 431905 | New Sicilian Tarot | NA |
| 431913 | Seak and suit | NA |
| 431929 | Onward | NA |
| 432011 | Agile Unicorn | NA |
| 432038 | Scenic Route: Tennessee | NA |
| 432059 | What The Ghost?! | NA |
| 432066 | Bombix | NA |
| 432072 | Deep Web | NA |
| 432075 | Memories of July 1986 | NA |
| 432085 | Palourde | NA |
| 432224 | Tree Folk | NA |
| 432301 | Fungopia | NA |
| 432332 | Donjara NEO Hololive “Hololive” Premium Bandai Limited | NA |
| 432356 | Picnic Spinner Game | NA |
| 432394 | Noisy Forest | NA |
| 432411 | Grand Heist: Paris, Les Annees Folles | NA |
| 432441 | Abracabattle | NA |
| 432629 | Two-Ten-Jack | NA |
| 432660 | Boxo Blox | NA |
| 432703 | Post Spiel | NA |
| 432787 | Build a Masjid | NA |
| 432798 | Tuknanavuhpi | NA |
| 432834 | The Great Library | NA |
| 432844 | Microverse | NA |
| 432850 | War in Christmas Village Tabletop Game Rules | NA |
| 432869 | Playground Empires | NA |
| 432879 | Puppet Master | NA |
| 433049 | DISBARRED: The Card Game | NA |
| 433066 | Disney Winnie The Pooh: Kids Bingo | NA |
| 433074 | Cat Between Us | NA |
| 433100 | Original Remmidemmi “Wie du mir - so ich dir! | NA |
| 433105 | Benton Harbor-Opoly | NA |
| 433206 | Ramadan | NA |
