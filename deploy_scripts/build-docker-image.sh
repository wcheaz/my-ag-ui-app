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
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    handle_validation_error 201 "Dockerfile not found in project root" \
        "Ensure Dockerfile exists in the project root directory."
    exit 1
fi

# Pre-flight check: Verify Docker daemon is accessible
if ! docker info >/dev/null 2>&1; then
    handle_docker_error 202 "Docker daemon is not accessible" \
        "Start Docker daemon: sudo systemctl start docker"
    exit 1
fi

# Check disk space before Docker build operation
if ! df . | awk 'NR==2 {gsub(/%/,""); print $5}' | grep -q -E '^[0-9]+$' && [ $(df . | awk 'NR==2 {gsub(/%/,""); print $5}') -gt 90 ]; then
    log "WARNING: Low disk space for Docker build"
fi

# Build Docker image
log_info "Starting Docker image build for 'my-ag-ui-app:latest'..."

# Capture Docker build output for debugging
build_output=""
if ! build_output=$(docker build -t my-ag-ui-app:latest . 2>&1); then
    # Log build output on failure
    log_error "Docker build failed"
    log_error "Build output:"
    echo "$build_output" | tee -a "$LOG_FILE"
    
    handle_docker_error 203 "Failed to build Docker image" \
        "Check Dockerfile and project structure. Ensure all required files are present."
    exit 1
fi

# Log build output on success (full output in log file, summary in console)
log_info "Docker build completed successfully"
log_info "Build output:"
echo "$build_output" | tee -a "$LOG_FILE"

# Show build summary in console if not in verbose mode
if [ "${VERBOSE:-false}" != "true" ]; then
    # Extract and show key information from build output (if available)
    if echo "$build_output" | grep -q -E "(Successfully built|Successfully tagged| => | --->)"; then
        echo "$build_output" | grep -E "(Successfully built|Successfully tagged| => | --->)" | head -10 | while IFS= read -r line; do
            [ -n "$line" ] && log_info "Build: $line"
        done
    else
        log_info "Build: Docker image built successfully (no detailed build summary available)"
    fi
fi

log_info "Docker image 'my-ag-ui-app:latest' built successfully"

# Verify Docker image was built successfully
if ! docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    handle_docker_error 204 "Docker image verification failed" \
        "Verify the image was built correctly: docker images my-ag-ui-app:latest"
    exit 1
fi

log_info "Docker image 'my-ag-ui-app:latest' verified successfully"
log_info "Docker build process completed successfully"