#!/bin/bash

# Load balancing test script for my-ag-ui-app on Kubernetes
# This script verifies that load balancing is working across multiple pods

set -e

# Configuration
VM_NAME="my-ag-ui-app-k8s"
LOG_FILE="load-balancing-test.log"
TEST_REPLICAS=3
TEST_REQUESTS=10

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Function to check if microk8s is ready
microk8s_ready() {
    multipass exec "$VM_NAME" -- microk8s status --wait --timeout 30 >/dev/null 2>&1
}

# Function to get current replica count
get_current_replicas() {
    multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0"
}

# Function to set replica count
set_replicas() {
    local replicas=$1
    log "Setting deployment replicas to $replicas..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl scale deployment my-ag-ui-app --replicas=$replicas 2>&1 | tee -a "$LOG_FILE"; then
        handle_error "Failed to scale deployment to $replicas replicas"
    fi
    log "Deployment scaled to $replicas replicas"
}

# Function to wait for pods to be ready
wait_for_pods_ready() {
    local expected_replicas=$1
    local max_attempts=30
    local attempt=1
    
    log "Waiting for $expected_replicas pods to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        log "Checking pod status... (attempt $attempt/$max_attempts)"
        
        # Get number of ready pods
        local ready_replicas=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        
        if [ "$ready_replicas" = "$expected_replicas" ]; then
            log "All $expected_replicas pods are ready"
            return 0
        else
            log "Pods not ready yet. Ready: $ready_replicas/$expected_replicas"
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            handle_error "Pods did not become ready after $max_attempts attempts"
        fi
        
        sleep 3
        attempt=$((attempt + 1))
    done
}

# Function to get pod names
get_pod_names() {
    multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""
}

# Function to get pod IPs
get_pod_ips() {
    multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.podIP}' 2>/dev/null || echo ""
}

# Function to make a test request and get the responding pod's IP
make_test_request() {
    local response=$(multipass exec "$VM_NAME" -- curl -s -f --connect-timeout 5 http://localhost 2>/dev/null || echo "")
    
    # Get the most recent ingress controller logs to see which pod handled the request
    local ingress_pod=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$ingress_pod" ]; then
        # Get the most recent log entries and try to extract the backend pod IP
        local backend_ip=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=5 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+' | tail -1 | cut -d: -f1 || echo "")
        echo "$backend_ip"
    else
        echo ""
    fi
}

# Function to test load balancing
test_load_balancing() {
    local test_requests=$1
    local pod_ip_counts=()
    local total_responses=0
    local unique_pods=0
    
    log "Starting load balancing test with $test_requests requests..."
    
    # Get all pod IPs
    local all_pod_ips=$(get_pod_ips)
    log "Available pod IPs: $all_pod_ips"
    
    # Initialize array to count hits per pod
    for pod_ip in $all_pod_ips; do
        pod_ip_counts["$pod_ip"]=0
    done
    
    # Make test requests
    for i in $(seq 1 $test_requests); do
        log "Making test request $i/$test_requests..."
        
        local responding_pod_ip=$(make_test_request)
        
        if [ -n "$responding_pod_ip" ]; then
            log "Request $i handled by pod IP: $responding_pod_ip"
            pod_ip_counts["$responding_pod_ip"]=$((${pod_ip_counts["$responding_pod_ip"]} + 1))
            total_responses=$((total_responses + 1))
        else
            log "Could not determine responding pod for request $i"
        fi
        
        # Small delay between requests
        sleep 0.5
    done
    
    # Analyze results
    log "=== LOAD BALANCING TEST RESULTS ==="
    log "Total requests made: $test_requests"
    log "Total responses captured: $total_responses"
    log ""
    
    # Count unique pods that responded
    for pod_ip in "${!pod_ip_counts[@]}"; do
        local count=${pod_ip_counts["$pod_ip"]}
        if [ $count -gt 0 ]; then
            unique_pods=$((unique_pods + 1))
            log "Pod $pod_ip handled $count requests"
        fi
    done
    
    log ""
    log "Unique pods that responded: $unique_pods"
    log "Expected pods: $(echo $all_pod_ips | wc -w)"
    
    # Check if load balancing is working
    if [ $unique_pods -gt 1 ]; then
        log "SUCCESS: Load balancing is working - requests distributed across $unique_pods pods"
        
        # Check distribution
        local expected_per_pod=$((test_requests / unique_pods))
        log "Expected distribution: ~$expected_per_pod requests per pod"
        
        # Check if distribution is reasonably balanced (within 50% of expected)
        local is_balanced=true
        for pod_ip in "${!pod_ip_counts[@]}"; do
            local count=${pod_ip_counts["$pod_ip"]}
            if [ $count -gt 0 ]; then
                local deviation=$((count - expected_per_pod))
                local percent_deviation=$((deviation * 100 / expected_per_pod))
                if [ ${percent_deviation#-} -gt 50 ]; then
                    is_balanced=false
                    log "WARNING: Pod $pod_ip has uneven distribution ($count requests, ${percent_deviation#-}% deviation)"
                fi
            fi
        done
        
        if [ "$is_balanced" = "true" ]; then
            log "SUCCESS: Load distribution appears balanced"
        else
            log "INFO: Load distribution may need optimization"
        fi
    else
        log "WARNING: Load balancing may not be working - only $unique_pods pod responded"
        if [ $total_responses -eq 0 ]; then
            log "ERROR: No responses captured - check application connectivity"
        fi
    fi
    log "===================================="
}

# Main test execution
log "Starting load balancing test..."

# Verify microk8s is ready
if ! microk8s_ready; then
    handle_error "Microk8s is not ready for load balancing test"
fi
log "Microk8s is ready for load balancing test"

# Get original replica count
original_replicas=$(get_current_replicas)
log "Current deployment replica count: $original_replicas"

# Scale up to test replicas
set_replicas $TEST_REPLICAS

# Wait for pods to be ready
wait_for_pods_ready $TEST_REPLICAS

# Get pod information
log "Getting pod information..."
pod_names=$(get_pod_names)
pod_ips=$(get_pod_ips)
log "Pod names: $pod_names"
log "Pod IPs: $pod_ips"

# Test load balancing
test_load_balancing $TEST_REQUESTS

# Scale back to original replica count
log "Scaling deployment back to original replica count: $original_replicas"
set_replicas $original_replicas

# Wait for pods to be ready
if [ $original_replicas -gt 0 ]; then
    wait_for_pods_ready $original_replicas
fi

log "Load balancing test completed successfully"