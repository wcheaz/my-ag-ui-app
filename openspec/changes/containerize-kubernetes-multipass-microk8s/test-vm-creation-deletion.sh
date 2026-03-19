#!/bin/bash

# Test script for VM creation and deletion functionality
# This script tests that VMs can be created and deleted properly

set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipeline fails

# Configuration
TEST_VM_NAME="test-vm-creation-deletion"
VM_CPUS=2
VM_MEMORY="2G"
VM_DISK="5G"
LOG_FILE="vm-test.log"

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
    multipass list | grep -q "^$TEST_VM_NAME "
}

# Function to check if VM is running
vm_running() {
    multipass info "$TEST_VM_NAME" 2>/dev/null | grep -q "State:[[:space:]]*Running"
}

# Cleanup function to ensure test VM is removed
cleanup_test_vm() {
    log "Cleaning up test VM '$TEST_VM_NAME'..."
    if vm_exists; then
        log "Test VM exists, stopping and deleting..."
        if vm_running; then
            multipass stop "$TEST_VM_NAME" || log "Warning: Failed to stop test VM"
        fi
        multipass delete "$TEST_VM_NAME" || log "Warning: Failed to delete test VM"
        multipass purge || log "Warning: Failed to purge test VM"
        log "Test VM cleaned up"
    else
        log "Test VM does not exist, no cleanup needed"
    fi
}

# Set trap to ensure cleanup happens even if script fails
trap cleanup_test_vm EXIT

# =====================
# TEST EXECUTION
# =====================

log "Starting VM creation and deletion test..."
log "Test VM configuration: $VM_CPUS CPUs, $VM_MEMORY RAM, $VM_DISK disk"

# Check prerequisites
log "Checking prerequisites..."
if ! command_exists multipass; then
    handle_error "multipass is not installed. Please install multipass before running this test."
fi
log "multipass is installed: $(multipass version)"

# Ensure no existing test VM
log "Ensuring no existing test VM..."
cleanup_test_vm
sleep 2  # Give some time for cleanup to complete

# Test 1: VM Creation
log ""
log "=== TEST 1: VM Creation ==="
log "Creating test VM '$TEST_VM_NAME'..."

# Create VM with smaller resources for testing
if ! multipass launch \
    --name "$TEST_VM_NAME" \
    --cpus "$VM_CPUS" \
    --memory "$VM_MEMORY" \
    --disk "$VM_DISK" \
    --timeout 300; then
    handle_error "Failed to create test VM"
fi

log "Test VM '$TEST_VM_NAME' created successfully"

# Verify VM exists
if ! vm_exists; then
    handle_error "VM creation reported success but VM does not exist in multipass list"
fi

log "VM existence verified in multipass list"

# Test 2: VM Readiness
log ""
log "=== TEST 2: VM Readiness ==="
log "Waiting for VM to be ready..."

MAX_ATTEMPTS=60
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if vm_running; then
    # Get VM state info
    VM_STATE=$(multipass info "$TEST_VM_NAME" 2>/dev/null | grep "State:" | awk '{print $2}' | tr -d '\r\n ')
        log "VM state: $VM_STATE"
        
        # Test if VM has IP address
        VM_IP=$(multipass info "$TEST_VM_NAME" 2>/dev/null | grep "IPv4:" | awk '{print $2}' | tr -d '\r\n ')
        if [ -n "$VM_IP" ]; then
            log "VM IP address: $VM_IP"
            
            # Test if VM is responsive by running a simple command
            if multipass exec "$TEST_VM_NAME" -- echo "VM readiness test" >/dev/null 2>&1; then
                log "VM is ready and responsive"
                break
            else
                log "VM is running with IP but SSH not ready yet..."
            fi
        else
            log "VM is running but no IP address yet..."
        fi
    else
        log "VM is not running yet... (State: $(multipass info "$TEST_VM_NAME" 2>/dev/null | grep "State:" | awk '{print $2}' | tr -d '\r\n ' || echo 'unknown'))"
    fi
    log "Waiting for VM to be ready... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    if vm_running; then
        handle_error "VM is running but not responsive after $MAX_ATTEMPTS attempts"
    else
        handle_error "VM failed to start after $MAX_ATTEMPTS attempts"
    fi
fi

# Test 3: VM Networking
log ""
log "=== TEST 3: VM Networking ==="
log "Testing VM networking..."

# Get VM IP
VM_IP=$(multipass info "$TEST_VM_NAME" | grep "IPv4:" | awk '{print $2}')
if [ -z "$VM_IP" ]; then
    handle_error "VM has no IP address"
fi
log "VM IP address: $VM_IP"

# Test DNS resolution
log "Testing DNS resolution..."
if ! multipass exec "$TEST_VM_NAME" -- nslookup google.com >/dev/null 2>&1; then
    handle_error "DNS resolution test failed"
fi
log "DNS resolution test passed"

# Test outbound connectivity
log "Testing outbound connectivity..."
if ! multipass exec "$TEST_VM_NAME" -- curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    handle_error "Outbound connectivity test failed"
fi
log "Outbound connectivity test passed"

# Test SSH access
log "Testing SSH access..."
if ! multipass exec "$TEST_VM_NAME" -- echo "SSH access test successful" >/dev/null 2>&1; then
    handle_error "SSH access test failed"
fi
log "SSH access test passed"

log "VM networking tests passed"

# Test 4: VM Information
log ""
log "=== TEST 4: VM Information ==="
log "Retrieving VM information..."

# Get VM info
log "VM Information:"
multipass info "$TEST_VM_NAME" | tee -a "$LOG_FILE"

# Verify VM resources
log "Verifying VM resources..."

# Check CPU count
ACTUAL_CPUS=$(multipass info "$TEST_VM_NAME" | grep "CPU(s):" | awk '{print $2}' | sed 's/,//' | tr -d '\r\n ')
if [ "$ACTUAL_CPUS" != "$VM_CPUS" ]; then
    handle_error "VM has incorrect number of CPUs: expected $VM_CPUS, got $ACTUAL_CPUS"
fi
log "CPU count verified: $ACTUAL_CPUS"

# Check memory (this is approximate since multipass may show slightly different values)
MEMORY_INFO=$(multipass info "$TEST_VM_NAME" | grep "Memory usage:" | awk '{print $3}' | tr -d '\r\n ')
log "Memory info: $MEMORY_INFO (expected: $VM_MEMORY)"

# Check disk size
DISK_INFO=$(multipass info "$TEST_VM_NAME" | grep "Disk usage:" | awk '{print $3}' | tr -d '\r\n ')
log "Disk info: $DISK_INFO (expected: $VM_DISK)"

log "VM information verified"

# Test 5: VM File Operations
log ""
log "=== TEST 5: VM File Operations ==="
log "Testing file operations in VM..."

# Create test file in VM
log "Creating test file in VM..."
if ! multipass exec "$TEST_VM_NAME" -- bash -c "echo 'VM test file content' > /tmp/test_vm_file.txt"; then
    handle_error "Failed to create test file in VM"
fi

# Read test file from VM
log "Reading test file from VM..."
TEST_FILE_CONTENT=$(multipass exec "$TEST_VM_NAME" -- cat /tmp/test_vm_file.txt)
if [ "$TEST_FILE_CONTENT" != "VM test file content" ]; then
    handle_error "Test file content mismatch: expected 'VM test file content', got '$TEST_FILE_CONTENT'"
fi
log "Test file content verified: $TEST_FILE_CONTENT"

# Clean up test file
log "Cleaning up test file..."
multipass exec "$TEST_VM_NAME" -- rm -f /tmp/test_vm_file.txt
log "File operations test passed"

# Test 6: VM Deletion
log ""
log "=== TEST 6: VM Deletion ==="
log "Testing VM deletion..."

# Stop VM
log "Stopping VM..."
if ! multipass stop "$TEST_VM_NAME"; then
    handle_error "Failed to stop VM"
fi
log "VM stopped successfully"

# Verify VM is stopped
if vm_running; then
    handle_error "VM is still running after stop command"
fi
log "VM stop verified"

# Delete VM
log "Deleting VM..."
if ! multipass delete "$TEST_VM_NAME"; then
    handle_error "Failed to delete VM"
fi
log "VM marked for deletion successfully"

# Purge VM
log "Purging VM..."
if ! multipass purge; then
    handle_error "Failed to purge VM"
fi
log "VM purged successfully"

# Verify VM is deleted
if vm_exists; then
    handle_error "VM still exists after deletion and purge"
fi
log "VM deletion verified"

# Test 7: VM Recreation (idempotency test)
log ""
log "=== TEST 7: VM Recreation (Idempotency Test) ==="
log "Testing that VM can be recreated after deletion..."

# Recreate VM with same name
log "Recreating VM '$TEST_VM_NAME'..."
if ! multipass launch \
    --name "$TEST_VM_NAME" \
    --cpus "$VM_CPUS" \
    --memory "$VM_MEMORY" \
    --disk "$VM_DISK" \
    --timeout 300; then
    handle_error "Failed to recreate VM"
fi

log "VM recreated successfully"

# Verify recreated VM is ready
log "Waiting for recreated VM to be ready..."
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if vm_running && multipass exec "$TEST_VM_NAME" -- uptime >/dev/null 2>&1; then
        log "Recreated VM is ready"
        break
    fi
    log "Waiting for recreated VM... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    handle_error "Recreated VM failed to become ready"
fi

log "VM recreation test passed"

# Final cleanup
log ""
log "=== FINAL CLEANUP ==="
cleanup_test_vm
log "Final cleanup completed"

# Test Summary
log ""
log "=== TEST SUMMARY ==="
log "VM creation and deletion test completed successfully!"
log ""
log "Tests performed:"
log "  ✓ VM Creation"
log "  ✓ VM Readiness"
log "  ✓ VM Networking"
log "  ✓ VM Information"
log "  ✓ VM File Operations"
log "  ✓ VM Deletion"
log "  ✓ VM Recreation (Idempotency)"
log ""
log "All tests passed. VM creation and deletion functionality is working correctly."
log "Test log saved to: $LOG_FILE"

echo
echo "SUCCESS: All VM creation and deletion tests passed!"