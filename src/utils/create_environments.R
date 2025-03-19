#' Create development and staging environments in Google Cloud Storage
#'
#' This script creates the necessary buckets and BigQuery datasets for development and staging environments.
#' Run this script once to set up the infrastructure for environment separation.
#'
#' @param create_buckets Whether to create GCS buckets
#' @return List with operation results
create_environments <- function(create_buckets = TRUE) {
  # Get configurations
  dev_cfg <- config::get(config = "default")
  staging_cfg <- config::get(config = "staging")

  results <- list()

  # Create GCS buckets
  if (create_buckets) {
    # Check if auth file exists
    auth_file <- Sys.getenv("GCS_AUTH_FILE")
    if (auth_file == "") {
      message(
        "GCS_AUTH_FILE environment variable not set. Skipping bucket creation."
      )
      results$buckets <- "skipped - no auth file"
    } else {
      # Authenticate
      tryCatch(
        {
          # Authenticate to GCP (same approach as in _targets.R)
          googleCloudStorageR::gcs_auth(json_file = auth_file)

          # Get project ID from config
          project_id <- dev_cfg$project_id

          # Get existing buckets
          existing_buckets <- googleCloudStorageR::gcs_list_buckets(
            projectId = project_id
          )

          # Create development bucket if it doesn't exist
          if (!dev_cfg$bucket %in% existing_buckets$name) {
            message(paste("Creating development bucket:", dev_cfg$bucket))
            dev_bucket <- googleCloudStorageR::gcs_create_bucket(
              name = dev_cfg$bucket,
              projectId = project_id,
              storageClass = "MULTI_REGIONAL"
            )
            results$dev_bucket <- dev_bucket
          } else {
            message(paste("Development bucket already exists:", dev_cfg$bucket))
            results$dev_bucket <- "already exists"
          }

          # Create staging bucket if it doesn't exist
          if (!staging_cfg$bucket %in% existing_buckets$name) {
            message(paste("Creating staging bucket:", staging_cfg$bucket))
            staging_bucket <- googleCloudStorageR::gcs_create_bucket(
              name = staging_cfg$bucket,
              projectId = project_id,
              storageClass = "MULTI_REGIONAL"
            )
            results$staging_bucket <- staging_bucket
          } else {
            message(paste("Staging bucket already exists:", staging_cfg$bucket))
            results$staging_bucket <- "already exists"
          }
        },
        error = function(e) {
          message(paste("Error authenticating with GCS:", e$message))
          results$buckets <- paste("error:", e$message)
        }
      )
    }
  }

  # Create logs directory
  if (!dir.exists("logs")) {
    dir.create("logs")
    results$logs_dir <- "created"
  } else {
    results$logs_dir <- "already exists"
  }

  # Create targets workspaces directory
  if (!dir.exists(".targets/workspaces")) {
    dir.create(".targets/workspaces", recursive = TRUE)
    results$workspaces_dir <- "created"
  } else {
    results$workspaces_dir <- "already exists"
  }

  return(results)
}

# Example usage:
# create_environments()
