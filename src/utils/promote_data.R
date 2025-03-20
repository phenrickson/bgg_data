#' Promote data from one environment to another
#'
#' @param from_env Source environment (e.g., "staging")
#' @param to_env Target environment (e.g., "production")
#' @param dry_run If TRUE, just show what would be copied without doing it
#' @return List with operation results
promote_data <- function(from_env, to_env, dry_run = TRUE) {
  # Get config for both environments
  from_cfg <- config::get(config = from_env)
  to_cfg <- config::get(config = to_env)

  # Set up GCS
  googleCloudStorageR::gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))

  # List objects in source bucket
  googleCloudStorageR::gcs_global_bucket(bucket = from_cfg$bucket)
  objects <- googleCloudStorageR::gcs_list_objects(
    prefix = from_cfg$prefix
  )

  if (dry_run) {
    return(list(
      from_env = from_env,
      to_env = to_env,
      objects_to_copy = objects,
      message = "Dry run - no data was copied"
    ))
  }

  # Copy each object
  results <- list()
  for (i in 1:nrow(objects)) {
    obj <- objects$name[i]

    # Get object from source
    temp_file <- tempfile()
    success <- FALSE

    # Try with the full object name first
    tryCatch(
      {
        googleCloudStorageR::gcs_get_object(
          object_name = obj,
          saveToDisk = temp_file
        )
        success <- TRUE
      },
      error = function(e) {
        message("Error downloading object with full name: ", e$message)
      }
    )

    # If that failed, try without the prefix
    if (!success) {
      message("Trying to download without prefix...")
      temp_file <- tempfile() # Use a new temp file

      # Get just the object name without the prefix
      obj_name <- gsub(paste0("^", from_cfg$prefix, "/"), "", obj)

      tryCatch(
        {
          googleCloudStorageR::gcs_get_object(
            object_name = obj_name,
            saveToDisk = temp_file
          )
          success <- TRUE
        },
        error = function(e) {
          message("Error downloading object without prefix: ", e$message)
        }
      )
    }

    # If both attempts failed, skip this object
    if (!success) {
      message("Failed to download object: ", obj)
      next
    }

    # Upload to destination
    googleCloudStorageR::gcs_global_bucket(bucket = to_cfg$bucket)
    new_obj_name <- gsub(
      pattern = paste0("^", from_cfg$prefix),
      replacement = to_cfg$prefix,
      x = obj
    )

    # Check if object exists and delete it if it does
    tryCatch(
      {
        # Try to delete the object if it exists
        googleCloudStorageR::gcs_delete_object(new_obj_name)
        message("Deleted existing object: ", new_obj_name)
      },
      error = function(e) {
        # Object doesn't exist or other error, just continue
        message("Object doesn't exist or couldn't be deleted: ", e$message)
      }
    )

    # Upload the new object
    result <- googleCloudStorageR::gcs_upload(
      file = temp_file,
      name = new_obj_name
    )

    results[[obj]] <- result
    unlink(temp_file)
  }

  return(list(
    from_env = from_env,
    to_env = to_env,
    copied_objects = objects,
    results = results
  ))
}
