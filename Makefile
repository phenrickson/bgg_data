# Makefile for BGG Data Pipeline
# This Makefile provides commands to execute the pipeline, promote code, and create environments

# Default shell
SHELL := /bin/bash

# Environment variables
R_SCRIPT := Rscript
ENV ?= default

# Directories
LOG_DIR := logs
TARGET_DIR := _targets

# Ensure log directory exists
$(shell mkdir -p $(LOG_DIR))

# Default target
.PHONY: help
help:
	@echo "BGG Data Pipeline Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  run                 Run the pipeline in the default environment"
	@echo "  run-dev             Run the pipeline in the development environment"
	@echo "  run-staging         Run the pipeline in the staging environment"
	@echo "  run-prod            Run the pipeline in the production environment"
	@echo "  test                Run the test pipeline"
	@echo "  create-environments Create all environments"
	@echo "  promote             Promote data from dev to staging to production"
	@echo "  promote-dev-staging Promote data from dev to staging only"
	@echo "  promote-staging-prod Promote data from staging to production only"
	@echo "  dry-run-promote     Show what would be promoted without actually promoting"
	@echo "  render              Render Quarto documents"
	@echo "  render-preview      Render Quarto documents and preview in browser"
	@echo "  clean               Clean up temporary files"
	@echo "  clean-all           Clean up all generated files including targets stores"
	@echo ""
	@echo "Options:"
	@echo "  ENV=<environment>   Specify environment (default, staging, production)"

# Run the pipeline
.PHONY: run
run:
	@echo "Running pipeline in $(ENV) environment..."
	$(R_SCRIPT) run_pipeline.R $(ENV)

# Run the pipeline in specific environments
.PHONY: run-dev
run-dev:
	@echo "Running pipeline in development environment..."
	$(R_SCRIPT) run_pipeline.R default

.PHONY: run-staging
run-staging:
	@echo "Running pipeline in staging environment..."
	$(R_SCRIPT) run_pipeline.R staging

.PHONY: run-prod
run-prod:
	@echo "Running pipeline in production environment..."
	$(R_SCRIPT) run_pipeline.R production

# Test the pipeline
.PHONY: test
test:
	@echo "Running test pipeline..."
	$(R_SCRIPT) test_pipeline.R

# Create environments
.PHONY: create-environments
create-environments:
	@echo "Creating environments..."
	$(R_SCRIPT) create_environments.R

# Promote data between environments
.PHONY: promote
promote:
	@echo "Promoting data from dev to staging to production..."
	./promote.sh

.PHONY: promote-dev-staging
promote-dev-staging:
	@echo "Promoting data from dev to staging..."
	$(R_SCRIPT) compare_and_promote.R --dev-to-staging

.PHONY: promote-staging-prod
promote-staging-prod:
	@echo "Promoting data from staging to production..."
	$(R_SCRIPT) compare_and_promote.R --staging-to-prod

.PHONY: dry-run-promote
dry-run-promote:
	@echo "Dry run of promotion process..."
	./promote.sh --dry-run

# Render Quarto documents
.PHONY: render
render:
	@echo "Rendering Quarto documents..."
	quarto render

.PHONY: render-preview
render-preview:
	@echo "Rendering Quarto documents and opening preview..."
	quarto render --preview

# Clean up
.PHONY: clean
clean:
	@echo "Cleaning up temporary files..."
	rm -rf $(LOG_DIR)/*.log

.PHONY: clean-all
clean-all: clean
	@echo "Cleaning up all generated files including targets stores..."
	rm -rf $(TARGET_DIR)_default
	rm -rf $(TARGET_DIR)_staging
	rm -rf $(TARGET_DIR)_production
	rm -rf $(TARGET_DIR)/workspaces

# Pipeline workflow targets
.PHONY: full-pipeline
full-pipeline: create-environments run-dev promote-dev-staging run-staging promote-staging-prod run-prod
	@echo "Full pipeline workflow completed"

.PHONY: dev-to-staging
dev-to-staging: run-dev promote-dev-staging run-staging
	@echo "Development to staging workflow completed"

.PHONY: staging-to-prod
staging-to-prod: run-staging promote-staging-prod run-prod
	@echo "Staging to production workflow completed"
