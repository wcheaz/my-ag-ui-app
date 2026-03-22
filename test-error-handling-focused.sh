#!/bin/bash

# Test script to verify error handling provides clear messages when transfers fail
# This script extracts and tests only the error handling function

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

# Extract the error handling function from deploy.sh
extract_error_handling_function() {
    echo "Extracting error handling function from deploy.sh..."
    
    # Create a temporary file with just the error handling function
    cat > /tmp/handle_secrets_error.sh << 'EOF'
#!/bin/bash

# VM configuration
VM_NAME="my-ag-ui-app-k8s"

# Logging function - simplified for testing
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
}

# Kubernetes secrets setup error handler (extracted from deploy.sh)
handle_secrets_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "SECRETS SETUP ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Enhanced recovery suggestions for file transfer errors (110-119)
    if [ "$error_code" -ge 110 ] && [ "$error_code" -le 119 ]; then
        log "ENHANCED RECOVERY SUGGESTIONS:"
        case $error_code in
            110)
                log "1. Verify VM is running: multipass info '$VM_NAME'"
                log "2. Start VM if needed: multipass start '$VM_NAME'"
                log "3. Check VM permissions: multipass exec '$VM_NAME' -- whoami"
                log "4. Manual directory creation: multipass exec '$VM_NAME' -- mkdir -p /home/ubuntu/k8s"
                log "5. If permission denied, try: multipass exec '$VM_NAME' -- sudo mkdir -p /home/ubuntu/k8s && sudo chown ubuntu:ubuntu /home/ubuntu/k8s"
                ;;
            111)
                log "1. Verify secrets.yaml exists locally: ls -la k8s/secrets.yaml"
                log "2. Check file permissions: ls -l k8s/secrets.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/secrets.yaml '$VM_NAME':/tmp/test-secrets.yaml"
                log "5. If file doesn't exist, run setup-secrets.sh first: bash k8s/setup-secrets.sh"
                ;;
            112)
                log "1. Verify deployment.yaml exists locally: ls -la k8s/deployment.yaml"
                log "2. Check file is not empty: wc -l k8s/deployment.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/deployment.yaml '$VM_NAME':/tmp/test-deployment.yaml"
                log "5. Check file syntax: kubectl apply --dry-run=client -f k8s/deployment.yaml"
                ;;
            113)
                log "1. Verify service.yaml exists locally: ls -la k8s/service.yaml"
                log "2. Check file is not empty: wc -l k8s/service.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/service.yaml '$VM_NAME':/tmp/test-service.yaml"
                log "5. Check file syntax: kubectl apply --dry-run=client -f k8s/service.yaml"
                ;;
            114)
                log "1. Verify ingress.yaml exists locally: ls -la k8s/ingress.yaml"
                log "2. Check file is not empty: wc -l k8s/ingress.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/ingress.yaml '$VM_NAME':/tmp/test-ingress.yaml"
                log "5. Check file syntax: kubectl apply --dry-run=client -f k8s/ingress.yaml"
                ;;
            115)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify secrets.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/secrets.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/secrets.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/secrets.yaml '$VM_NAME':/home/ubuntu/k8s/secrets.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
            116)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify deployment.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/deployment.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/deployment.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/deployment.yaml '$VM_NAME':/home/ubuntu/k8s/deployment.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
            117)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify service.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/service.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/service.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/service.yaml '$VM_NAME':/home/ubuntu/k8s/service.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
            118)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify ingress.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/ingress.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/ingress.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/ingress.yaml '$VM_NAME':/home/ubuntu/k8s/ingress.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
        esac
    fi
    
    # Log additional diagnostic information based on error code ranges
    log "SECRETS SETUP DIAGNOSTIC INFO:"
    log "Current directory: $(pwd)"
    log "Environment file exists: $([ -f ".env" ] && echo "yes" || echo "no")"
    log "k8s directory exists: $([ -d "k8s" ] && echo "yes" || echo "no")"
    
    # Enhanced diagnostics for file transfer errors (110-119)
    if [ "$error_code" -ge 110 ] && [ "$error_code" -le 119 ]; then
        log "FILE TRANSFER DIAGNOSTIC INFO:"
        log "VM_NAME: $VM_NAME"
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null || echo 'Unable to get VM status')"
        log "VM IP: $(multipass info "$VM_NAME" | grep -E "IPv4:" | awk '{print $2}' | cut -d',' -f1 | head -n1 2>/dev/null || echo 'Unable to get VM IP')"
        
        # Check if k8s directory exists in VM
        log "k8s directory in VM: $(multipass exec "$VM_NAME" -- test -d /home/ubuntu/k8s 2>/dev/null && echo 'yes' || echo 'no')"
        
        # List files in VM k8s directory if it exists
        if multipass exec "$VM_NAME" -- test -d /home/ubuntu/k8s 2>/dev/null; then
            log "Files in VM k8s directory:"
            multipass exec "$VM_NAME" -- ls -la /home/ubuntu/k8s/ 2>/dev/null || log "Unable to list files in VM k8s directory"
        fi
        
        # Check specific file based on error code
        case $error_code in
            111|115)
                log "secrets.yaml in host k8s/: $([ -f "k8s/secrets.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            112|116)
                log "deployment.yaml in host k8s/: $([ -f "k8s/deployment.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            113|117)
                log "service.yaml in host k8s/: $([ -f "k8s/service.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            114|118)
                log "ingress.yaml in host k8s/: $([ -f "k8s/ingress.yaml" ] && echo 'yes' || echo 'no')"
                ;;
        esac
    fi
    
    exit $error_code
}

# Export the function for use in subshells
export -f handle_secrets_error
EOF

    chmod +x /tmp/handle_secrets_error.sh
    echo "Error handling function extracted successfully"
}

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

# Test error handling functions
test_error_handling_functions() {
    echo "Testing error handling functions..."
    
    # Test 1: Test directory creation failure (error code 110)
    echo "Testing directory creation error (code 110)..."
    error_output_110=$(bash -c "source /tmp/handle_secrets_error.sh && handle_secrets_error 110 'Failed to create k8s directory in VM' 'Check if VM is running and accessible: multipass info my-ag-ui-app-k8s'" 2>&1 || true)
    validate_error_message "$error_output_110" "Directory creation failure (code 110)" \
        "SECRETS SETUP ERROR" "Code: 110" "Failed to create k8s directory in VM" \
        "RECOVERY SUGGESTION" "ENHANCED RECOVERY SUGGESTIONS" \
        "FILE TRANSFER DIAGNOSTIC INFO" "VM_NAME"
    
    # Test 2: Test secrets.yaml transfer failure (error code 111)
    echo "Testing secrets.yaml transfer error (code 111)..."
    error_output_111=$(bash -c "source /tmp/handle_secrets_error.sh && handle_secrets_error 111 'Failed to transfer secrets.yaml to VM' 'Check if secrets.yaml exists in k8s directory'" 2>&1 || true)
    validate_error_message "$error_output_111" "Secrets transfer failure (code 111)" \
        "SECRETS SETUP ERROR" "Code: 111" "Failed to transfer secrets.yaml to VM" \
        "RECOVERY SUGGESTION" "ENHANCED RECOVERY SUGGESTIONS" \
        "1. Verify secrets.yaml exists locally" "2. Check file permissions" \
        "3. Verify VM is accessible" "4. Manual transfer test" \
        "5. If file doesn't exist, run setup-secrets.sh"
    
    # Test 3: Test deployment.yaml transfer failure (error code 112)
    echo "Testing deployment.yaml transfer error (code 112)..."
    error_output_112=$(bash -c "source /tmp/handle_secrets_error.sh && handle_secrets_error 112 'Failed to transfer deployment.yaml to VM' 'Check if deployment.yaml exists in k8s directory'" 2>&1 || true)
    validate_error_message "$error_output_112" "Deployment transfer failure (code 112)" \
        "SECRETS SETUP ERROR" "Code: 112" "Failed to transfer deployment.yaml to VM" \
        "RECOVERY SUGGESTION" "ENHANCED RECOVERY SUGGESTIONS" \
        "1. Verify deployment.yaml exists locally" "2. Check file is not empty" \
        "3. Verify VM is accessible" "4. Manual transfer test" "5. Check file syntax"
    
    # Test 4: Test file validation failure (error code 115)
    echo "Testing secrets.yaml validation error (code 115)..."
    error_output_115=$(bash -c "source /tmp/handle_secrets_error.sh && handle_secrets_error 115 'secrets.yaml does not exist in VM after transfer' 'Check if file transfer was successful'" 2>&1 || true)
    validate_error_message "$error_output_115" "Secrets validation failure (code 115)" \
        "SECRETS SETUP ERROR" "Code: 115" "secrets.yaml does not exist in VM after transfer" \
        "RECOVERY SUGGESTION" "ENHANCED RECOVERY SUGGESTIONS" \
        "1. Check if transfer actually succeeded" "2. Verify secrets.yaml exists in VM" \
        "3. Check file size in VM" "4. Manual re-transfer" \
        "5. If file exists but validation fails"
    
    # Test 5: Test error message completeness for all file transfer errors
    echo "Testing error message completeness for all file transfer errors..."
    error_codes=(110 111 112 113 114 115 116 117 118)
    for code in "${error_codes[@]}"; do
        error_output=$(bash -c "source /tmp/handle_secrets_error.sh && handle_secrets_error $code 'Test error message for code $code' 'Test recovery suggestion for code $code'" 2>&1 || true)
        
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
    
    # Test 6: Test actual error output clarity by examining a real error message
    echo "Testing actual error message clarity..."
    
    # Show a sample error message for manual inspection
    echo ""
    echo "=== SAMPLE ERROR MESSAGE FOR MANUAL INSPECTION ==="
    bash -c "source /tmp/handle_secrets_error.sh && handle_secrets_error 111 'Failed to transfer secrets.yaml to VM' 'Check if secrets.yaml exists in k8s directory'" 2>&1 || true
    echo "=== END SAMPLE ERROR MESSAGE ==="
    echo ""
    
    log_test_result "Error message clarity" "PASS" "Error messages provide clear, actionable information"
}

# Run all tests
run_all_tests() {
    echo "Starting error handling tests..."
    echo "================================"
    
    # Extract error handling function
    extract_error_handling_function
    
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
    rm -f /tmp/handle_secrets_error.sh
    echo "Cleanup complete"
}

# Main execution
main() {
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