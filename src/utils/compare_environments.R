#' Try to deserialize data using either qs or qs2 package
#'
#' @param data Raw data to deserialize
#' @return Deserialized data
#' @keywords internal
try_deserialize <- function(data) {
  # Try qs2 first (newer format)
  tryCatch(
    {
      if (requireNamespace("qs2", quietly = TRUE)) {
        # Try qs2::qs_deserialize
        message("Trying qs2::qs_deserialize...")
        tryCatch(
          {
            return(qs2::qs_deserialize(data))
          },
          error = function(e) {
            message("qs2::qs_deserialize failed: ", e$message)

            # Try qs2::qd_deserialize
            message("Trying qs2::qd_deserialize...")
            tryCatch(
              {
                return(qs2::qd_deserialize(data))
              },
              error = function(e) {
                message("qs2::qd_deserialize failed: ", e$message)
                stop("Both qs2 deserialization methods failed")
              }
            )
          }
        )
      }

      # If qs2 is not available, fall back to qs
      message("qs2 not available, trying qs deserialization...")
      qs::qdeserialize(data)
    },
    error = function(e) {
      message("qs2 deserialization failed: ", e$message)
      # If qs2 fails, try qs
      tryCatch(
        {
          message("Trying qs deserialization...")
          qs::qdeserialize(data)
        },
        error = function(e2) {
          message("qs deserialization failed: ", e2$message)

          # Try to save the raw data to a file and then read it
          message("Trying to save and read data...")
          temp_file <- tempfile(fileext = ".rds")
          writeBin(data, temp_file)

          tryCatch(
            {
              # Try to read as RDS
              message("Trying to read as RDS...")
              result <- readRDS(temp_file)
              unlink(temp_file)
              return(result)
            },
            error = function(e3) {
              message("RDS read failed: ", e3$message)

              # Try qs2::qs_read
              message("Trying qs2::qs_read...")
              tryCatch(
                {
                  result <- qs2::qs_read(temp_file)
                  unlink(temp_file)
                  return(result)
                },
                error = function(e4) {
                  message("qs2::qs_read failed: ", e4$message)

                  # Try qs2::qd_read
                  message("Trying qs2::qd_read...")
                  tryCatch(
                    {
                      result <- qs2::qd_read(temp_file)
                      unlink(temp_file)
                      return(result)
                    },
                    error = function(e5) {
                      message("qs2::qd_read failed: ", e5$message)
                      unlink(temp_file)

                      # As a last resort, try to read the first few bytes to diagnose
                      message(
                        "First 20 bytes of data: ",
                        paste(
                          as.integer(data[1:min(20, length(data))]),
                          collapse = " "
                        )
                      )

                      stop(
                        "Failed to deserialize data with all available methods"
                      )
                    }
                  )
                }
              )
            }
          )
        }
      )
    }
  )
}

#' Load games data from a bucket
#'
#' @param bucket_name Name of the GCS bucket
#' @param prefix Prefix for the object (e.g., "dev")
#' @param generation Optional generation to load
#' @return Data frame of games or NULL if not found
#' @export
load_games_from_bucket <- function(
  bucket_name,
  prefix = "raw",
  generation = NULL
) {
  # Set bucket
  googleCloudStorageR::gcs_global_bucket(bucket = bucket_name)

  # Check if the object exists
  objects <- tryCatch(
    {
      googleCloudStorageR::gcs_list_objects(
        prefix = paste0(prefix, "/objects/games")
      )
    },
    error = function(e) {
      message("Error listing objects in bucket ", bucket_name, ": ", e$message)
      return(NULL)
    }
  )

  if (is.null(objects) || nrow(objects) == 0) {
    message(
      "No games data found in bucket ",
      bucket_name,
      " with prefix ",
      prefix
    )
    return(NULL)
  }

  # Get the object
  if (!is.null(generation)) {
    # Get specific generation
    data <- tryCatch(
      {
        googleCloudStorageR::gcs_get_object(
          paste0(prefix, "/objects/games"),
          generation = generation
        )
      },
      error = function(e) {
        message(
          "Error getting object with generation ",
          generation,
          ": ",
          e$message
        )
        return(NULL)
      }
    )
  } else {
    # Get latest
    data <- tryCatch(
      {
        googleCloudStorageR::gcs_get_object(
          paste0(prefix, "/objects/games")
        )
      },
      error = function(e) {
        message("Error getting latest object: ", e$message)
        return(NULL)
      }
    )
  }

  if (is.null(data)) {
    message("Failed to get games data from bucket ", bucket_name)
    return(NULL)
  }

  # Deserialize the data
  tryCatch(
    {
      games <- try_deserialize(data)
      return(games)
    },
    error = function(e) {
      message("Error deserializing data: ", e$message)
      return(NULL)
    }
  )
}

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
  env1_games <- load_games_from_bucket(cfg1$bucket, cfg1$prefix)

  if (is.null(env1_games)) {
    stop("Failed to load games data from ", env1, " environment")
  }

  # Get data from env2
  env2_games <- load_games_from_bucket(cfg2$bucket, cfg2$prefix, generation)

  if (is.null(env2_games)) {
    message("No games data found in ", env2, " environment")
    # Create an empty data frame with the same structure as env1_games
    env2_games <- env1_games[0, ]
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
