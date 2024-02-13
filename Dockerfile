FROM r-base as base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libglpk-dev \
    && apt-get clean

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

FROM r-base

WORKDIR /bgg_data
COPY --from=base /bgg_data .

# add commands that need to be debugged below