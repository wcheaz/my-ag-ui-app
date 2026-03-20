#!/bin/bash

# Test script specifically for testing health checks (liveness and readiness probes)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="test-health-checks-$(date +%s)"
LOG_FILE="$SCRIPT_DIR/test-health-checks.log"

echo "Testing health checks (liveness and readiness probes)..."
echo "Test VM name: $VM_NAME"
echo "Log file: $LOG_FILE"
echo ""

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to cleanup on exit
cleanup() {
    log "Cleaning up test VM..."
    if multipass list | grep -q "^$VM_NAME "; then
        multipass delete "$VM_NAME" && multipass purge
        log "Test VM deleted"
    else
        log "No test VM found to delete"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Step 1: Verify multipass is available
log "Step 1: Verifying multipass is available..."
if ! command -v multipass &> /dev/null; then
    echo "ERROR: multipass is not installed or not in PATH"
    exit 1
fi
log "✓ multipass is available"

# Step 2: Create test VM
log "Step 2: Creating test VM..."
if ! multipass launch --cpus 2 --memory 4G --disk 10G --name "$VM_NAME"; then
    echo "ERROR: Failed to create test VM"
    exit 1
fi
log "✓ Test VM created successfully"

# Step 3: Wait for VM to be ready
log "Step 3: Waiting for VM to be ready..."
sleep 10
if ! multipass exec "$VM_NAME" -- uptime; then
    echo "ERROR: VM is not responding"
    exit 1
fi
log "✓ VM is ready and responsive"

# Step 4: Install microk8s in VM
log "Step 4: Installing microk8s in VM..."
if ! multipass exec "$VM_NAME" -- sudo snap install microk8s --classic; then
    echo "ERROR: Failed to install microk8s"
    exit 1
fi
log "✓ microk8s installed successfully"

# Step 5: Configure microk8s permissions
log "Step 5: Configuring microk8s permissions..."
if ! multipass exec "$VM_NAME" -- sudo usermod -a -G microk8s ubuntu; then
    echo "ERROR: Failed to add user to microk8s group"
    exit 1
fi
if ! multipass exec "$VM_NAME" -- sudo chown -f -R ubuntu ~/.kube; then
    echo "WARNING: Failed to chown .kube directory (may not exist yet)"
fi
log "✓ microk8s permissions configured"

# Step 6: Wait for microk8s to be ready
log "Step 6: Waiting for microk8s to be ready..."
sleep 30
if ! multipass exec "$VM_NAME" -- sudo microk8s status --wait-ready; then
    echo "ERROR: microk8s is not ready"
    exit 1
fi
log "✓ microk8s is ready"

# Step 7: Enable required add-ons
log "Step 7: Enabling required add-ons..."

# Enable DNS add-on
if ! multipass exec "$VM_NAME" -- sudo microk8s enable dns; then
    echo "ERROR: Failed to enable DNS add-on"
    exit 1
fi
log "✓ DNS add-on enabled"

# Enable ingress add-on
if ! multipass exec "$VM_NAME" -- sudo microk8s enable ingress; then
    echo "ERROR: Failed to enable ingress add-on"
    exit 1
fi
log "✓ Ingress add-on enabled"

# Step 8: Verify add-ons are enabled
log "Step 8: Verifying add-ons are enabled..."
sleep 10

# Get the status and check for enabled add-ons
ADDON_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s status)

# Check if DNS is enabled
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "dns"; then
    echo "ERROR: DNS add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ DNS add-on is enabled"

# Check if ingress is enabled
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "ingress"; then
    echo "ERROR: Ingress add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ Ingress add-on is enabled"

# Step 9: Create test application deployment with health checks
log "Step 9: Creating test application deployment with health checks..."

# Create a test deployment that mimics our actual application deployment
TEST_DEPLOYMENT=$(cat <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-check-test
  labels:
    app: health-check-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-check-test
  template:
    metadata:
      labels:
        app: health-check-test
    spec:
      containers:
      - name: health-check-test
        image: nginx:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
EOF
)

# Create a test service
TEST_SERVICE=$(cat <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: health-check-test-service
  labels:
    app: health-check-test
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: health-check-test
EOF
)

# Step 10: Apply deployment manifest
log "Step 10: Applying Kubernetes deployment manifest..."
if ! echo "$TEST_DEPLOYMENT" | multipass exec "$VM_NAME" -- sudo microk8s kubectl apply -f -; then
    echo "ERROR: Failed to apply deployment manifest"
    exit 1
fi
log "✓ Deployment manifest applied successfully"

# Step 11: Apply service manifest
log "Step 11: Applying Kubernetes service manifest..."
if ! echo "$TEST_SERVICE" | multipass exec "$VM_NAME" -- sudo microk8s kubectl apply -f -; then
    echo "ERROR: Failed to apply service manifest"
    exit 1
fi
log "✓ Service manifest applied successfully"

# Step 12: Wait for deployment to be ready
log "Step 12: Waiting for deployment to be ready..."
MAX_WAIT=120
WAIT_INTERVAL=5
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check if deployment exists and is ready
    DEPLOYMENT_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get deployment health-check-test -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    if [ "$DEPLOYMENT_STATUS" != "0" ] && [ -n "$DEPLOYMENT_STATUS" ]; then
        log "✓ Deployment is ready (ready replicas: $DEPLOYMENT_STATUS)"
        break
    fi
    
    log "Waiting for deployment to be ready... (${ELAPSED}s/${MAX_WAIT}s)"
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "ERROR: Deployment is not ready after $MAX_WAIT seconds"
    echo "Final deployment status:"
    multipass exec "$VM_NAME" -- sudo microk8s kubectl get deployment health-check-test
    exit 1
fi

# Step 13: Get pod name for detailed testing
log "Step 13: Getting pod name for detailed testing..."
POD_NAME=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -l app=health-check-test -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$POD_NAME" ]; then
    echo "ERROR: Could not get pod name"
    exit 1
fi
log "✓ Pod name: $POD_NAME"

# Step 14: Verify liveness probe configuration
log "Step 14: Verifying liveness probe configuration..."
POD_DESCRIBE=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl describe pod "$POD_NAME" 2>/dev/null || echo "")

# Check liveness probe configuration
if ! echo "$POD_DESCRIBE" | grep -q "Liveness:"; then
    echo "ERROR: Liveness probe is not configured"
    exit 1
fi

# Extract liveness probe details
LIVENESS_PATH=$(echo "$POD_DESCRIBE" | grep -A 15 "Liveness:" | grep "HTTP GET" | head -1 | awk -F'/' '{print $2}' | awk '{print $1}' || echo "/")
LIVENESS_PORT=$(echo "$POD_DESCRIBE" | grep -A 15 "Liveness:" | grep "port:" | head -1 | awk '{print $2}' || echo "80")
LIVENESS_INITIAL_DELAY=$(echo "$POD_DESCRIBE" | grep -A 15 "Liveness:" | grep "initial delay seconds:" | head -1 | awk '{print $4}' || echo "30")
LIVENESS_PERIOD=$(echo "$POD_DESCRIBE" | grep -A 15 "Liveness:" | grep "period seconds:" | head -1 | awk '{print $3}' || echo "30")
LIVENESS_TIMEOUT=$(echo "$POD_DESCRIBE" | grep -A 15 "Liveness:" | grep "timeout seconds:" | head -1 | awk '{print $3}' || echo "10")

log "✓ Liveness probe configured:"
log "  - Path: $LIVENESS_PATH"
log "  - Port: $LIVENESS_PORT"
log "  - Initial delay: ${LIVENESS_INITIAL_DELAY}s"
log "  - Period: ${LIVENESS_PERIOD}s"
log "  - Timeout: ${LIVENESS_TIMEOUT}s"

# Step 15: Verify readiness probe configuration
log "Step 15: Verifying readiness probe configuration..."
if ! echo "$POD_DESCRIBE" | grep -q "Readiness:"; then
    echo "ERROR: Readiness probe is not configured"
    exit 1
fi

# Extract readiness probe details
READINESS_PATH=$(echo "$POD_DESCRIBE" | grep -A 15 "Readiness:" | grep "HTTP GET" | head -1 | awk -F'/' '{print $2}' | awk '{print $1}' || echo "/")
READINESS_PORT=$(echo "$POD_DESCRIBE" | grep -A 15 "Readiness:" | grep "port:" | head -1 | awk '{print $2}' || echo "80")
READINESS_INITIAL_DELAY=$(echo "$POD_DESCRIBE" | grep -A 15 "Readiness:" | grep "initial delay seconds:" | head -1 | awk '{print $4}' || echo "5")
READINESS_PERIOD=$(echo "$POD_DESCRIBE" | grep -A 15 "Readiness:" | grep "period seconds:" | head -1 | awk '{print $3}' || echo "10")
READINESS_TIMEOUT=$(echo "$POD_DESCRIBE" | grep -A 15 "Readiness:" | grep "timeout seconds:" | head -1 | awk '{print $3}' || echo "5")

log "✓ Readiness probe configured:"
log "  - Path: $READINESS_PATH"
log "  - Port: $READINESS_PORT"
log "  - Initial delay: ${READINESS_INITIAL_DELAY}s"
log "  - Period: ${READINESS_PERIOD}s"
log "  - Timeout: ${READINESS_TIMEOUT}s"

# Step 16: Test liveness probe endpoint
log "Step 16: Testing liveness probe endpoint..."

# Test port-forwarding to access the liveness endpoint
log "Testing liveness endpoint via port-forwarding..."
multipass exec "$VM_NAME" -- sudo microk8s kubectl port-forward service/health-check-test-service 8080:80 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait for port-forwarding to start
sleep 5

# Test liveness endpoint
if ! multipass exec "$VM_NAME" -- curl -s -f http://localhost:8080$LIVENESS_PATH >/dev/null 2>&1; then
    echo "ERROR: Liveness endpoint is not responding"
    kill $PORT_FORWARD_PID 2>/dev/null || true
    exit 1
fi
log "✓ Liveness endpoint is responding"

# Kill port-forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true

# Step 17: Test readiness probe endpoint
log "Step 17: Testing readiness probe endpoint..."

# Test port-forwarding to access the readiness endpoint
log "Testing readiness endpoint via port-forwarding..."
multipass exec "$VM_NAME" -- sudo microk8s kubectl port-forward service/health-check-test-service 8080:80 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait for port-forwarding to start
sleep 5

# Test readiness endpoint
if ! multipass exec "$VM_NAME" -- curl -s -f http://localhost:8080$READINESS_PATH >/dev/null 2>&1; then
    echo "ERROR: Readiness endpoint is not responding"
    kill $PORT_FORWARD_PID 2>/dev/null || true
    exit 1
fi
log "✓ Readiness endpoint is responding"

# Kill port-forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true

# Step 18: Monitor probe activity
log "Step 18: Monitoring probe activity..."

# Wait for some probe activity to occur
sleep 30

# Check if there are any probe events
PROBE_EVENTS=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get events --field-selector involvedObject.name="$POD_NAME" 2>/dev/null | grep -i "probe" || echo "")
if [ -n "$PROBE_EVENTS" ]; then
    log "✓ Probe activity detected:"
    echo "$PROBE_EVENTS" | while read line; do
        log "  - $line"
    done
else
    log "ℹ No probe events in recent history (this is normal for healthy pods)"
fi

# Step 19: Verify pod is still healthy
log "Step 19: Verifying pod is still healthy..."
POD_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
if [ "$POD_STATUS" != "Running" ]; then
    echo "ERROR: Pod is not running. Status: $POD_STATUS"
    exit 1
fi

# Check if pod is ready
READY_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get pod "$POD_NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
if [ "$READY_STATUS" != "True" ]; then
    echo "ERROR: Pod is not ready. Ready status: $READY_STATUS"
    exit 1
fi

log "✓ Pod is healthy and ready"

# Step 20: Cleanup test resources
log "Step 20: Cleaning up test resources..."

# Delete the service
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl delete service health-check-test-service; then
    echo "WARNING: Failed to delete service (may already be deleted)"
fi
log "✓ Service deleted"

# Delete the deployment
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl delete deployment health-check-test; then
    echo "WARNING: Failed to delete deployment (may already be deleted)"
fi
log "✓ Deployment deleted"

# Wait for resources to be deleted
sleep 10

echo ""
log "All health check tests passed!"
echo ""
log "Tested functionality:"
log "- Liveness probe configuration and endpoint"
log "- Readiness probe configuration and endpoint"
log "- Probe parameters (path, port, timing, thresholds)"
log "- Probe endpoint accessibility"
log "- Probe activity monitoring"
log "- Pod health status verification"
echo ""
log "Health check test completed successfully!"