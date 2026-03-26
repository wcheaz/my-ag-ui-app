#!/bin/bash

# DEBUG LEVEL: FULL (problematic phase)

# Set error handling
set -e

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
else
    # Fallback error handling if common.sh is not available
    VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
    LOG_FILE="${LOG_FILE:-/tmp/deploy-$(date +%Y%m%d-%H%M%S).log}"
    
    log() {
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $message" | tee -a "$LOG_FILE"
    }
    
    handle_error() {
        local error_code="$1"
        local error_message="$2"
        local recovery_suggestion="$3"
        
        log "ERROR: $error_message"
        log "RECOVERY: $recovery_suggestion"
        exit "$error_code"
    }
fi



# Enable debug output if DEBUG=all is set
if [ "$DEBUG" = "all" ]; then
    log "DEBUG: Verbose debug output enabled for Kubernetes secrets setup"
    set -x
fi

# 5.4 Create Kubernetes secrets for sensitive environment variables
log "Starting Kubernetes secrets setup..."

# Check if k8s directory exists
if [ ! -d "k8s" ]; then
    handle_validation_error 101 "k8s directory not found" \
        "Ensure k8s directory exists with Kubernetes manifests: $(pwd)/k8s/"
fi
log "k8s directory found: $(pwd)/k8s/"

# Check if setup-secrets.sh script exists
if [ ! -f "k8s/setup-secrets.sh" ]; then
    handle_validation_error 102 "setup-secrets.sh script not found" \
        "Ensure setup-secrets.sh exists in k8s directory: $(pwd)/k8s/setup-secrets.sh"
fi
log "setup-secrets.sh script found: $(pwd)/k8s/setup-secrets.sh"

# Check if .env file exists
if [ ! -f ".env" ]; then
    log "WARNING: .env file not found in current directory"
    log "Using environment variables from shell environment"
fi

# Set up environment variables for secrets creation
log "Setting up environment variables for secrets creation..."

# Read environment variables from .env file if it exists
if [ -f ".env" ]; then
    log "Loading environment variables from .env file..."
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^#.*$ ]] && [[ -n "$line" ]]; then
            # Export the variable
            export "$line"
            log "Set environment variable: ${line%%=*}"
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
    log "ERROR: Missing required environment variables:"
    for missing_var in "${MISSING_VARS[@]}"; do
        log "  - $missing_var"
    done
    handle_validation_error 103 "Missing required environment variables" \
        "Set the missing environment variables in your shell or .env file before running the script"
fi
log "All required environment variables are set"

# Run the secrets setup script
log "Running secrets setup script..."
if ! bash k8s/setup-secrets.sh 2>&1 | tee -a "$LOG_FILE"; then
    handle_kubernetes_error 104 "Failed to set up Kubernetes secrets" \
        "Check the secrets setup script output above for errors. Ensure environment variables are correctly set."
fi
log "Kubernetes secrets setup completed successfully"