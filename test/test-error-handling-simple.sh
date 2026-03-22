#!/bin/bash

# Test script to verify error handling provides clear messages when transfers fail
# This script tests the error handling functions directly without running full deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to log test results
log_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓ PASS${NC}: $test_name - $details"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗ FAIL${NC}: $test_name - $details"
    fi
}

# Function to check if error message contains expected elements
validate_error_message() {
    local error_output="$1"
    local test_name="$2"
    local expected_elements=("${@:3}")
    
    local all_elements_found=true
    local missing_elements=()
    
    for element in "${expected_elements[@]}"; do
        if ! echo "$error_output" | grep -q "$element"; then
            all_elements_found=false
            missing_elements+=("$element")
        fi
    done
    
    if [ "$all_elements_found" = true ]; then
        log_test_result "$test_name" "PASS" "All expected elements found in error message"
        return 0
    else
        local missing_list=$(IFS=", "; echo "${missing_elements[*]}")
        log_test_result "$test_name" "FAIL" "Missing elements: $missing_list"
        return 1
    fi
}

# Create a test script that sources deploy.sh and tests error handling
test_error_handling_functions() {
    echo "Testing error handling functions..."
    
    # Source the deploy.sh script to access its functions
    source ./deploy.sh
    
    # Test 1: Test directory creation failure (error code 110)
    echo "Testing directory creation error (code 110)..."
    
    # Create a temporary script to test the error handler
    cat > /tmp/test-110.sh << 'EOF'
#!/bin/bash
source ./deploy.sh

# Test error code 110
handle_secrets_error 110 "Failed to create k8s directory in VM" \
    "Check if VM is running and accessible: multipass info '$VM_NAME'"
EOF
    
    chmod +x /tmp/test-110.sh
    cd /home/ncheaz/git/my-ag-ui-app
    /tmp/test-110.sh > /tmp/test-110-output.log 2>&1 || true
    
    local error_output_110=$(cat /tmp/test-110-output.log)
    validate_error_message "$error_output_110" "Directory creation failure (code 110)" \
        "SECRETS SETUP ERROR" "Code: 110" "Failed to create k8s directory in VM" \
        "RECOVERY SUGGESTION" "multipass info" "VM_NAME"
    
    # Test 2: Test secrets.yaml transfer failure (error code 111)
    echo "Testing secrets.yaml transfer error (code 111)..."
    
    cat > /tmp/test-111.sh << 'EOF'
#!/bin/bash
source ./deploy.sh

# Test error code 111
handle_secrets_error 111 "Failed to transfer secrets.yaml to VM" \
    "Check if secrets.yaml exists in k8s directory"
EOF
    
    chmod +x /tmp/test-111.sh
    /tmp/test-111.sh > /tmp/test-111-output.log 2>&1 || true
    
    local error_output_111=$(cat /tmp/test-111-output.log)
    validate_error_message "$error_output_111" "Secrets transfer failure (code 111)" \
        "SECRETS SETUP ERROR" "Code: 111" "Failed to transfer secrets.yaml to VM" \
        "RECOVERY SUGGESTION" "1. Verify secrets.yaml exists locally" \
        "2. Check file permissions" "3. Verify VM is accessible" \
        "4. Manual transfer test" "5. If file doesn't exist, run setup-secrets.sh"
    
    # Test 3: Test deployment.yaml transfer failure (error code 112)
    echo "Testing deployment.yaml transfer error (code 112)..."
    
    cat > /tmp/test-112.sh << 'EOF'
#!/bin/bash
source ./deploy.sh

# Test error code 112
handle_secrets_error 112 "Failed to transfer deployment.yaml to VM" \
    "Check if deployment.yaml exists in k8s directory"
EOF
    
    chmod +x /tmp/test-112.sh
    /tmp/test-112.sh > /tmp/test-112-output.log 2>&1 || true
    
    local error_output_112=$(cat /tmp/test-112-output.log)
    validate_error_message "$error_output_112" "Deployment transfer failure (code 112)" \
        "SECRETS SETUP ERROR" "Code: 112" "Failed to transfer deployment.yaml to VM" \
        "RECOVERY SUGGESTION" "1. Verify deployment.yaml exists locally" \
        "2. Check file is not empty" "3. Verify VM is accessible" \
        "4. Manual transfer test" "5. Check file syntax"
    
    # Test 4: Test file validation failure (error code 115)
    echo "Testing secrets.yaml validation error (code 115)..."
    
    cat > /tmp/test-115.sh << 'EOF'
#!/bin/bash
source ./deploy.sh

# Test error code 115
handle_secrets_error 115 "secrets.yaml does not exist in VM after transfer" \
    "Check if file transfer was successful"
EOF
    
    chmod +x /tmp/test-115.sh
    /tmp/test-115.sh > /tmp/test-115-output.log 2>&1 || true
    
    local error_output_115=$(cat /tmp/test-115-output.log)
    validate_error_message "$error_output_115" "Secrets validation failure (code 115)" \
        "SECRETS SETUP ERROR" "Code: 115" "secrets.yaml does not exist in VM after transfer" \
        "RECOVERY SUGGESTION" "1. Check if transfer actually succeeded" \
        "2. Verify secrets.yaml exists in VM" "3. Check file size in VM" \
        "4. Manual re-transfer" "5. If file exists but validation fails"
    
    # Test 5: Test error message completeness for all file transfer errors
    echo "Testing error message completeness for all file transfer errors..."
    
    # Check that all error codes 110-118 have proper handling
    local error_codes=(110 111 112 113 114 115 116 117 118)
    for code in "${error_codes[@]}"; do
        cat > /tmp/test-$code-complete.sh << EOF
#!/bin/bash
source ./deploy.sh

# Test error code $code completeness
handle_secrets_error $code "Test error message for code $code" \
    "Test recovery suggestion for code $code"
EOF
        
        chmod +x /tmp/test-$code-complete.sh
        /tmp/test-$code-complete.sh > /tmp/test-$code-complete-output.log 2>&1 || true
        
        local error_output=$(cat /tmp/test-$code-complete-output.log)
        if echo "$error_output" | grep -q "ENHANCED RECOVERY SUGGESTIONS:"; then
            log_test_result "Error code $code enhanced recovery" "PASS" "Enhanced recovery suggestions provided"
        else
            log_test_result "Error code $code enhanced recovery" "FAIL" "Enhanced recovery suggestions missing"
        fi
        
        if echo "$error_output" | grep -q "FILE TRANSFER DIAGNOSTIC INFO:"; then
            log_test_result "Error code $code diagnostic info" "PASS" "File transfer diagnostic info provided"
        else
            log_test_result "Error code $code diagnostic info" "FAIL" "File transfer diagnostic info missing"
        fi
    done
}

# Run all tests
run_all_tests() {
    echo "Starting error handling tests..."
    echo "================================"
    
    # Test error handling
    test_error_handling_functions
    
    echo "================================"
    echo "Test Results Summary:"
    echo "================================"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed! Error handling provides clear messages.${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. Error handling needs improvement.${NC}"
        return 1
    fi
}

# Cleanup function
cleanup_test_files() {
    echo "Cleaning up test files..."
    rm -f /tmp/test-*.sh /tmp/test-*-output.log
    echo "Cleanup complete"
}

# Main execution
main() {
    # Check if deploy.sh exists
    if [ ! -f "deploy.sh" ]; then
        echo "Error: deploy.sh not found in current directory"
        exit 1
    fi
    
    # Run tests
    run_all_tests
    local test_result=$?
    
    # Cleanup
    cleanup_test_files
    
    # Exit with test result
    exit $test_result
}

# Execute main function
main "$@"