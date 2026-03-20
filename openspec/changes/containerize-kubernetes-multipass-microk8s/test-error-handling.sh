#!/bin/bash

# Error Handling Test Script for my-ag-ui-app Kubernetes Deployment
# This script simulates various failure scenarios to test error handling

set -e

# Configuration
LOG_FILE="error-handling-test.log"
VM_NAME="my-ag-ui-app-k8s"
TEST_RESULTS_FILE="error-handling-test-results.md"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Initialize test results file
init_test_results() {
    cat > "$TEST_RESULTS_FILE" << 'EOF'
# Error Handling Test Results

This document contains the results of error handling tests for the my-ag-ui-app Kubernetes deployment script.

## Test Scenarios Executed

EOF
}

# Function to record test result
record_test_result() {
    local test_name="$1"
    local test_status="$2"
    local test_details="$3"
    local expected_behavior="$4"
    local actual_behavior="$5"
    local passed="$6"
    
    cat >> "$TEST_RESULTS_FILE" << EOF

### ${test_name}

**Status:** ${test_status}
**Expected Behavior:** ${expected_behavior}
**Actual Behavior:** ${actual_behavior}
**Details:** ${test_details}

**Result:** ${passed}

EOF
}

# Function to simulate a failure scenario
test_failure_scenario() {
    local scenario_name="$1"
    local test_command="$2"
    local expected_error="$3"
    local expected_exit_code="$4"
    
    log "Testing failure scenario: $scenario_name"
    log "Command: $test_command"
    log "Expected error: $expected_error"
    log "Expected exit code: $expected_exit_code"
    
    local actual_result=""
    local actual_exit_code=0
    local passed="FAILED"
    
    # Execute the test command and capture result
    set +e
    actual_result=$(eval "$test_command" 2>&1)
    actual_exit_code=$?
    set -e
    
    log "Actual exit code: $actual_exit_code"
    log "Actual result: $actual_result"
    
    # Check if the error was handled correctly
    if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
        if echo "$actual_result" | grep -q "$expected_error"; then
            passed="PASSED"
        fi
    fi
    
    # Record the result
    record_test_result \
        "$scenario_name" \
        "$passed" \
        "Command: $test_command" \
        "Exit with code $expected_exit_code and show error: $expected_error" \
        "Exit code: $actual_exit_code, Result: $actual_result" \
        "$passed"
    
    log "Test $passed: $scenario_name"
    
    # Clean up after the test if needed
    cleanup_after_test "$scenario_name"
}

# Function to clean up after a test
cleanup_after_test() {
    local scenario_name="$1"
    
    case "$scenario_name" in
        *"VM creation"*)
            # Clean up any test VMs
            multipass delete test-error-vm --purge 2>/dev/null || true
            ;;
        *"microk8s installation"*)
            # Clean up test microk8s installation if any
            if multipass list | grep -q "^test-vm "; then
                multipass delete test-vm --purge 2>/dev/null || true
            fi
            ;;
        *"Docker build"*)
            # Clean up any test containers or images
            docker rmi test-error-image:latest 2>/dev/null || true
            ;;
        *"Kubernetes deployment"*)
            # Clean up test Kubernetes resources
            if multipass list | grep -q "^test-vm "; then
                multipass exec test-vm -- microk8s kubectl delete namespace test-error-ns --ignore-not-found=true 2>/dev/null || true
            fi
            ;;
    esac
}

# Function to test VM provisioning failures
test_vm_provisioning_failures() {
    log "=== Testing VM Provisioning Failure Scenarios ==="
    
    # Test 1: Insufficient resources for VM creation
    test_failure_scenario \
        "VM Creation - Insufficient CPU" \
        "multipass launch --name test-error-vm --cpus 32 --memory 1G --disk 1G 2>&1 || true" \
        "insufficient\|not enough\|failed" \
        "1"
    
    # Test 2: VM with invalid name
    test_failure_scenario \
        "VM Creation - Invalid Name" \
        "multipass launch --name 'invalid@name' --cpus 1 --memory 1G --disk 1G 2>&1 || true" \
        "invalid\|failed" \
        "1"
    
    # Test 3: VM with already existing name
    # First create a VM, then try to create another with the same name
    multipass launch --name duplicate-test-vm --cpus 1 --memory 1G --disk 1G --timeout 60 2>/dev/null || true
    test_failure_scenario \
        "VM Creation - Duplicate Name" \
        "multipass launch --name duplicate-test-vm --cpus 1 --memory 1G --disk 1G 2>&1 || true" \
        "already exists\|duplicate" \
        "1"
    multipass delete duplicate-test-vm --purge 2>/dev/null || true
    
    # Test 4: VM creation timeout
    test_failure_scenario \
        "VM Creation - Timeout" \
        "timeout 5 multipass launch --name timeout-test-vm --cpus 1 --memory 1G --disk 1G 2>&1 || true" \
        "timeout\|timed out" \
        "124"
}

# Function to test microk8s installation failures
test_microk8s_installation_failures() {
    log "=== Testing microk8s Installation Failure Scenarios ==="
    
    # Create a test VM first
    multipass launch --name test-vm --cpus 2 --memory 4G --disk 10G --timeout 60 2>/dev/null || true
    
    # Wait for VM to be ready
    local max_attempts=12
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if multipass exec test-vm -- uptime >/dev/null 2>&1; then
            break
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    # Test 1: microk8s installation without snap (simulate snap not available)
    test_failure_scenario \
        "microk8s Installation - Snap Not Available" \
        "multipass exec test-vm -- sudo apt remove -y snapd && sudo microk8s 2>&1 || true" \
        "not found\|command not found" \
        "1"
    
    # Reinstall snap for other tests
    multipass exec test-vm -- sudo apt update -qq && sudo apt install -y snapd 2>/dev/null || true
    
    # Test 2: microk8s installation with network issues (simulate network failure)
    test_failure_scenario \
        "microk8s Installation - Network Issues" \
        "multipass exec test-vm -- sudo iptables -A OUTPUT -p tcp --dport 53 -j DROP && timeout 10 sudo snap install microk8s --classic 2>&1 || multipass exec test-vm -- sudo iptables -D OUTPUT -p tcp --dport 53 -j DROP; true" \
        "timeout\|network\|connection" \
        "1\|124"
    
    # Test 3: microk8s add-on enablement failures
    test_failure_scenario \
        "microk8s Add-on - Invalid Add-on" \
        "multipass exec test-vm -- sudo snap install microk8s --classic 2>/dev/null && multipass exec test-vm -- microk8s enable nonexistent-addon 2>&1 || true" \
        "not found\|invalid" \
        "1"
    
    # Clean up test VM
    multipass delete test-vm --purge 2>/dev/null || true
}

# Function to test container build failures
test_container_build_failures() {
    log "=== Testing Container Build Failure Scenarios ==="
    
    # Create temporary test directory
    local test_dir="/tmp/test-container-build-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Test 1: Dockerfile with syntax errors
    cat > Dockerfile << 'EOF'
FROM node:16-alpine
INVALID_SYNTAX
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF
    
    test_failure_scenario \
        "Docker Build - Syntax Error" \
        "docker build -t test-error-image:latest . 2>&1 || true" \
        "syntax error\|unknown instruction" \
        "1"
    
    # Test 2: Dockerfile with non-existent base image
    cat > Dockerfile << 'EOF'
FROM nonexistent/image:latest
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF
    
    test_failure_scenario \
        "Docker Build - Non-existent Base Image" \
        "docker build -t test-error-image:latest . 2>&1 || true" \
        "pull access denied\|manifest not found\|not found" \
        "1"
    
    # Test 3: Build context with missing files
    cat > Dockerfile << 'EOF'
FROM node:16-alpine
COPY package.json .
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF
    
    test_failure_scenario \
        "Docker Build - Missing Files" \
        "docker build -t test-error-image:latest . 2>&1 || true" \
        "no such file\|not found\|failed" \
        "1"
    
    # Clean up
    cd - > /dev/null
    rm -rf "$test_dir"
    docker rmi test-error-image:latest 2>/dev/null || true
}

# Function to test Kubernetes deployment failures
test_kubernetes_deployment_failures() {
    log "=== Testing Kubernetes Deployment Failure Scenarios ==="
    
    # Create test directory with invalid Kubernetes manifests
    local test_dir="/tmp/test-k8s-deployment-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Test 1: Invalid deployment manifest
    cat > invalid-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: test
        image: nginx:latest
        resources:
          requests:
            memory: "1000Gi"  # Impossible amount
            cpu: "1000"
EOF
    
    # Create a test VM with microk8s
    multipass launch --name test-vm --cpus 2 --memory 4G --disk 10G --timeout 60 2>/dev/null || true
    
    # Wait for VM and install microk8s
    local max_attempts=12
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if multipass exec test-vm -- uptime >/dev/null 2>&1; then
            break
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    # Install microk8s
    multipass exec test-vm -- sudo snap install microk8s --classic 2>/dev/null || true
    
    # Wait for microk8s to be ready
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if multipass exec test-vm -- microk8s status --wait-ready >/dev/null 2>&1; then
            break
        fi
        sleep 5
        attempt=$((attempt + 1))
    done
    
    # Enable required add-ons
    multipass exec test-vm -- microk8s enable dns storage ingress 2>/dev/null || true
    
    # Test the invalid deployment
    test_failure_scenario \
        "Kubernetes Deployment - Invalid Resource Requests" \
        "multipass exec test-vm -- microk8s kubectl apply -f invalid-deployment.yaml 2>&1 || true" \
        "insufficient\|invalid\|failed" \
        "1"
    
    # Test 2: Service pointing to non-existent deployment
    cat > invalid-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: test-service
spec:
  selector:
    app: nonexistent  # Non-existent app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF
    
    test_failure_scenario \
        "Kubernetes Service - No Matching Pods" \
        "multipass exec test-vm -- microk8s kubectl apply -f invalid-service.yaml 2>&1 || true" \
        "no endpoints\|not found" \
        "0"  # This might succeed but have no endpoints, so exit code 0
    
    # Test 3: Ingress with non-existent service
    cat > invalid-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nonexistent-service
            port:
              number: 80
EOF
    
    test_failure_scenario \
        "Kubernetes Ingress - Non-existent Service" \
        "multipass exec test-vm -- microk8s kubectl apply -f invalid-ingress.yaml 2>&1 || true" \
        "not found\|invalid" \
        "1"
    
    # Clean up
    multipass delete test-vm --purge 2>/dev/null || true
    cd - > /dev/null
    rm -rf "$test_dir"
}

# Function to test network connectivity failures
test_network_connectivity_failures() {
    log "=== Testing Network Connectivity Failure Scenarios ==="
    
    # Test 1: No internet connectivity (simulate network failure)
    test_failure_scenario \
        "Network - No Internet Connectivity" \
        "timeout 5 curl -s https://www.google.com 2>&1 || true" \
        "timeout\|connection failed\|resolve host" \
        "1\|28\|124"
    
    # Test 2: DNS resolution failure
    test_failure_scenario \
        "Network - DNS Resolution Failure" \
        "timeout 5 nslookup nonexistent-domain.invalid 2>&1 || true" \
        "NXDOMAIN\|not found\|timeout" \
        "1\|28"
    
    # Test 3: Connection to non-existent host
    test_failure_scenario \
        "Network - Connection to Non-existent Host" \
        "timeout 5 nc -z 192.0.2.1 80 2>&1 || timeout 5 curl -s http://192.0.2.1:80 2>&1 || true" \
        "connection refused\|timeout\|failed" \
        "1\|124"
}

# Function to test permission failures
test_permission_failures() {
    log "=== Testing Permission Failure Scenarios ==="
    
    # Test 1: Docker without permissions
    test_failure_scenario \
        "Permissions - Docker Without Sudo" \
        "docker info 2>&1 || true" \
        "permission denied\|cannot connect" \
        "1"
    
    # Test 2: multipass without permissions
    test_failure_scenario \
        "Permissions - Multipass Command Access" \
        "command -v multipass >/dev/null 2>&1 && multipass list 2>&1 || echo 'multipass not found'" \
        "" \
        "0"  # This should succeed if multipass is installed
}

# Function to test resource constraint failures
test_resource_constraint_failures() {
    log "=== Testing Resource Constraint Failure Scenarios ==="
    
    # Test 1: Insufficient disk space
    test_failure_scenario \
        "Resources - Insufficient Disk Space" \
        "df . | awk 'NR==2 {print \$4}'" \
        "" \
        "0"  # This is just to check available space
    
    # Test 2: Insufficient memory
    test_failure_scenario \
        "Resources - Insufficient Memory" \
        "free -m | awk 'NR==2 {print \$2}'" \
        "" \
        "0"  # This is just to check available memory
    
    # Note: We can't easily test actual resource exhaustion without risking system stability
}

# Main test execution
main() {
    log "Starting Error Handling Tests for my-ag-ui-app Kubernetes Deployment"
    log "Test results will be logged to: $LOG_FILE"
    log "Detailed results will be saved to: $TEST_RESULTS_FILE"
    
    # Initialize test results
    init_test_results
    
    # Run all test suites
    test_vm_provisioning_failures
    test_microk8s_installation_failures
    test_container_build_failures
    test_kubernetes_deployment_failures
    test_network_connectivity_failures
    test_permission_failures
    test_resource_constraint_failures
    
    # Generate summary
    log "=== Error Handling Test Summary ==="
    
    # Count tests and results
    local total_tests=$(grep -c "### " "$TEST_RESULTS_FILE")
    local passed_tests=$(grep -c "Result: PASSED" "$TEST_RESULTS_FILE")
    local failed_tests=$((total_tests - passed_tests))
    
    log "Total tests executed: $total_tests"
    log "Tests passed: $passed_tests"
    log "Tests failed: $failed_tests"
    log "Success rate: $(( passed_tests * 100 / total_tests ))%"
    
    # Add summary to test results
    cat >> "$TEST_RESULTS_FILE" << EOF

## Test Summary

- **Total Tests:** $total_tests
- **Passed:** $passed_tests
- **Failed:** $failed_tests
- **Success Rate:** $(( passed_tests * 100 / total_tests ))%

## Test Execution Date

$(date)

## Log File

Detailed test execution logs are available in: \`$LOG_FILE\`

EOF
    
    log "Error handling tests completed. Results saved to: $TEST_RESULTS_FILE"
    
    # Return non-zero exit code if any tests failed
    if [ $failed_tests -gt 0 ]; then
        log "WARNING: $failed_tests error handling tests failed"
        exit 1
    else
        log "All error handling tests passed!"
        exit 0
    fi
}

# Execute main function
main "$@"