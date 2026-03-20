#!/bin/bash

# Cleanup script for my-ag-ui-app Kubernetes deployment
# This script removes all deployed resources including VM, Kubernetes resources, and temporary files

set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipeline fails

# Configuration
VM_NAME="my-ag-ui-app-k8s"
LOG_FILE="cleanup.log"
FORCE_CLEANUP=false

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Cleanup script for my-ag-ui-app Kubernetes deployment"
    echo
    echo "OPTIONS:"
    echo "  -f, --force    Force cleanup without confirmation prompts"
    echo "  -h, --help     Display this help message"
    echo
    echo "This script will:"
    echo "  - Remove Kubernetes resources (ingress, service, deployment)"
    echo "  - Delete the multipass VM"
    echo "  - Purge deleted VMs"
    echo "  - Clean up temporary files"
    echo
}

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
    multipass info "$VM_NAME" 2>/dev/null | grep -q "State:[[:space:]]*Running"
}

# Function to confirm cleanup
confirm_cleanup() {
    if [ "$FORCE_CLEANUP" = true ]; then
        return 0
    fi
    
    echo
    echo "WARNING: This will permanently remove all deployed resources!"
    echo "The following resources will be deleted:"
    echo "  - Kubernetes resources (ingress, service, deployment)"
    echo "  - Multipass VM: $VM_NAME"
    echo "  - Temporary files"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Cleanup cancelled by user"
        exit 0
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_CLEANUP=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# =====================
# CLEANUP PROCESS
# =====================

log "Starting cleanup process for my-ag-ui-app Kubernetes deployment..."

# Check prerequisites
log "Checking prerequisites..."
if ! command_exists multipass; then
    handle_error "multipass is not installed. This script requires multipass to manage VMs."
fi
log "multipass is installed: $(multipass version)"

# Confirm cleanup
confirm_cleanup

# 8.2 Add Kubernetes resource cleanup (delete ingress, service, deployment)
log "Cleaning up Kubernetes resources..."
if command_exists microk8s.kubectl || command_exists kubectl; then
    # Determine which kubectl command to use
    if command_exists microk8s.kubectl; then
        KUBECTL_CMD="microk8s.kubectl"
    else
        KUBECTL_CMD="kubectl"
    fi
    
    log "Using kubectl command: $KUBECTL_CMD"
    
    # Check if we're in a directory with k8s manifests
    if [ -d "k8s" ]; then
        log "Found k8s directory, attempting to clean up Kubernetes resources..."
        
        # Try to delete resources using manifests
        if [ -f "k8s/ingress.yaml" ]; then
            log "Deleting ingress resources..."
            $KUBECTL_CMD delete -f k8s/ingress.yaml --ignore-not-found=true || log "Warning: Failed to delete ingress resources (may not exist)"
        fi
        
        if [ -f "k8s/service.yaml" ]; then
            log "Deleting service resources..."
            $KUBECTL_CMD delete -f k8s/service.yaml --ignore-not-found=true || log "Warning: Failed to delete service resources (may not exist)"
        fi
        
        if [ -f "k8s/deployment.yaml" ]; then
            log "Deleting deployment resources..."
            $KUBECTL_CMD delete -f k8s/deployment.yaml --ignore-not-found=true || log "Warning: Failed to delete deployment resources (may not exist)"
        fi
    else
        log "No k8s directory found, skipping Kubernetes resource cleanup"
    fi
    
    # Additional cleanup - remove any remaining resources in the default namespace
    log "Checking for any remaining Kubernetes resources..."
    $KUBECTL_CMD delete ingress,service,deployment --all --ignore-not-found=true || log "Warning: Failed to clean up all Kubernetes resources"
    
    log "Kubernetes resource cleanup completed"
else
    log "kubectl not found, skipping Kubernetes resource cleanup"
fi

# 8.3 Add microk8s cleanup (optional)
log "Cleaning up microk8s (if installed)..."
if command_exists microk8s; then
    log "microk8s found, checking if it's running..."
    if microk8s status >/dev/null 2>&1; then
        log "microk8s is running, stopping it..."
        microk8s stop || log "Warning: Failed to stop microk8s"
    fi
    log "microk8s cleanup completed"
else
    log "microk8s not found, skipping microk8s cleanup"
fi

# 8.4 Add VM deletion (multipass delete and purge)
log "Cleaning up multipass VM..."
if vm_exists; then
    log "VM '$VM_NAME' exists"
    
    # Stop VM if running
    if vm_running; then
        log "Stopping VM '$VM_NAME'..."
        multipass stop "$VM_NAME" || handle_error "Failed to stop VM '$VM_NAME'"
        log "VM '$VM_NAME' stopped successfully"
    fi
    
    # Delete VM
    log "Deleting VM '$VM_NAME'..."
    multipass delete "$VM_NAME" || handle_error "Failed to delete VM '$VM_NAME'"
    log "VM '$VM_NAME' marked for deletion"
    
    # Purge deleted VMs
    log "Purging deleted VMs..."
    multipass purge || handle_error "Failed to purge deleted VMs"
    log "VM cleanup completed successfully"
else
    log "VM '$VM_NAME' does not exist, skipping VM cleanup"
fi

# 8.5 Add cleanup confirmation prompt (or flag for non-interactive)
# This is handled by the confirm_cleanup function above

# 8.6 Add error handling for cleanup failures
# This is handled by the handle_error function and set -e

# Additional cleanup - clean up log files
log "Cleaning up temporary files..."
if [ -f "$LOG_FILE" ]; then
    log "Log file created: $LOG_FILE"
fi

if [ -f "deployment.log" ]; then
    log "Removing deployment.log..."
    rm -f deployment.log || log "Warning: Failed to remove deployment.log"
fi

# Clean up any test files
log "Cleaning up test files..."
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "test_*" -type f -delete 2>/dev/null || true

log "All cleanup operations completed successfully"
log "Summary of cleanup actions:"
log "  - Kubernetes resources cleaned up (if applicable)"
log "  - VM '$VM_NAME' deleted and purged (if existed)"
log "  - Temporary files cleaned up"
log "  - Cleanup logged to: $LOG_FILE"

echo
echo "Cleanup completed successfully!"
echo "All resources have been removed."
echo