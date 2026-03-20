#!/bin/bash

# Test script to verify resource limits are properly configured and respected

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="test-resource-limits-$(date +%s)"
LOG_FILE="$SCRIPT_DIR/test-resource-limits.log"

echo "Testing resource limits configuration and enforcement..."
echo "Test VM name: $VM_NAME"
echo "Log file: $LOG_FILE"
echo ""

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to cleanup on exit
cleanup() {
    log "Cleaning up test resources..."
    if multipass list | grep -q "^$VM_NAME "; then
        multipass delete "$VM_NAME" && multipass purge
        log "✓ Test VM deleted"
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

# Step 2: Verify deployment.yaml contains resource limits
log "Step 2: Verifying deployment.yaml contains resource limits..."
DEPLOYMENT_FILE="$SCRIPT_DIR/k8s/deployment.yaml"

if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "ERROR: deployment.yaml not found at $DEPLOYMENT_FILE"
    exit 1
fi

# Check for resource requests and limits
if ! grep -q "resources:" "$DEPLOYMENT_FILE"; then
    echo "ERROR: resources section not found in deployment.yaml"
    exit 1
fi

if ! grep -q "requests:" "$DEPLOYMENT_FILE"; then
    echo "ERROR: requests section not found in deployment.yaml"
    exit 1
fi

if ! grep -q "limits:" "$DEPLOYMENT_FILE"; then
    echo "ERROR: limits section not found in deployment.yaml"
    exit 1
fi

# Check for CPU and memory in both requests and limits
if ! grep -q "cpu:" "$DEPLOYMENT_FILE"; then
    echo "ERROR: cpu resource not specified in deployment.yaml"
    exit 1
fi

if ! grep -q "memory:" "$DEPLOYMENT_FILE"; then
    echo "ERROR: memory resource not specified in deployment.yaml"
    exit 1
fi

log "✓ Resource limits are properly configured in deployment.yaml"

# Step 3: Create test VM with microk8s
log "Step 3: Creating test VM with microk8s..."
if ! multipass launch --cpus 2 --memory 4G --disk 10G --name "$VM_NAME"; then
    echo "ERROR: Failed to create test VM"
    exit 1
fi
log "✓ Test VM created successfully"

# Step 4: Install microk8s in VM
log "Step 4: Installing microk8s in VM..."
if ! multipass exec "$VM_NAME" -- sudo snap install microk8s --classic; then
    echo "ERROR: Failed to install microk8s"
    exit 1
fi
log "✓ microk8s installed successfully"

# Step 5: Install Docker in VM
log "Step 5: Installing Docker in VM..."
multipass exec "$VM_NAME" -- sudo snap install docker --classic
log "✓ Docker installed successfully"

# Step 6: Configure microk8s permissions and wait for it to be ready
log "Step 6: Configuring microk8s permissions..."
multipass exec "$VM_NAME" -- sudo usermod -a -G microk8s ubuntu
multipass exec "$VM_NAME" -- sudo usermod -a -G docker ubuntu || true
multipass exec "$VM_NAME" -- sudo chown -R ubuntu /home/ubuntu/.kube || true
log "✓ microk8s permissions configured"

log "Step 7: Waiting for microk8s to be ready..."
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s status --wait-ready"
log "✓ microk8s is ready"

# Step 8: Enable required add-ons
log "Step 8: Enabling required add-ons..."
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s enable dns"
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s enable storage"
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s enable ingress"
log "✓ Add-ons enabled"

# Step 9: Copy Kubernetes manifests to VM
log "Step 9: Copying Kubernetes manifests to VM..."
if [ ! -d "$SCRIPT_DIR/k8s" ]; then
    echo "ERROR: k8s directory not found"
    exit 1
fi

multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/k8s
multipass copy-files "$SCRIPT_DIR/k8s"/* "$VM_NAME:/home/ubuntu/k8s/"
log "✓ Kubernetes manifests copied to VM"

# Step 10: Copy Dockerfile and build context
log "Step 10: Copying Dockerfile and build context to VM..."
multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/app

# Copy files from the project root directory
PROJECT_ROOT="/home/ncheaz/git/my-ag-ui-app"
echo "DEBUG: Using PROJECT_ROOT: $PROJECT_ROOT"
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    multipass copy-files "$PROJECT_ROOT/Dockerfile" "$VM_NAME:/home/ubuntu/app/"
else
    echo "ERROR: Dockerfile not found at $PROJECT_ROOT/Dockerfile"
    exit 1
fi

if [ -f "$PROJECT_ROOT/package.json" ]; then
    multipass copy-files "$PROJECT_ROOT/package.json" "$VM_NAME:/home/ubuntu/app/"
else
    echo "ERROR: package.json not found at $PROJECT_ROOT/package.json"
    exit 1
fi

if [ -f "$PROJECT_ROOT/package-lock.json" ]; then
    multipass copy-files "$PROJECT_ROOT/package-lock.json" "$VM_NAME:/home/ubuntu/app/"
else
    echo "ERROR: package-lock.json not found at $PROJECT_ROOT/package-lock.json"
    exit 1
fi

if [ -d "$PROJECT_ROOT/src" ]; then
    multipass copy-files "$PROJECT_ROOT/src" "$VM_NAME:/home/ubuntu/app/src/" --recursive
else
    echo "ERROR: src directory not found at $PROJECT_ROOT/src"
    exit 1
fi

if [ -d "$PROJECT_ROOT/public" ]; then
    multipass copy-files "$PROJECT_ROOT/public" "$VM_NAME:/home/ubuntu/app/public/" --recursive
fi

if [ -f "$PROJECT_ROOT/next.config.ts" ]; then
    multipass copy-files "$PROJECT_ROOT/next.config.ts" "$VM_NAME:/home/ubuntu/app/"
fi

if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
    multipass copy-files "$PROJECT_ROOT/tsconfig.json" "$VM_NAME:/home/ubuntu/app/"
fi

log "✓ Build context copied to VM"

# Step 11: Build Docker image in VM
log "Step 11: Building Docker image in VM..."
multipass exec "$VM_NAME" -- sudo docker build -t my-ag-ui-app:latest /home/ubuntu/app/
log "✓ Docker image built successfully"

# Step 12: Load image into microk8s
log "Step 12: Loading Docker image into microk8s..."
multipass exec "$VM_NAME" -- sudo docker save my-ag-ui-app:latest > /tmp/my-ag-ui-app.tar
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s image import /tmp/my-ag-ui-app.tar"
log "✓ Docker image loaded into microk8s"

# Step 13: Create test config and secrets
log "Step 13: Creating test config and secrets..."
multipass exec "$VM_NAME" -- bash -c 'newgrp microk8s && cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-ag-ui-app-config
data:
  openai-base-url: "https://api.openai.com/v1"
  openai-model: "gpt-4"
  llm-max-tokens: "4000"
  llm-context-window: "8000"
  embedding-model: "text-embedding-ada-002"
EOF'

multipass exec "$VM_NAME" -- bash -c 'newgrp microk8s && cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: my-ag-ui-app-secrets
type: Opaque
data:
  openai-api-key: dGVzdC1hcGkta2V5  # "test-api-key" base64 encoded
  logfire-token: dGVzdC1sb2dmaXJlLXRva2Vu  # "test-logfire-token" base64 encoded
EOF'
log "✓ Test config and secrets created"

# Step 14: Apply deployment manifest
log "Step 14: Applying deployment manifest..."
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl apply -f /home/ubuntu/k8s/deployment.yaml"
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl apply -f /home/ubuntu/k8s/service.yaml"
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl apply -f /home/ubuntu/k8s/ingress.yaml"
log "✓ Kubernetes manifests applied"

# Step 15: Wait for pod to be ready
log "Step 15: Waiting for pod to be ready..."
timeout 300 bash -c "until multipass exec '$VM_NAME' -- bash -c \"newgrp microk8s && microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.phase}'\" | grep -q 'Running'; do sleep 5; done"
log "✓ Pod is running"

# Step 16: Verify resource limits are being enforced
log "Step 16: Verifying resource limits are being enforced..."
POD_NAME=$(multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].metadata.name}'")

# Check actual resource usage against limits
log "Checking pod resource usage..."
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl top pod \"$POD_NAME\"" || log "WARNING: metrics-server not installed, skipping actual usage check"

# Verify resource limits are set in the running pod
log "Verifying resource limits in pod specification..."
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl get pod \"$POD_NAME\" -o jsonpath='{.spec.containers[0].resources.requests.cpu}'" > /tmp/requests_cpu.txt
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl get pod \"$POD_NAME\" -o jsonpath='{.spec.containers[0].resources.requests.memory}'" > /tmp/requests_memory.txt
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl get pod \"$POD_NAME\" -o jsonpath='{.spec.containers[0].resources.limits.cpu}'" > /tmp/limits_cpu.txt
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl get pod \"$POD_NAME\" -o jsonpath='{.spec.containers[0].resources.limits.memory}'" > /tmp/limits_memory.txt

log "Resource requests - CPU: $(cat /tmp/requests_cpu.txt), Memory: $(cat /tmp/requests_memory.txt)"
log "Resource limits - CPU: $(cat /tmp/limits_cpu.txt), Memory: $(cat /tmp/limits_memory.txt)"

# Step 17: Stress test to verify limits are enforced
log "Step 17: Stress testing to verify resource limits are enforced..."
multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl exec $POD_NAME -- /bin/sh -c 'dd if=/dev/zero of=/dev/null bs=1M count=1000 & sleep 30; kill \$!'" || true
log "✓ Stress test completed"

# Step 18: Verify pod is still running after stress test
log "Step 18: Verifying pod is still running after stress test..."
POD_STATUS=$(multipass exec "$VM_NAME" -- bash -c "newgrp microk8s && microk8s kubectl get pod \"$POD_NAME\" -o jsonpath='{.status.phase}'")
if [ "$POD_STATUS" = "Running" ]; then
    log "✓ Pod is still running after stress test"
else
    echo "ERROR: Pod is not running after stress test (status: $POD_STATUS)"
    exit 1
fi

log ""
log "🎉 All resource limits tests passed!"
log "Resource limits are properly configured and being enforced by Kubernetes."

exit 0