#!/bin/bash
###############################################################################
# Anki Stats Auto-Update Script for Raspberry Pi
###############################################################################
# This script:
# 1. Exports Anki review statistics to JSON
# 2. Checks if the data has changed
# 3. Commits and pushes changes to the data repository
# 4. Logs all operations for debugging
#
# Designed to run via cron job (e.g., daily at 2 AM UTC)
###############################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ============================================================================
# CONFIGURATION - Customize these paths for your setup
# ============================================================================

# Base directory for Anki export operations
EXPORT_DIR="${HOME}/anki-export"

# Path to the Python export script
EXPORT_SCRIPT="${EXPORT_DIR}/export_anki_stats.py"

# Path to the data repository (cloned from GitHub)
DATA_REPO_DIR="${EXPORT_DIR}/anki-stats-data"

# Output JSON file within the data repository
OUTPUT_JSON="${DATA_REPO_DIR}/anki-stats.json"

# Log file for this script
LOG_FILE="${EXPORT_DIR}/update-anki-stats.log"

# Deck name filter (leave empty for all decks)
DECK_NAME="Mandarin"

# Number of days of history to export
DAYS=365

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "${LOG_FILE}" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $*" | tee -a "${LOG_FILE}"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_dependencies() {
    log "Validating dependencies..."

    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        log_error "python3 is not installed or not in PATH"
        return 1
    fi

    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_error "git is not installed or not in PATH"
        return 1
    fi

    # Check if export script exists
    if [[ ! -f "${EXPORT_SCRIPT}" ]]; then
        log_error "Export script not found at: ${EXPORT_SCRIPT}"
        return 1
    fi

    # Check if data repository directory exists
    if [[ ! -d "${DATA_REPO_DIR}" ]]; then
        log_error "Data repository not found at: ${DATA_REPO_DIR}"
        log_error "Please run setup-pi-cron.sh first"
        return 1
    fi

    # Check if data repo is a valid git repository
    if [[ ! -d "${DATA_REPO_DIR}/.git" ]]; then
        log_error "Data repository is not a valid git repository"
        return 1
    fi

    log_success "All dependencies validated"
    return 0
}

check_internet() {
    log "Checking internet connectivity..."

    # Try to ping GitHub (with timeout)
    if timeout 5 ping -c 1 github.com &> /dev/null; then
        log_success "Internet connection available"
        return 0
    else
        log_error "No internet connection detected"
        return 1
    fi
}

# ============================================================================
# MAIN OPERATIONS
# ============================================================================

export_anki_stats() {
    log "Starting Anki stats export..."

    # Build the export command
    local export_cmd="python3 ${EXPORT_SCRIPT} --output ${OUTPUT_JSON} --days ${DAYS}"

    # Add deck filter if specified
    if [[ -n "${DECK_NAME}" ]]; then
        export_cmd="${export_cmd} --deck-name ${DECK_NAME}"
    fi

    # Run the export
    log "Running: ${export_cmd}"
    if ${export_cmd} >> "${LOG_FILE}" 2>&1; then
        log_success "Stats exported successfully to: ${OUTPUT_JSON}"
        return 0
    else
        log_error "Failed to export stats"
        return 1
    fi
}

check_changes() {
    log "Checking for changes in stats data..."

    cd "${DATA_REPO_DIR}" || return 1

    # Check if the JSON file has changes
    if git diff --quiet anki-stats.json; then
        log "No changes detected in stats data"
        return 1  # Return 1 to indicate no changes
    else
        log_success "Changes detected in stats data"
        return 0  # Return 0 to indicate changes exist
    fi
}

commit_and_push() {
    log "Committing and pushing changes..."

    cd "${DATA_REPO_DIR}" || return 1

    # Pull latest changes first (in case of concurrent updates)
    log "Pulling latest changes from remote..."
    if ! git pull --rebase origin main >> "${LOG_FILE}" 2>&1; then
        log_error "Failed to pull latest changes"
        return 1
    fi

    # Add the JSON file
    git add anki-stats.json

    # Create commit message with timestamp
    local commit_msg="Update Anki stats - $(date '+%Y-%m-%d %H:%M:%S UTC')"

    # Commit changes
    if git commit -m "${commit_msg}" >> "${LOG_FILE}" 2>&1; then
        log_success "Changes committed: ${commit_msg}"
    else
        log_error "Failed to commit changes"
        return 1
    fi

    # Push to remote
    log "Pushing to GitHub..."
    if git push origin main >> "${LOG_FILE}" 2>&1; then
        log_success "Changes pushed to GitHub successfully"
        return 0
    else
        log_error "Failed to push changes to GitHub"
        return 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "=========================================="
    log "Starting Anki stats update process"
    log "=========================================="

    # Validate all dependencies
    if ! validate_dependencies; then
        log_error "Dependency validation failed. Exiting."
        exit 1
    fi

    # Check internet connection
    if ! check_internet; then
        log_error "No internet connection. Exiting."
        exit 1
    fi

    # Export Anki statistics
    if ! export_anki_stats; then
        log_error "Failed to export stats. Exiting."
        exit 1
    fi

    # Check if there are changes
    if ! check_changes; then
        log "No changes to commit. Job complete."
        log "=========================================="
        exit 0
    fi

    # Commit and push changes
    if ! commit_and_push; then
        log_error "Failed to commit/push changes. Exiting."
        exit 1
    fi

    log_success "Anki stats update completed successfully!"
    log "=========================================="
    exit 0
}

# Run main function
main "$@"
