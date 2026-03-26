#!/bin/bash
set -euo pipefail

# Test Manual Rollback Procedure Script
# This script tests the manual rollback procedure by reapplying the backup manifest

echo "=== Starting Manual Rollback Test ==="
echo "Timestamp: $(date)"
echo ""

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo "ERROR: Kubernetes cluster is not accessible"
    echo "Please ensure microk8s or kubectl is properly configured and running"
    exit 1
fi

echo "✓ Kubernetes cluster is accessible"

# Get current deployment state before rollback
echo ""
echo "=== Current Deployment State (Before Rollback) ==="
kubectl get deployment my-ag-ui-app -o yaml | head -20 || echo "Deployment not found or not accessible"

echo ""
echo "=== Current Pod States (Before Rollback) ==="
kubectl get pods -l app=my-ag-ui-app || echo "No pods found or not accessible"

# Apply backup manifest
echo ""
echo "=== Applying Backup Manifest ==="
echo "Source: k8s/deployment.yaml.backup"

if kubectl apply -f k8s/deployment.yaml.backup; then
    echo "✓ Backup manifest applied successfully"
else
    echo "ERROR: Failed to apply backup manifest"
    exit 1
fi

# Monitor deployment rollout
echo ""
echo "=== Monitoring Deployment Rollout ==="
kubectl rollout status deployment/my-ag-ui-app --timeout=300s

echo ""
echo "=== Deployment State (After Rollback) ==="
kubectl get deployment my-ag-ui-app

echo ""
echo "=== Pod States (After Rollback) ==="
kubectl get pods -l app=my-ag-ui-app

# Verify pods are running
echo ""
echo "=== Verifying Pod Status ==="
RUNNING_PODS=$(kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)

if [ "$RUNNING_PODS" -gt 0 ]; then
    echo "✓ Found $RUNNING_PODS running pods"
else
    echo "⚠ No running pods found - checking pod status details"
    kubectl get pods -l app=my-ag-ui-app -o wide
    kubectl describe pods -l app=my-ag-ui-app | tail -20
fi

# Check pod readiness
echo ""
echo "=== Checking Pod Readiness ==="
READY_PODS=$(kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[?(@.status.ready)].metadata.name}' | wc -w)

if [ "$READY_PODS" -gt 0 ]; then
    echo "✓ Found $READY_PODS ready pods"
else
    echo "⚠ No ready pods found - checking pod events"
    kubectl get events --field-selector involvedObject.kind=Pod,involvedObject.name=my-ag-ui-app | tail -10
fi

echo ""
echo "=== Rollback Test Completed ==="
echo "Timestamp: $(date)"
echo ""
echo "=== Summary ==="
echo "If all pods are Running and Ready, the rollback procedure is working correctly."
echo "If pods are not Running/Ready, check the events and logs above for troubleshooting."
echo ""
echo "To check pod logs manually:"
echo "  kubectl logs -l app=my-ag-ui-app"
echo ""
echo "To check pod events manually:"
echo "  kubectl get events --field-selector involvedObject.kind=Pod,involvedObject.name=my-ag-ui-app"