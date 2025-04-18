
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

```bash
# Create all environments
make create-environments
```

### Running in Different Environments

```bash
# Development
make run-dev

# Staging
make run-staging

# Production
make run-prod

# Or specify environment
make run ENV=staging
```

### Comparing and Promoting Data

The project includes utilities for comparing data between environments and promoting data from one environment to another:

```bash
# Dry run (shows what would be promoted without making changes)
make dry-run-promote

# Promote data between environments
make promote                # Full promotion (dev → staging → prod)
make promote-dev-staging    # Dev to staging only
make promote-staging-prod   # Staging to production only

# Execute workflow targets that include promotion
make full-pipeline          # Full pipeline with all environments
make dev-to-staging         # Run dev pipeline and promote to staging
make staging-to-prod        # Run staging pipeline and promote to production
```

See `src/utils/environment_guide.R` for more detailed examples and workflow recommendations.

## Using the Makefile

A Makefile has been added to simplify common operations. Here are the available commands:

```bash
# Show available commands
make help

# Run the pipeline in the default environment
make run

# Run the pipeline in a specific environment
make run ENV=staging

# Run the pipeline in specific environments (convenience targets)
make run-dev
make run-staging
make run-prod

# Run the test pipeline
make test

# Create all environments
make create-environments

# Promote data between environments
make promote                # Full promotion (dev → staging → prod)
make promote-dev-staging    # Dev to staging only
make promote-staging-prod   # Staging to production only
make dry-run-promote        # Dry run (shows what would be promoted)

# Render Quarto documents
make render
make render-preview         # Render and open preview in browser

# Clean up temporary files
make clean

# Clean up all generated files including targets stores
make clean-all

# Pipeline workflow targets
make full-pipeline          # Execute full pipeline workflow (create environments, run in all environments with promotion)
make dev-to-staging         # Run dev pipeline and promote to staging
make staging-to-prod        # Run staging pipeline and promote to production
```

The Makefile provides a convenient interface for all common operations in the project. Use `make help` to see a list of all available commands.
