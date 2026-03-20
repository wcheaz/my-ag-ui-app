#!/bin/bash

# Test script to actually test microk8s installation functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="test-microk8s-installation-$(date +%s)"
LOG_FILE="$SCRIPT_DIR/test-microk8s-installation.log"

echo "Testing microk8s installation functionality..."
echo "Test VM name: $VM_NAME"
echo "Log file: $LOG_FILE"
echo ""

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to cleanup on exit
cleanup() {
    log "Cleaning up test VM..."
    if multipass list | grep -q "$VM_NAME"; then
        multipass delete "$VM_NAME" && multipass purge
        log "Test VM deleted"
    else
        log "No test VM found to delete"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Step 1: Verify multipass is available
log "Step 1: Verifying multipass is available..."
if ! command -v multipass &> /dev/null; then
    echo "ERROR: multipass is not installed or not in PATH"
    exit 1
fi
log "✓ multipass is available"

# Step 2: Create test VM
log "Step 2: Creating test VM..."
if ! multipass launch --cpus 2 --memory 4G --disk 10G --name "$VM_NAME"; then
    echo "ERROR: Failed to create test VM"
    exit 1
fi
log "✓ Test VM created successfully"

# Step 3: Wait for VM to be ready
log "Step 3: Waiting for VM to be ready..."
sleep 10
if ! multipass exec "$VM_NAME" -- uptime; then
    echo "ERROR: VM is not responding"
    exit 1
fi
log "✓ VM is ready and responsive"

# Step 4: Install microk8s in VM
log "Step 4: Installing microk8s in VM..."
if ! multipass exec "$VM_NAME" -- sudo snap install microk8s --classic; then
    echo "ERROR: Failed to install microk8s"
    exit 1
fi
log "✓ microk8s installed successfully"

# Step 5: Configure microk8s permissions
log "Step 5: Configuring microk8s permissions..."
if ! multipass exec "$VM_NAME" -- sudo usermod -a -G microk8s ubuntu; then
    echo "ERROR: Failed to add user to microk8s group"
    exit 1
fi
if ! multipass exec "$VM_NAME" -- sudo chown -f -R ubuntu ~/.kube; then
    echo "WARNING: Failed to chown .kube directory (may not exist yet)"
fi
log "✓ microk8s permissions configured"

# Step 6: Wait for microk8s to be ready
log "Step 6: Waiting for microk8s to be ready..."
sleep 30
if ! multipass exec "$VM_NAME" -- sudo microk8s status --wait-ready; then
    echo "ERROR: microk8s is not ready"
    exit 1
fi
log "✓ microk8s is ready"

# Step 7: Verify microk8s status
log "Step 7: Verifying microk8s status..."
if ! multipass exec "$VM_NAME" -- sudo microk8s status; then
    echo "ERROR: Failed to get microk8s status"
    exit 1
fi
log "✓ microk8s status verified"

# Step 8: Enable required add-ons
log "Step 8: Enabling required add-ons..."

# Enable DNS add-on
if ! multipass exec "$VM_NAME" -- sudo microk8s enable dns; then
    echo "ERROR: Failed to enable DNS add-on"
    exit 1
fi
log "✓ DNS add-on enabled"

# Enable storage add-on
if ! multipass exec "$VM_NAME" -- sudo microk8s enable storage; then
    echo "ERROR: Failed to enable storage add-on"
    exit 1
fi
log "✓ Storage add-on enabled"

# Enable ingress add-on
if ! multipass exec "$VM_NAME" -- sudo microk8s enable ingress; then
    echo "ERROR: Failed to enable ingress add-on"
    exit 1
fi
log "✓ Ingress add-on enabled"

# Step 9: Verify add-ons are enabled
log "Step 9: Verifying add-ons are enabled..."
sleep 10

# Get the status and check for enabled add-ons
ADDON_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s status)

# Check if DNS is enabled
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "dns"; then
    echo "ERROR: DNS add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ DNS add-on is enabled"

# Check if storage is enabled (look for hostpath-storage since storage is deprecated)
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "hostpath-storage"; then
    echo "ERROR: Storage add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ Storage add-on is enabled"

# Check if ingress is enabled
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "ingress"; then
    echo "ERROR: Ingress add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ Ingress add-on is enabled"

# Step 10: Test basic kubectl functionality
log "Step 10: Testing basic kubectl functionality..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl get nodes; then
    echo "ERROR: kubectl get nodes failed"
    exit 1
fi
log "✓ kubectl get nodes works"

if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -n kube-system; then
    echo "ERROR: kubectl get pods failed"
    exit 1
fi
log "✓ kubectl get pods works"

# Step 11: Test cluster info
log "Step 11: Getting cluster info..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl cluster-info; then
    echo "ERROR: kubectl cluster-info failed"
    exit 1
fi
log "✓ Cluster info retrieved successfully"



echo ""
log "All microk8s installation tests passed!"
echo ""
log "Tested functionality:"
log "- VM creation with multipass"
log "- microk8s installation in VM"
log "- microk8s readiness verification"
log "- Required add-ons enablement (dns, storage, ingress)"
log "- Add-on status verification"
log "- Basic kubectl functionality"
log ""
log "Test completed successfully!"