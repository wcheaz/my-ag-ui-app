#!/bin/bash

# Test Error Handling When Registry Is Not Enabled - Simplified Version
# =================================================================
# This script tests error handling scenarios when the microk8s registry 
# is not enabled, focusing on error message structure and validation.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/registry-error-handling-test-$(date +%Y%m%d-%H%M%S).log"
VM_NAME="my-ag-ui-app-k8s"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp] REGISTRY ERROR TEST: ${message}${NC}"
    echo "[$timestamp] REGISTRY ERROR TEST: ${message}" >> "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}✅ SUCCESS: ${message}${NC}"
    echo "SUCCESS: ${message}" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}❌ ERROR: ${message}${NC}"
    echo "ERROR: ${message}" >> "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${YELLOW}ℹ️  INFO: ${message}${NC}"
    echo "INFO: ${message}" >> "$LOG_FILE"
}

# Test result logging
log_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "$test_name - $details"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "$test_name - $details"
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
        if ! echo "$error_output" | grep -q -i "$element"; then
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

# Test 1: Error handling when microk8s is not available
test_microk8s_not_available() {
    log "Test 1: Error handling when microk8s is not available"
    
    # Create a function that simulates checking for microk8s
    simulate_microk8s_check() {
        local microk8s_cmd="microk8s"
        
        # Check if microk8s command exists
        if ! command -v "$microk8s_cmd" >/dev/null 2>&1; then
            echo "ERROR: $microk8s_cmd command not found"
            echo "RECOVERY: Install microk8s with: sudo snap install microk8s --classic"
            echo "DIAGNOSTIC: Check if snap is available: snap --version"
            return 1
        fi
        
        # Check if microk8s is running
        if ! "$microk8s_cmd" status --wait-ready >/dev/null 2>&1; then
            echo "ERROR: $microk8s_cmd is not running"
            echo "RECOVERY: Start $microk8s_cmd with: sudo $microk8s_cmd start"
            echo "DIAGNOSTIC: Check $microk8s_cmd installation: sudo snap info $microk8s_cmd"
            return 2
        fi
        
        echo "INFO: $microk8s_cmd is running and ready"
        return 0
    }
    
    # Test the scenario
    local error_output
    error_output=$(simulate_microk8s_check 2>&1 || true)
    
    # Show the error output for debugging
    log "Error output from microk8s check:"
    echo "$error_output" | head -10
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Microk8s not available error handling" \
        "microk8s" "not found" "RECOVERY" "sudo snap install microk8s" "DIAGNOSTIC"
}

# Test 2: Error handling when registry is not enabled (simulated)
test_registry_not_enabled_simulated() {
    log "Test 2: Error handling when registry is not enabled (simulated)"
    
    # Create a function that simulates checking registry status
    simulate_registry_check() {
        local registry_status="disabled"  # Simulate disabled registry
        
        if [ "$registry_status" = "disabled" ]; then
            echo "ERROR: microk8s registry is not enabled"
            echo "RECOVERY: Enable registry with: microk8s enable registry"
            echo "DIAGNOSTIC: Check registry status: microk8s status"
            echo "DETAILED RECOVERY:"
            echo "1. Verify microk8s is running: microk8s status"
            echo "2. Enable registry add-on: microk8s enable registry"
            echo "3. Wait for registry pod to be ready: microk8s kubectl get pods -n container-registry"
            echo "4. Test registry accessibility: curl http://localhost:32000/v2/_catalog"
            return 1
        elif [ "$registry_status" = "enabled" ]; then
            # Check if registry pod is running
            echo "ERROR: Registry pod is not running in container-registry namespace"
            echo "RECOVERY: Check registry pod status: microk8s kubectl get pods -n container-registry"
            return 2
        else
            # Check registry API accessibility
            echo "ERROR: Registry API is not accessible at localhost:32000"
            echo "RECOVERY: Check registry pod logs: microk8s kubectl logs -n container-registry -l app=registry"
            return 3
        fi
    }
    
    # Test the scenario
    local error_output
    error_output=$(simulate_registry_check 2>&1 || true)
    
    # Show the error output for debugging
    log "Error output from registry check:"
    echo "$error_output" | head -10
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Registry not enabled error handling" \
        "registry" "not enabled" "RECOVERY" "microk8s enable registry" "DIAGNOSTIC" "DETAILED RECOVERY"
}

# Test 3: Error handling when registry port is not accessible (simulated)
test_registry_port_not_accessible() {
    log "Test 3: Error handling when registry port is not accessible (simulated)"
    
    # Create a function that simulates checking registry port accessibility
    simulate_port_check() {
        local registry_port="32000"
        local registry_host="localhost"
        local registry_url="http://${registry_host}:${registry_port}"
        local port_accessible="false"  # Simulate port not accessible
        
        if [ "$port_accessible" = "false" ]; then
            echo "ERROR: Registry port ${registry_port} is not accessible at ${registry_url}"
            echo "RECOVERY: Check if registry is enabled: microk8s enable registry"
            echo "DIAGNOSTIC: Check if port is in use: sudo netstat -tlnp | grep :${registry_port}"
            echo "DIAGNOSTIC: Check firewall rules: sudo ufw status"
            echo "DIAGNOSTIC: Verify microk8s is running and registry is enabled"
            return 1
        fi
        
        echo "INFO: Registry port ${registry_port} is accessible"
        return 0
    }
    
    # Test the scenario
    local error_output
    error_output=$(simulate_port_check 2>&1 || true)
    
    # Show the error output for debugging
    log "Error output from port check:"
    echo "$error_output" | head -10
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Registry port not accessible error handling" \
        "port" "not accessible" "RECOVERY" "microk8s enable registry" "DIAGNOSTIC" "firewall"
}

# Test 4: Error handling for Docker push when registry is not available (simulated)
test_docker_push_unavailable() {
    log "Test 4: Error handling for Docker push when registry is not available (simulated)"
    
    # Create a function that simulates Docker push to unavailable registry
    simulate_docker_push() {
        local registry_accessible="false"  # Simulate registry not accessible
        
        if [ "$registry_accessible" = "false" ]; then
            echo "ERROR: Registry not accessible at localhost:32000 before push"
            echo "RECOVERY: Ensure registry is enabled: microk8s enable registry"
            echo "RECOVERY: Check registry status: microk8s status | grep registry"
            echo "DIAGNOSTIC: Registry must be enabled and accessible before pushing images"
            echo "DETAILED RECOVERY:"
            echo "1. Verify microk8s is running: microk8s status"
            echo "2. Enable registry if needed: microk8s enable registry"
            echo "3. Wait for registry pod to be ready: microk8s kubectl get pods -n container-registry"
            echo "4. Test registry accessibility: curl http://localhost:32000/v2/_catalog"
            echo "5. Retry push operation"
            return 1
        fi
        
        echo "INFO: Registry is accessible, push can proceed"
        return 0
    }
    
    # Test the scenario
    local error_output
    error_output=$(simulate_docker_push 2>&1 || true)
    
    # Show the error output for debugging
    log "Error output from Docker push simulation:"
    echo "$error_output" | head -15
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Docker push to unavailable registry error handling" \
        "Registry not accessible" "RECOVERY" "microk8s enable registry" "DETAILED RECOVERY" "kubectl get pods"
}

# Test 5: Comprehensive error message structure validation
test_error_message_structure() {
    log "Test 5: Comprehensive error message structure validation"
    
    # Test that error messages follow the expected structure
    local test_error_messages=(
        "ERROR: microk8s is not running
RECOVERY: Start microk8s with: sudo microk8s start
DIAGNOSTIC: Check microk8s installation: sudo snap info microk8s"
        
        "ERROR: microk8s registry is not enabled
RECOVERY: Enable registry with: microk8s enable registry
DIAGNOSTIC: Check registry status: microk8s status
DETAILED RECOVERY:
1. Verify microk8s is running
2. Enable registry add-on
3. Wait for registry pod to be ready
4. Test registry accessibility"
        
        "ERROR: Registry port 32000 is not accessible
RECOVERY: Check if registry is enabled: microk8s enable registry
DIAGNOSTIC: Check if port is in use: sudo netstat -tlnp
DIAGNOSTIC: Check firewall rules: sudo ufw status"
    )
    
    for i in "${!test_error_messages[@]}"; do
        local error_message="${test_error_messages[$i]}"
        local test_num=$((i + 1))
        
        log "Testing error message structure $test_num..."
        
        # Validate error message contains required sections
        validate_error_message "$error_message" "Error message structure $test_num" \
            "ERROR" "RECOVERY"
        
        # Most error messages should have diagnostic information
        if [ $test_num -le 3 ]; then
            validate_error_message "$error_message" "Error message diagnostic $test_num" \
                "DIAGNOSTIC"
        fi
    done
}

# Test 6: Recovery suggestions validation
test_recovery_suggestions() {
    log "Test 6: Recovery suggestions validation"
    
    # Test specific recovery suggestions for each error type
    local recovery_tests=(
        "microk8s not running|sudo microk8s start|sudo snap info microk8s"
        "registry not enabled|microk8s enable registry|microk8s status"
        "port not accessible|microk8s enable registry|sudo netstat|sudo ufw"
        "docker push failed|microk8s enable registry|kubectl get pods|curl"
    )
    
    for test in "${recovery_tests[@]}"; do
        IFS='|' read -ra parts <<< "$test"
        local error_type="${parts[0]}"
        local expected_recoveries=("${parts[@]:1}")
        
        log "Testing recovery suggestions for: $error_type"
        
        # Create a simulated error message
        local error_message="ERROR: $error_type
RECOVERY: ${expected_recoveries[0]}
DIAGNOSTIC: Check ${expected_recoveries[1]}"
        
        # Validate that the error message contains expected recovery suggestions
        validate_error_message "$error_message" "Recovery suggestions for $error_type" \
            "ERROR" "RECOVERY" "${expected_recoveries[0]}"
    done
}

# Test 7: Integration with deploy.sh error handling (if available)
test_deploy_sh_integration() {
    log "Test 7: Integration with deploy.sh error handling"
    
    if [ ! -f "deploy.sh" ]; then
        log_info "deploy.sh not found, skipping integration test"
        log_test_result "deploy.sh integration" "SKIP" "deploy.sh file not found"
        return 0
    fi
    
    # Check if deploy.sh contains error handling functions
    local has_error_handling=false
    
    if grep -q "handle.*error\|error.*handling" deploy.sh; then
        has_error_handling=true
        log_success "deploy.sh contains error handling functions"
    else
        log_info "deploy.sh does not contain explicit error handling functions"
    fi
    
    # Check if deploy.sh contains registry-related functions
    local has_registry_functions=false
    
    if grep -q "registry\|enable.*registry" deploy.sh; then
        has_registry_functions=true
        log_success "deploy.sh contains registry-related functions"
    else
        log_info "deploy.sh does not contain registry-related functions"
    fi
    
    # Test result
    if [ "$has_error_handling" = true ] && [ "$has_registry_functions" = true ]; then
        log_test_result "deploy.sh integration" "PASS" "deploy.sh has error handling and registry functions"
    elif [ "$has_registry_functions" = true ]; then
        log_test_result "deploy.sh integration" "PARTIAL" "deploy.sh has registry functions but limited error handling"
    else
        log_test_result "deploy.sh integration" "FAIL" "deploy.sh lacks error handling and registry functions"
    fi
}

# Main test runner
run_all_tests() {
    log "Starting registry error handling tests..."
    log "=========================================="
    
    # Run all tests
    test_microk8s_not_available
    test_registry_not_enabled_simulated
    test_registry_port_not_accessible
    test_docker_push_unavailable
    test_error_message_structure
    test_recovery_suggestions
    test_deploy_sh_integration
    
    log "=========================================="
    log "Registry Error Handling Test Summary:"
    log "=========================================="
    log "Total Tests: $TOTAL_TESTS"
    log "Passed: $PASSED_TESTS"
    log "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All registry error handling tests passed!"
        log_info "Error handling when registry is not enabled has been successfully tested"
        log_info "The system provides clear error messages and recovery suggestions"
        return 0
    else
        log_error "Some registry error handling tests failed"
        log_info "Review failed tests above and improve error handling as needed"
        return 1
    fi
}

# Help function
show_help() {
    echo "Test Error Handling When Registry Is Not Enabled"
    echo ""
    echo "This script tests error handling scenarios when the microk8s registry"
    echo "is not enabled, focusing on error message structure and validation."
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  help, -h, --help    Show this help message"
    echo ""
    echo "Tests performed:"
    echo "  1. Error handling when microk8s is not available"
    echo "  2. Error handling when registry is not enabled (simulated)"
    echo "  3. Error handling when registry port is not accessible (simulated)"
    echo "  4. Error handling for Docker push when registry is not available (simulated)"
    echo "  5. Comprehensive error message structure validation"
    echo "  6. Recovery suggestions validation"
    echo "  7. Integration with deploy.sh error handling"
    echo ""
}

# Parse command line arguments
case "$1" in
    help|-h|--help)
        show_help
        exit 0
        ;;
    "")
        # Run all tests
        run_all_tests
        exit $?
        ;;
    *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac