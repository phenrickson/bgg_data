#' Create batches out of game IDs
#'
#' @param x Vector of game IDs
#' @param size Batch size
#' @return Vector of batch numbers
#' @export
create_batches <- function(x, size = 250) {
  ceiling(seq_along(x) / size)
}

#' Create custom error class for BGG API errors
#'
#' @param type Error type
#' @param message Error message
#' @param details Additional error details
#' @return Error object
create_bgg_error <- function(type, message, details = list()) {
  structure(
    list(
      type = type,
      message = message,
      details = details,
      timestamp = Sys.time()
    ),
    class = c(
      paste0("bgg_", type, "_error"),
      "bgg_error",
      "error",
      "condition"
    )
  )
}

#' Create API error
#'
#' @param message Error message
#' @param response API response
#' @param request API request
#' @return API error object
api_error <- function(message, response = NULL, request = NULL) {
  create_bgg_error(
    "api",
    message,
    list(
      response = response,
      request = request,
      status_code = if (!is.null(response)) {
        response$status_code
      } else {
        NULL
      }
    )
  )
}

#' Request a batch of games
#'
#' @param games_batch Batch of games to request
#' @param max_tries Maximum number of retry attempts
#' @return Tibble of game data
#' @export
request_batch <- function(games_batch, max_tries = 5) {
  b <- unique(games_batch$batch)

  message(paste("batch", b, sep = ": "))

  # Get environment config
  env <- Sys.getenv("R_CONFIG_ACTIVE", "default")
  cfg <- config::get(config = env)
  
  # Track retry attempts for this batch
  attempt <- 1
  max_batch_retries <- 3
  
  while (attempt <= max_batch_retries) {
    tryCatch(
      {
        result <- games_batch |>
          pull(id) |>
          request_games(max_tries = max_tries)

        # Log success
        message(paste("Successfully processed batch", b))

        return(result)
      },
      error = function(e) {
        # Log detailed error
        message(paste(
          "Failed to process batch",
          b,
          "attempt", attempt, "of", max_batch_retries,
          ":",
          e$message
        ))

        # Determine if we should retry or fail
        if (
          inherits(e, "bgg_api_error") &&
            !is.null(e$details$status_code) &&
            e$details$status_code %in%
              c(429, 503, 504)
        ) {
          # For rate limiting errors, add an increasing delay before retrying
          if (e$details$status_code == 429) {
            retry_delay <- 30 * attempt  # Increasing delay: 30s, 60s, 90s
            message(paste(
              "Rate limit hit (429). Waiting", 
              retry_delay, 
              "seconds before retry..."
            ))
            Sys.sleep(retry_delay)
          } else {
            # For other server errors, use a shorter delay
            message("Server error. Waiting 10 seconds before retry...")
            Sys.sleep(10)
          }
          
          # Signal to retry by returning NULL
          return(NULL)
        } else {
          # Re-throw error for critical failures
          stop(e)
        }
      }
    ) -> result
    
    # If we got a result (not NULL), break the loop
    if (!is.null(result)) {
      return(result)
    }
    
    # Increment attempt counter
    attempt <- attempt + 1
  }
  
  # If we've exhausted all retries, return empty tibble
  message(paste(
    "Exhausted all", max_batch_retries, "retries for batch", b,
    "- returning empty result"
  ))
  return(tibble::tibble())
}

#' Request games from BGG API
#'
#' @param game_ids Vector of game IDs
#' @param max_tries Maximum number of retry attempts
#' @return Tibble of game data
#' @export
request_games <- function(game_ids, max_tries = 5) {
  tryCatch(
    {
      # submit request
      resp <- game_ids |>
        request_bgg_api(max_tries = max_tries)

      # parse response
      xml <- resp |>
        parse_bgg_xml()

      # tidy xml
      xml |>
        tidy_bgg_xml()
    },
    error = function(e) {
      # Wrap in our custom error type if it's not already
      if (!inherits(e, "bgg_error")) {
        stop(create_bgg_error(
          "processing",
          paste(
            "Error processing games:",
            e$message
          )
        ))
      } else {
        stop(e)
      }
    }
  )
}

#' Request data from BGG API
#'
#' @param game_ids Vector of game IDs
#' @param max_tries Maximum number of retry attempts
#' @return API response
#' @export
request_bgg_api <- function(game_ids, max_tries = 5) {
  # if duplicated
  if (identical(game_ids, unique(game_ids)) == F) {
    # warning
    warning(
      "duplicated game ids in request. submitting only unique game ids"
    )
    # deduplicate
    game_ids <- unique(game_ids)
  }

  # Validate input
  if (length(game_ids) == 0) {
    stop(api_error("No game IDs provided"))
  }

  # Create URL
  url <- paste(
    "https://www.boardgamegeek.com/xmlapi2/thing?id=",
    paste(game_ids, collapse = ","),
    "&stats=1",
    sep = ""
  )

  # Get number of workers from config to adjust throttling
  env <- Sys.getenv("R_CONFIG_ACTIVE", "default")
  cfg <- config::get(config = env)
  workers <- cfg$workers

  # Calculate a more conservative throttle rate based on workers
  # Default to 2 requests per minute per worker
  throttle_rate <- 2 / (60 * workers)

  message(paste(
    "Using throttle rate of",
    round(1 / throttle_rate),
    "seconds between requests"
  ))

  tryCatch(
    {
      # request to bgg api
      req <- httr2::request(url)

      # submit request and get response
      resp <-
        req %>%
        # throttle rate of request - more conservative based on workers
        httr2::req_throttle(throttle_rate) %>%
        # set policies for retry with exponential backoff
        httr2::req_retry(
          max_tries = max_tries,
          backoff = ~ 10 * 1.5^.x, # Exponential backoff starting at 10 seconds
          # Specifically handle 429 errors with longer delays
          is_transient = function(resp) {
            status <- httr2::resp_status(resp)
            if (status == 429) {
              # For 429, add extra sleep time
              Sys.sleep(15)
              return(TRUE)
            }
            status %in% c(429, 503, 504, 500)
          }
        ) %>%
        # perform
        httr2::req_perform()

      # Check for successful status code
      if (resp$status_code != 200) {
        stop(api_error(
          paste(
            "API request failed with status code:",
            resp$status_code
          ),
          response = resp,
          request = req
        ))
      }

      return(resp)
    },
    error = function(e) {
      # Check if it's already our custom error
      if (inherits(e, "bgg_error")) {
        stop(e)
      } else {
        # Wrap in our custom error
        stop(api_error(
          paste("API request failed:", e$message),
          request = list(url = url)
        ))
      }
    }
  )
}

#' Parse BGG XML response
#'
#' @param resp API response
#' @return Parsed XML
#' @export
parse_bgg_xml <- function(resp) {
  tryCatch(
    {
      # check status
      if (resp$status_code == 200) {
        message("request status ok...")
      } else {
        stop(api_error(
          paste(
            "request status not ok:",
            resp$status_code
          ),
          response = resp
        ))
      }

      # parse
      result <- bggUtils:::parse_bgg_api(resp)

      # Validate result
      if (is.null(result) || length(result) == 0) {
        stop(create_bgg_error(
          "parsing",
          "XML parsing returned empty result",
          list(response = resp)
        ))
      }

      return(result)
    },
    error = function(e) {
      # Check if it's already our custom error
      if (inherits(e, "bgg_error")) {
        stop(e)
      } else {
        # Wrap in our custom error
        stop(create_bgg_error(
          "parsing",
          paste("XML parsing error:", e$message),
          list(response = resp)
        ))
      }
    }
  )
}

#' Tidy BGG XML data
#'
#' @param xml Parsed XML data
#' @return Tibble of game data
#' @export
tidy_bgg_xml <- function(xml) {
  tryCatch(
    {
      # Validate input
      if (is.null(xml) || length(xml) == 0) {
        stop(create_bgg_error(
          "transformation",
          "Empty XML data provided for transformation"
        ))
      }

      # extract data
      game_data <- furrr::future_map(xml, function(item) {
        tryCatch(
          bggUtils:::extract_bgg_data(item),
          error = function(e) {
            stop(create_bgg_error(
              "transformation",
              paste(
                "Error extracting game data:",
                e$message
              ),
              list(item = item)
            ))
          }
        )
      })

      # Check if any game data was extracted
      if (length(game_data) == 0) {
        stop(create_bgg_error(
          "transformation",
          "No game data could be extracted from XML"
        ))
      }

      # convert to to data frame
      game_info <- tryCatch(
        {
          lapply(
            game_data,
            "[",
            c(
              "type",
              "ids",
              "yearpublished",
              "minplayers",
              "maxplayers",
              "playingtime",
              "minplaytime",
              "maxplaytime",
              "minage",
              "description",
              "thumbnail",
              "image"
            )
          ) %>%
            bind_rows() %>%
            unnest(
              everything(),
              keep_empty = T
            ) %>%
            nest(
              info = c(
                yearpublished,
                minplayers,
                maxplayers,
                playingtime,
                minplaytime,
                maxplaytime,
                minage,
                description,
                thumbnail,
                image
              )
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error processing game info:",
              e$message
            )
          ))
        }
      )

      # game names
      game_names <- tryCatch(
        {
          lapply(game_data, "[[", "names") %>%
            bind_rows(
              .,
              .id = "game_id"
            ) %>%
            as_tibble() %>%
            mutate(
              game_id = as.integer(
                game_id
              ),
              sortindex = as.integer(
                sortindex
              )
            ) %>%
            nest(
              names = one_of(c(
                "type",
                "sortindex",
                "value"
              ))
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error processing game names:",
              e$message
            )
          ))
        }
      )

      # game links
      game_links <- tryCatch(
        {
          lapply(game_data, "[[", "links") %>%
            bind_rows(
              .,
              .id = "game_id"
            ) %>%
            mutate(
              game_id = as.integer(
                game_id
              ),
              id = as.integer(id)
            ) %>%
            nest(
              links = one_of(
                "type",
                "id",
                "value"
              )
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error processing game links:",
              e$message
            )
          ))
        }
      )

      # game statistics
      game_statistics <- tryCatch(
        {
          lapply(
            game_data,
            "[[",
            "statistics"
          ) %>%
            bind_rows(
              .,
              .id = "game_id"
            ) %>%
            as_tibble() %>%
            mutate_at(
              c(
                "game_id",
                "usersrated",
                "median",
                "owned",
                "trading",
                "wanting",
                "wishing",
                "numcomments",
                "numweights"
              ),
              as.integer
            ) %>%
            mutate_at(
              c(
                "averageweight",
                "average",
                "bayesaverage",
                "stddev"
              ),
              as.numeric
            ) %>%
            nest(
              statistics = c(
                averageweight,
                usersrated,
                average,
                bayesaverage,
                stddev,
                median,
                owned,
                trading,
                wanting,
                wishing,
                numcomments,
                numweights
              )
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error processing game statistics:",
              e$message
            )
          ))
        }
      )

      # game ranks
      game_ranks <- tryCatch(
        {
          lapply(game_data, "[[", "ranks") %>%
            bind_rows(
              .,
              .id = "game_id"
            ) %>%
            mutate_at(
              c(
                "game_id",
                "id"
              ),
              as.integer
            ) %>%
            nest(
              ranks = c(
                type,
                id,
                name,
                friendlyname,
                value,
                bayesaverage
              )
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error processing game ranks:",
              e$message
            )
          ))
        }
      )

      # game polls
      game_polls <- tryCatch(
        {
          lapply(game_data, "[[", "polls") %>%
            bind_rows(
              .,
              .id = "game_id"
            ) %>%
            mutate(
              game_id = as.integer(
                game_id
              ),
              numvotes = as.integer(
                numvotes
              )
            ) %>%
            nest(
              polls = c(
                value,
                numvotes,
                numplayers
              )
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error processing game polls:",
              e$message
            )
          ))
        }
      )

      # join up
      tidy_bgg_data <- tryCatch(
        {
          game_info %>%
            left_join(
              .,
              game_names,
              by = c("game_id")
            ) %>%
            left_join(
              .,
              game_links,
              by = c("game_id")
            ) %>%
            left_join(
              .,
              game_statistics,
              by = c("game_id")
            ) %>%
            left_join(
              .,
              game_ranks,
              by = c("game_id")
            ) %>%
            left_join(
              .,
              game_polls,
              by = c("game_id")
            )
        },
        error = function(e) {
          stop(create_bgg_error(
            "transformation",
            paste(
              "Error joining game data:",
              e$message
            )
          ))
        }
      )

      # Validate output
      if (nrow(tidy_bgg_data) == 0) {
        stop(create_bgg_error(
          "transformation",
          "Transformation resulted in empty data frame"
        ))
      }

      return(tidy_bgg_data)
    },
    error = function(e) {
      # Check if it's already our custom error
      if (inherits(e, "bgg_error")) {
        stop(e)
      } else {
        # Wrap in our custom error
        stop(create_bgg_error(
          "transformation",
          paste(
            "Error transforming XML data:",
            e$message
          )
        ))
      }
    }
  )
}

#' Get ranked games
#'
#' @param games Tibble of games
#' @return Tibble of ranked games
#' @export
get_ranked_games <- function(games) {
  tryCatch(
    {
      # Validate input
      if (is.null(games) || nrow(games) == 0) {
        stop(create_bgg_error(
          "processing",
          "Empty games data provided"
        ))
      }

      # Get ranked games
      ranked <- tryCatch(
        {
          games |>
            bggUtils:::unnest_outcomes() |>
            filter(!is.na(bayesaverage)) |>
            arrange(desc(bayesaverage))
        },
        error = function(e) {
          stop(create_bgg_error(
            "processing",
            paste(
              "Error unnesting outcomes:",
              e$message
            )
          ))
        }
      )

      # Check if any ranked games were found
      if (nrow(ranked) == 0) {
        message("No ranked games found")
        return(tibble::tibble())
      }

      # Join with original games data
      result <- tryCatch(
        {
          ranked |>
            select(game_id) |>
            inner_join(games)
        },
        error = function(e) {
          stop(create_bgg_error(
            "processing",
            paste(
              "Error joining ranked games:",
              e$message
            )
          ))
        }
      )

      return(result)
    },
    error = function(e) {
      # Check if it's already our custom error
      if (inherits(e, "bgg_error")) {
        stop(e)
      } else {
        # Wrap in our custom error
        stop(create_bgg_error(
          "processing",
          paste(
            "Error getting ranked games:",
            e$message
          )
        ))
      }
    }
  )
}


#' Write table to GCP
#'
#' @param name Table name
#' @param ... Additional arguments passed to dbWriteTable
#' @return Table name
#' @export
write_table <- function(name, ...) {
  tryCatch(
    {
      message(glue::glue("writing {name}..."))

      # Validate connection
      args <- list(...)
      if (
        length(args) == 0 ||
          !inherits(args[[1]], "DBIConnection")
      ) {
        stop(create_bgg_error(
          "database",
          "Invalid database connection"
        ))
      }

      # Validate value
      value_arg <- which(names(args) == "value")
      if (
        length(value_arg) == 0 ||
          !is.data.frame(args[[value_arg]])
      ) {
        stop(create_bgg_error(
          "database",
          "Invalid data for database write"
        ))
      }

      # Write to database
      result <- tryCatch(
        {
          DBI::dbWriteTable(
            ...,
            name = name
          )
          TRUE
        },
        error = function(e) {
          stop(create_bgg_error(
            "database",
            paste(
              "Error writing to database:",
              e$message
            )
          ))
        }
      )

      message("done.")
      return(name)
    },
    error = function(e) {
      # Check if it's already our custom error
      if (inherits(e, "bgg_error")) {
        stop(e)
      } else {
        # Wrap in our custom error
        stop(create_bgg_error(
          "database",
          paste("Error writing table:", e$message)
        ))
      }
    }
  )
}
