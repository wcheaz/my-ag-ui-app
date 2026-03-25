#!/bin/bash

# DEBUG LEVEL: MINIMAL (successful phase)

set -e

# Build Docker image for my-ag-ui-app
# This script builds the Docker image and verifies it was created successfully

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
}

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    log "ERROR: Dockerfile not found in project root"
    exit 1
fi

# Pre-flight check: Verify Docker daemon is accessible
if ! docker info >/dev/null 2>&1; then
    log "ERROR: Docker daemon is not accessible"
    log "Start Docker daemon: sudo systemctl start docker"
    exit 1
fi

# Check disk space before Docker build operation
if ! df . | awk 'NR==2 {gsub(/%/,""); print $5}' | grep -q -E '^[0-9]+$' && [ $(df . | awk 'NR==2 {gsub(/%/,""); print $5}') -gt 90 ]; then
    log "WARNING: Low disk space for Docker build"
fi

# Build Docker image
log "Building Docker image 'my-ag-ui-app:latest'..."

if [ "$DEBUG" = "all" ]; then
    # Verbose output for debugging
    if ! docker build -t my-ag-ui-app:latest . 2>&1; then
        log "ERROR: Failed to build Docker image"
        exit 1
    fi
else
    # Minimal output for successful phase
    if ! docker build -t my-ag-ui-app:latest . >/dev/null 2>&1; then
        log "ERROR: Failed to build Docker image"
        exit 1
    fi
fi

log "Docker image 'my-ag-ui-app:latest' built successfully"

# Verify Docker image was built successfully
if ! docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    log "ERROR: Docker image verification failed"
    exit 1
fi

log "Docker image 'my-ag-ui-app:latest' verified successfully"