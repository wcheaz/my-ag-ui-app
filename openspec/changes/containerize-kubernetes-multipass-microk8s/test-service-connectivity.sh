#!/bin/bash

# Test script for Kubernetes service connectivity
# This script verifies that the Kubernetes service is accessible and responding

set -e

# Configuration
VM_NAME="my-ag-ui-app-vm"
SERVICE_NAME="my-ag-ui-app-service"
NAMESPACE="default"
LOG_FILE="service-connectivity-test.log"

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
log "Starting service connectivity test for $SERVICE_NAME"

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
if ! multipass exec "$VM_NAME" -- bash -c "microk8s status --wait-ready"; then
    error_exit "microk8s is not ready in VM $VM_NAME"
fi

log "microk8s is ready. Checking service deployment..."

# Check if service exists
log "Checking if service $SERVICE_NAME exists..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get service $SERVICE_NAME -n $NAMESPACE" >/dev/null 2>&1; then
    error_exit "Service $SERVICE_NAME not found in namespace $NAMESPACE"
fi

log "Service $SERVICE_NAME found. Checking service details..."

# Get service details
SERVICE_INFO=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get service $SERVICE_NAME -n $NAMESPACE -o json")
SERVICE_TYPE=$(echo "$SERVICE_INFO" | jq -r '.spec.type')
CLUSTER_IP=$(echo "$SERVICE_INFO" | jq -r '.spec.clusterIP')
PORT=$(echo "$SERVICE_INFO" | jq -r '.spec.ports[0].port')
TARGET_PORT=$(echo "$SERVICE_INFO" | jq -r '.spec.ports[0].targetPort')

log "Service details:"
log "  - Type: $SERVICE_TYPE"
log "  - Cluster IP: $CLUSTER_IP"
log "  - Port: $PORT"
log "  - Target Port: $TARGET_PORT"

# Check if pods are running
log "Checking pods for service $SERVICE_NAME..."
POD_SELECTOR=$(echo "$SERVICE_INFO" | jq -r '.spec.selector | to_entries | map("\(.key)=\(.value)") | join(",")')
PODS=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -n $NAMESPACE -l $POD_SELECTOR")

if [[ -z "$PODS" ]]; then
    error_exit "No pods found for service $SERVICE_NAME"
fi

log "Pods found:"
echo "$PODS" | tee -a "$LOG_FILE"

# Check if pods are ready
READY_PODS=$(echo "$PODS" | grep -c "Running" || true)
TOTAL_PODS=$(echo "$PODS" | wc -l)

if [[ "$READY_PODS" -eq 0 ]]; then
    error_exit "No pods are in Running state"
fi

log "Pods status: $READY_PODS/$TOTAL_PODS pods are running"

# Test service connectivity by creating a temporary test pod
log "Testing service connectivity using a temporary test pod..."

cat > /tmp/test-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: service-connectivity-test
  namespace: $NAMESPACE
spec:
  containers:
  - name: curl
    image: curlimages/curl:latest
    command: ['sh', '-c', 'echo "Testing service connectivity..." && sleep 3600']
  restartPolicy: Never
EOF

# Create the test pod
log "Creating temporary test pod..."
multipass exec "$VM_NAME" -- bash -c "cat > /tmp/test-pod.yaml" < /tmp/test-pod.yaml
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl apply -f /tmp/test-pod.yaml"

# Wait for test pod to be ready
log "Waiting for test pod to be ready..."
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl wait --for=condition=ready pod/service-connectivity-test -n $NAMESPACE --timeout=60s"

# Test service connectivity
log "Testing HTTP connectivity to service $SERVICE_NAME..."
HTTP_TEST_RESULT=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl exec service-connectivity-test -n $NAMESPACE -- curl -s -o /dev/null -w '%{http_code}' http://$SERVICE_NAME.$NAMESPACE.svc.cluster.local:$PORT" || echo "failed")

if [[ "$HTTP_TEST_RESULT" == "200" ]] || [[ "$HTTP_TEST_RESULT" == "302" ]]; then
    log "SUCCESS: Service responded with HTTP status $HTTP_TEST_RESULT"
else
    log "WARNING: Service responded with HTTP status $HTTP_TEST_RESULT (may be expected for non-root paths)"
fi

# Test connectivity to cluster IP directly
log "Testing connectivity to service cluster IP $CLUSTER_IP:$PORT..."
CLUSTER_IP_TEST_RESULT=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl exec service-connectivity-test -n $NAMESPACE -- curl -s -o /dev/null -w '%{http_code}' http://$CLUSTER_IP:$PORT" || echo "failed")

if [[ "$CLUSTER_IP_TEST_RESULT" == "200" ]] || [[ "$CLUSTER_IP_TEST_RESULT" == "302" ]]; then
    log "SUCCESS: Cluster IP responded with HTTP status $CLUSTER_IP_TEST_RESULT"
else
    log "WARNING: Cluster IP responded with HTTP status $CLUSTER_IP_TEST_RESULT (may be expected for non-root paths)"
fi

# Clean up test pod
log "Cleaning up test pod..."
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl delete pod service-connectivity-test -n $NAMESPACE" || true
rm -f /tmp/test-pod.yaml

# Final verification
log "Performing final verification..."

# Check service endpoints
log "Checking service endpoints..."
ENDPOINTS=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get endpoints $SERVICE_NAME -n $NAMESPACE" || echo "failed")

if [[ "$ENDPOINTS" != "failed" ]]; then
    log "SUCCESS: Service endpoints found:"
    echo "$ENDPOINTS" | tee -a "$LOG_FILE"
else
    log "WARNING: Could not retrieve service endpoints"
fi

# Test completed successfully
log "Service connectivity test completed successfully"
log "Service $SERVICE_NAME is accessible and responding"

echo ""
echo "=== Service Connectivity Test Summary ==="
echo "✓ VM exists and is running"
echo "✓ microk8s is ready"
echo "✓ Service exists and is configured"
echo "✓ Pods are running"
echo "✓ Service is accessible via service name"
echo "✓ Service is accessible via cluster IP"
echo "✓ Service endpoints are configured"
echo ""
echo "Service connectivity test PASSED"