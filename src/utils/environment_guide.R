#' Environment Separation Guide
#'
#' This script demonstrates how to use the environment separation features.
#' It provides examples of running the pipeline in different environments,
#' comparing data between environments, and promoting data from one environment to another.
#'

#' Step 1: Set up the environments
#' ------------------------------
#' Before using multiple environments, you need to set up the infrastructure.
#' Run this once to create the necessary buckets and datasets:
#'
#' ```r
#' source("src/utils/create_environments.R")
#' create_environments()
#' ```

#' Step 2: Run the pipeline in development environment
#' -------------------------------------------------
#' To run the pipeline in the development environment:
#'
#' ```r
#' # From command line
#' Rscript run.R default
#'
#' # Or from R
#' Sys.setenv(R_CONFIG_ACTIVE = "default")
#' Sys.setenv(TAR_PROJECT = "_targets_default")
#' source("run.R")
#' ```

#' Step 3: Test changes in staging environment
#' ------------------------------------------
#' After testing in development, promote to staging:
#'
#' ```r
#' # From command line
#' Rscript run.R staging
#'
#' # Or from R
#' Sys.setenv(R_CONFIG_ACTIVE = "staging")
#' Sys.setenv(TAR_PROJECT = "_targets_staging")
#' source("run.R")
#' ```

#' Step 4: Compare environments
#' ---------------------------
#' To compare data between environments:
#'
#' ```r
#' source("src/utils/compare_environments.R")
#'
#' # Compare development and staging
#' dev_vs_staging <- compare_game_data("default", "staging")
#' print(dev_vs_staging$summary)
#'
#' # Compare staging and production
#' staging_vs_prod <- compare_game_data("staging", "production")
#' print(staging_vs_prod$summary)
#'
#' # Look at games only in one environment
#' View(staging_vs_prod$only_in_env1)
#' ```

#' Step 5: Promote data between environments
#' ---------------------------------------
#' To promote data from one environment to another:
#'
#' ```r
#' source("src/utils/promote_data.R")
#'
#' # First do a dry run to see what would be copied
#' promote_dry_run <- promote_data("staging", "production", dry_run = TRUE)
#' print(promote_dry_run$objects_to_copy)
#'
#' # Then do the actual promotion
#' promotion_result <- promote_data("staging", "production", dry_run = FALSE)
#' ```

#' Development Workflow
#' ------------------
#' 1. Make changes in a feature branch
#' 2. Test in development environment: `Rscript run.R default`
#' 3. Compare with production: `compare_game_data("default", "production")`
#' 4. Merge to staging branch
#' 5. Test in staging environment: `Rscript run.R staging`
#' 6. Compare with production: `compare_game_data("staging", "production")`
#' 7. Merge to main branch
#' 8. Run in production: `Rscript run.R production`
#'
#' Alternatively, you can promote data directly:
#' - From development to staging: `promote_data("default", "staging", dry_run = FALSE)`
#' - From staging to production: `promote_data("staging", "production", dry_run = FALSE)`

#' Environment-Specific Targets Cache
#' --------------------------------
#' The pipeline uses separate target caches for each environment:
#' - Development: `_targets_default/`
#' - Staging: `_targets_staging/`
#' - Production: `_targets_production/`
#'
#' This allows you to switch between environments without rebuilding everything.
