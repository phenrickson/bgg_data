#!/bin/bash

# This script automates the promotion of data between all environments
# It first promotes from dev to staging, then from staging to production

# Set the path to the R script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPARE_SCRIPT="${SCRIPT_DIR}/compare_and_promote.R"

# Log file
LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/promotion_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Start logging
log "Starting environment promotion process"
log "Script directory: $SCRIPT_DIR"
log "Log file: $LOG_FILE"

# Parse command line arguments
DRY_RUN=false

for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      ;;
    --help)
      echo "Usage: $0 [--dry-run]"
      echo ""
      echo "Options:"
      echo "  --dry-run  Show what would be copied without actually copying"
      echo "  --help     Show this help message"
      exit 0
      ;;
  esac
done

# Build the base command
if [ "$DRY_RUN" = true ]; then
  BASE_CMD="Rscript $COMPARE_SCRIPT --dry-run"
  log "Running in DRY RUN mode - no data will be copied"
else
  BASE_CMD="Rscript $COMPARE_SCRIPT"
  log "Running in PRODUCTION mode - data will be copied"
fi

# Step 1: Promote from dev to staging
log "Step 1: Promoting from DEV to STAGING"
DEV_TO_STAGING_CMD="$BASE_CMD --dev-to-staging"
log "Executing: $DEV_TO_STAGING_CMD"

# Execute the command and capture output
DEV_TO_STAGING_OUTPUT=$($DEV_TO_STAGING_CMD 2>&1)
DEV_TO_STAGING_EXIT_CODE=$?

# Log the output
log "Command output:"
echo "$DEV_TO_STAGING_OUTPUT" | tee -a "$LOG_FILE"

# Check exit code
if [ $DEV_TO_STAGING_EXIT_CODE -eq 0 ]; then
  log "DEV to STAGING promotion completed successfully"
else
  log "DEV to STAGING promotion failed with exit code $DEV_TO_STAGING_EXIT_CODE"
  log "Aborting promotion process"
  exit $DEV_TO_STAGING_EXIT_CODE
fi

# Step 2: Promote from staging to production
log "Step 2: Promoting from STAGING to PRODUCTION"
STAGING_TO_PROD_CMD="$BASE_CMD --staging-to-prod"
log "Executing: $STAGING_TO_PROD_CMD"

# Execute the command and capture output
STAGING_TO_PROD_OUTPUT=$($STAGING_TO_PROD_CMD 2>&1)
STAGING_TO_PROD_EXIT_CODE=$?

# Log the output
log "Command output:"
echo "$STAGING_TO_PROD_OUTPUT" | tee -a "$LOG_FILE"

# Check exit code
if [ $STAGING_TO_PROD_EXIT_CODE -eq 0 ]; then
  log "STAGING to PRODUCTION promotion completed successfully"
else
  log "STAGING to PRODUCTION promotion failed with exit code $STAGING_TO_PROD_EXIT_CODE"
  log "Promotion process partially completed (DEV to STAGING succeeded)"
  exit $STAGING_TO_PROD_EXIT_CODE
fi

log "Full promotion process completed successfully"
exit 0
