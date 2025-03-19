
# bgg_data

Loading historical data from BGG for predictive modeling and analysis

1.  Loads universe of game ids from [bgg activity
    club](http://bgg.activityclub.org/bggdata/thingids.txt%5D)
2.  Submits batches of requests via
    [bggUtils](https://github.com/phenrickson/bggUtils)
3.  Stores responses on BigQuery and Google Cloud Storage

## Targets

Uses [targets](https://github.com/ropensci/targets) package to create
pipeline

## Environment Separation

The project now supports separate environments for development, staging, and production:

- **Development**: For implementing and testing changes without affecting production data
- **Staging**: For final testing before promoting to production
- **Production**: The live environment used by other projects

### Environment Setup

To set up the necessary infrastructure for environment separation:

```r
source("src/utils/create_environments.R")
create_environments()
```

### Running in Different Environments

```bash
# Development
Rscript run.R default

# Staging
Rscript run.R staging

# Production
Rscript run.R production
```

### Comparing and Promoting Data

The project includes utilities for comparing data between environments and promoting data from one environment to another:

```r
# Compare environments
source("src/utils/compare_environments.R")
compare_game_data("staging", "production")

# Promote data (dry run first)
source("src/utils/promote_data.R")
promote_data("staging", "production", dry_run = TRUE)
promote_data("staging", "production", dry_run = FALSE)
```

See `src/utils/environment_guide.R` for more detailed examples and workflow recommendations.