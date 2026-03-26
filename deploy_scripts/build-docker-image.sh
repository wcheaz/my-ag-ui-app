#!/bin/bash

# DEBUG LEVEL: MINIMAL (successful phase)

set -e

# Source common error handling functions
source "deploy_scripts/common.sh"

# Log build process start
log_info "Starting Docker build process"

# Validate package.json and package-lock.json synchronization
validate_lock_files() {
    log "Starting dependency validation..."
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        handle_dependency_error 201 "package.json not found" \
            "Ensure you're running this script from the project root directory where package.json is located."
        return 1
    fi
    
    # Check if package-lock.json exists
    if [ ! -f "package-lock.json" ]; then
        handle_dependency_error 202 "package-lock.json not found" \
            "Run 'npm install' to generate the missing package-lock.json. This file is required for reproducible builds."
        return 1
    fi
    
    log "Checking if package.json and package-lock.json are in sync..."
    
    # Run npm ci --dry-run to validate lock file consistency
    local ci_output
    ci_output=$(npm ci --dry-run 2>&1)
    local ci_status=$?
    
    if [ $ci_status -ne 0 ]; then
        handle_dependency_error 200 "Lock files are out of sync" \
            "Run 'npm install' to update package-lock.json, then commit both files together."
        return 1
    fi
    
    log "✅ SUCCESS: package.json and package-lock.json are synchronized"
    log "   Dependencies are ready for reproducible Docker builds."
    return 0
}

# Validate dependencies before building Docker image
if ! validate_lock_files; then
    log "🛑 DEPLOYMENT HALTED: Dependency validation failed"
    log "   Fix the lock file sync issue and try again"
    handle_dependency_error 200 "Dependency validation failed" \
        "Run 'npm install' to update package-lock.json, then commit both files together."
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    handle_validation_error 201 "Dockerfile not found in project root" \
        "Ensure Dockerfile exists in the project root directory."
fi

# Pre-flight check: Verify Docker daemon is accessible
if ! docker info >/dev/null 2>&1; then
    handle_docker_error 202 "Docker daemon is not accessible" \
        "Start Docker daemon: sudo systemctl start docker"
fi

# Check disk space before Docker build operation
if ! df . | awk 'NR==2 {gsub(/%/,""); print $5}' | grep -q -E '^[0-9]+$' && [ $(df . | awk 'NR==2 {gsub(/%/,""); print $5}') -gt 90 ]; then
    log "WARNING: Low disk space for Docker build"
fi

# Build Docker image
log_info "Starting Docker image build for 'my-ag-ui-app:latest'..."

if [ "$DEBUG" = "all" ]; then
    # Verbose output for debugging
    if ! docker build -t my-ag-ui-app:latest . 2>&1; then
        handle_docker_error 203 "Failed to build Docker image" \
            "Check Dockerfile and project structure. Ensure all required files are present."
    fi
else
    # Minimal output for successful phase
    if ! docker build -t my-ag-ui-app:latest . >/dev/null 2>&1; then
        handle_docker_error 203 "Failed to build Docker image" \
            "Check Dockerfile and project structure. Ensure all required files are present."
    fi
fi

log_info "Docker image 'my-ag-ui-app:latest' built successfully"

# Verify Docker image was built successfully
if ! docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    handle_docker_error 204 "Docker image verification failed" \
        "Verify the image was built correctly: docker images my-ag-ui-app:latest"
fi

log_info "Docker image 'my-ag-ui-app:latest' verified successfully"
log_info "Docker build process completed successfully"