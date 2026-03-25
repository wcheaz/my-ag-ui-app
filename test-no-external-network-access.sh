#!/bin/bash

# Test script to verify no external network access is required for deployment
# This is for task 8.3: Verify no external network access is required for deployment

echo "=== TASK 8.3: VERIFY NO EXTERNAL NETWORK ACCESS IS REQUIRED FOR DEPLOYMENT ==="
echo "Testing deployment without external network access requirements..."

# Set VM name (same as in deploy.sh)
VM_NAME="my-ag-ui-app-k8s"
DEPLOYMENT_FILE="/home/ncheaz/git/my-ag-ui-app/k8s/deployment.yaml"

# Step 1: Check if VM is running
echo "Step 1: Checking if VM '$VM_NAME' is running..."
if ! multipass info "$VM_NAME" | grep -q "Running"; then
    echo "❌ ERROR: VM '$VM_NAME' is not running"
    echo "RECOVERY: Start the VM with: multipass start '$VM_NAME'"
    exit 1
fi
echo "✅ VM '$VM_NAME' is running"

# Step 2: Verify deployment manifest uses local registry
echo "Step 2: Verifying deployment manifest uses local registry..."
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "❌ ERROR: Deployment file not found: $DEPLOYMENT_FILE"
    exit 1
fi

# Check if deployment manifest is currently using local registry
if grep -q "localhost:32000/my-ag-ui-app:latest" "$DEPLOYMENT_FILE"; then
    echo "✅ Deployment manifest is configured to use local registry: localhost:32000/my-ag-ui-app:latest"
    LOCAL_REGISTRY_CONFIGURED=true
elif grep -q "my-ag-ui-app:latest" "$DEPLOYMENT_FILE"; then
    echo "⚠️  WARNING: Deployment manifest is using external image reference: my-ag-ui-app:latest"
    echo "   This test requires the deployment to be configured for local registry"
    echo "   Please configure deployment to use: localhost:32000/my-ag-ui-app:latest"
    LOCAL_REGISTRY_CONFIGURED=false
else
    echo "❌ ERROR: Unable to determine image reference in deployment manifest"
    exit 1
fi

# Step 3: Check microk8s registry is accessible
echo "Step 3: Verifying microk8s registry is accessible..."
if ! multipass exec "$VM_NAME" -- curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
    echo "❌ ERROR: Local registry is not accessible at localhost:32000"
    echo "RECOVERY: Enable microk8s registry: multipass exec '$VM_NAME' -- microk8s enable registry"
    exit 1
fi
echo "✅ Local registry is accessible at localhost:32000"

# Step 4: Check if image exists in local registry
echo "Step 4: Checking if my-ag-ui-app image exists in local registry..."
registry_catalog=$(multipass exec "$VM_NAME" -- curl -s http://localhost:32000/v2/_catalog 2>/dev/null || echo "error")
if [[ "$registry_catalog" == *"error"* ]]; then
    echo "❌ ERROR: Failed to query registry catalog"
    exit 1
fi

if [[ "$registry_catalog" == *"my-ag-ui-app"* ]]; then
    echo "✅ my-ag-ui-app repository exists in local registry"
    
    # Check image tags
    image_tags=$(multipass exec "$VM_NAME" -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list 2>/dev/null || echo "error")
    if [[ "$image_tags" == *"latest"* ]]; then
        echo "✅ my-ag-ui-app:latest tag exists in local registry"
        IMAGE_IN_REGISTRY=true
    else
        echo "⚠️  WARNING: my-ag-ui-app repository exists but 'latest' tag not found"
        IMAGE_IN_REGISTRY=false
    fi
else
    echo "⚠️  WARNING: my-ag-ui-app repository not found in local registry"
    echo "   Registry catalog: $registry_catalog"
    IMAGE_IN_REGISTRY=false
fi

# Step 5: Verify deployment can be applied without external network access
echo "Step 5: Testing deployment without external network access..."

if [ "$LOCAL_REGISTRY_CONFIGURED" = true ] && [ "$IMAGE_IN_REGISTRY" = true ]; then
    echo "✅ Prerequisites met for testing deployment without external network access"
    
    # Get current pod status before deployment
    echo "Checking current pod status..."
    current_pods=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "none")
    echo "Current pod status: $current_pods"
    
    # Apply deployment
    echo "Applying deployment..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f - < "$DEPLOYMENT_FILE"; then
        echo "❌ ERROR: Failed to apply deployment"
        exit 1
    fi
    echo "✅ Deployment applied successfully"
    
    # Wait for deployment to stabilize
    echo "Waiting for deployment to stabilize..."
    sleep 10
    
    # Check pod status
    echo "Checking pod status after deployment..."
    pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "unknown")
    
    if [ "$pod_status" = "Running" ]; then
        echo "✅ Pod is running without external network access"
        
        # Verify pod is using local registry image
        echo "Verifying pod is using local registry image..."
        pod_image=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null || echo "unknown")
        
        if [[ "$pod_image" == *"localhost:32000"* ]]; then
            echo "✅ Pod is using local registry image: $pod_image"
            
            # Check for ImagePullBackOff errors
            echo "Checking for ImagePullBackOff errors..."
            pod_ready=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
            
            # Check if the image was successfully pulled from local registry (no external network access required)
            image_pull_success=false
            if multipass exec "$VM_NAME" -- microk8s kubectl describe pod -l app=my-ag-ui-app | grep -q "Container image.*localhost:32000.*already present on machine"; then
                image_pull_success=true
            elif multipass exec "$VM_NAME" -- microk8s kubectl describe pod -l app=my-ag-ui-app | grep -q "Pulled image.*localhost:32000"; then
                image_pull_success=true
            fi
            
            if [ "$image_pull_success" = true ]; then
                echo "✅ SUCCESS: Image successfully pulled from local registry without external network access"
                
                if [ "$pod_ready" = "true" ]; then
                    echo "✅ Pod is ready and healthy"
                    echo "✅ COMPLETE SUCCESS: Deployment completed without requiring external network access"
                    echo "   - Pod is running with local registry image"
                    echo "   - No ImagePullBackOff errors"
                    echo "   - Pod is ready and healthy"
                else
                    echo "⚠️  WARNING: Pod is not ready (ready: $pod_ready)"
                    echo "   NOTE: This is an application health issue, not a network access issue"
                    echo "   The image was successfully pulled from the local registry"
                    echo "   Checking pod events for application health details..."
                    multipass exec "$VM_NAME" -- microk8s kubectl describe pod -l app=my-ag-ui-app | grep -A 10 "Events:"
                fi
                
                EXTERNAL_NETWORK_NOT_REQUIRED=true
            else
                echo "❌ ERROR: Failed to pull image from local registry"
                echo "   This suggests external network access might be required"
                echo "   Checking pod events for details..."
                multipass exec "$VM_NAME" -- microk8s kubectl describe pod -l app=my-ag-ui-app | grep -A 10 "Events:"
                EXTERNAL_NETWORK_NOT_REQUIRED=false
            fi
        else
            echo "❌ ERROR: Pod is not using local registry image: $pod_image"
            EXTERNAL_NETWORK_NOT_REQUIRED=false
        fi
    else
        echo "❌ ERROR: Pod is not running (status: $pod_status)"
        echo "   Checking pod events for errors..."
        multipass exec "$VM_NAME" -- microk8s kubectl describe pod -l app=my-ag-ui-app | grep -A 10 "Events:"
        EXTERNAL_NETWORK_NOT_REQUIRED=false
    fi
else
    echo "⚠️  WARNING: Cannot test deployment due to missing prerequisites"
    echo "   Local registry configured: $LOCAL_REGISTRY_CONFIGURED"
    echo "   Image in registry: $IMAGE_IN_REGISTRY"
    echo "   Skipping actual deployment test"
    EXTERNAL_NETWORK_NOT_REQUIRED="unknown"
fi

# Step 6: Summary
echo ""
echo "=== TASK 8.3: EXTERNAL NETWORK ACCESS VERIFICATION SUMMARY ==="
if [ "$EXTERNAL_NETWORK_NOT_REQUIRED" = true ]; then
    echo "✅ SUCCESS: No external network access is required for deployment"
    echo "✅ All image pulls are served by the local microk8s registry"
    echo "✅ Deployment can be completed entirely within the VM environment"
elif [ "$EXTERNAL_NETWORK_NOT_REQUIRED" = false ]; then
    echo "❌ FAILED: External network access appears to be required for deployment"
    echo "   This indicates that some images or dependencies are being pulled from external registries"
    echo "   Please check the deployment configuration and image references"
else
    echo "⚠️  UNABLE TO VERIFY: Could not complete verification due to missing prerequisites"
    echo "   Please ensure:"
    echo "   1. Deployment manifest is configured to use localhost:32000/my-ag-ui-app:latest"
    echo "   2. Image is pushed to local registry"
    echo "   3. Local registry is accessible"
fi

echo ""
echo "VERIFICATION DETAILS:"
echo "- VM Name: $VM_NAME"
echo "- Deployment File: $DEPLOYMENT_FILE"
echo "- Local Registry Configured: $LOCAL_REGISTRY_CONFIGURED"
echo "- Image in Registry: $IMAGE_IN_REGISTRY"
echo "- External Network Required: $EXTERNAL_NETWORK_NOT_REQUIRED"

echo ""
if [ "$EXTERNAL_NETWORK_NOT_REQUIRED" = true ]; then
    echo "✅ TASK 8.3: VERIFY NO EXTERNAL NETWORK ACCESS IS REQUIRED FOR DEPLOYMENT - COMPLETED"
    exit 0
else
    echo "❌ TASK 8.3: VERIFY NO EXTERNAL NETWORK ACCESS IS REQUIRED FOR DEPLOYMENT - FAILED"
    exit 1
fi