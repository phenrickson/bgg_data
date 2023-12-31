# get modeled data
get_game_links =
        function(bgg_games) { 
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        mutate(row = row_number()) %>%
                        select(game_id, links) %>%
                        unnest(links) %>%
                        mutate(game_id,
                               type = gsub("boardgame", "", type),
                               id,
                               value,
                               load_ts = Sys.time(),
                               .keep = 'none')
                
        }

get_game_names =
        function(bgg_games) { 
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        select(game_id, names) %>%
                        unnest(names) %>%
                        type_convert() %>%
                        mutate(game_id,
                               type,
                               value,
                               sortindex,
                               load_ts = Sys.time(),
                               .keep = 'none')
                
        }

get_game_ids = 
        function(bgg_games, bgg_ids) {
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        select(game_id) %>%
                        left_join(.,
                                  get_game_names(bgg_games) %>%
                                          filter(type == 'primary') %>%
                                          mutate(game_id,
                                                 name = value),
                                  by = 'game_id') %>%
                        # get bgg's raw name for each game
                        left_join(.,
                                  bgg_ids %>%
                                          distinct(game_id, raw_name),
                                  by = c("game_id")) %>%
                        # get yearpublished
                        mutate(game_id,
                               name,
                               raw_name,
                               load_ts = Sys.time(),
                               .keep = 'none')
                
        }

get_game_expansions = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_links() %>%
                        filter(type == 'expansion') %>%
                        mutate(game_id, 
                               expansion_id = id,
                               expansion_name = value,
                               load_ts = Sys.time(),
                               .keep = 'none')
        }

get_game_descriptions = 
        function(bgg_games) {
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        select(game_id, info) %>%
                        unnest(info) %>%
                        type_convert() %>%
                        mutate(game_id,
                               description,
                               load_ts = Sys.time(),
                               .keep = 'none')
        }

get_game_images = 
        function(bgg_games) {
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        select(game_id, info) %>%
                        unnest(info) %>%
                        type_convert() %>%
                        # remove missingness
                        filter(!is.na(image)) %>%
                        mutate(game_id,
                               image,
                               thumbnail,
                               load_ts = Sys.time(),
                               .keep = 'none')
        }

get_game_playercounts = 
        function(bgg_games) {
                
                bgg_games%>%
                        filter(type == 'boardgame') %>%
                        select(game_id, polls) %>%
                        unnest(polls) %>%
                        type_convert() %>%
                        mutate(game_id,
                               value,
                               numvotes,
                               numplayers,
                               load_ts = Sys.time(),
                               .keep = 'none')
        }

get_game_ranks = 
        function(bgg_games) {
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        select(game_id, ranks) %>%
                        unnest(ranks) %>%
                        filter(name %in% c("abstracts",
                                           "boardgame", 
                                           "childrensgames",
                                           "cgs",
                                           "familygames",
                                           "partygames",
                                           "strategygames",
                                           "thematic",
                                           "wargames")) %>%
                        mutate(bayesaverage = case_when(bayesaverage == 'Not Ranked' ~ NA_character_,
                                                        TRUE ~ bayesaverage),
                               value = case_when(value == 'Not Ranked' ~ NA_character_,
                                                 TRUE ~ value)) %>%
                        type_convert() %>%
                        mutate(game_id,
                               rank_type = name,
                               rank = value,
                               bayesaverage,
                               load_ts = Sys.time(),
                               .keep = 'none')
                
                
        }

get_game_info =
        function(bgg_games) {
                
                bgg_games %>%
                        filter(type == 'boardgame') %>%
                        select(game_id, info, statistics) %>%
                        unnest(c(info, statistics)) %>%
                        # add names
                        left_join(.,
                                  get_game_names(bgg_games) %>%
                                          filter(type == 'primary') %>%
                                          transmute(game_id,
                                                    name = value),
                                  by = c("game_id")) %>%
                        mutate(game_id,
                               name,
                               yearpublished,
                               averageweight,
                               average,
                               bayesaverage,
                               usersrated,
                               stddev,
                               minage,
                               minplayers,
                               maxplayers,
                               playingtime,
                               minplaytime,
                               maxplaytime,
                               numcomments,
                               numweights,
                               owned,
                               trading,
                               wanting,
                               wishing,
                               load_ts = Sys.time(),
                               .keep = 'none'
                        )
        }

get_rec_playercounts = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_playercounts() %>%
                        mutate(value = tolower(gsub("\\s+", "", value))) %>%
                        filter(numvotes > 0) %>%
                        group_by(game_id) %>%
                        mutate(total_votes = sum(numvotes)) %>%
                        ungroup() %>%
                        group_by(game_id, numplayers) %>%
                        slice_max(numvotes, n=1, with_ties = F) %>% 
                        group_by(game_id) %>%
                        select(game_id, value, numplayers, total_votes, load_ts) %>% 
                        pivot_wider(values_from = c("numplayers"),
                                    names_from = c("value"), 
                                    id_cols = c("game_id", "total_votes", "load_ts"),
                                    names_prefix = c("playercount_"),
                                    values_fn = ~ paste(.x, collapse=",")) %>%
                        select(game_id, total_votes, playercount_best, playercount_recommended, playercount_notrecommended, load_ts) %>%
                        ungroup() %>%
                        mutate(game_id,
                               playercount_votes = total_votes,
                               playercount_best,
                               playercount_rec = playercount_recommended,
                               playercount_notrec = playercount_notrecommended,
                               load_ts,
                               .keep = 'none')
                
        }

get_rank_types = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_ranks() %>%
                        select(game_id, rank_type, rank, load_ts) %>%
                        pivot_wider(names_from = c("rank_type"),
                                    values_from = c("rank"),
                                    names_prefix = c("rank_"),
                                    id_cols = c("game_id", "load_ts")) %>%
                        mutate(game_id,
                               rank_boardgame,
                               rank_thematic,
                               rank_strategy = rank_strategygames,
                               rank_wargame = rank_wargames,
                               rank_family = rank_familygames,
                               rank_children = rank_childrensgames,
                               rank_cgs,
                               rank_abstract = rank_abstracts,
                               rank_party = rank_partygames,
                               load_ts,
                               .keep = 'none')
                
        }

get_analysis_games = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_info() %>%
                        # get image
                        left_join(.,
                                  get_game_images(bgg_games) %>%
                                          select(game_id,
                                                 image,
                                                 thumbnail),
                                  by = c("game_id")) %>%
                        # get playercounts
                        left_join(.,
                                  get_rec_playercounts(bgg_games) %>%
                                          select(game_id,
                                                 playercount_votes,
                                                 playercount_best,
                                                 playercount_rec,
                                                 playercount_notrec),
                                  by = c("game_id")) %>%
                        # get ranks
                        left_join(.,
                                  get_rank_types(bgg_games) %>%
                                          select(game_id,
                                                 rank_boardgame,
                                                 rank_thematic,
                                                 rank_strategy,
                                                 rank_wargame,
                                                 rank_family,
                                                 rank_children,
                                                 rank_cgs,
                                                 rank_abstract,
                                                 rank_party),
                                  by = c("game_id")) %>%
                        mutate(
                                game_id,
                                name,
                                yearpublished,
                                image, 
                                thumbnail,
                                averageweight,
                                average,
                                bayesaverage,
                                usersrated,
                                stddev,
                                minage,
                                minplayers,
                                maxplayers,
                                playingtime,
                                minplaytime,
                                maxplaytime,
                                numcomments,
                                numweights,
                                owned,
                                trading,
                                wanting,
                                wishing,
                                playercount_votes,
                                playercount_best,
                                playercount_rec,
                                playercount_notrec,
                                rank_boardgame,
                                rank_thematic,
                                rank_strategy,
                                rank_wargame,
                                rank_family,
                                rank_children,
                                rank_cgs,
                                rank_abstract,
                                rank_party,
                                load_ts,
                                .keep = 'none')
                
        }

get_rec_playercounts = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_playercounts() %>%
                        mutate(value = tolower(gsub("\\s+", "", value))) %>%
                        filter(numvotes > 0) %>%
                        group_by(game_id) %>%
                        mutate(total_votes = sum(numvotes)) %>%
                        ungroup() %>%
                        group_by(game_id, numplayers) %>%
                        slice_max(numvotes, n=1, with_ties = F) %>% 
                        group_by(game_id) %>%
                        select(game_id, value, numplayers, total_votes, load_ts) %>% 
                        pivot_wider(values_from = c("numplayers"),
                                    names_from = c("value"), 
                                    id_cols = c("game_id", "total_votes", "load_ts"),
                                    names_prefix = c("playercount_"),
                                    values_fn = ~ paste(.x, collapse=",")) %>%
                        select(game_id, total_votes, playercount_best, playercount_recommended, playercount_notrecommended, load_ts) %>%
                        ungroup() %>%
                        mutate(game_id,
                                  playercount_votes = total_votes,
                                  playercount_best,
                                  playercount_rec = playercount_recommended,
                                  playercount_notrec = playercount_notrecommended,
                                  load_ts,
                                  .keep = 'none')
                
        }

get_rank_types = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_ranks() %>%
                        select(game_id, rank_type, rank, load_ts) %>%
                        pivot_wider(names_from = c("rank_type"),
                                    values_from = c("rank"),
                                    names_prefix = c("rank_"),
                                    id_cols = c("game_id", "load_ts")) %>%
                        mutate(game_id,
                               rank_boardgame,
                               rank_thematic,
                               rank_strategy = rank_strategygames,
                               rank_wargame = rank_wargames,
                               rank_family = rank_familygames,
                               rank_children = rank_childrensgames,
                               rank_cgs,
                               rank_abstract = rank_abstracts,
                               rank_party = rank_partygames,
                               load_ts,
                               .keep = 'none')
                
        }

get_analysis_games = 
        function(bgg_games) {
        
        bgg_games %>%
                get_game_info() %>%
                # get image
                left_join(.,
                          get_game_images(bgg_games) %>%
                                  select(game_id,
                                         image,
                                         thumbnail),
                          by = c("game_id")) %>%
                # get playercounts
                left_join(.,
                          get_rec_playercounts(bgg_games) %>%
                                  select(game_id,
                                         playercount_votes,
                                         playercount_best,
                                         playercount_rec,
                                         playercount_notrec),
                          by = c("game_id")) %>%
                # get ranks
                left_join(.,
                          get_rank_types(bgg_games) %>%
                                  select(game_id,
                                         rank_boardgame,
                                         rank_thematic,
                                         rank_strategy,
                                         rank_wargame,
                                         rank_family,
                                         rank_children,
                                         rank_cgs,
                                         rank_abstract,
                                         rank_party),
                          by = c("game_id")) %>%
                mutate(
                        game_id,
                        name,
                        yearpublished,
                        image, 
                        thumbnail,
                        averageweight,
                        average,
                        bayesaverage,
                        usersrated,
                        stddev,
                        minage,
                        minplayers,
                        maxplayers,
                        playingtime,
                        minplaytime,
                        maxplaytime,
                        numcomments,
                        numweights,
                        owned,
                        trading,
                        wanting,
                        wishing,
                        playercount_votes,
                        playercount_best,
                        playercount_rec,
                        playercount_notrec,
                        rank_boardgame,
                        rank_thematic,
                        rank_strategy,
                        rank_wargame,
                        rank_family,
                        rank_children,
                        rank_cgs,
                        rank_abstract,
                        rank_party,
                        load_ts,
                        .keep = 'none') %>%
                        # change integers to numeric
                        mutate_if(is.integer, as.numeric) %>%
                        # change zeroes to NA
                        mutate_at(c("averageweight",
                                    "playingtime",
                                    "minplaytime",
                                    "maxplaytime",
                                    "yearpublished"),
                                  ~ case_when(. == 0 ~ NA_real_,
                                              TRUE ~ .)) %>%
                        arrange(desc(bayesaverage))
        
        }

get_unreleased_games = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_links() %>%
                        filter(value == 'Admin: Unreleased Games' | value == 'Upcoming Releases') %>%
                        mutate(
                                type,
                                value,
                                id,
                                game_id,
                                load_ts,
                                .keep = 'none'
                        )
        }

get_drop_games =
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_links() %>%
                        # add in yearpublished and numweights for filtering
                        left_join(.,
                                  get_analysis_games(bgg_games) %>%
                                          select(game_id, name, yearpublished) %>%
                                          distinct,
                                  by = c("game_id")) %>%
                        # remove upcoming releases from this set
                        filter(value != 'Admin: Unreleased Games') %>%
                        # select games if they meet any of the following criteria
                        filter(
                                # expansion for base game or looking for a publisher
                                value %in% 
                                        c('Expansion for Base-game',
                                          'Fan Expansion',
                                          '(Looking for a publisher)') |
                                        # # games where there's an admin note, as this usually indicates a data quality problem
                                        grepl("Admin: Book entries that should be split", value) |
                                        grepl("Admin: Cancelled Games", value) |
                                        grepl("Admin: Miscellaneous Placeholder", value) |
                                        grepl("Admin: Outside the Scope of BGG", value) |
                                        grepl("Admin: Test Family for revision", value) |
                                        #    missingness on yearpublished
                                        is.na(yearpublished) |
                                        is.na(name)
                        ) %>%
                        select(game_id, name, load_ts) %>%
                        unique
                
                
        }

get_game_families = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_links() %>%
                        filter(type == 'family') %>%
                        separate(value,
                                 into = c("family_type", "family_value"),
                                 sep= ": ",
                                 extra = "merge",
                                 fill = "right") %>%
                        mutate(type,
                               family_type,
                               family_value,
                               value = paste(family_type, family_value),
                               id,
                               game_id,
                               load_ts,
                               .keep = 'none')
                
        }

get_link_type = 
        function(bgg_games,
                 link_type) {
                
                if (link_type %in% c('compilation', 'implementation')) {
                        
                        bgg_games %>%
                                get_game_links() %>%
                                filter(type == link_type) %>%
                                mutate(
                                        type,
                                        name = value,
                                        id = id,
                                        game_id,
                                        load_ts,
                                        .keep = 'none')
                        
                } else {
                        
                        bgg_games %>%
                                get_game_links() %>%
                                filter(type == link_type) %>%
                                mutate(type,
                                       value,
                                       id = id,
                                       game_id,
                                       load_ts,
                                       .keep = 'none')
                        
                }
                
                
        }

get_game_categories = 
        function(bgg_games) {
                
                bgg_games %>%
                        get_game_links() %>%
                        filter(type == 'category') %>%
                        transmute(type,
                                  value = value,
                                  id = id,
                                  game_id,
                                  load_ts)
        }

# run ---------------------------------------------------------------------

# game_info = 
#         bgg_games_data %>%
#         get_game_info()
# 
# game_ids = 
#         bgg_games_data %>%
#         get_game_ids()
# 
# game_expansions = 
#         bgg_games_data %>%
#         get_game_expansions()
# 
# game_names = 
#         bgg_games_data %>%
#         get_game_names()
# 
# game_links = 
#         bgg_games_data %>%
#         get_game_links()
# 
# game_ranks = 
#         bgg_games_data %>%
#         get_game_ranks()
# 
# game_playercounts = 
#         bgg_games_data %>%
#         get_game_playercounts()
# 
# game_images = 
#         bgg_games_data %>%
#         get_game_images()
# 
# game_descriptions = 
#         bgg_games_data %>%
#         get_game_descriptions()
# 
# analysis_games = 
#         bgg_games_data %>%
#         get_analysis_games()


# load --------------------------------------------------------------------


# # game info
# dbWriteTable(bigquerycon,
#              name = "api_game_info",
#              append = T,
#              value = game_info)
# 
# # game ids
# dbWriteTable(bigquerycon,
#              name = "api_game_ids",
#              overwrite = T,
#              value = game_ids)
# 
# # game expansions
# dbWriteTable(bigquerycon,
#              name = "api_game_expansions",
#              overwrite = T,
#              value = game_expansions)
# 
# # game expansions
# dbWriteTable(bigquerycon,
#              name = "api_game_names",
#              overwrite = T,
#              value = game_names)
# 
# # game links
# dbWriteTable(bigquerycon,
#              name = "api_game_links",
#              overwrite = T,
#              value = game_links)
# 
# # game ranks
# dbWriteTable(bigquerycon,
#              name = "api_game_ranks",
#              overwrite = T,
#              value = game_ranks)
# 
# # game playercounts
# dbWriteTable(bigquerycon,
#              name = "api_game_playercounts",
#              overwrite = T,
#              value = game_playercounts)
# 
# # game images
# dbWriteTable(bigquerycon,
#              name = "api_game_images",
#              overwrite = T,
#              value = game_images)
# 
# # game descriptions
# dbWriteTable(bigquerycon,
#              name = "api_game_descriptions",
#              overwrite = T,
#              value = game_descriptions)
# 
# ### analysis
# dbWriteTable(bigquerycon,
#              name = "analysis_games",
#              overwrite = T,
#              value = analysis_games)

#message("all tables loaded to GCP.")