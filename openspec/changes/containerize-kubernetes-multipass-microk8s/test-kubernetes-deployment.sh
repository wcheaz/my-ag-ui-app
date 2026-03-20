#!/bin/bash

# Test script to test Kubernetes deployment functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="test-kubernetes-deployment-$(date +%s)"
LOG_FILE="$SCRIPT_DIR/test-kubernetes-deployment.log"

echo "Testing Kubernetes deployment functionality..."
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

# Enable storage add-on
if ! multipass exec "$VM_NAME" -- sudo microk8s enable storage; then
    echo "ERROR: Failed to enable storage add-on"
    exit 1
fi
log "✓ Storage add-on enabled"

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

# Check if storage is enabled (look for hostpath-storage since storage is deprecated)
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "hostpath-storage"; then
    echo "ERROR: Storage add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ Storage add-on is enabled"

# Check if ingress is enabled
if ! echo "$ADDON_STATUS" | grep -A 20 "addons:" | grep -A 10 "enabled:" | grep -q "ingress"; then
    echo "ERROR: Ingress add-on is not enabled"
    echo "Status output:"
    echo "$ADDON_STATUS" | grep -A 20 "addons:"
    exit 1
fi
log "✓ Ingress add-on is enabled"

# Step 9: Create test application deployment
log "Step 9: Creating test application deployment..."

# Create a simple test deployment
TEST_DEPLOYMENT=$(cat <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-nginx-deployment
  labels:
    app: test-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-nginx
  template:
    metadata:
      labels:
        app: test-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
EOF
)

# Create a test service
TEST_SERVICE=$(cat <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: test-nginx-service
  labels:
    app: test-nginx
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: test-nginx
EOF
)

# Create a test ingress
TEST_INGRESS=$(cat <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-nginx-ingress
  labels:
    app: test-nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: test-nginx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-nginx-service
            port:
              number: 80
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

# Step 12: Apply ingress manifest
log "Step 12: Applying Kubernetes ingress manifest..."
if ! echo "$TEST_INGRESS" | multipass exec "$VM_NAME" -- sudo microk8s kubectl apply -f -; then
    echo "ERROR: Failed to apply ingress manifest"
    exit 1
fi
log "✓ Ingress manifest applied successfully"

# Step 13: Wait for deployment to be ready
log "Step 13: Waiting for deployment to be ready..."
MAX_WAIT=120  # Maximum wait time in seconds
WAIT_INTERVAL=5  # Check every 5 seconds
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check if deployment exists and is ready
    DEPLOYMENT_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get deployment test-nginx-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    if [ "$DEPLOYMENT_STATUS" != "0" ] && [ -n "$DEPLOYMENT_STATUS" ]; then
        log "✓ Deployment is ready (ready replicas: $DEPLOYMENT_STATUS)"
        break
    fi
    
    # Check deployment status for debugging
    log "Waiting for deployment to be ready... (${ELAPSED}s/${MAX_WAIT}s)"
    multipass exec "$VM_NAME" -- sudo microk8s kubectl get deployment test-nginx-deployment 2>/dev/null || true
    
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "ERROR: Deployment is not ready after $MAX_WAIT seconds"
    echo "Final deployment status:"
    multipass exec "$VM_NAME" -- sudo microk8s kubectl get deployment test-nginx-deployment
    
    echo "Pod status:"
    multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -l app=test-nginx
    
    echo "Pod describe (first pod):"
    POD_NAME=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -l app=test-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$POD_NAME" ]; then
        multipass exec "$VM_NAME" -- sudo microk8s kubectl describe pod "$POD_NAME" 2>/dev/null || true
    fi
    
    echo "Recent events:"
    multipass exec "$VM_NAME" -- sudo microk8s kubectl get events --sort-by='.lastTimestamp' | tail -10 || true
    
    exit 1
fi

# Step 14: Verify pod is running
log "Step 14: Verifying pod is running..."
POD_STATUS=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -l app=test-nginx -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
if [ "$POD_STATUS" != "Running" ]; then
    echo "ERROR: Pod is not running. Status: $POD_STATUS"
    echo "Pod details:"
    multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -l app=test-nginx
    exit 1
fi
log "✓ Pod is running"

# Step 15: Verify service is created
log "Step 15: Verifying service is created..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl get service test-nginx-service >/dev/null 2>&1; then
    echo "ERROR: Service was not created"
    exit 1
fi
log "✓ Service is created"

# Step 16: Verify ingress is created
log "Step 16: Verifying ingress is created..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl get ingress test-nginx-ingress >/dev/null 2>&1; then
    echo "ERROR: Ingress was not created"
    exit 1
fi
log "✓ Ingress is created"

# Step 17: Test application accessibility
log "Step 17: Testing application accessibility..."

# Get the pod name
POD_NAME=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get pods -l app=test-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

# Test port-forwarding to access the application
log "Testing application via port-forwarding..."
# Start port-forwarding in background
multipass exec "$VM_NAME" -- sudo microk8s kubectl port-forward service/test-nginx-service 8080:80 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait a moment for port-forwarding to start
sleep 5

# Test if we can access the application via port-forwarding
if ! multipass exec "$VM_NAME" -- curl -s -f http://localhost:8080 >/dev/null 2>&1; then
    echo "ERROR: Application is not accessible via port-forwarding"
    # Kill port-forwarding
    kill $PORT_FORWARD_PID 2>/dev/null || true
    exit 1
fi
log "✓ Application is accessible via port-forwarding"

# Kill port-forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true

# Step 18: Test liveness and readiness probes
log "Step 18: Testing liveness and readiness probes..."

# Get pod details to check probe status (using kubectl describe instead of jq)
POD_DESCRIBE=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl describe pod "$POD_NAME" 2>/dev/null || echo "")

# Check if liveness probe is configured
if echo "$POD_DESCRIBE" | grep -q "Liveness:"; then
    log "✓ Liveness probe is configured"
else
    echo "ERROR: Liveness probe is not configured"
    echo "Pod describe output (probing for Liveness):"
    echo "$POD_DESCRIBE" | grep -A 5 -B 5 "Liveness\|Readiness\|Probe" || echo "No probe information found"
    exit 1
fi

# Check if readiness probe is configured
if echo "$POD_DESCRIBE" | grep -q "Readiness:"; then
    log "✓ Readiness probe is configured"
else
    echo "ERROR: Readiness probe is not configured"
    echo "Pod describe output (probing for Readiness):"
    echo "$POD_DESCRIBE" | grep -A 5 -B 5 "Liveness\|Readiness\|Probe" || echo "No probe information found"
    exit 1
fi

# Step 19: Test resource limits
log "Step 19: Testing resource limits..."

# Get container resource limits (using kubectl describe instead of jq)
if echo "$POD_DESCRIBE" | grep -q "Limits:"; then
    # Extract limits information
    CPU_LIMIT=$(echo "$POD_DESCRIBE" | grep -A 10 "Limits:" | grep "cpu" | awk '{print $2}' || echo "unknown")
    MEMORY_LIMIT=$(echo "$POD_DESCRIBE" | grep -A 10 "Limits:" | grep "memory" | awk '{print $2}' || echo "unknown")
    
    if [ "$CPU_LIMIT" != "unknown" ] && [ "$MEMORY_LIMIT" != "unknown" ]; then
        log "✓ Resource limits are configured (CPU: $CPU_LIMIT, Memory: $MEMORY_LIMIT)"
    else
        echo "ERROR: Resource limits are not configured properly"
        echo "Pod describe output (probing for Limits):"
        echo "$POD_DESCRIBE" | grep -A 10 -B 2 "Limits\|Requests" || echo "No resource limit information found"
        exit 1
    fi
else
    echo "ERROR: Resource limits are not configured"
    echo "Pod describe output:"
    echo "$POD_DESCRIBE" | grep -A 10 -B 2 "Limits\|Requests" || echo "No resource limit information found"
    exit 1
fi

# Step 20: Test deployment cleanup
log "Step 20: Testing deployment cleanup..."

# Delete the ingress
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl delete ingress test-nginx-ingress; then
    echo "ERROR: Failed to delete ingress"
    exit 1
fi
log "✓ Ingress deleted successfully"

# Delete the service
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl delete service test-nginx-service; then
    echo "ERROR: Failed to delete service"
    exit 1
fi
log "✓ Service deleted successfully"

# Delete the deployment
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl delete deployment test-nginx-deployment; then
    echo "ERROR: Failed to delete deployment"
    exit 1
fi
log "✓ Deployment deleted successfully"

# Wait for resources to be deleted
sleep 10

# Verify all resources are deleted
REMAINING_RESOURCES=$(multipass exec "$VM_NAME" -- sudo microk8s kubectl get all -l app=test-nginx 2>/dev/null || echo "none")
if [ "$REMAINING_RESOURCES" != "none" ]; then
    # Check if remaining resources are just terminating pods
    if echo "$REMAINING_RESOURCES" | grep -q "Terminating"; then
        log "✓ Resources are being terminated (this is normal)"
        log "Remaining resources (terminating):"
        echo "$REMAINING_RESOURCES" | grep "Terminating" || true
    elif echo "$REMAINING_RESOURCES" | grep -q "No resources found"; then
        log "✓ All resources cleaned up successfully"
    else
        # Check if there are any non-terminating resources
        NON_TERMINATING=$(echo "$REMAINING_RESOURCES" | grep -v "Terminating" | grep "test-nginx" || echo "")
        if [ -z "$NON_TERMINATING" ]; then
            log "✓ All resources cleaned up successfully (only terminating resources remain)"
        else
            echo "ERROR: Some resources were not deleted:"
            echo "$REMAINING_RESOURCES"
            exit 1
        fi
    fi
else
    log "✓ All resources cleaned up successfully"
fi


echo ""
log "All Kubernetes deployment tests passed!"
echo ""
log "Tested functionality:"
log "- VM creation with multipass"
log "- microk8s installation and configuration"
log "- Required add-ons enablement (dns, storage, ingress)"
log "- Kubernetes deployment creation"
log "- Kubernetes service creation"
log "- Kubernetes ingress creation"
log "- Deployment readiness verification"
log "- Pod running status verification"
log "- Application accessibility via port-forwarding"
log "- Liveness and readiness probe configuration"
log "- Resource limits configuration"
log "- Resource cleanup"
echo ""
log "Test completed successfully!"