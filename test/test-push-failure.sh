#!/bin/bash

# Test script to verify push failure error handling
# This script intentionally creates a push failure scenario to test error handling

set -euo pipefail

# Source the common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deploy_scripts/common.sh"

# Initialize log file
setup_log_file

# Test configuration
VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
INVALID_IMAGE="localhost:32000/nonexistent-image:latest"

log_info "Starting push failure scenario test..."
log_info "This test will intentionally attempt to push a non-existent image"

# Function to test push failure scenario
test_push_failure() {
    log_info "Testing push failure with non-existent image: $INVALID_IMAGE"
    
    # Verify VM is accessible (pre-condition for test)
    if ! multipass list | grep -q "$VM_NAME"; then
        log_error "Test aborted: VM '$VM_NAME' not accessible"
        return 1
    fi
    
    # Verify Docker daemon is running in VM (pre-condition for test)
    if ! multipass exec "$VM_NAME" -- docker info >/dev/null 2>&1; then
        log_error "Test aborted: Docker daemon not accessible in VM"
        return 1
    fi
    
    # Verify the invalid image does not exist in VM's Docker daemon
    if multipass exec "$VM_NAME" -- docker images "$INVALID_IMAGE" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$INVALID_IMAGE"; then
        log_warning "Unexpected: Invalid image $INVALID_IMAGE actually exists in VM - removing it for test"
        multipass exec "$VM_NAME" -- docker rmi "$INVALID_IMAGE" >/dev/null 2>&1 || true
    fi
    
# Verify registry is accessible within VM (pre-condition for test)
if ! multipass exec "$VM_NAME" -- curl -s "http://localhost:32000/v2/_catalog" >/dev/null 2>&1; then
    log_error "Test aborted: Registry not accessible within VM at http://localhost:32000/v2/_catalog"
    log_error "Please ensure microk8s registry is enabled: multipass exec '$VM_NAME' -- microk8s enable registry"
    return 1
fi
    
    log_info "Pre-conditions verified, starting intentional push failure test..."
    
    # Attempt to push the non-existent image - this should fail
    log_info "Executing: multipass exec $VM_NAME -- docker push $INVALID_IMAGE"
    
    # Capture the output and exit code
    local push_output
    local push_exit_code
    
    if push_output=$(multipass exec "$VM_NAME" -- timeout 30 docker push "$INVALID_IMAGE" 2>&1); then
        push_exit_code=0
        log_error "UNEXPECTED: Push of non-existent image succeeded (should have failed)"
        log_error "This indicates a test setup issue - the image should not exist"
        return 1
    else
        push_exit_code=$?
        log_info "✅ EXPECTED: Push failed with exit code $push_exit_code"
        
        # Log the error output for verification
        log_info "Error output (first 5 lines):"
        echo "$push_output" | head -5 | tee -a "$LOG_FILE"
        
        # Verify the error contains expected patterns
        local error_patterns_found=0
        
        if echo "$push_output" | grep -q -E "(no such image|image not found|manifest unknown|blob unknown|tag does not exist)"; then
            log_info "✅ EXPECTED: Error message contains 'no such image' or similar pattern"
            error_patterns_found=$((error_patterns_found + 1))
        else
            log_warning "UNEXPECTED: Error message does not contain expected 'no such image' pattern"
            log_warning "Full error output:"
            echo "$push_output" | tee -a "$LOG_FILE"
        fi
        
        # Verify the exit code is non-zero
        if [ $push_exit_code -ne 0 ]; then
            log_info "✅ EXPECTED: Non-zero exit code returned ($push_exit_code)"
            error_patterns_found=$((error_patterns_found + 1))
        else
            log_error "UNEXPECTED: Exit code is 0 (should be non-zero for push failure)"
        fi
        
        # Check if we found expected error patterns
        if [ $error_patterns_found -ge 2 ]; then
            log_info "✅ SUCCESS: Push failure error handling verified"
            log_info "   - Non-existent image properly detected"
            log_info "   - Appropriate error messages displayed"
            log_info "   - Non-zero exit code returned"
            return 0
        else
            log_error "FAILURE: Push failure error handling not fully verified"
            log_error "   Only $error_patterns_found/2 expected patterns found"
            return 1
        fi
    fi
}

# Execute the test
log_info "=== PUSH FAILURE SCENARIO TEST START ==="
log_info "Test purpose: Verify error handling when pushing non-existent image"
log_info "Expected result: Script should fail with appropriate error message"
log_info ""

if test_push_failure; then
    log_info "=== PUSH FAILURE TEST PASSED ==="
    log_info "Error handling for push failure scenario is working correctly"
    exit 0
else
    log_error "=== PUSH FAILURE TEST FAILED ==="
    log_error "Error handling for push failure scenario needs attention"
    exit 1
fi