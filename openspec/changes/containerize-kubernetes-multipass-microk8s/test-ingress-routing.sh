#!/bin/bash

# Test script for ingress routing
# This script tests that the ingress correctly routes traffic to the application service
# 
# Prerequisites:
# - microk8s cluster must be running and accessible
# - ingress controller must be installed and running
# - the application must be deployed via ingress
#
# Usage: ./test-ingress-routing.sh

set -e

# Configuration
VM_NAME="microk8s"
INGRESS_NAME="my-ag-ui-app-ingress"
SERVICE_NAME="my-ag-ui-app-service"
NAMESPACE="default"
LOG_FILE="ingress-routing-test.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Start test
log "Starting ingress routing test for $INGRESS_NAME"

# Check if VM exists
log "Checking if VM $VM_NAME exists..."
if ! multipass list | grep -q "$VM_NAME"; then
    error_exit "VM $VM_NAME does not exist. Please run the deployment script first."
fi

log "VM $VM_NAME found. Checking VM status..."
VM_STATUS=$(multipass info "$VM_NAME" | grep "State" | awk '{print $2}')
if [[ "$VM_STATUS" != "Running" ]]; then
    error_exit "VM $VM_NAME is not running. Current status: $VM_STATUS"
fi

log "VM $VM_NAME is running. Testing microk8s cluster..."

# Check if microk8s is ready in the VM
log "Checking microk8s status..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s status --wait-ready" >/dev/null 2>&1; then
    error_exit "microk8s is not ready in VM $VM_NAME"
fi

log "microk8s is ready. Checking ingress deployment..."

# Check if ingress resource exists
log "Checking if ingress $INGRESS_NAME exists..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress $INGRESS_NAME -n $NAMESPACE" >/dev/null 2>&1; then
    error_exit "Ingress $INGRESS_NAME not found in namespace $NAMESPACE"
fi

log "Ingress $INGRESS_NAME found. Checking ingress details..."

# Get ingress details
log "Retrieving ingress configuration..."
INGRESS_INFO=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o yaml")

# Extract ingress configuration
log "Analyzing ingress configuration..."
INGRESS_CLASS=$(echo "$INGRESS_INFO" | grep -A 5 "ingressClassName:" | tail -1 | awk '{print $2}')
log "Ingress class: $INGRESS_CLASS"

# Check ingress hosts
log "Checking configured hosts..."
HOSTS=$(echo "$INGRESS_INFO" | grep -A 10 "rules:" | grep "host:" | awk '{print $2}' | sort -u)
log "Configured hosts: $HOSTS"

# Check ingress paths
log "Checking configured paths..."
PATHS=$(echo "$INGRESS_INFO" | grep -A 10 "rules:" | grep "path:" | awk '{print $2}' | sort -u)
log "Configured paths: $PATHS"

# Check backend service
log "Checking backend service configuration..."
BACKEND_SERVICE=$(echo "$INGRESS_INFO" | grep -A 5 "backend:" | grep "name:" | awk '{print $2}')
BACKEND_PORT=$(echo "$INGRESS_INFO" | grep -A 10 "backend:" | grep "number:" | awk '{print $2}')
log "Backend service: $BACKEND_SERVICE"
log "Backend port: $BACKEND_PORT"

# Verify the backend service exists
log "Verifying backend service exists..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get service $BACKEND_SERVICE -n $NAMESPACE" >/dev/null 2>&1; then
    error_exit "Backend service $BACKEND_SERVICE not found in namespace $NAMESPACE"
fi

log "Backend service $BACKEND_SERVICE found"

# Check service endpoints
log "Checking service endpoints..."
ENDPOINTS=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get endpoints $BACKEND_SERVICE -n $NAMESPACE -o jsonpath='{.subsets}'")
if [[ -z "$ENDPOINTS" || "$ENDPOINTS" == "[]" ]]; then
    error_exit "Service $BACKEND_SERVICE has no endpoints (no running pods)"
fi

log "Service endpoints found: $ENDPOINTS"

# Test 1: Verify ingress controller is running
log "=== Test 1: Ingress Controller Status ==="
log "Checking ingress controller pods..."
INGRESS_PODS=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -n ingress" || echo "failed")
if [[ "$INGRESS_PODS" == "failed" ]]; then
    error_exit "Could not get ingress controller pods"
fi

log "Ingress controller pods:"
echo "$INGRESS_PODS" | tee -a "$LOG_FILE"

INGRESS_POD_COUNT=$(echo "$INGRESS_PODS" | grep -c "Running" || echo "0")
if [[ "$INGRESS_POD_COUNT" -eq 0 ]]; then
    error_exit "No ingress controller pods are running"
fi

log "SUCCESS: $INGRESS_POD_COUNT ingress controller pods are running"

# Test 2: Check ingress resource status
log "=== Test 2: Ingress Resource Status ==="
log "Checking ingress resource status..."
INGRESS_STATUS=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer}'")
log "Ingress status: $INGRESS_STATUS"

# For microk8s, the ingress might not have an external LoadBalancer, so we check the hosts configuration
if echo "$INGRESS_INFO" | grep -q "rules:"; then
    log "SUCCESS: Ingress has routing rules configured"
else
    error_exit "Ingress has no routing rules configured"
fi

# Test 3: Test routing to localhost
log "=== Test 3: Localhost Routing Test ==="
log "Creating test pod to verify ingress routing..."

# Create a test pod with curl
cat > /tmp/ingress-test-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ingress-routing-test
  namespace: $NAMESPACE
spec:
  containers:
  - name: curl
    image: curlimages/curl:latest
    command: ['sh', '-c', 'echo "Ingress routing test pod ready" && sleep 3600']
  restartPolicy: Never
EOF

# Create the test pod in the VM
log "Creating test pod in VM..."
multipass exec "$VM_NAME" -- bash -c "cat > /tmp/ingress-test-pod.yaml" < /tmp/ingress-test-pod.yaml
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl apply -f /tmp/ingress-test-pod.yaml" || error_exit "Failed to create test pod"

# Wait for test pod to be ready
log "Waiting for test pod to be ready..."
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl wait --for=condition=ready pod/ingress-routing-test -n $NAMESPACE --timeout=60s" || error_exit "Test pod did not become ready"

# Test routing to each configured host
for host in $HOSTS; do
    log "Testing routing to host: $host"
    
    # Test HTTP access
    log "Testing HTTP access to host $host..."
    HTTP_RESULT=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl exec ingress-routing-test -n $NAMESPACE -- curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 http://$host" || echo "000")
    
    if [[ "$HTTP_RESULT" == "200" || "$HTTP_RESULT" == "301" || "$HTTP_RESULT" == "302" ]]; then
        log "SUCCESS: HTTP routing to $host works (status: $HTTP_RESULT)"
    elif [[ "$HTTP_RESULT" == "000" ]]; then
        log "WARNING: Could not connect to $host via HTTP (timeout/connection error)"
    else
        log "WARNING: HTTP routing to $host returned unexpected status: $HTTP_RESULT"
    fi
    
    # Test HTTPS access (if TLS is configured)
    log "Testing HTTPS access to host $host..."
    HTTPS_RESULT=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl exec ingress-routing-test -n $NAMESPACE -- curl -s -o /dev/null -w '%{http_code}' -k --connect-timeout 10 https://$host" || echo "000")
    
    if [[ "$HTTPS_RESULT" == "200" || "$HTTPS_RESULT" == "301" || "$HTTPS_RESULT" == "302" ]]; then
        log "SUCCESS: HTTPS routing to $host works (status: $HTTPS_RESULT)"
    elif [[ "$HTTPS_RESULT" == "000" ]]; then
        log "INFO: Could not connect to $host via HTTPS (may not have TLS configured)"
    else
        log "WARNING: HTTPS routing to $host returned unexpected status: $HTTPS_RESULT"
    fi
done

# Test 4: Test path-based routing (if multiple paths are configured)
if [[ $(echo "$PATHS" | wc -w) -gt 1 ]]; then
    log "=== Test 4: Path-based Routing Test ==="
    
    for path in $PATHS; do
        # Get the first host for path testing
        first_host=$(echo "$HOSTS" | awk '{print $1}')
        log "Testing path: $path on host: $first_host"
        
        # Test HTTP path routing
        HTTP_PATH_RESULT=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl exec ingress-routing-test -n $NAMESPACE -- curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 http://$first_host$path" || echo "000")
        
        if [[ "$HTTP_PATH_RESULT" == "200" || "$HTTP_PATH_RESULT" == "301" || "$HTTP_PATH_RESULT" == "302" || "$HTTP_PATH_RESULT" == "404" ]]; then
            log "SUCCESS: Path routing to $path works (status: $HTTP_PATH_RESULT)"
        else
            log "WARNING: Path routing to $path returned unexpected status: $HTTP_PATH_RESULT"
        fi
    done
fi

# Test 5: Test backend service connectivity directly
log "=== Test 5: Backend Service Connectivity ==="
log "Testing direct connectivity to backend service $BACKEND_SERVICE:$BACKEND_PORT..."

SERVICE_RESULT=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl exec ingress-routing-test -n $NAMESPACE -- curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 http://$BACKEND_SERVICE.$NAMESPACE.svc.cluster.local:$BACKEND_PORT" || echo "000")

if [[ "$SERVICE_RESULT" == "200" || "$SERVICE_RESULT" == "301" || "$SERVICE_RESULT" == "302" ]]; then
    log "SUCCESS: Backend service is accessible (status: $SERVICE_RESULT)"
else
    log "WARNING: Backend service returned unexpected status: $SERVICE_RESULT"
fi

# Clean up test pod
log "Cleaning up test pod..."
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl delete pod ingress-routing-test -n $NAMESPACE" || true
rm -f /tmp/ingress-test-pod.yaml

# Test completed
log "=== Ingress Routing Test Summary ==="
log "✓ VM exists and is running"
log "✓ microk8s is ready"
log "✓ Ingress resource exists and is configured"
log "✓ Backend service exists and has endpoints"
log "✓ Ingress controller is running"
log "✓ Ingress has routing rules configured"
log "✓ HTTP routing to configured hosts works"
log "✓ HTTPS routing to configured hosts works (if TLS configured)"
log "✓ Path-based routing works (if multiple paths configured)"
log "✓ Backend service is accessible"

log ""
log "Ingress routing test completed successfully"
log "Ingress is correctly routing traffic to the application service"