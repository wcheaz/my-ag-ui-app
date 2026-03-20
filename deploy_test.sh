#!/bin/bash

# Deployment script for my-ag-ui-app on Kubernetes using multipass and microk8s
# This script automates the entire deployment process for ralph-loop execution

set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipeline fails

# Configuration with timeout settings
VM_NAME="my-ag-ui-app-k8s"
VM_CPUS=4
VM_MEMORY="7.7G"
VM_DISK="20GiB"
LOG_FILE="deployment.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Initialize log file with header information
init_log_file() {
    log "=========================================================="
    log "🚀 MY-AG-UI-APP DEPLOYMENT SCRIPT INITIALIZED"
    log "=========================================================="
    log "Script Configuration:"
    log "  - VM Name: $VM_NAME"
    log "  - VM CPUs: $VM_CPUS"
    log "  - VM Memory: $VM_MEMORY"
    log "  - VM Disk: $VM_DISK"
    log "  - Log File: $LOG_FILE"
    log "  - Start Time: $(date)"
    log "  - User: $(whoami)"
    log "  - Working Directory: $(pwd)"
    log "=========================================================="
    log "📝 LOGGING INITIALIZED - All operations will be logged to this file"
    log "=========================================================="
}

# Initialize log file
init_log_file

log "=========================================================="
log "🚀 STARTING DEPLOYMENT SCRIPT EXECUTION"
log "=========================================================="
log "Script Information:"
log "  - Script: ${BASH_SOURCE[0]}"
log "  - User: $(whoami)"
log "  - Working Directory: $(pwd)"
log "  - Date: $(date)"
log "  - Log File: $LOG_FILE"
log "=========================================================="

log "📋 SECTION 1/3: PRE-DEPLOYMENT CHECKS"
log "=========================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check multipass installation
log "Checking multipass installation..."
if ! command_exists multipass; then
    log "ERROR: multipass is not installed"
    log "Please install multipass before running this script. Installation instructions: https://multipass.run/install"
    exit 201
fi
log "SUCCESS: multipass is installed and ready"

# Check Docker installation
log "Checking Docker installation..."
if ! command_exists docker; then
    log "ERROR: Docker is not installed"
    log "Please install Docker before running this script. Installation instructions: https://docs.docker.com/get-docker/"
    exit 202
fi
log "SUCCESS: Docker is installed"

# Check system resources
log "Checking system resources..."
AVAILABLE_CPUS=$(nproc)
REQUIRED_CPUS=4
log "Available CPU cores: $AVAILABLE_CPUS (required: $REQUIRED_CPUS)"

if [ "$AVAILABLE_CPUS" -lt "$REQUIRED_CPUS" ]; then
    log "WARNING: System has only $AVAILABLE_CPUS CPU cores, $REQUIRED_CPUS are recommended"
fi

AVAILABLE_MEMORY=$(free -g | awk 'NR==2{print $7}')
REQUIRED_MEMORY=4
log "Available memory: ${AVAILABLE_MEMORY}GB (required: ${REQUIRED_MEMORY}GB)"

if [ "$AVAILABLE_MEMORY" -lt "$REQUIRED_MEMORY" ]; then
    log "WARNING: System has only ${AVAILABLE_MEMORY}GB memory, ${REQUIRED_MEMORY}GB are recommended"
fi

log "✅ PRE-DEPLOYMENT CHECKS COMPLETED"

log "📋 SECTION 2/3: VM PROVISIONING"
log "=========================================================="

log "Creating VM '$VM_NAME' with $VM_CPUS CPUs, $VM_MEMORY RAM, $VM_DISK disk..."

# Check if VM already exists
if multipass list | grep -q "^$VM_NAME "; then
    log "VM '$VM_NAME' already exists, deleting it first..."
    multipass delete "$VM_NAME" --purge || true
fi

# Create VM with proper disk size
log "Creating new VM..."
if ! multipass launch --cpus "$VM_CPUS" --memory "$VM_MEMORY" --disk "$VM_DISK" --name "$VM_NAME" 22.04; then
    log "ERROR: Failed to create VM '$VM_NAME'"
    exit 102
fi

log "SUCCESS: VM '$VM_NAME' created successfully"

# Wait for VM to be ready
log "Waiting for VM to be ready..."
sleep 30

# Verify VM is running
if ! multipass info "$VM_NAME" | grep -q "State:[[:space:]]*Running"; then
    log "ERROR: VM '$VM_NAME' is not running"
    exit 103
fi

log "SUCCESS: VM '$VM_NAME' is running"
log "✅ VM PROVISIONING COMPLETED"

log "📋 SECTION 3/3: MICROK8S INSTALLATION"
log "=========================================================="

log "Installing microk8s in VM '$VM_NAME'..."
if ! multipass exec "$VM_NAME" -- sudo snap install microk8s --classic; then
    log "ERROR: Failed to install microk8s"
    exit 103
fi

log "SUCCESS: microk8s installed successfully"

# Wait for microk8s to be ready
log "Waiting for microk8s to be ready..."
if ! multipass exec "$VM_NAME" -- microk8s status --wait-ready; then
    log "ERROR: microk8s is not ready"
    exit 104
fi

log "SUCCESS: microk8s is ready"

# Enable required add-ons
for addon in dns storage ingress; do
    log "Enabling $addon add-on..."
    if ! multipass exec "$VM_NAME" -- microk8s enable "$addon"; then
        log "ERROR: Failed to enable $addon add-on"
        exit 105
    fi
    log "SUCCESS: $addon add-on enabled"
done

log "SUCCESS: All microk8s add-ons enabled"
log "✅ MICROK8S INSTALLATION COMPLETED"

log "=========================================================="
log "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
log "=========================================================="
log "VM Details:"
log "  - Name: $VM_NAME"
log "  - CPUs: $VM_CPUS"
log "  - Memory: $VM_MEMORY"
log "  - Disk: $VM_DISK"
log ""
log "Microk8s Details:"
log "  - Status: Ready"
log "  - Add-ons: dns, storage, ingress"
log ""
log "Next Steps:"
log "  1. Verify deployment: multipass exec $VM_NAME -- microk8s kubectl get all"
log "  2. Access VM: multipass shell $VM_NAME"
log "=========================================================="

log "SUCCESS: Deployment script completed successfully"
exit 0
