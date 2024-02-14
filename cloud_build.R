library(googleCloudRunner)
library(googleCloudStorageR)
library(googlePubsubR)

# setup
cr_project_set(Sys.getenv("GCS_PROJECT_ID"))
cr_region_set("europe-west1")
cr_email_set("435019619962-compute@developer.gserviceaccount.com")
googlePubsubR::ps_project_set(Sys.getenv("GCS_PROJECT_ID"))

# 
bs <- cr_buildstep_targets_multi(
        target_folder = "raw",
        task_image = "gcr.io/gcp-demos-411520/bgg_data"
)

# cr_build_targets(bs,
#                  target_folder = "raw",
#                  task_image = "gcr.io/gcp-demos-411520/bgg_data",
#                  execute = "now")

