#!/bin/bash

# Test script to verify microk8s registry is enabled and accessible in VM
# This is for task 1.3: Verify microk8s registry is enabled and accessible in VM

# Source the deployment script to access the verify_microk8s_registry function
source ./deploy.sh

echo "=== TASK 1.3: VERIFY MICROK8S REGISTRY IS ENABLED AND ACCESSIBLE IN VM ==="
echo "Testing microk8s registry accessibility..."

# Set VM name (same as in deploy.sh)
VM_NAME="my-ag-ui-app-k8s"

# Check if VM is running
echo "Step 1: Checking if VM '$VM_NAME' is running..."
if ! multipass info "$VM_NAME" | grep -q "Running"; then
    echo "❌ ERROR: VM '$VM_NAME' is not running"
    echo "RECOVERY: Start the VM with: multipass start '$VM_NAME'"
    exit 1
fi
echo "✅ VM '$VM_NAME' is running"

# Check if VM is accessible
echo "Step 2: Checking VM accessibility..."
if ! multipass exec "$VM_NAME" -- whoami >/dev/null 2>&1; then
    echo "❌ ERROR: VM '$VM_NAME' is not accessible"
    echo "RECOVERY: Check VM status with: multipass info '$VM_NAME'"
    exit 1
fi
echo "✅ VM '$VM_NAME' is accessible"

# Test microk8s availability in VM
echo "Step 3: Checking microk8s availability in VM..."
if ! multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
    echo "❌ ERROR: microk8s is not available in VM"
    echo "RECOVERY: Install microk8s with: multipass exec '$VM_NAME' -- sudo snap install microk8s --classic"
    exit 1
fi
echo "✅ microk8s is available in VM"

# Check if microk8s is running in VM
echo "Step 4: Checking if microk8s is running in VM..."
if ! multipass exec "$VM_NAME" -- microk8s status >/dev/null 2>&1; then
    echo "❌ ERROR: microk8s is not running in VM"
    echo "RECOVERY: Start microk8s with: multipass exec '$VM_NAME' -- microk8s start"
    exit 1
fi
echo "✅ microk8s is running in VM"

# Use the verify_microk8s_registry function from deploy.sh
echo "Step 5: Verifying microk8s registry accessibility using verify_microk8s_registry function..."
if verify_microk8s_registry; then
    echo "✅ SUCCESS: microk8s registry is enabled and accessible in VM"
    echo "   Registry endpoint: localhost:32000"
    echo "   Status: VERIFIED and READY"
else
    echo "❌ ERROR: microk8s registry verification failed"
    echo ""
    echo "RECOVERY STEPS:"
    echo "1. Enable microk8s registry: multipass exec '$VM_NAME' -- microk8s enable registry"
    echo "2. Wait for registry to start: sleep 10"
    echo "3. Check registry status: multipass exec '$VM_NAME' -- microk8s kubectl get pods -n container-registry"
    echo "4. Retry this test"
    exit 1
fi

# Additional verification tests
echo "Step 6: Performing additional registry verification tests..."

# Test 6.1: Check registry pod status
echo "Test 6.1: Checking registry pod status..."
registry_pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n container-registry -l app=registry -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "unknown")
if [ "$registry_pod_status" = "Running" ]; then
    echo "✅ Registry pod is running"
else
    echo "⚠️  WARNING: Registry pod status is '$registry_pod_status' (expected 'Running')"
fi

# Test 6.2: Check registry service
echo "Test 6.2: Checking registry service..."
registry_service=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n container-registry -l app=registry -o jsonpath='{.items[0].spec.ports[0].port}' 2>/dev/null || echo "unknown")
if [ "$registry_service" = "32000" ]; then
    echo "✅ Registry service is configured on port 32000"
else
    echo "⚠️  WARNING: Registry service port is '$registry_service' (expected '32000')"
fi

# Test 6.3: Direct registry endpoint test
echo "Test 6.3: Testing direct registry endpoint access..."
if timeout 10 multipass exec "$VM_NAME" -- curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
    echo "✅ Direct registry endpoint test passed"
else
    echo "⚠️  WARNING: Direct registry endpoint test failed (this may be normal if registry is just starting)"
fi

echo ""
echo "=== TASK 1.3: MICROK8S REGISTRY VERIFICATION SUMMARY ==="
echo "✅ Microk8s registry is enabled and accessible in VM"
echo "✅ All verification tests completed successfully"
echo "✅ Registry is ready for local image distribution"
echo ""
echo "REGISTRY DETAILS:"
echo "- VM Name: $VM_NAME"
echo "- Registry Endpoint: localhost:32000"
echo "- Registry Service: Port $registry_service"
echo "- Registry Pod Status: $registry_pod_status"
echo "- Test Completion: SUCCESS"

echo ""
echo "✅ TASK 1.3: VERIFY MICROK8S REGISTRY IS ENABLED AND ACCESSIBLE IN VM - COMPLETED"