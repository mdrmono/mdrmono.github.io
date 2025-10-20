#!/bin/bash
###############################################################################
# Anki Stats Cron Job Setup Script for Raspberry Pi
###############################################################################
# This script helps you set up automated Anki stats updates on your Pi.
# It will:
# 1. Guide you through SSH key generation for GitHub
# 2. Clone the data repository
# 3. Install the cron job for daily updates
# 4. Test the complete workflow
#
# Run this script once on your Raspberry Pi to set up the automation.
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURATION
# ============================================================================

EXPORT_DIR="${HOME}/anki-export"
EXPORT_SCRIPT="${EXPORT_DIR}/export_anki_stats.py"
UPDATE_SCRIPT="${EXPORT_DIR}/update-anki-stats.sh"
DATA_REPO_DIR="${EXPORT_DIR}/anki-stats-data"
SSH_KEY_PATH="${HOME}/.ssh/anki_github_deploy_key"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_step() {
    echo -e "\n${GREEN}[Step $1]${NC} $2\n"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC}  $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

prompt_continue() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

check_prerequisites() {
    print_step "1/6" "Checking prerequisites"

    local missing_deps=()

    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    else
        print_success "Python 3 is installed: $(python3 --version)"
    fi

    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    else
        print_success "Git is installed: $(git --version)"
    fi

    # Check for ssh-keygen
    if ! command -v ssh-keygen &> /dev/null; then
        missing_deps+=("ssh-keygen")
    else
        print_success "ssh-keygen is available"
    fi

    # Check for crontab
    if ! command -v crontab &> /dev/null; then
        missing_deps+=("cron")
    else
        print_success "crontab is available"
    fi

    # If any dependencies are missing, show error and exit
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install them with:"
        echo "  sudo apt update && sudo apt install -y ${missing_deps[*]}"
        exit 1
    fi

    print_success "All prerequisites are met"
}

check_export_script() {
    print_step "2/6" "Checking export script"

    # Check if export script exists
    if [[ ! -f "${EXPORT_SCRIPT}" ]]; then
        print_error "Export script not found at: ${EXPORT_SCRIPT}"
        echo ""
        print_info "Please copy export_anki_stats.py to ${EXPORT_DIR}"
        echo "From your development machine, run:"
        echo "  scp scripts/export_anki_stats.py pi@YOUR_PI_IP:${EXPORT_DIR}/"
        exit 1
    fi

    print_success "Export script found at: ${EXPORT_SCRIPT}"

    # Test if the export script can run
    print_info "Testing export script..."
    if python3 "${EXPORT_SCRIPT}" --help > /dev/null 2>&1; then
        print_success "Export script is executable"
    else
        print_error "Export script has issues. Please check the file."
        exit 1
    fi
}

# ============================================================================
# SETUP FUNCTIONS
# ============================================================================

setup_ssh_key() {
    print_step "3/6" "Setting up GitHub SSH key"

    if [[ -f "${SSH_KEY_PATH}" ]]; then
        print_info "SSH key already exists at: ${SSH_KEY_PATH}"
        echo ""
        echo "Do you want to:"
        echo "  1) Use the existing key"
        echo "  2) Generate a new key (will overwrite existing)"
        echo ""
        read -rp "Enter choice (1 or 2): " choice

        if [[ "${choice}" == "2" ]]; then
            print_info "Generating new SSH key..."
            ssh-keygen -t ed25519 -C "anki-stats-pi-automation" -f "${SSH_KEY_PATH}" -N ""
        fi
    else
        print_info "Generating SSH key for GitHub authentication..."
        ssh-keygen -t ed25519 -C "anki-stats-pi-automation" -f "${SSH_KEY_PATH}" -N ""
    fi

    print_success "SSH key ready at: ${SSH_KEY_PATH}"

    # Display the public key
    echo ""
    echo -e "${BLUE}────────────────────────────────────────${NC}"
    echo -e "${GREEN}Your SSH Public Key:${NC}"
    echo -e "${BLUE}────────────────────────────────────────${NC}"
    cat "${SSH_KEY_PATH}.pub"
    echo -e "${BLUE}────────────────────────────────────────${NC}"
    echo ""

    print_info "Follow these steps to add the deploy key to GitHub:"
    echo ""
    echo "  1. Go to: https://github.com/YOUR_USERNAME/anki-stats-data"
    echo "  2. Click 'Settings' → 'Deploy keys' → 'Add deploy key'"
    echo "  3. Title: 'Raspberry Pi - Anki Stats Automation'"
    echo "  4. Paste the public key above"
    echo "  5. ✓ Check 'Allow write access'"
    echo "  6. Click 'Add key'"
    echo ""

    prompt_continue
}

configure_git_ssh() {
    print_info "Configuring SSH for Git..."

    # Add GitHub to known hosts if not already present
    if ! ssh-keygen -F github.com > /dev/null 2>&1; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
        print_success "Added github.com to known_hosts"
    fi

    # Create or update SSH config
    local ssh_config="${HOME}/.ssh/config"
    local config_entry="Host github.com
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes"

    if [[ -f "${ssh_config}" ]] && grep -q "github.com" "${ssh_config}"; then
        print_info "SSH config for github.com already exists"
    else
        echo "${config_entry}" >> "${ssh_config}"
        chmod 600 "${ssh_config}"
        print_success "Added GitHub SSH configuration"
    fi
}

clone_data_repo() {
    print_step "4/6" "Cloning data repository"

    # Ask for GitHub username and repo name
    echo ""
    read -rp "Enter your GitHub username: " github_username
    read -rp "Enter data repository name [anki-stats-data]: " repo_name
    repo_name=${repo_name:-anki-stats-data}

    local repo_url="git@github.com:${github_username}/${repo_name}.git"

    print_info "Repository URL: ${repo_url}"

    # Remove existing directory if it exists
    if [[ -d "${DATA_REPO_DIR}" ]]; then
        print_info "Data repository directory already exists"
        read -rp "Remove and re-clone? (y/n): " remove_choice
        if [[ "${remove_choice}" == "y" ]]; then
            rm -rf "${DATA_REPO_DIR}"
            print_success "Removed existing directory"
        else
            print_info "Keeping existing directory"
            return 0
        fi
    fi

    # Clone the repository
    print_info "Cloning repository..."
    if git clone "${repo_url}" "${DATA_REPO_DIR}"; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        echo ""
        print_info "Please ensure:"
        echo "  1. The repository exists: https://github.com/${github_username}/${repo_name}"
        echo "  2. The deploy key is added with write access"
        echo "  3. The SSH key is correct"
        exit 1
    fi

    # Configure git user for commits
    cd "${DATA_REPO_DIR}"

    echo ""
    read -rp "Enter git commit name [Raspberry Pi]: " git_name
    read -rp "Enter git commit email [pi@raspberrypi.local]: " git_email
    git_name=${git_name:-"Raspberry Pi"}
    git_email=${git_email:-"pi@raspberrypi.local"}

    git config user.name "${git_name}"
    git config user.email "${git_email}"

    print_success "Git user configured"
}

install_cron_job() {
    print_step "5/6" "Installing cron job"

    # Copy update script to export directory
    local script_source="$(dirname "$0")/update-anki-stats.sh"
    if [[ -f "${script_source}" ]]; then
        cp "${script_source}" "${UPDATE_SCRIPT}"
        chmod +x "${UPDATE_SCRIPT}"
        print_success "Update script installed at: ${UPDATE_SCRIPT}"
    else
        print_error "Update script not found. Please ensure update-anki-stats.sh is in the same directory."
        exit 1
    fi

    # Cron job entry (runs daily at 2 AM UTC)
    local cron_entry="0 2 * * * ${UPDATE_SCRIPT} >> ${EXPORT_DIR}/cron.log 2>&1"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -qF "${UPDATE_SCRIPT}"; then
        print_info "Cron job already exists"
        read -rp "Replace existing cron job? (y/n): " replace_choice
        if [[ "${replace_choice}" != "y" ]]; then
            print_info "Keeping existing cron job"
            return 0
        fi
        # Remove old entry
        crontab -l 2>/dev/null | grep -vF "${UPDATE_SCRIPT}" | crontab -
    fi

    # Add new cron job
    (crontab -l 2>/dev/null; echo "${cron_entry}") | crontab -
    print_success "Cron job installed: Daily at 2:00 AM UTC"

    # Show current crontab
    echo ""
    print_info "Current crontab:"
    crontab -l
}

test_workflow() {
    print_step "6/6" "Testing the workflow"

    print_info "Running a test execution of the update script..."
    echo ""

    if bash "${UPDATE_SCRIPT}"; then
        echo ""
        print_success "Test execution completed successfully!"
        echo ""
        print_info "Check the log file for details:"
        echo "  tail -n 50 ${EXPORT_DIR}/update-anki-stats.log"
    else
        echo ""
        print_error "Test execution failed"
        echo ""
        print_info "Check the log file for errors:"
        echo "  tail -n 50 ${EXPORT_DIR}/update-anki-stats.log"
        exit 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_header "Anki Stats Automation Setup"

    echo ""
    echo "This script will set up automated Anki stats updates on your Raspberry Pi."
    echo ""
    print_info "Setup will create/modify:"
    echo "  - SSH key for GitHub: ${SSH_KEY_PATH}"
    echo "  - Data repository: ${DATA_REPO_DIR}"
    echo "  - Update script: ${UPDATE_SCRIPT}"
    echo "  - Cron job: Daily at 2:00 AM UTC"
    echo ""

    prompt_continue

    # Run setup steps
    check_prerequisites
    check_export_script
    setup_ssh_key
    configure_git_ssh
    clone_data_repo
    install_cron_job
    test_workflow

    # Final success message
    echo ""
    print_header "Setup Complete!"
    echo ""
    print_success "Anki stats automation is now configured!"
    echo ""
    echo "What happens next:"
    echo "  • The update script will run daily at 2:00 AM UTC"
    echo "  • Stats will be exported, committed, and pushed to GitHub"
    echo "  • Logs will be written to: ${EXPORT_DIR}/update-anki-stats.log"
    echo ""
    echo "Useful commands:"
    echo "  • Test manually:    bash ${UPDATE_SCRIPT}"
    echo "  • View logs:        tail -f ${EXPORT_DIR}/update-anki-stats.log"
    echo "  • View cron jobs:   crontab -l"
    echo "  • Edit cron jobs:   crontab -e"
    echo ""
}

# Run main function
main "$@"
