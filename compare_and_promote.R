#!/usr/bin/env Rscript

# This script compares game data between environments and promotes data
# from dev to staging to prod.
#
# Usage:
#   Rscript compare_and_promote.R [--dev-to-staging] [--staging-to-prod] [--dry-run]
#
# Options:
#   --dev-to-staging     Promote data from dev to staging
#   --staging-to-prod    Promote data from staging to production
#   --dry-run            Show what would be copied without actually copying
#
# Examples:
#   Rscript compare_and_promote.R                     # Just compare, no promotion
#   Rscript compare_and_promote.R --dev-to-staging    # Promote from dev to staging
#   Rscript compare_and_promote.R --staging-to-prod   # Promote from staging to prod
#   Rscript compare_and_promote.R --dev-to-staging --staging-to-prod  # Promote both
#   Rscript compare_and_promote.R --dry-run --dev-to-staging          # Dry run

# Load required libraries and scripts
library(targets)
library(dplyr)
library(qs)
library(qs2)

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
promote_dev_to_staging <- "--dev-to-staging" %in% args
promote_staging_to_prod <- "--staging-to-prod" %in% args
dry_run <- "--dry-run" %in% args

# Print settings
cat("Settings:\n")
cat("  Promote DEV to STAGING:", promote_dev_to_staging, "\n")
cat("  Promote STAGING to PROD:", promote_staging_to_prod, "\n")
cat("  Dry run:", dry_run, "\n\n")

# src
targets::tar_source("src")

# Step 1: Compare dev (default) and staging
cat("\n=== Comparing DEV and STAGING ===\n")
dev_vs_staging <- compare_game_data("default", "staging")
print(dev_vs_staging$summary)

# Show details about differences
cat("\nGames only in DEV:", nrow(dev_vs_staging$only_in_env1), "\n")
if (nrow(dev_vs_staging$only_in_env1) > 0) {
    cat("Sample of games only in DEV:\n")
    print(head(dev_vs_staging$only_in_env1 %>% select(game_id, type), 5))
}

cat("\nGames only in STAGING:", nrow(dev_vs_staging$only_in_env2), "\n")
if (nrow(dev_vs_staging$only_in_env2) > 0) {
    cat("Sample of games only in STAGING:\n")
    print(head(dev_vs_staging$only_in_env2 %>% select(game_id, type), 5))
}

# Check if we should promote from dev to staging
if (promote_dev_to_staging) {
    cat("\nPromoting data from DEV to STAGING...\n")

    # First do a dry run to show what would be copied
    cat("Showing what will be copied:\n")
    promote_dry_run <- promote_data("default", "staging", dry_run = TRUE)
    print(promote_dry_run$objects_to_copy)

    if (!dry_run) {
        # Do the actual promotion
        cat("\nPerforming actual promotion...\n")
        promotion_result <- promote_data("default", "staging", dry_run = FALSE)
        cat("Promotion completed. Summary:\n")
        cat(paste(
            "Copied",
            nrow(promotion_result$copied_objects),
            "objects from DEV to STAGING\n"
        ))
    } else {
        cat("\nDry run - no data was copied.\n")
    }
} else {
    cat("\nSkipping promotion from DEV to STAGING.\n")
}

# Step 2: Compare staging and production
cat("\n=== Comparing STAGING and PRODUCTION ===\n")

# Check if staging has data
staging_cfg <- config::get(config = "staging")
googleCloudStorageR::gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))
googleCloudStorageR::gcs_global_bucket(bucket = staging_cfg$bucket)
staging_objects <- tryCatch(
    {
        googleCloudStorageR::gcs_list_objects(
            prefix = paste0(staging_cfg$prefix, "/objects/games")
        )
    },
    error = function(e) {
        return(NULL)
    }
)

if (is.null(staging_objects) || nrow(staging_objects) == 0) {
    cat(
        "No data found in STAGING environment. Skipping comparison with PRODUCTION.\n"
    )
    cat("You need to promote data from DEV to STAGING first.\n")

    # Exit if trying to promote from staging to prod but staging is empty
    if (promote_staging_to_prod) {
        cat(
            "ERROR: Cannot promote from STAGING to PRODUCTION because STAGING is empty.\n"
        )
        cat("Run with --dev-to-staging first.\n")
        quit(status = 1)
    }
} else {
    # Staging has data, proceed with comparison
    staging_vs_prod <- compare_game_data("staging", "production")
    print(staging_vs_prod$summary)

    # Show details about differences
    cat("\nGames only in STAGING:", nrow(staging_vs_prod$only_in_env1), "\n")
    if (nrow(staging_vs_prod$only_in_env1) > 0) {
        cat("Sample of games only in STAGING:\n")
        print(head(staging_vs_prod$only_in_env1 %>% select(game_id, type), 5))
    }

    cat("\nGames only in PRODUCTION:", nrow(staging_vs_prod$only_in_env2), "\n")
    if (nrow(staging_vs_prod$only_in_env2) > 0) {
        cat("Sample of games only in PRODUCTION:\n")
        print(head(staging_vs_prod$only_in_env2 %>% select(game_id, type), 5))
    }

    # Check if we should promote from staging to production
    if (promote_staging_to_prod) {
        cat("\nPromoting data from STAGING to PRODUCTION...\n")

        # First do a dry run to show what would be copied
        cat("Showing what will be copied:\n")
        promote_dry_run <- promote_data("staging", "production", dry_run = TRUE)
        print(promote_dry_run$objects_to_copy)

        if (!dry_run) {
            # Do the actual promotion
            cat("\nPerforming actual promotion...\n")
            promotion_result <- promote_data(
                "staging",
                "production",
                dry_run = FALSE
            )
            cat("Promotion completed. Summary:\n")
            cat(paste(
                "Copied",
                nrow(promotion_result$copied_objects),
                "objects from STAGING to PRODUCTION\n"
            ))
        } else {
            cat("\nDry run - no data was copied.\n")
        }
    } else {
        cat("\nSkipping promotion from STAGING to PRODUCTION.\n")
    }
}

cat("\nComparison and promotion process completed.\n")
