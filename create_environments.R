#!/usr/bin/env Rscript

# Demo script for environment separation features
# This script demonstrates how to use the environment separation features

# Load required libraries
library(logger)

# 1. Set up the environments (only need to run once)
cat("Step 1: Setting up environments...\n")
source("src/utils/create_environments.R")
env_setup <- create_environments()
print(env_setup)

# 2. Run a simple test in development environment
cat("\nStep 2: Running in development environment...\n")
Sys.setenv(R_CONFIG_ACTIVE = "default")
Sys.setenv(TAR_PROJECT = "_targets_default")
dev_cfg <- config::get()
cat("Development configuration:\n")
print(dev_cfg)
cat("Using targets store:", Sys.getenv("TAR_PROJECT"), "\n")

# 3. Run a simple test in staging environment
cat("\nStep 3: Running in staging environment...\n")
Sys.setenv(R_CONFIG_ACTIVE = "staging")
Sys.setenv(TAR_PROJECT = "_targets_staging")
staging_cfg <- config::get()
cat("Staging configuration:\n")
print(staging_cfg)
cat("Using targets store:", Sys.getenv("TAR_PROJECT"), "\n")

# 4. Run a simple test in production environment
cat("\nStep 4: Running in production environment...\n")
Sys.setenv(R_CONFIG_ACTIVE = "production")
Sys.setenv(TAR_PROJECT = "_targets_production")
prod_cfg <- config::get()
cat("Production configuration:\n")
print(prod_cfg)
cat("Using targets store:", Sys.getenv("TAR_PROJECT"), "\n")

# 5. Compare environments (if data exists)
cat("\nStep 5: Comparing environments...\n")
tryCatch(
  {
    source("src/utils/compare_environments.R")
    cat("Comparing development and staging environments...\n")
    dev_vs_staging <- compare_game_data("default", "staging")
    print(dev_vs_staging$summary)
  },
  error = function(e) {
    cat("Error comparing environments:", e$message, "\n")
    cat(
      "This is expected if you haven't run the pipeline in both environments yet.\n"
    )
  }
)

# 6. Show how to promote data (dry run only)
cat("\nStep 6: Demonstrating data promotion (dry run)...\n")
tryCatch(
  {
    source("src/utils/promote_data.R")
    cat("Dry run of promoting data from staging to production...\n")
    promotion <- promote_data("staging", "production", dry_run = TRUE)
    cat("Objects that would be copied:\n")
    if (nrow(promotion$objects_to_copy) > 0) {
      print(promotion$objects_to_copy)
    } else {
      cat(
        "No objects found to copy. This is expected if you haven't run the pipeline in staging yet.\n"
      )
    }
  },
  error = function(e) {
    cat("Error demonstrating promotion:", e$message, "\n")
  }
)

# 7. Show next steps
cat("\nStep 7: Next steps...\n")
cat("To run the full pipeline in different environments:\n")
cat("  Development: Rscript run.R default\n")
cat("  Staging:     Rscript run.R staging\n")
cat("  Production:  Rscript run.R production\n\n")

cat("For more detailed examples, see src/utils/environment_guide.R\n")
