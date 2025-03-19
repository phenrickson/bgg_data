#' Compare game data between environments
#'
#' @param env1 First environment (e.g., "staging")
#' @param env2 Second environment (e.g., "production")
#' @param generation Optional generation to compare for env2
#' @return List with comparison results
compare_game_data <- function(env1, env2, generation = NULL) {
  # Get config for both environments
  cfg1 <- config::get(config = env1)
  cfg2 <- config::get(config = env2)

  # Set up GCS
  googleCloudStorageR::gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))

  # Get latest data from env1
  googleCloudStorageR::gcs_global_bucket(bucket = cfg1$bucket)
  env1_games <- googleCloudStorageR::gcs_get_object(
    paste0(cfg1$prefix, "/objects/games")
  ) |>
    qs::qdeserialize()

  # Get data from env2
  googleCloudStorageR::gcs_global_bucket(bucket = cfg2$bucket)

  if (!is.null(generation)) {
    # Get specific generation
    env2_games <- googleCloudStorageR::gcs_get_object(
      paste0(cfg2$prefix, "/objects/games"),
      generation = generation
    ) |>
      qs::qdeserialize()
  } else {
    # Get latest
    env2_games <- googleCloudStorageR::gcs_get_object(
      paste0(cfg2$prefix, "/objects/games")
    ) |>
      qs::qdeserialize()
  }

  # Compare counts
  env1_count <- nrow(env1_games)
  env2_count <- nrow(env2_games)

  # Find differences
  only_in_env1 <- env1_games |>
    dplyr::anti_join(env2_games |> dplyr::select(game_id), by = "game_id")

  only_in_env2 <- env2_games |>
    dplyr::anti_join(env1_games |> dplyr::select(game_id), by = "game_id")

  # Return comparison
  list(
    env1 = env1,
    env2 = env2,
    env1_count = env1_count,
    env2_count = env2_count,
    diff_count = abs(env1_count - env2_count),
    only_in_env1 = only_in_env1,
    only_in_env2 = only_in_env2,
    summary = data.frame(
      metric = c("Total Games", "Only in ENV1", "Only in ENV2"),
      env1_value = c(env1_count, nrow(only_in_env1), 0),
      env2_value = c(env2_count, 0, nrow(only_in_env2))
    )
  )
}
