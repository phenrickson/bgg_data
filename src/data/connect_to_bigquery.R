# connect to big query data warehouse

bigquery_authenticate <- function(path = ".secrets/gcp_demos",
                                  key = "GCS_AUTH_KEY") {
  bq_auth(
    path = gargle::secret_decrypt_json(
      path = path,
      key = key
    )
  )
}

bigquery_connect <- function(gcp_project_id = Sys.getenv("GCS_PROJECT_ID"),
                             bq_schema = "bgg",
                             ...) {
  bigquery_authenticate(...)

  bigrquery::dbConnect(
    bigrquery::bigquery(),
    project = gcp_project_id,
    dataset = bq_schema
  )
}

# # download table from bigquery
# bigquery_download_table =
#         function(my_query) {
#
#                 bigquery_connect()
#
#                 bq_table_download(
#                         bq_project_query(
#                                 bigquery_project_id(),
#                                 my_query)
#                 )
#         }
#
#
# # point to bigquery table
# bigquery_table = function(table) {
#
#         bigrquery::as_bq_table(list(project_id = bigquery_project_id(),
#                                     dataset_id = bigquery_dataset(),
#                                     table_id = table))
# }
