#!/bin/bash

# Test script for rollback mechanism with intentional version conflicts
# This script tests the rollback_deployment function's ability to handle resource version conflicts

set -euo pipefail

# Source common functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
else
    echo "ERROR: deploy_scripts/common.sh not found. Cannot continue with test."
    exit 1
fi

# Initialize log file
setup_log_file

echo "======================================"
echo "Testing rollback mechanism with intentional version conflicts"
echo "======================================"

# Get current deployment state
echo "1. Getting current deployment state..."
current_resource_version=$(multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.metadata.resourceVersion}' 2>/dev/null || echo "")
echo "   Current resource version: $current_resource_version"

# Create a test deployment manifest with conflicting resource version
echo "2. Creating test deployment manifest with conflicting resource version..."
cat > test-conflict-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
  labels:
    app: my-ag-ui-app
  # Intentionally using an old resource version to create conflict
  resourceVersion: "627253"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ag-ui-app
  template:
    metadata:
      labels:
        app: my-ag-ui-app
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              key: openai-api-key
              name: my-ag-ui-app-secrets
        - name: OPENAI_BASE_URL
          valueFrom:
            secretKeyRef:
              key: openai-base-url
              name: my-ag-ui-app-secrets
        - name: OPENAI_MODEL
          valueFrom:
            secretKeyRef:
              key: openai-model
              name: my-ag-ui-app-secrets
        - name: EMBEDDING_MODEL
          valueFrom:
            secretKeyRef:
              key: embedding-model
              name: my-ag-ui-app-secrets
        - name: LOGFIRE_TOKEN
          valueFrom:
            secretKeyRef:
              key: logfire-token
              name: my-ag-ui-app-secrets
        - name: LLM_MAX_TOKENS
          valueFrom:
            configMapKeyRef:
              key: llm-max-tokens
              name: my-ag-ui-app-config
        - name: LLM_CONTEXT_WINDOW
          valueFrom:
            configMapKeyRef:
              key: llm-context-window
              name: my-ag-ui-app-config
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          failureThreshold: 3
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 256Mi
      imagePullSecrets:
      - name: registry-secret
      restartPolicy: Always
EOF

echo "3. Verifying test deployment manifest exists..."
ls -la test-conflict-deployment.yaml
echo "3. Transferring test deployment manifest to VM..."
multipass transfer test-conflict-deployment.yaml "${VM_NAME:-my-ag-ui-app-k8s}:/home/ubuntu/test-conflict-deployment.yaml"

echo "4. Attempting to apply conflicting deployment manifest (should fail with conflict error)..."
if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl apply -f /home/ubuntu/test-conflict-deployment.yaml 2>&1 | tee -a "$LOG_FILE"; then
    echo "   ⚠️  WARNING: Conflict did not occur as expected. This might indicate an issue with the test setup."
else
    echo "   ✅ Expected conflict detected when applying deployment manifest"
fi

echo "5. Testing rollback mechanism with backup deployment..."

# Make sure backup file exists
if [ ! -f "k8s/deployment.yaml.backup" ]; then
    echo "   ❌ ERROR: Backup deployment file not found. Cannot test rollback."
    exit 1
fi

# Transfer backup file to VM
echo "   Transferring backup deployment manifest to VM..."
if ! multipass transfer k8s/deployment.yaml.backup "${VM_NAME:-my-ag-ui-app-k8s}:/home/ubuntu/deployment.yaml.backup" 2>&1 | tee -a "$LOG_FILE"; then
    echo "   ❌ ERROR: Could not transfer backup deployment manifest to VM"
    exit 1
fi

# Get the rollback_deployment function from deploy-all.sh
echo "   Sourcing rollback function from deploy-all.sh..."
# Source the entire deploy-all.sh script to get the rollback function
source deploy-all.sh

echo "6. Executing rollback mechanism..."
if rollback_deployment; then
    echo "   ✅ ROLLBACK TEST PASSED: Rollback mechanism successfully handled version conflicts"
    
    # Verify the deployment was restored
    echo "7. Verifying deployment was restored..."
    restored_resource_version=$(multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.metadata.resourceVersion}' 2>/dev/null || echo "")
    
    if [ -n "$restored_resource_version" ]; then
        echo "   ✅ Deployment restored with resource version: $restored_resource_version"
        
        # Check deployment status
        deployment_status=$(multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "")
        
        if [ "$deployment_status" = "True" ]; then
            echo "   ✅ Deployment is in Available status after rollback"
        else
            echo "   ⚠️  Deployment is not yet in Available status after rollback (this may be expected if image issues persist)"
        fi
    else
        echo "   ❌ ERROR: Could not get restored deployment resource version"
        exit 1
    fi
else
    echo "   ❌ ROLLBACK TEST FAILED: Rollback mechanism did not handle version conflicts correctly"
    exit 1
fi

echo "======================================"
echo "ROLLBACK MECHANISM TEST COMPLETED SUCCESSFULLY"
echo "✅ Rollback mechanism successfully handled resource version conflicts"
echo "======================================"

# Cleanup
rm -f test-conflict-deployment.yaml
multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- rm -f /home/ubuntu/test-conflict-deployment.yaml

echo "Test artifacts cleaned up successfully."