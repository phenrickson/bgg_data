# who: phil henrickson
# what: run scripts to scrape bgg data and load to gcp
# when: 11/2/22

# scrapes pages of boardgamegeek to get universe of ids
reticulate::source_python(here::here("src", "data", "scrape_bgg_ids.py"))
