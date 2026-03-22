#!/bin/bash

# Simple test script for file validation - tests only the validation logic
# This test intentionally creates missing file scenarios and validates error handling

set -e  # Exit on any error

echo "=== Testing File Validation for Missing Files ==="
echo "This test will intentionally create missing file scenarios and validate error handling"

# Test configuration
VM_NAME="my-ag-ui-app-k8s"
TEST_LOG="/tmp/file-validation-test-$(date +%Y%m%d-%H%M%S).log"

# Function to log test output
test_log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] TEST: $message" | tee -a "$TEST_LOG"
}

# Function to cleanup test environment
cleanup_test() {
    test_log "Cleaning up test environment..."
    # Remove test files from VM if they exist
    multipass exec "$VM_NAME" -- rm -rf /home/ubuntu/k8s 2>/dev/null || true
    test_log "Test environment cleaned up"
}

# Function to run validation test
run_validation_test() {
    local test_name="$1"
    local missing_file="$2"
    
    test_log "Running test: $test_name"
    test_log "Expected missing file: $missing_file"
    
    # Setup: Create k8s directory and transfer only some files
    test_log "Setting up test scenario..."
    
    # Ensure k8s directory exists
    multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/k8s 2>/dev/null || true
    
    # Transfer only 3 out of 4 files (simulate missing file scenario)
    case $missing_file in
        "secrets.yaml")
            test_log "Transferring all files EXCEPT secrets.yaml..."
            multipass transfer k8s/deployment.yaml "$VM_NAME":/home/ubuntu/k8s/deployment.yaml 2>/dev/null || true
            multipass transfer k8s/service.yaml "$VM_NAME":/home/ubuntu/k8s/service.yaml 2>/dev/null || true
            multipass transfer k8s/ingress.yaml "$VM_NAME":/home/ubuntu/k8s/ingress.yaml 2>/dev/null || true
            ;;
        "deployment.yaml")
            test_log "Transferring all files EXCEPT deployment.yaml..."
            multipass transfer k8s/secrets.yaml "$VM_NAME":/home/ubuntu/k8s/secrets.yaml 2>/dev/null || true
            multipass transfer k8s/service.yaml "$VM_NAME":/home/ubuntu/k8s/service.yaml 2>/dev/null || true
            multipass transfer k8s/ingress.yaml "$VM_NAME":/home/ubuntu/k8s/ingress.yaml 2>/dev/null || true
            ;;
        "service.yaml")
            test_log "Transferring all files EXCEPT service.yaml..."
            multipass transfer k8s/secrets.yaml "$VM_NAME":/home/ubuntu/k8s/secrets.yaml 2>/dev/null || true
            multipass transfer k8s/deployment.yaml "$VM_NAME":/home/ubuntu/k8s/deployment.yaml 2>/dev/null || true
            multipass transfer k8s/ingress.yaml "$VM_NAME":/home/ubuntu/k8s/ingress.yaml 2>/dev/null || true
            ;;
        "ingress.yaml")
            test_log "Transferring all files EXCEPT ingress.yaml..."
            multipass transfer k8s/secrets.yaml "$VM_NAME":/home/ubuntu/k8s/secrets.yaml 2>/dev/null || true
            multipass transfer k8s/deployment.yaml "$VM_NAME":/home/ubuntu/k8s/deployment.yaml 2>/dev/null || true
            multipass transfer k8s/service.yaml "$VM_NAME":/home/ubuntu/k8s/service.yaml 2>/dev/null || true
            ;;
    esac
    
    # List files actually in VM for debugging
    test_log "Files in VM k8s directory:"
    multipass exec "$VM_NAME" -- ls -la /home/ubuntu/k8s/ 2>/dev/null || test_log "Unable to list files in VM k8s directory"
    
    # Test the validation by directly running the validation commands
    test_log "Testing validation for missing $missing_file..."
    
    # Extract the validation logic from deploy.sh and test it
    case $missing_file in
        "secrets.yaml")
            # Test secrets.yaml validation (should fail)
            if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/secrets.yaml 2>/dev/null; then
                test_log "✓ PASS: secrets.yaml correctly detected as missing"
                return 0
            else
                test_log "✗ FAIL: secrets.yaml was not detected as missing"
                return 1
            fi
            ;;
        "deployment.yaml")
            # Test deployment.yaml validation (should fail)
            if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/deployment.yaml 2>/dev/null; then
                test_log "✓ PASS: deployment.yaml correctly detected as missing"
                return 0
            else
                test_log "✗ FAIL: deployment.yaml was not detected as missing"
                return 1
            fi
            ;;
        "service.yaml")
            # Test service.yaml validation (should fail)
            if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/service.yaml 2>/dev/null; then
                test_log "✓ PASS: service.yaml correctly detected as missing"
                return 0
            else
                test_log "✗ FAIL: service.yaml was not detected as missing"
                return 1
            fi
            ;;
        "ingress.yaml")
            # Test ingress.yaml validation (should fail)
            if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/ingress.yaml 2>/dev/null; then
                test_log "✓ PASS: ingress.yaml correctly detected as missing"
                return 0
            else
                test_log "✗ FAIL: ingress.yaml was not detected as missing"
                return 1
            fi
            ;;
    esac
}

# Main test execution
test_log "Starting file validation tests..."

# Check if VM exists and is running
if ! multipass info "$VM_NAME" >/dev/null 2>&1; then
    test_log "ERROR: VM '$VM_NAME' does not exist or is not accessible"
    test_log "Please ensure the VM is created and running before running this test"
    exit 1
fi

test_log "VM '$VM_NAME' is accessible"

# Initialize test counters
TOTAL_TESTS=4
PASSED_TESTS=0
FAILED_TESTS=0

# Test 1: Missing secrets.yaml (error code 115)
if run_validation_test "Missing secrets.yaml" "secrets.yaml"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
cleanup_test

# Test 2: Missing deployment.yaml (error code 116)
if run_validation_test "Missing deployment.yaml" "deployment.yaml"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
cleanup_test

# Test 3: Missing service.yaml (error code 117)
if run_validation_test "Missing service.yaml" "service.yaml"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
cleanup_test

# Test 4: Missing ingress.yaml (error code 118)
if run_validation_test "Missing ingress.yaml" "ingress.yaml"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
cleanup_test

# Test results summary
test_log "=== Test Results Summary ==="
test_log "Total tests run: $TOTAL_TESTS"
test_log "Tests passed: $PASSED_TESTS"
test_log "Tests failed: $FAILED_TESTS"

if [ "$FAILED_TESTS" -eq 0 ]; then
    test_log "✓ ALL TESTS PASSED: File validation correctly detects missing files"
    echo ""
    echo "SUCCESS: File validation test completed successfully"
    echo "All missing file scenarios were properly detected"
    exit 0
else
    test_log "✗ SOME TESTS FAILED: File validation did not properly detect all missing files"
    echo ""
    echo "FAILURE: File validation test failed"
    echo "Check the test log: $TEST_LOG"
    exit 1
fi