# Test script for optimized pipeline
library(targets)
library(tarchetypes)
library(dplyr)
library(purrr)
library(tidyr)
library(tibble)

# Set environment to default (which we've optimized)
Sys.setenv(R_CONFIG_ACTIVE = "default")

# Create a small test function to run a limited pipeline
test_pipeline <- function(num_ids = 1000) {
    # Source the API functions
    source("src/data/api.R")

    # Get configuration
    cfg <- config::get(config = "default")

    # Print the configuration
    cat("Using configuration:\n")
    cat("Workers:", cfg$workers, "\n")
    cat("Batch size:", cfg$batch_size, "\n")

    # Get real BGG IDs and sample from them
    cat("Fetching BGG IDs...\n")
    all_game_ids <- bggUtils::get_bgg_ids() |>
        filter(type == "boardgame")

    # Sample from the real IDs
    set.seed(123)
    sample_ids <- all_game_ids |>
        sample_n(num_ids)

    # Create batches
    batch_numbers <- sample_ids$id %>%
        create_batches(size = cfg$batch_size)

    # Add batch numbers to IDs
    req_game_batches <- sample_ids %>%
        add_column(batch = batch_numbers) %>%
        group_by(batch)

    # Print batch information
    cat("\nProcessing", length(unique(req_game_batches$batch)), "batches\n")

    # Time the API requests
    start_time <- Sys.time()

    # Process each batch
    results <- list()
    for (b in unique(req_game_batches$batch)) {
        cat("\nProcessing batch", b, "\n")
        batch_start <- Sys.time()

        # Get the batch
        batch <- req_game_batches %>% filter(batch == b)

        # Request the batch
        tryCatch(
            {
                result <- request_batch(batch, max_tries = 3)
                results[[length(results) + 1]] <- result
                cat("Batch", b, "completed successfully\n")
            },
            error = function(e) {
                cat("Error processing batch", b, ":", e$message, "\n")
            }
        )

        batch_end <- Sys.time()
        cat(
            "Batch",
            b,
            "took",
            difftime(batch_end, batch_start, units = "secs"),
            "seconds\n"
        )
    }

    end_time <- Sys.time()
    total_time <- difftime(end_time, start_time, units = "secs")

    cat("\nTotal processing time:", total_time, "seconds\n")
    cat(
        "Average time per batch:",
        total_time / length(unique(req_game_batches$batch)),
        "seconds\n"
    )

    return(results)
}

# Run the test with a small number of IDs
cat("Starting test pipeline with optimized settings...\n")
results <- test_pipeline(1000)

dplyr::bind_rows(results)
