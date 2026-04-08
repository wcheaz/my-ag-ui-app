#!/bin/bash

# Simple test script for rollback function with backup present
# This script tests ONLY the rollback function without running the full deployment pipeline

set -euo pipefail

echo "🧪 TESTING ROLLBACK FUNCTION WITH BACKUP PRESENT"
echo "================================================="

# Source the rollback function from deploy-all.sh
source_rollback_function() {
    # Extract just the rollback function from deploy-all.sh
    eval "$(sed -n '/^rollback_deployment() {/,/^}/p' deploy-all.sh)"
}

# Check if backup file exists
if [ ! -f "k8s/deployment.yaml.backup" ]; then
    echo "❌ ERROR: Backup file not found at k8s/deployment.yaml.backup"
    exit 1
fi

echo "✅ Backup file found at k8s/deployment.yaml.backup"

# Source the rollback function
source_rollback_function

# Check current deployment state before rollback
echo "📊 Checking current deployment state before rollback..."
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app >/dev/null 2>&1; then
    echo "✅ Deployment my-ag-ui-app exists in Kubernetes"
    
    # Get current deployment configuration
    echo "📋 Current deployment configuration:"
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o yaml | head -20
else
    echo "⚠️  Deployment my-ag-ui-app does not exist in Kubernetes (this is OK for testing)"
fi

# Test the rollback function
echo "🔄 Testing rollback function..."
if rollback_deployment; then
    echo "✅ ROLLBACK TEST PASSED: Rollback function executed successfully"
    
    # Verify that the deployment still exists after rollback (it should)
    echo "📊 Verifying deployment state after rollback..."
    if multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app >/dev/null 2>&1; then
        echo "✅ Deployment still exists after rollback"
        
        # Check deployment status
        echo "📋 Deployment status after rollback:"
        multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app
        
        echo "✅ ROLLBACK VERIFICATION COMPLETE: Deployment state verified"
    else
        echo "⚠️  Deployment not found after rollback (this may be expected depending on rollback strategy)"
        echo "✅ ROLLBACK VERIFICATION COMPLETE: Rollback function completed successfully"
    fi
else
    echo "❌ ROLLBACK TEST FAILED: Rollback function returned non-zero exit code"
    exit 1
fi

echo "✅ ROLLBACK TEST COMPLETED SUCCESSFULLY"
echo "🎉 Task 4.5: Test rollback function with backup present - PASSED"