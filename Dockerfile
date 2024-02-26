FROM rocker/r-base:4.3.1 as base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libglpk-dev \
    libsodium-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# environment variables for Google Authentication
ENV GCS_DEFAULT_BUCKET=bgg_data
ENV GCS_PROJECT_ID=gcp-demos-411520

# R packages
RUN R -e "install.packages('renv', repos = 'https://packagemanager.posit.co/cran/__linux__/bookworm/latest')"

WORKDIR /bgg_data
# Copy files from the local repository to the container
COPY renv.lock renv.lock
COPY Rprofile.site /etc/R

RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# change default location of cache to project folder
RUN mkdir renv/.cache
ENV RENV_PATHS_CACHE renv/.cache

# restore from renv
RUN R -e "renv::restore(repos = c(binary = 'https://packagemanager.posit.com/all/__linux__/bookworm/latest', RSPM = 'https://packagemanager.posit.co/cran/__linux__/bookworm/latest', CRAN = 'https://cloud.r-project.org'))"

FROM base

WORKDIR /bgg_data
COPY --from=base /bgg_data .
# Copy files from the local repository to the container
COPY . /bgg_data