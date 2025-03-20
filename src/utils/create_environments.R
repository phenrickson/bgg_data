#' Create development and staging environments in Google Cloud Storage
#'
#' This script creates the necessary buckets and BigQuery datasets for development and staging environments.
#' Run this script once to set up the infrastructure for environment separation.
#'
#' @param create_buckets Whether to create GCS buckets
#' @param create_datasets Whether to create BigQuery datasets
#' @return List with operation results
create_environments <- function(create_buckets = TRUE, create_datasets = TRUE) {
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
          existing_buckets <- googleCloudStorageR::gcs_list_buckets()

          # Create development bucket if it doesn't exist
          if (!dev_cfg$bucket %in% existing_buckets$name) {
            message(paste("Creating development bucket:", dev_cfg$bucket))
            dev_bucket <- googleCloudStorageR::gcs_create_bucket(
              dev_cfg$bucket,
              projectId = project_id,
              location = "us-central1", # Use same location as production
              storage_class = "STANDARD"
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
              staging_cfg$bucket,
              projectId = project_id,
              location = "us-central1",
              storage_class = "STANDARD"
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

  # Create BigQuery datasets
  if (create_datasets) {
    # Check if .secrets directory exists
    if (!dir.exists(".secrets") || !file.exists(".secrets/gcp_demos")) {
      message(".secrets/gcp_demos file not found. Skipping dataset creation.")
      results$datasets <- "skipped - no auth file"
    } else {
      # Try to authenticate
      tryCatch(
        {
          bigrquery::bq_auth(
            path = gargle::secret_decrypt_json(
              path = ".secrets/gcp_demos",
              key = "GCS_AUTH_KEY"
            )
          )

          # Project ID - get from config instead of environment variable
          project_id <- dev_cfg$project_id

          # Verify project ID is available
          if (is.null(project_id) || project_id == "") {
            stop("Project ID is not set in config.yml")
          }

          # Create development dataset
          message(paste("Creating development dataset:", dev_cfg$schema))
          tryCatch(
            {
              dev_dataset <- bigrquery::bq_dataset_create(
                x = bigrquery::bq_dataset(project_id, dev_cfg$schema),
                exists_ok = TRUE
              )
              results$dev_dataset <- "created or already exists"
            },
            error = function(e) {
              message(paste("Error creating development dataset:", e$message))
              results$dev_dataset <- paste("error:", e$message)
            }
          )

          # Create staging dataset
          message(paste("Creating staging dataset:", staging_cfg$schema))
          tryCatch(
            {
              staging_dataset <- bigrquery::bq_dataset_create(
                x = bigrquery::bq_dataset(project_id, staging_cfg$schema),
                exists_ok = TRUE
              )
              results$staging_dataset <- "created or already exists"
            },
            error = function(e) {
              message(paste("Error creating staging dataset:", e$message))
              results$staging_dataset <- paste("error:", e$message)
            }
          )
        },
        error = function(e) {
          message(paste("Error authenticating with BigQuery:", e$message))
          results$datasets <- paste("error:", e$message)
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
