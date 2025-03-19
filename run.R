#!/usr/bin/env Rscript

# This is a helper script to run the pipeline.
# Choose how to execute the pipeline below.
# See https://books.ropensci.org/targets/hpc.html
# to learn about your options.

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
env <- if (length(args) > 0) args[1] else "default"

# Set environment variables
Sys.setenv(R_CONFIG_ACTIVE = env)
Sys.setenv(TAR_PROJECT = paste0("_targets_", env))

# Log which environment we're using
cat(paste0("Running pipeline in ", env, " environment\n"))
cat(paste0("Using targets store: ", Sys.getenv("TAR_PROJECT"), "\n"))

# Run the pipeline
targets::tar_make(reporter = "summary")

# Show results
targets::tar_glimpse()
