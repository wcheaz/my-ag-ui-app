#!/bin/bash

# Deployment script for my-ag-ui-app on Kubernetes using multipass and microk8s
# This script automates the entire deployment process for ralph-loop execution

set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipeline fails

# Configuration
VM_NAME="my-ag-ui-app-k8s"
VM_CPUS=4
VM_MEMORY="7.7G"
VM_DISK="19.3G"
LOG_FILE="deployment.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if VM exists
vm_exists() {
    multipass list | grep -q "^$VM_NAME "
}

# Function to check if VM is running
vm_running() {
    multipass info "$VM_NAME" | grep -q "State: Running"
}

# =====================
# VM PROVISIONING SECTION
# =====================

log "Starting VM provisioning..."

# 3.2 Add multipass installation check to deployment script
log "Checking multipass installation..."
if ! command_exists multipass; then
    handle_error "multipass is not installed. Please install multipass before running this script. Installation instructions: https://multipass.run/install"
fi
log "multipass is installed: $(multipass version)"

# 3.3 Configure VM creation with 4 CPUs, 7.7GiB RAM, 19.3GiB disk
log "Checking if VM '$VM_NAME' already exists..."
if vm_exists; then
    log "VM '$VM_NAME' already exists"
    if vm_running; then
        log "VM '$VM_NAME' is running"
    else
        log "Starting existing VM '$VM_NAME'..."
        multipass start "$VM_NAME" || handle_error "Failed to start VM '$VM_NAME'"
        log "VM '$VM_NAME' started successfully"
    fi
else
    log "Creating VM '$VM_NAME' with $VM_CPUS CPUs, $VM_MEMORY RAM, $VM_DISK disk..."
    multipass launch \
        --name "$VM_NAME" \
        --cpus "$VM_CPUS" \
        --memory "$VM_MEMORY" \
        --disk "$VM_DISK" \
        --timeout 600 \
        || handle_error "Failed to create VM '$VM_NAME'"
    log "VM '$VM_NAME' created successfully"
fi

# 3.4 Add VM readiness verification to deployment script
log "Waiting for VM to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if vm_running; then
        # Test if VM is responsive by running a simple command
        if multipass exec "$VM_NAME" -- uptime >/dev/null 2>&1; then
            log "VM '$VM_NAME' is ready and responsive"
            break
        fi
    fi
    log "Waiting for VM to be ready... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    handle_error "VM '$VM_NAME' did not become ready within $MAX_ATTEMPTS attempts"
fi

# 3.5 Configure VM networking verification
log "Verifying VM networking..."
VM_IP=$(multipass info "$VM_NAME" | grep "IPv4:" | awk '{print $2}')
log "VM '$VM_NAME' IP address: $VM_IP"

# Test DNS resolution
if ! multipass exec "$VM_NAME" -- nslookup google.com >/dev/null 2>&1; then
    log "WARNING: DNS resolution test failed in VM"
fi

# Test outbound connectivity
if ! multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    log "WARNING: Outbound connectivity test failed in VM"
fi

# 3.6 Add VM status monitoring during deployment
log "VM '$VM_NAME' status:"
multipass info "$VM_NAME"

log "VM provisioning completed successfully"