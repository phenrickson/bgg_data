# Load required packages
suppressPackageStartupMessages({
    library(qs2)
    library(dplyr)
    library(purrr)
    library(tidyr)
    library(jsonlite)
    library(nanoparquet)
    library(targets)
    library(googleCloudStorageR)
    library(config)
})

# upload function
# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)
config_env <- if (length(args) > 0) args[1] else "default"

# Function to upload Parquet file to Google Cloud Storage
upload_to_gcs = function(
    file = "data/games.parquet",
    environment = config_env,
    destination_path = "processed/games.parquet"
) {
    # Load configuration
    cfg <- config::get(config = environment)

    # Authenticate to GCS
    googleCloudStorageR::gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))

    # Set the bucket
    googleCloudStorageR::gcs_global_bucket(cfg$bucket)

    # Upload the file
    result <- googleCloudStorageR::gcs_upload(
        file,
        name = destination_path
    )

    cat("Uploaded", file, "to", cfg$bucket, "at", destination_path, "\n")
    return(result)
}

# Preprocessing functions
summarize_character = function(var) {
    var = tolower(var)
    var = gsub("\\s+", "_", var)
    var = gsub("\\-+", "_", var)
    var = gsub("[^a-z0-9_]", "", var)
    var = gsub("\\_+", "_", var)

    paste0(var, collapse = ", ")
}

extract_categories = function(data) {
    df = data |>
        select(game_id, links) |>
        unnest(links, keep_empty = TRUE) |>
        filter(type == 'boardgamecategory') |>
        select(game_id, value) |>
        group_by(game_id) |>
        summarize(categories = summarize_character(value))

    data |>
        left_join(df, by = "game_id")
}

extract_mechanics = function(data) {
    df = data |>
        select(game_id, links) |>
        unnest(links, keep_empty = TRUE) |>
        filter(type == 'boardgamemechanic') |>
        select(game_id, value) |>
        group_by(game_id) |>
        summarize(mechanics = summarize_character(value))

    data |>
        left_join(df, by = "game_id")
}

extract_genres = function(data) {
    df = data |>
        select(game_id, ranks) |>
        unnest(ranks) |>
        filter(type == 'family') |>
        mutate(
            genres = case_when(
                name == 'strategygames' ~ 'strategy',
                name == 'familygames' ~ 'family',
                name == 'abstracts' ~ 'abstract',
                name == 'cgs' ~ 'customizable',
                name == 'wargames' ~ 'war',
                name == 'partygames' ~ 'party',
                name == 'thematic' ~ 'thematic',
                name == 'childrensgames' ~ 'children',
                TRUE ~ NA_character_
            )
        ) |>
        select(game_id, genres) |>
        group_by(game_id) |>
        summarize(genres = summarize_character(genres), .groups = 'drop')

    data |>
        left_join(df, by = "game_id")
}

extract_categorical = function(data) {
    data |>
        extract_categories() |>
        extract_mechanics() |>
        extract_genres() |>
        select(game_id, categories, mechanics, genres)
}

extract_info = function(data) {
    info =
        data |>
        select(game_id, info) |>
        unnest(info)

    names =
        data |>
        select(game_id, names) |>
        unnest(names) |>
        filter(type == "primary") |>
        select(game_id, name = value)

    stats =
        data |>
        select(game_id, statistics) |>
        unnest(statistics)

    categorical =
        data |>
        extract_categorical()

    data |>
        select(game_id) |>
        inner_join(info, by = "game_id") |>
        inner_join(names, by = "game_id") |>
        inner_join(stats, by = "game_id") |>
        inner_join(categorical, by = "game_id") |>
        select(
            game_id,
            yearpublished,
            name,
            image,
            description,
            averageweight,
            usersrated,
            average,
            bayesaverage,
            numweights,
            categories,
            mechanics,
            genres
        )
}

# use nanoparquet to write the data into parquet format
write_to_parquet = function(data, file) {
    data |>
        nanoparquet::write_parquet(
            file,
            compression = "snappy"
        )
}

# load the dataset, extract info, and write to parquet
convert_to_parquet = function(
    games_data,
    output_file = "data/games.parquet"
) {
    cat("Converting games data to parquet format...\n")
    games_data |>
        extract_info() |>
        write_to_parquet(
            file = output_file
        )
    cat("Conversion complete. Parquet file saved to", output_file, "\n")
}

# Function to upload Parquet file to Google Cloud Storage
upload_to_gcs = function(
    file = "data/games.parquet",
    bucket = Sys.getenv("GCS_BUCKET", "bgg_data_dev"),
    destination_path = "processed/games.parquet"
) {
    # Authenticate to GCS
    googleCloudStorageR::gcs_auth(json_file = Sys.getenv("GCS_AUTH_FILE"))

    # Set the bucket
    googleCloudStorageR::gcs_global_bucket(bucket)

    # Upload the file
    result <- googleCloudStorageR::gcs_upload(
        file,
        name = destination_path
    )

    cat("Uploaded", file, "to", bucket, "at", destination_path, "\n")
    return(result)
}

# get games
tar_load(games)

# extract info from games and format for parquet
games |>
    convert_to_parquet()

# upload parquet file to GCS
upload_to_gcs()
