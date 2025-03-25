#!/usr/bin/env Rscript

# This is a helper script to run the pipeline.
# Choose how to execute the pipeline below.
# See https://books.ropensci.org/targets/hpc.html
# to learn about your options.

# Load required packages
library(targets)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
env <- if (length(args) > 0) args[1] else "default"

# Set environment variables
Sys.setenv(R_CONFIG_ACTIVE = env)
Sys.setenv(TAR_PROJECT = paste0("_targets_", env))

# Set up logging
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- paste0("logs/run_pipeline_", env, "_", timestamp, ".log")

# Function to write to log file
write_log <- function(message) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    log_message <- paste0("[", timestamp, "] ", message, "\n")
    cat(log_message, file = log_file, append = TRUE)
    # Also print to console
    cat(message, "\n")
}

# Create log directory if it doesn't exist
if (!dir.exists("logs")) {
    dir.create("logs", recursive = TRUE)
}

# Log which environment we're using
write_log(paste0("Running pipeline in ", env, " environment"))
write_log(paste0("Using targets store: ", Sys.getenv("TAR_PROJECT")))
write_log("Starting pipeline execution")

# Create a custom reporter function
custom_reporter <- function(msg) {
    # Extract target name and status from message if possible
    if (grepl("target", msg, ignore.case = TRUE)) {
        write_log(msg)
    }
}

# Set up a sink to capture all output
sink_file <- paste0("logs/run_pipeline_sink_", env, "_", timestamp, ".log")
sink(sink_file, split = TRUE)

# Run tar_make with verbose output to capture more information
options(tar_verbose = TRUE)

# Add error handling
tryCatch(
    {
        result <- tar_make(reporter = "verbose")
    },
    error = function(e) {
        # Log the error
        write_log(paste0("ERROR: ", conditionMessage(e)))

        # Check if it's an HTTP error
        if (grepl("HTTP", conditionMessage(e))) {
            write_log(paste0("HTTP ERROR DETECTED: ", conditionMessage(e)))
        }

        # Return the error message
        return(list(error = conditionMessage(e)))
    }
)

# Close the sink
sink()

# Check if there was an error
if (exists("result") && is.list(result) && !is.null(result$error)) {
    write_log(paste0("Pipeline execution failed with error: ", result$error))
}

# Read the sink file and extract relevant information
sink_content <- readLines(sink_file)
for (line in sink_content) {
    if (grepl("target|pipeline", line, ignore.case = TRUE)) {
        write_log(paste0("Pipeline output: ", line))
    }
}

write_log("Pipeline execution completed")

# Get progress information and log it
progress <- tar_progress()
if (nrow(progress) > 0) {
    write_log(sprintf("Pipeline completed with %d targets", nrow(progress)))
    for (i in 1:nrow(progress)) {
        target_name <- progress$name[i]
        target_status <- progress$progress[i]
        target_time <- progress$seconds[i]
        write_log(sprintf(
            "Target '%s' status: '%s', time: %.2f seconds",
            target_name,
            target_status,
            target_time
        ))
    }
} else {
    write_log("No targets were executed")
}

# Print summary to console as well
cat(paste0("Pipeline execution completed. See log file: ", log_file, "\n"))
