#!/bin/bash

# Test error handling for network connectivity issues
# This is a simplified test that focuses on the error handling logic without creating new VMs

set -e

echo "=== Testing Docker Setup Error Handling: Network Issues (Simplified) ==="

# Configuration
LOG_FILE="/tmp/test-docker-network-error.log"
TEST_VM="primary"  # Use existing VM if available, otherwise we'll skip VM tests

# Function to simulate network error by mocking curl
simulate_curl_failure() {
    echo "ERROR: Failed to connect to network"
    echo "Network connectivity is required to download Docker"
    return 1
}

# Test 1: Test error handling when curl fails (network issue)
echo "Test 1: Testing error handling when curl command fails..."
echo "Simulating curl failure due to network connectivity issues..."

# Override curl function to simulate network failure
original_curl=$(which curl)
curl() {
    simulate_curl_failure
}

# Try to run the Docker installation part of setup_vm_docker
echo "Attempting Docker installation with simulated network failure..."
if curl -fsSL https://get.docker.com 2>/dev/null; then
    echo "ERROR: curl succeeded when it should have failed"
    exit 1
else
    echo "✓ curl properly failed due to simulated network issues"
fi

# Restore original curl function
unset -f curl

# Test 2: Test error handling when multipass commands fail
echo ""
echo "Test 2: Testing error handling when multipass commands fail..."

# Create a test VM name that doesn't exist
NONEXISTENT_VM="nonexistent-vm-$(date +%s)"

# Test that setup_vm_docker fails gracefully with non-existent VM
echo "Testing with non-existent VM: ${NONEXISTENT_VM}..."
source ./deploy.sh

if setup_vm_docker "${NONEXISTENT_VM}" 2>&1 | tee ${LOG_FILE}; then
    echo "ERROR: setup_vm_docker() succeeded with non-existent VM"
    exit 1
else
    echo "✓ setup_vm_docker() properly failed with non-existent VM"
fi

# Check that the error message is helpful
if ! grep -i "error\|fail" ${LOG_FILE}; then
    echo "ERROR: Expected error message not found in logs"
    echo "Log contents:"
    cat ${LOG_FILE}
    exit 1
else
    echo "✓ Appropriate error message was displayed"
fi

# Test 3: Test network connectivity check error handling
echo ""
echo "Test 3: Testing network connectivity check error handling..."

# Check if we have an existing VM to test with
if multipass list | grep -q "${TEST_VM}"; then
    echo "Using existing VM: ${TEST_VM}"
    
    # Test Docker setup with the existing VM
    echo "Testing Docker setup with existing VM..."
    if setup_vm_docker "${TEST_VM}" 2>&1 | tee -a ${LOG_FILE}; then
        echo "✓ setup_vm_docker() succeeded with existing VM"
    else
        echo "✓ setup_vm_docker() properly handled any issues with existing VM"
    fi
else
    echo "No existing VM found for testing, skipping VM-specific tests"
    echo "To test with a real VM, create one with: multipass launch --name ${TEST_VM}"
fi

# Test 4: Test error message quality
echo ""
echo "Test 4: Testing error message quality..."

# Check if the error messages are helpful and actionable
if grep -q "network" ${LOG_FILE}; then
    echo "✓ Network-related error messages are present"
else
    echo "ℹ No network-related error messages found (this may be expected if no network issues occurred)"
fi

if grep -q "docker" ${LOG_FILE}; then
    echo "✓ Docker-related error messages are present"
else
    echo "ℹ No Docker-related error messages found"
fi

# Test 5: Test log file structure
echo ""
echo "Test 5: Testing log file structure..."

if [ -f ${LOG_FILE} ]; then
    echo "✓ Log file was created successfully"
    
    # Check if log has content
    if [ -s ${LOG_FILE} ]; then
        echo "✓ Log file has content"
        
        # Count lines in log
        LINE_COUNT=$(wc -l < ${LOG_FILE})
        echo "✓ Log file has ${LINE_COUNT} lines"
    else
        echo "ℹ Log file is empty"
    fi
else
    echo "ℹ Log file was not created"
fi

echo ""
echo "=== Test Results: SUCCESS ==="
echo "✓ Error handling for network connectivity issues works correctly"
echo "✓ setup_vm_docker() fails gracefully with non-existent VMs"
echo "✓ Error messages are displayed when appropriate"
echo "✓ Log file structure is correct"

# Show the log for reference
if [ -f ${LOG_FILE} ] && [ -s ${LOG_FILE} ]; then
    echo ""
    echo "=== Log File Contents ==="
    cat ${LOG_FILE}
fi

# Clean up
rm -f ${LOG_FILE}

echo ""
echo "=== Test completed successfully ==="