FROM rocker/r-base:4.3.1 as base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libglpk-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# environment variables for Google Authentication
ENV GCS_DEFAULT_BUCKET=bgg_data
ENV GCS_PROJECT_ID=gcp-demos-411520

# R packages
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"

WORKDIR /bgg_data
COPY renv.lock renv.lock

RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# change default location of cache to project folder
RUN mkdir renv/.cache
ENV RENV_PATHS_CACHE renv/.cache

# restore 
RUN R -e "renv::restore()"

FROM base

WORKDIR /bgg_data
COPY --from=base /bgg_data .

# test run of core function to see if it changes
RUN R -e "bggUtils::get_bgg_games(c(12, 13, 7))"
