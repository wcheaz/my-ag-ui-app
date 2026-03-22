#!/bin/bash

# Test script for YAML file path fixes
# This script tests just the file copying and Kubernetes deployment parts

set -e

# Configuration
VM_NAME="my-ag-ui-app-k8s"
K8S_DIR="/home/ncheaz/git/my-ag-ui-app/openspec/changes/containerize-kubernetes-multipass-microk8s/k8s"

echo "=== TESTING YAML FILE PATH FIXES ==="
echo "VM Name: $VM_NAME"
echo "K8S Directory: $K8S_DIR"

# 1. Create k8s directory inside VM
echo "Step 1: Creating k8s directory inside VM..."
if ! multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/k8s; then
    echo "ERROR: Failed to create k8s directory inside VM"
    exit 1
fi
echo "SUCCESS: k8s directory created inside VM"

# 2. Verify directory was created
echo "Step 2: Verifying k8s directory exists in VM..."
if ! multipass exec "$VM_NAME" -- test -d /home/ubuntu/k8s; then
    echo "ERROR: k8s directory was not created in VM"
    exit 1
fi
echo "SUCCESS: k8s directory verified in VM"

# 3. Copy secrets.yaml to VM
echo "Step 3: Copying secrets.yaml to VM..."
if [ -f "$K8S_DIR/secrets.yaml" ]; then
    if ! multipass transfer "$K8S_DIR/secrets.yaml" "$VM_NAME:/home/ubuntu/k8s/secrets.yaml"; then
        echo "ERROR: Failed to copy secrets.yaml to VM"
        exit 1
    fi
    echo "SUCCESS: secrets.yaml copied to VM"
    
    # Verify file exists in VM
    if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/secrets.yaml; then
        echo "ERROR: secrets.yaml not found in VM after copy"
        exit 1
    fi
    echo "SUCCESS: secrets.yaml verified in VM"
else
    echo "WARNING: secrets.yaml not found on host, skipping"
fi

# 4. Copy deployment.yaml to VM
echo "Step 4: Copying deployment.yaml to VM..."
if ! multipass transfer "$K8S_DIR/deployment.yaml" "$VM_NAME:/home/ubuntu/k8s/deployment.yaml"; then
    echo "ERROR: Failed to copy deployment.yaml to VM"
    exit 1
fi
echo "SUCCESS: deployment.yaml copied to VM"

# Verify file exists in VM
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/deployment.yaml; then
    echo "ERROR: deployment.yaml not found in VM after copy"
    exit 1
fi
echo "SUCCESS: deployment.yaml verified in VM"

# 5. Copy service.yaml to VM
echo "Step 5: Copying service.yaml to VM..."
if ! multipass transfer "$K8S_DIR/service.yaml" "$VM_NAME:/home/ubuntu/k8s/service.yaml"; then
    echo "ERROR: Failed to copy service.yaml to VM"
    exit 1
fi
echo "SUCCESS: service.yaml copied to VM"

# Verify file exists in VM
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/service.yaml; then
    echo "ERROR: service.yaml not found in VM after copy"
    exit 1
fi
echo "SUCCESS: service.yaml verified in VM"

# 6. Copy ingress.yaml to VM
echo "Step 6: Copying ingress.yaml to VM..."
if ! multipass transfer "$K8S_DIR/ingress.yaml" "$VM_NAME:/home/ubuntu/k8s/ingress.yaml"; then
    echo "ERROR: Failed to copy ingress.yaml to VM"
    exit 1
fi
echo "SUCCESS: ingress.yaml copied to VM"

# Verify file exists in VM
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/ingress.yaml; then
    echo "ERROR: ingress.yaml not found in VM after copy"
    exit 1
fi
echo "SUCCESS: ingress.yaml verified in VM"

# 7. List all files in VM k8s directory
echo "Step 7: Listing all files in VM k8s directory..."
multipass exec "$VM_NAME" -- ls -la /home/ubuntu/k8s/
echo "SUCCESS: Files listed in VM k8s directory"

# 8. Test applying a simple Kubernetes resource (secrets if it exists, otherwise deployment)
echo "Step 8: Testing Kubernetes resource application..."
if [ -f "$K8S_DIR/secrets.yaml" ]; then
    echo "Testing secrets.yaml application..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f /home/ubuntu/k8s/secrets.yaml --dry-run=client; then
        echo "ERROR: Failed to apply secrets.yaml (dry-run)"
        exit 1
    fi
    echo "SUCCESS: secrets.yaml can be applied (dry-run test passed)"
fi

echo "Testing deployment.yaml application..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f /home/ubuntu/k8s/deployment.yaml --dry-run=client; then
    echo "ERROR: Failed to apply deployment.yaml (dry-run)"
    exit 1
fi
echo "SUCCESS: deployment.yaml can be applied (dry-run test passed)"

echo "Testing service.yaml application..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f /home/ubuntu/k8s/service.yaml --dry-run=client; then
    echo "ERROR: Failed to apply service.yaml (dry-run)"
    exit 1
fi
echo "SUCCESS: service.yaml can be applied (dry-run test passed)"

echo "Testing ingress.yaml application..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f /home/ubuntu/k8s/ingress.yaml --dry-run=client; then
    echo "ERROR: Failed to apply ingress.yaml (dry-run)"
    exit 1
fi
echo "SUCCESS: ingress.yaml can be applied (dry-run test passed)"

echo ""
echo "=== ALL TESTS PASSED ==="
echo "YAML file path fixes are working correctly!"
echo "All files were successfully copied to the VM and can be applied to Kubernetes."

# Clean up - remove the test files from VM
echo "Cleaning up test files from VM..."
multipass exec "$VM_NAME" -- rm -rf /home/ubuntu/k8s
echo "Test files cleaned up"