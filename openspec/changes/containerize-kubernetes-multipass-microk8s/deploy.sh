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
if [ -z "$VM_IP" ]; then
    handle_error "Failed to get VM IP address - VM networking is not properly configured"
fi
log "VM '$VM_NAME' IP address: $VM_IP"

# Test DNS resolution
log "Testing DNS resolution in VM..."
if ! multipass exec "$VM_NAME" -- nslookup google.com >/dev/null 2>&1; then
    log "ERROR: DNS resolution test failed in VM"
    log "This may prevent Kubernetes from pulling images and resolving service names"
    handle_error "VM DNS resolution is not working"
fi
log "DNS resolution test passed"

# Test outbound connectivity
log "Testing outbound connectivity from VM..."
if ! multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    log "ERROR: Outbound connectivity test failed in VM"
    log "This will prevent Kubernetes from pulling container images"
    handle_error "VM outbound connectivity is not working"
fi
log "Outbound connectivity test passed"

# Test container image pulling (critical for Kubernetes)
log "Testing container image pulling capability..."
if ! multipass exec "$VM_NAME" -- docker pull alpine:latest >/dev/null 2>&1; then
    log "WARNING: Could not test Docker image pulling (Docker may not be installed yet)"
    log "This is expected if Docker hasn't been installed in the VM yet"
else
    log "Container image pulling test passed"
    # Clean up the test image
    multipass exec "$VM_NAME" -- docker rmi alpine:latest >/dev/null 2>&1 || true
fi

# Test connectivity from host to VM
log "Testing connectivity from host to VM..."
if ! ping -c 1 -W 5 "$VM_IP" >/dev/null 2>&1; then
    log "WARNING: Cannot ping VM from host"
    log "This may be due to firewall restrictions but should not prevent Kubernetes operation"
else
    log "Host to VM connectivity test passed"
fi

# Test SSH access to VM (required for microk8s installation)
log "Testing SSH access to VM..."
if ! multipass exec "$VM_NAME" -- echo "SSH access test successful" >/dev/null 2>&1; then
    handle_error "SSH access to VM failed - this is required for microk8s installation"
fi
log "SSH access test passed"

log "VM networking verification completed successfully"

# 3.6 Add VM status monitoring during deployment
log "=== VM Status Monitoring ==="
log "VM '$VM_NAME' detailed status:"

# Get comprehensive VM information
log "VM Basic Information:"
multipass info "$VM_NAME" | tee -a "$LOG_FILE"

# Get detailed resource information
log "VM Resource Usage:"
if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
    log "Memory Usage:"
    multipass exec "$VM_NAME" -- free -h | tee -a "$LOG_FILE"
fi

if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
    log "Disk Usage:"
    multipass exec "$VM_NAME" -- df -h | tee -a "$LOG_FILE"
fi

if multipass exec "$VM_NAME" -- command -v top >/dev/null 2>&1; then
    log "CPU Information:"
    multipass exec "$VM_NAME" -- top -bn1 | head -5 | tee -a "$LOG_FILE"
fi

# Get network information
log "VM Network Configuration:"
VM_IP=$(multipass info "$VM_NAME" | grep "IPv4:" | awk '{print $2}')
log "VM IP Address: $VM_IP" | tee -a "$LOG_FILE"

if multipass exec "$VM_NAME" -- command -v ip >/dev/null 2>&1; then
    log "Network Interfaces:"
    multipass exec "$VM_NAME" -- ip addr show | tee -a "$LOG_FILE"
fi

# Monitor VM health and readiness
log "VM Health Status:"
log "Checking VM responsiveness..."
if multipass exec "$VM_NAME" -- uptime >/dev/null 2>&1; then
    UPTIME_OUTPUT=$(multipass exec "$VM_NAME" -- uptime)
    log "VM is responsive - Uptime: $UPTIME_OUTPUT" | tee -a "$LOG_FILE"
else
    handle_error "VM is not responding to commands"
fi

# Check disk space availability
log "Checking disk space availability..."
DISK_USAGE=$(multipass exec "$VM_NAME" -- df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log "WARNING: VM disk usage is at ${DISK_USAGE}% - consider cleaning up or increasing disk size"
else
    log "VM disk usage is at ${DISK_USAGE}% - acceptable"
fi

# Check memory availability
if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
    log "Checking memory availability..."
    MEMORY_INFO=$(multipass exec "$VM_NAME" -- free -m | awk 'NR==2{printf "%.2f%%", $3/$2*100}')
    log "VM memory usage: $MEMORY_INFO"
fi

# Set up continuous monitoring
log "Setting up continuous VM status monitoring..."
monitor_vm_status() {
    local monitor_count=0
    local max_monitor_count=3
    
    while [ $monitor_count -lt $max_monitor_count ]; do
        log "VM Status Check #$((monitor_count + 1)):"
        
        # Check if VM is still running
        if ! vm_running; then
            handle_error "VM stopped running during deployment"
        fi
        
        # Check VM responsiveness
        if ! multipass exec "$VM_NAME" -- echo "VM status check" >/dev/null 2>&1; then
            handle_error "VM became unresponsive during deployment"
        fi
        
        # Log current status
        log "VM is running and responsive - continuing with deployment"
        
        monitor_count=$((monitor_count + 1))
        if [ $monitor_count -lt $max_monitor_count ]; then
            sleep 5
        fi
    done
}

# Run continuous monitoring
monitor_vm_status

log "=== VM Status Monitoring Complete ==="
log "All VM status checks passed. VM is ready for microk8s installation."

log "VM provisioning completed successfully"