#!/usr/bin/env Rscript

# This script migrates data from old prefixes to the new "raw" prefix
# It copies data within each bucket from the old prefix to the new prefix

# Load required libraries
library(googleCloudStorageR)

# Set up GCS authentication
gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))

# Function to copy objects within a bucket from one prefix to another
copy_prefix <- function(bucket_name, old_prefix, new_prefix) {
    cat(paste0(
        "Copying objects in bucket '",
        bucket_name,
        "' from prefix '",
        old_prefix,
        "' to '",
        new_prefix,
        "'\n"
    ))

    # Set the bucket
    gcs_global_bucket(bucket = bucket_name)

    # List objects with the old prefix
    objects <- tryCatch(
        {
            gcs_list_objects(prefix = old_prefix)
        },
        error = function(e) {
            cat(paste0("Error listing objects: ", e$message, "\n"))
            return(NULL)
        }
    )

    if (is.null(objects) || nrow(objects) == 0) {
        cat(paste0("No objects found with prefix '", old_prefix, "'\n"))
        return(FALSE)
    }

    cat(paste0("Found ", nrow(objects), " objects to copy\n"))

    # Copy each object
    for (i in 1:nrow(objects)) {
        obj <- objects$name[i]
        cat(paste0("Copying object: ", obj, "\n"))

        # Download the object
        temp_file <- tempfile()
        tryCatch(
            {
                gcs_get_object(object_name = obj, saveToDisk = temp_file)
            },
            error = function(e) {
                cat(paste0("Error downloading object: ", e$message, "\n"))
                return(FALSE)
            }
        )

        # Create the new object name with the new prefix
        new_obj_name <- gsub(paste0("^", old_prefix), new_prefix, obj)
        cat(paste0("New object name: ", new_obj_name, "\n"))

        # Check if the new object already exists and delete it if it does
        tryCatch(
            {
                gcs_delete_object(new_obj_name)
                cat(paste0("Deleted existing object: ", new_obj_name, "\n"))
            },
            error = function(e) {
                # Object doesn't exist or other error, just continue
                cat(paste0(
                    "Object doesn't exist or couldn't be deleted: ",
                    e$message,
                    "\n"
                ))
            }
        )

        # Upload with the new name
        tryCatch(
            {
                gcs_upload(file = temp_file, name = new_obj_name)
                cat(paste0("Successfully copied to: ", new_obj_name, "\n"))
            },
            error = function(e) {
                cat(paste0("Error uploading object: ", e$message, "\n"))
                return(FALSE)
            }
        )

        # Clean up
        unlink(temp_file)
    }

    cat(paste0(
        "Successfully copied all objects from '",
        old_prefix,
        "' to '",
        new_prefix,
        "'\n"
    ))
    return(TRUE)
}

# Migrate data in the dev bucket
dev_result <- copy_prefix("bgg_data_dev", "dev/objects", "raw/objects")
cat(paste0(
    "Dev migration result: ",
    if (dev_result) "SUCCESS" else "FAILURE",
    "\n\n"
))

# Migrate data in the staging bucket
staging_result <- copy_prefix(
    "bgg_data_staging",
    "staging/objects",
    "raw/objects"
)
cat(paste0(
    "Staging migration result: ",
    if (staging_result) "SUCCESS" else "FAILURE",
    "\n\n"
))

# No need to migrate production as it already uses "raw" prefix

cat("Migration complete\n")
