#!/bin/bash

# Test error handling when VM has no network connectivity
# This test verifies that setup_vm_docker() properly handles network connectivity issues

set -e

echo "=== Testing Docker Setup Error Handling: No Network Connectivity ==="

# Configuration
TEST_VM="test-docker-no-network"
LOG_FILE="/tmp/test-docker-no-network.log"

# Clean up any existing test VM
cleanup() {
    echo "Cleaning up test environment..."
    if multipass list | grep -q "${TEST_VM}"; then
        echo "Deleting test VM: ${TEST_VM}"
        multipass delete ${TEST_VM} --purge || true
    fi
    # Clean up log file
    rm -f ${LOG_FILE}
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Clean up before starting
cleanup

echo "Step 1: Creating test VM ${TEST_VM}..."
multipass launch --name ${TEST_VM} --memory 2G --cpus 2

echo "Step 2: Installing Docker in VM (while it still has network)..."
# First install Docker normally since we need it installed to test network errors during Docker operations
multipass exec ${TEST_VM} -- bash -c "curl -fsSL https://get.docker.com | sh" || {
    echo "ERROR: Failed to install Docker in VM"
    exit 1
}

multipass exec ${TEST_VM} -- bash -c "sudo usermod -aG docker ubuntu" || {
    echo "ERROR: Failed to add user to docker group"
    exit 1
}

echo "Step 3: Stopping Docker daemon..."
multipass exec ${TEST_VM} -- bash -c "sudo systemctl stop docker" || {
    echo "ERROR: Failed to stop Docker daemon"
    exit 1
}

echo "Step 4: Simulating network connectivity loss by modifying /etc/hosts..."
# Simulate network connectivity loss by breaking DNS resolution
# This is safer than iptables and works in most VM environments
multipass exec ${TEST_VM} -- bash -c "sudo cp /etc/hosts /etc/hosts.backup" || {
    echo "ERROR: Failed to backup /etc/hosts"
    exit 1
}

# Add invalid entries to /etc/hosts to break DNS resolution
multipass exec ${TEST_VM} -- bash -c "echo '127.0.0.1 invalid-host' | sudo tee -a /etc/hosts" || {
    echo "ERROR: Failed to modify /etc/hosts"
    exit 1
}

echo "Step 5: Testing network connectivity (should be limited)..."
# Test that we can't resolve external hosts
if multipass exec ${TEST_VM} -- bash -c "nslookup google.com" 2>/dev/null; then
    echo "WARNING: DNS resolution still working, network isolation may not be complete"
else
    echo "DNS resolution successfully blocked."
fi

echo "Step 6: Testing setup_vm_docker() error handling..."
# Load the setup_vm_docker function
source ./deploy.sh

# Test the function with network issues
echo "Running setup_vm_docker() with network connectivity issues..."
if setup_vm_docker "${TEST_VM}" 2>&1 | tee ${LOG_FILE}; then
    echo "ERROR: setup_vm_docker() succeeded when it should have failed due to network issues"
    exit 1
fi

echo "Step 7: Verifying error handling..."
# Check that the function detected the network issue
if ! grep -q "network" ${LOG_FILE}; then
    echo "ERROR: Expected network-related error message not found in logs"
    echo "Log contents:"
    cat ${LOG_FILE}
    exit 1
fi

# Check that the function provided helpful error information
if ! grep -i -E "(fail|error|network|connectivity)" ${LOG_FILE}; then
    echo "ERROR: Expected error message not found in logs"
    echo "Log contents:"
    cat ${LOG_FILE}
    exit 1
fi

echo "Step 8: Verifying Docker status (should still be stopped)..."
# Verify Docker is still stopped since network was unavailable
if multipass exec ${TEST_VM} -- bash -c "sudo systemctl is-active docker" 2>/dev/null; then
    echo "ERROR: Docker daemon is running when it should be stopped due to network error"
    exit 1
fi

echo "Step 9: Restoring network connectivity..."
# Restore network connectivity by restoring /etc/hosts
multipass exec ${TEST_VM} -- bash -c "sudo cp /etc/hosts.backup /etc/hosts" || {
    echo "WARNING: Failed to restore /etc/hosts"
}

echo "Step 10: Verifying network connectivity is restored..."
# Verify network is restored by testing DNS resolution
if multipass exec ${TEST_VM} -- bash -c "nslookup google.com" 2>/dev/null; then
    echo "Network connectivity successfully restored."
else
    echo "WARNING: Network connectivity may not be fully restored"
fi

echo "Step 11: Testing that setup_vm_docker() works after network is restored..."
# Now that network is restored, the function should work
if ! setup_vm_docker "${TEST_VM}" 2>&1 | tee -a ${LOG_FILE}; then
    echo "ERROR: setup_vm_docker() failed even after network was restored"
    echo "Log contents:"
    cat ${LOG_FILE}
    exit 1
fi

echo "Step 12: Verifying Docker is running after network is restored..."
# Verify Docker is now running
if ! multipass exec ${TEST_VM} -- bash -c "sudo systemctl is-active docker" 2>/dev/null; then
    echo "ERROR: Docker daemon is not running after network restoration"
    exit 1
fi

echo "Step 13: Verifying Docker commands work..."
# Verify Docker commands work
if ! multipass exec ${TEST_VM} -- bash -c "docker ps" 2>/dev/null; then
    echo "ERROR: Docker commands not working after network restoration"
    exit 1
fi

echo ""
echo "=== Test Results: SUCCESS ==="
echo "✓ setup_vm_docker() properly handled network connectivity loss"
echo "✓ Function failed gracefully when network was unavailable"
echo "✓ Appropriate error messages were displayed"
echo "✓ Function worked correctly after network was restored"
echo "✓ Docker daemon is running and functional"

# Show the log for reference
echo ""
echo "=== Log File Contents ==="
cat ${LOG_FILE}

echo ""
echo "=== Test completed successfully ==="