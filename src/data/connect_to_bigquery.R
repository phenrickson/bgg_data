# connect to big query data warehouse

# project id
#project_id <- 'gcp-analytics-326219'

# set bq project id
bigquery_project_id = function() {
        'gcp-analytics-326219'
}

# set bq dataset
bigquery_dataset = function() {
        "bgg"
}


# connect to specified data on gcp
bigquery_connect = function(my_project_id = bigquery_project_id(),
                            my_email = 'phil.henrickson@aebs.com',
                            my_dataset = bigquery_dataset()) {
        
        require(bigrquery)
        
        # authenticate via email
        bigrquery::bq_auth(email = my_email)
        
        # establish connection
        bigrquery::dbConnect(
                bigrquery::bigquery(),
                project = my_project_id,
                dataset = my_dataset
        )
}

# download table from bigquery
bigquery_download_table = 
        function(my_query) {
                
                bigquery_connect()
                
                bq_table_download(
                        bq_project_query(
                                bigquery_project_id(),
                                my_query)
                )
        } 

# authenticate; default to using my email
bigquery_authenticate = function(email = 'phil.henrickson@aebs.com') {
        bigrquery::bq_auth(email = email)
}

# point to bigquery table
bigquery_table = function(table) {
        
        bigrquery::as_bq_table(list(project_id = bigquery_project_id(),
                                    dataset_id = bigquery_dataset(),
                                    table_id = table))
}

# confirm table exists on bigquery
bigquery_exists = function(bq_table) {
        
        # confirm table exists
        if (bigrquery::bq_table_exists(bq_table) == T) {
                message("writing to...", print(bq_table))
                bq_table
        }  else {
                stop("bigquery table does not exist!")
        }
        
}
