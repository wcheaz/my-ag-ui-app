#!/bin/bash

# DEBUG LEVEL: MINIMAL (successful phase)

set -e

# Source common error handling functions
source "deploy_scripts/common.sh"

# Log build process start
log_info "Starting Docker build process"

# Validate package.json and package-lock.json synchronization
validate_lock_files() {
    log_info "Starting dependency validation..."
    
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
    
    log_info "Checking if package.json and package-lock.json are in sync..."
    
    # Run npm ci --dry-run to validate lock file consistency
    local ci_output
    ci_output=$(npm ci --dry-run 2>&1)
    local ci_status=$?
    
    if [ $ci_status -ne 0 ]; then
        handle_dependency_error 200 "Lock files are out of sync" \
            "Run 'npm install' to update package-lock.json, then commit both files together."
        return 1
    fi
    
    log_info "✅ SUCCESS: package.json and package-lock.json are synchronized"
    log_info "   Dependencies are ready for reproducible Docker builds."
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
    log_info "WARNING: Low disk space for Docker build"
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

# Extract and show key information from build output (if available)
if echo "$build_output" | grep -q -E "(Successfully built|Successfully tagged| => | --->)"; then
    echo "$build_output" | grep -E "(Successfully built|Successfully tagged| => | --->)" | head -10 | while IFS= read -r line; do
        [ -n "$line" ] && log_info "Build: $line"
    done
else
    log_info "Build: Docker image built successfully (no detailed build summary available)"
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

# Transfer Docker image to VM
log_info "Transferring Docker image to VM..."

VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
TARGET_IMAGE="localhost:32000/my-ag-ui-app:latest"

# Pre-flight check: Verify VM exists
if ! multipass list | grep -q "$VM_NAME"; then
    log "❌ ERROR: VM '$VM_NAME' not found"
    log "   Cannot transfer image without VM"
    exit 1
fi

# Pre-flight check: Verify Docker daemon in VM
if ! multipass exec "$VM_NAME" -- docker info >/dev/null 2>&1; then
    log "❌ ERROR: Docker daemon not accessible in VM"
    log "   Cannot transfer image without Docker in VM"
    exit 1
fi

# Save image to tar file
log_info "Saving image to tar file..."
if ! docker save my-ag-ui-app:latest -o /tmp/my-ag-ui-app.tar; then
    log "❌ ERROR: Failed to save Docker image"
    exit 1
fi
log_info "✅ Image saved to /tmp/my-ag-ui-app.tar"

# Transfer tar file to VM
log_info "Transferring tar file to VM..."
if ! multipass transfer /tmp/my-ag-ui-app.tar "$VM_NAME:/tmp/"; then
    log "❌ ERROR: Failed to transfer image to VM"
    rm -f /tmp/my-ag-ui-app.tar
    exit 1
fi
log_info "✅ Image transferred to VM"

# Load image in VM
log_info "Loading image in VM..."
if ! multipass exec "$VM_NAME" -- docker load -i /tmp/my-ag-ui-app.tar; then
    log "❌ ERROR: Failed to load image in VM"
    multipass exec "$VM_NAME" -- rm -f /tmp/my-ag-ui-app.tar
    rm -f /tmp/my-ag-ui-app.tar
    exit 1
fi
log_info "✅ Image loaded in VM"

# Tag image for registry
log_info "Tagging image for registry..."
if ! multipass exec "$VM_NAME" -- docker tag my-ag-ui-app:latest "$TARGET_IMAGE"; then
    log "❌ ERROR: Failed to tag image in VM"
    multipass exec "$VM_NAME" -- rm -f /tmp/my-ag-ui-app.tar
    rm -f /tmp/my-ag-ui-app.tar
    exit 1
fi
log_info "✅ Image tagged as $TARGET_IMAGE in VM"

# Verify image in VM
log_info "Verifying image in VM..."
if ! multipass exec "$VM_NAME" -- docker images "$TARGET_IMAGE" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$TARGET_IMAGE"; then
    log "❌ ERROR: Image verification failed in VM"
    log "   Expected: $TARGET_IMAGE"
    log "   Found:"
    multipass exec "$VM_NAME" -- docker images | grep my-ag-ui-app | tee -a "$LOG_FILE"
    multipass exec "$VM_NAME" -- rm -f /tmp/my-ag-ui-app.tar
    rm -f /tmp/my-ag-ui-app.tar
    exit 1
fi
log_info "✅ Image verified in VM: $TARGET_IMAGE"

# Cleanup temporary files
log_info "Cleaning up temporary files..."
multipass exec "$VM_NAME" -- rm -f /tmp/my-ag-ui-app.tar
rm -f /tmp/my-ag-ui-app.tar
log_info "✅ Temporary files cleaned up"

log_info "✅ Docker image successfully built and transferred to VM"
log_info "   Host image: my-ag-ui-app:latest"
log_info "   VM image: $TARGET_IMAGE"