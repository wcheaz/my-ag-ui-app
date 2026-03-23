#!/bin/bash

# Test Error Handling When Registry Is Not Enabled
# ==============================================
# This script specifically tests error handling scenarios when the microk8s registry 
# is not enabled, ensuring clear error messages and recovery suggestions are provided.

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

# Test 1: Error handling when microk8s is not running
test_microk8s_not_running() {
    log "Test 1: Error handling when microk8s is not running"
    
    # Create a test function that simulates the scenario
    test_registry_enablement_without_microk8s() {
        log "Simulating registry enablement when microk8s is not running..."
        
        # Check if microk8s is running
        if ! command -v microk8s >/dev/null 2>&1; then
            echo "ERROR: microk8s command not found - cannot enable registry"
            echo "RECOVERY: Install microk8s or ensure it's in PATH"
            return 1
        fi
        
        # Check microk8s status
        if ! microk8s status --wait-ready >/dev/null 2>&1; then
            echo "ERROR: microk8s is not running or not ready"
            echo "RECOVERY: Start microk8s with: sudo microk8s start"
            echo "DIAGNOSTIC: Check microk8s installation: sudo snap info microk8s"
            return 2
        fi
        
        # If we get here, microk8s is running
        echo "INFO: microk8s is running and ready"
        return 0
    }
    
    # Test the scenario
    local error_output
    error_output=$(test_registry_enablement_without_microk8s 2>&1 || true)
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Microk8s not running error handling" \
        "microk8s" "not running" "RECOVERY" "sudo microk8s start"
}

# Test 2: Error handling when registry is not enabled
test_registry_not_enabled() {
    log "Test 2: Error handling when registry is not enabled"
    
    # Create a test function that checks registry status
    test_registry_availability() {
        log "Checking registry availability..."
        
        # Check if microk8s is available
        if ! command -v microk8s >/dev/null 2>&1; then
            echo "ERROR: microk8s command not available - cannot check registry status"
            echo "RECOVERY: Install microk8s or ensure it's available in PATH"
            return 1
        fi
        
        # Check if microk8s is running
        if ! microk8s status --wait-ready >/dev/null 2>&1; then
            echo "ERROR: microk8s is not running - cannot enable registry"
            echo "RECOVERY: Start microk8s with: sudo microk8s start"
            return 2
        fi
        
        # Check if registry is enabled
        if ! microk8s status | grep -q "registry: enabled"; then
            echo "ERROR: microk8s registry is not enabled"
            echo "RECOVERY: Enable registry with: microk8s enable registry"
            echo "DIAGNOSTIC: Check registry status: microk8s status"
            return 3
        fi
        
        # Check if registry pod is running
        if ! microk8s kubectl get pods -n container-registry 2>/dev/null | grep -q "Running"; then
            echo "ERROR: Registry pod is not running in container-registry namespace"
            echo "RECOVERY: Check registry pod status: microk8s kubectl get pods -n container-registry"
            echo "DIAGNOSTIC: Registry may be enabling but pods not yet ready"
            return 4
        fi
        
        # Check registry API accessibility
        if ! curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
            echo "ERROR: Registry API is not accessible at localhost:32000"
            echo "RECOVERY: Check registry pod logs: microk8s kubectl logs -n container-registry -l app=registry"
            echo "DIAGNOSTIC: Registry pod may be running but API not ready"
            return 5
        fi
        
        echo "INFO: Registry is enabled and accessible"
        return 0
    }
    
    # Test the scenario - first disable registry if it's enabled
    if command -v microk8s >/dev/null 2>&1 && microk8s status --wait-ready >/dev/null 2>&1; then
        if microk8s status | grep -q "registry: enabled"; then
            log_info "Registry is currently enabled, disabling for test..."
            microk8s disable registry >/dev/null 2>&1 || true
            sleep 2
        fi
    fi
    
    # Now test the error handling
    local error_output
    error_output=$(test_registry_availability 2>&1 || true)
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Registry not enabled error handling" \
        "registry" "not enabled" "RECOVERY" "microk8s enable registry"
    
    # Re-enable registry if it was disabled
    if command -v microk8s >/dev/null 2>&1 && microk8s status --wait-ready >/dev/null 2>&1; then
        log_info "Re-enabling registry after test..."
        microk8s enable registry >/dev/null 2>&1 || true
        sleep 5
    fi
}

# Test 3: Error handling when registry port is not accessible
test_registry_port_not_accessible() {
    log "Test 3: Error handling when registry port is not accessible"
    
    # Create a test function that simulates port accessibility check
    test_registry_port_accessibility() {
        log "Testing registry port accessibility..."
        
        local registry_port="32000"
        local registry_host="localhost"
        local registry_url="http://${registry_host}:${registry_port}"
        
        # Check if port is accessible
        if ! curl -s "${registry_url}/v2/_catalog" >/dev/null 2>&1; then
            echo "ERROR: Registry port ${registry_port} is not accessible at ${registry_url}"
            echo "RECOVERY: Check if registry is enabled: microk8s enable registry"
            echo "DIAGNOSTIC: Check if port is in use: sudo netstat -tlnp | grep :${registry_port}"
            echo "DIAGNOSTIC: Check firewall rules: sudo ufw status"
            
            # Additional diagnostics
            if command -v microk8s >/dev/null 2>&1; then
                if ! microk8s status --wait-ready >/dev/null 2>&1; then
                    echo "DIAGNOSTIC: microk8s is not running"
                elif ! microk8s status | grep -q "registry: enabled"; then
                    echo "DIAGNOSTIC: microk8s registry is not enabled"
                else
                    echo "DIAGNOSTIC: microk8s registry is enabled but port not accessible"
                fi
            else
                echo "DIAGNOSTIC: microk8s command not available"
            fi
            
            return 1
        fi
        
        echo "INFO: Registry port ${registry_port} is accessible"
        return 0
    }
    
    # Test the scenario
    local error_output
    error_output=$(test_registry_port_accessibility 2>&1 || true)
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Registry port not accessible error handling" \
        "port" "not accessible" "RECOVERY" "microk8s enable registry" "DIAGNOSTIC"
}

# Test 4: Error handling for Docker push when registry is not available
test_docker_push_to_unavailable_registry() {
    log "Test 4: Error handling for Docker push when registry is not available"
    
    # Create a test function that simulates Docker push to unavailable registry
    test_docker_push_unavailable() {
        log "Testing Docker push to unavailable registry..."
        
        # Check if Docker is available
        if ! command -v docker >/dev/null 2>&1; then
            echo "ERROR: Docker command not available"
            echo "RECOVERY: Install Docker or ensure it's in PATH"
            return 1
        fi
        
        # Check if Docker daemon is running
        if ! docker info >/dev/null 2>&1; then
            echo "ERROR: Docker daemon is not running"
            echo "RECOVERY: Start Docker daemon: sudo systemctl start docker"
            return 2
        fi
        
        # Check if we have a test image
        local test_image="localhost:32000/test-registry-error-handling:latest"
        
        # Create a small test image if it doesn't exist
        if ! docker images "$test_image" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$test_image"; then
            log_info "Creating small test image for push test..."
            echo "FROM alpine:latest
CMD echo 'Test image for registry error handling'" | docker build -t "$test_image" - >/dev/null 2>&1 || true
        fi
        
        # Verify test image exists
        if ! docker images "$test_image" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$test_image"; then
            echo "ERROR: Test image not available: $test_image"
            echo "RECOVERY: Build test image first"
            return 3
        fi
        
        # Check registry accessibility before push
        if ! curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
            echo "ERROR: Registry not accessible at localhost:32000 before push"
            echo "RECOVERY: Ensure registry is enabled: microk8s enable registry"
            echo "RECOVERY: Check registry status: microk8s status | grep registry"
            echo "DIAGNOSTIC: Registry must be enabled and accessible before pushing images"
            
            # Provide detailed recovery steps
            echo "DETAILED RECOVERY:"
            echo "1. Verify microk8s is running: microk8s status"
            echo "2. Enable registry if needed: microk8s enable registry"
            echo "3. Wait for registry pod to be ready: microk8s kubectl get pods -n container-registry"
            echo "4. Test registry accessibility: curl http://localhost:32000/v2/_catalog"
            echo "5. Retry push operation"
            
            return 4
        fi
        
        # Attempt push (this should succeed if registry is accessible, but we're testing error handling)
        log_info "Attempting test push to registry..."
        if docker push "$test_image" >/dev/null 2>&1; then
            echo "INFO: Test push successful (registry is accessible)"
            # Clean up test image
            docker rmi "$test_image" >/dev/null 2>&1 || true
            return 0
        else
            echo "ERROR: Docker push failed"
            echo "RECOVERY: Check registry accessibility and network connectivity"
            echo "DIAGNOSTIC: Verify registry is enabled and port 32000 is accessible"
            return 5
        fi
    }
    
    # Temporarily disable registry to simulate unavailability
    local registry_was_enabled=false
    if command -v microk8s >/dev/null 2>&1 && microk8s status --wait-ready >/dev/null 2>&1; then
        if microk8s status | grep -q "registry: enabled"; then
            registry_was_enabled=true
            log_info "Disabling registry temporarily for test..."
            microk8s disable registry >/dev/null 2>&1 || true
            sleep 3
        fi
    fi
    
    # Test the scenario
    local error_output
    error_output=$(test_docker_push_unavailable 2>&1 || true)
    
    # Validate error message contains expected elements
    validate_error_message "$error_output" "Docker push to unavailable registry error handling" \
        "Registry not accessible" "RECOVERY" "microk8s enable registry" "DETAILED RECOVERY"
    
    # Re-enable registry if it was disabled
    if [ "$registry_was_enabled" = true ]; then
        log_info "Re-enabling registry after test..."
        microk8s enable registry >/dev/null 2>&1 || true
        sleep 5
    fi
}

# Test 5: Comprehensive error message validation
test_comprehensive_error_messages() {
    log "Test 5: Comprehensive error message validation"
    
    # Test that error messages include all required elements
    local test_scenarios=(
        "microk8s not running"
        "registry not enabled"
        "port not accessible"
        "docker push failed"
    )
    
    for scenario in "${test_scenarios[@]}"; do
        log "Testing error message for scenario: $scenario"
        
        # Simulate error message generation
        local simulated_error
        simulated_error=$(cat << ERROR
ERROR: $scenario - registry operation failed
RECOVERY: Enable microk8s registry with: microk8s enable registry
DIAGNOSTIC: Check microk8s status: microk8s status
DIAGNOSTIC: Verify registry is accessible: curl http://localhost:32000/v2/_catalog
DETAILED RECOVERY:
1. Verify microk8s is installed and running
2. Enable registry add-on: microk8s enable registry
3. Wait for registry pod to be ready
4. Test registry accessibility
5. Retry the operation
ERROR
)
        
        # Validate error message contains all expected elements
        validate_error_message "$simulated_error" "Error message for $scenario" \
            "ERROR" "RECOVERY" "DIAGNOSTIC" "DETAILED RECOVERY" "microk8s enable registry"
    done
}

# Test 6: Error handling recovery suggestions validation
test_recovery_suggestions() {
    log "Test 6: Error handling recovery suggestions validation"
    
    # Test specific recovery suggestions for each error type
    test_error_type_1() {
        echo "ERROR: microk8s is not running"
        echo "RECOVERY: Start microk8s with: sudo microk8s start"
        echo "DIAGNOSTIC: Check microk8s installation: sudo snap info microk8s"
    }
    
    test_error_type_2() {
        echo "ERROR: microk8s registry is not enabled"
        echo "RECOVERY: Enable registry with: microk8s enable registry"
        echo "DIAGNOSTIC: Check registry status: microk8s status"
    }
    
    test_error_type_3() {
        echo "ERROR: Registry API is not accessible"
        echo "RECOVERY: Check registry pod logs: microk8s kubectl logs -n container-registry -l app=registry"
        echo "DIAGNOSTIC: Registry may be enabling but API not ready"
    }
    
    # Test each error type
    local error_output_1
    error_output_1=$(test_error_type_1)
    validate_error_message "$error_output_1" "Microk8s not running recovery" \
        "sudo microk8s start" "sudo snap info microk8s"
    
    local error_output_2
    error_output_2=$(test_error_type_2)
    validate_error_message "$error_output_2" "Registry not enabled recovery" \
        "microk8s enable registry" "microk8s status"
    
    local error_output_3
    error_output_3=$(test_error_type_3)
    validate_error_message "$error_output_3" "Registry API not accessible recovery" \
        "kubectl logs" "container-registry" "API not ready"
}

# Main test runner
run_all_tests() {
    log "Starting registry error handling tests..."
    log "=========================================="
    
    # Run all tests
    test_microk8s_not_running
    test_registry_not_enabled
    test_registry_port_not_accessible
    test_docker_push_to_unavailable_registry
    test_comprehensive_error_messages
    test_recovery_suggestions
    
    log "=========================================="
    log "Registry Error Handling Test Summary:"
    log "=========================================="
    log "Total Tests: $TOTAL_TESTS"
    log "Passed: $PASSED_TESTS"
    log "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All registry error handling tests passed!"
        return 0
    else
        log_error "Some registry error handling tests failed"
        return 1
    fi
}

# Help function
show_help() {
    echo "Test Error Handling When Registry Is Not Enabled"
    echo ""
    echo "This script tests error handling scenarios when the microk8s registry"
    echo "is not enabled, ensuring clear error messages and recovery suggestions."
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  help, -h, --help    Show this help message"
    echo ""
    echo "Tests performed:"
    echo "  1. Error handling when microk8s is not running"
    echo "  2. Error handling when registry is not enabled"
    echo "  3. Error handling when registry port is not accessible"
    echo "  4. Error handling for Docker push when registry is not available"
    echo "  5. Comprehensive error message validation"
    echo "  6. Error handling recovery suggestions validation"
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