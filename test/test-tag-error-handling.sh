#!/bin/bash

# Test script to verify Docker tag error handling in tag-docker-image.sh
# This script tests various failure scenarios to ensure proper error handling

set -euo pipefail

# Set up logging
LOG_FILE="/tmp/tag-error-test-$(date +%Y%m%d-%H%M%S).log"
echo "Tag Error Handling Test Log - $(date)" > "$LOG_FILE"

# Test function to run a scenario and check results
test_scenario() {
    local scenario_name="$1"
    local expected_error_type="$2"
    local test_command="$3"
    
    echo ""
    echo "=================================================="
    echo "Testing scenario: $scenario_name"
    echo "Expected error type: $expected_error_type"
    echo "=================================================="
    
    # Run the test command and capture output
    local test_output
    local test_exit_code
    
    echo "Running test..." | tee -a "$LOG_FILE"
    
    if test_output=$(eval "$test_command" 2>&1); then
        test_exit_code=0
        echo "❌ UNEXPECTED: Command succeeded when it should have failed" | tee -a "$LOG_FILE"
        echo "Test FAILED: Expected error but command succeeded" | tee -a "$LOG_FILE"
        return 1
    else
        test_exit_code=$?
        echo "✅ EXPECTED: Command failed with exit code $test_exit_code" | tee -a "$LOG_FILE"
    fi
    
    # Check if the error output contains the expected error type
    if echo "$test_output" | grep -q "$expected_error_type"; then
        echo "✅ PASS: Error message contains expected type: $expected_error_type" | tee -a "$LOG_FILE"
    else
        echo "❌ FAIL: Error message does not contain expected type: $expected_error_type" | tee -a "$LOG_FILE"
        echo "Actual output:" | tee -a "$LOG_FILE"
        echo "$test_output" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check if structured error information is present
    if echo "$test_output" | grep -q "ERROR CODE:" && echo "$test_output" | grep -q "ERROR SUMMARY:" && echo "$test_output" | grep -q "QUICK FIX:"; then
        echo "✅ PASS: Structured error information present" | tee -a "$LOG_FILE"
    else
        echo "❌ FAIL: Missing structured error information" | tee -a "$LOG_FILE"
        echo "Looking for: ERROR CODE:, ERROR SUMMARY:, QUICK FIX:" | tee -a "$LOG_FILE"
        echo "Actual output:" | tee -a "$LOG_FILE"
        echo "$test_output" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Log the full output for debugging
    echo "Full test output:" >> "$LOG_FILE"
    echo "$test_output" >> "$LOG_FILE"
    echo "--- End of output ---" >> "$LOG_FILE"
    
    echo "✅ Test PASSED: $scenario_name" | tee -a "$LOG_FILE"
    return 0
}

# Main test execution
echo "Starting Docker tag error handling tests..." | tee -a "$LOG_FILE"

# Track overall test results
TOTAL_TESTS=0
PASSED_TESTS=0

# Test 1: Non-existent source image (use a script that references non-existent image)
echo "Test 1: Testing with non-existent source image" | tee -a "$LOG_FILE"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Create a temporary modified script with non-existent image name
cp ./deploy_scripts/tag-docker-image.sh /tmp/tag-docker-image-test-missing.sh
sed -i 's/my-ag-ui-app:latest/non-existent-image-name:latest/g' /tmp/tag-docker-image-test-missing.sh

if test_scenario "Non-existent source image" "SOURCE IMAGE NOT FOUND" "VM_NAME=my-ag-ui-app-k8s DEBUG=false /tmp/tag-docker-image-test-missing.sh"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# Clean up temporary script
rm -f /tmp/tag-docker-image-test-missing.sh

# Test 2: Invalid VM name (should fail at VM accessibility check)
echo "Test 2: Testing with invalid VM name" | tee -a "$LOG_FILE"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if test_scenario "Invalid VM name" "DOCKER ERROR" "VM_NAME=invalid-vm-name-that-does-not-exist DEBUG=false ./deploy_scripts/tag-docker-image.sh"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# Test 3: Test with invalid tag format by modifying the script temporarily
echo "Test 3: Testing with invalid tag format" | tee -a "$LOG_FILE"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Create a temporary modified script with invalid tag
cp ./deploy_scripts/tag-docker-image.sh /tmp/tag-docker-image-test-invalid.sh
sed -i 's/localhost:32000\/my-ag-ui-app:latest/invalid::registry::tag::format/g' /tmp/tag-docker-image-test-invalid.sh

if test_scenario "Invalid tag format" "INVALID REPOSITORY NAME" "VM_NAME=my-ag-ui-app-k8s DEBUG=false /tmp/tag-docker-image-test-invalid.sh"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
fi

# Clean up temporary script
rm -f /tmp/tag-docker-image-test-invalid.sh

# Summary
echo ""
echo "=================================================="
echo "TEST SUMMARY"
echo "=================================================="
echo "Total tests run: $TOTAL_TESTS"
echo "Tests passed: $PASSED_TESTS"
echo "Tests failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [ "$PASSED_TESTS" -eq "$TOTAL_TESTS" ]; then
    echo "✅ ALL TESTS PASSED: Docker tag error handling is working correctly" | tee -a "$LOG_FILE"
    echo "✅ Task 5.5 completed successfully: Tagging failure scenarios tested and verified"
    exit 0
else
    echo "❌ SOME TESTS FAILED: Docker tag error handling needs investigation" | tee -a "$LOG_FILE"
    echo "Check log file for details: $LOG_FILE"
    exit 1
fi