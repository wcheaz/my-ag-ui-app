#!/bin/bash

# DEBUG LEVEL: FULL (problematic phase)

# Set strict error handling
set -euo pipefail

# Source common error handling functions
source "deploy_scripts/common.sh"

# Initialize log file
setup_log_file



# Enable debug output if DEBUG=all is set
if [ "$DEBUG" = "all" ]; then
    log_info "DEBUG: Verbose debug output enabled for Kubernetes secrets setup"
    set -x
fi

# 5.4 Create Kubernetes secrets for sensitive environment variables
log_info "Starting Kubernetes secrets setup..."

# Check if k8s directory exists
if [ ! -d "k8s" ]; then
    handle_validation_error "k8s directory not found" \
        "Ensure k8s directory exists with Kubernetes manifests: $(pwd)/k8s/"
fi
log_info "k8s directory found: $(pwd)/k8s/"

# Check if setup-secrets.sh script exists
if [ ! -f "k8s/setup-secrets.sh" ]; then
    handle_validation_error "setup-secrets.sh script not found" \
        "Ensure setup-secrets.sh exists in k8s directory: $(pwd)/k8s/setup-secrets.sh"
fi
log_info "setup-secrets.sh script found: $(pwd)/k8s/setup-secrets.sh"

# Check if .env file exists
if [ ! -f ".env" ]; then
    log_warning ".env file not found in current directory"
    log_info "Using environment variables from shell environment"
fi

# Set up environment variables for secrets creation
log_info "Setting up environment variables for secrets creation..."

# Read environment variables from .env file if it exists
if [ -f ".env" ]; then
    log_info "Loading environment variables from .env file..."
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^#.*$ ]] && [[ -n "$line" ]]; then
            # Export the variable
            export "$line"
            log_info "Set environment variable: ${line%%=*}"
        fi
    done < .env
fi

# Verify required environment variables are set
REQUIRED_VARS=("OPENAI_API_KEY" "OPENAI_BASE_URL" "OPENAI_MODEL" "EMBEDDING_MODEL")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_error "Missing required environment variables:"
    for missing_var in "${MISSING_VARS[@]}"; do
        log_error "  - $missing_var"
    done
    handle_validation_error "Missing required environment variables" \
        "Set the missing environment variables in your shell or .env file before running the script"
fi
log_info "All required environment variables are set"

# Run the secrets setup script
log_info "Running secrets setup script..."
if ! bash k8s/setup-secrets.sh 2>&1 | tee -a "$LOG_FILE"; then
    handle_kubernetes_error "Failed to set up Kubernetes secrets" \
        "Check the secrets setup script output above for errors. Ensure environment variables are correctly set."
fi
log_info "Kubernetes secrets setup completed successfully"