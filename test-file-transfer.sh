#!/bin/bash

# Test script for file transfer functionality
# This script tests the transfer of YAML files from host to VM

VM_NAME="my-ag-ui-app-k8s"

echo "=== Testing File Transfer for All Four YAML Files ==="

# 1. Test directory creation in VM
echo "1. Testing k8s directory creation in VM..."
if ! multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/k8s; then
    echo "ERROR: Failed to create k8s directory in VM"
    exit 1
fi
echo "✓ k8s directory created successfully in VM"

# 2. Test secrets.yaml transfer
echo "2. Testing secrets.yaml transfer..."
if ! multipass transfer k8s/secrets.yaml "$VM_NAME":/home/ubuntu/k8s/secrets.yaml; then
    echo "ERROR: Failed to transfer secrets.yaml to VM"
    exit 1
fi
echo "✓ secrets.yaml transferred successfully to VM"

# 3. Test deployment.yaml transfer
echo "3. Testing deployment.yaml transfer..."
if ! multipass transfer k8s/deployment.yaml "$VM_NAME":/home/ubuntu/k8s/deployment.yaml; then
    echo "ERROR: Failed to transfer deployment.yaml to VM"
    exit 1
fi
echo "✓ deployment.yaml transferred successfully to VM"

# 4. Test service.yaml transfer
echo "4. Testing service.yaml transfer..."
if ! multipass transfer k8s/service.yaml "$VM_NAME":/home/ubuntu/k8s/service.yaml; then
    echo "ERROR: Failed to transfer service.yaml to VM"
    exit 1
fi
echo "✓ service.yaml transferred successfully to VM"

# 5. Test ingress.yaml transfer
echo "5. Testing ingress.yaml transfer..."
if ! multipass transfer k8s/ingress.yaml "$VM_NAME":/home/ubuntu/k8s/ingress.yaml; then
    echo "ERROR: Failed to transfer ingress.yaml to VM"
    exit 1
fi
echo "✓ ingress.yaml transferred successfully to VM"

# 6. Validate all files exist in VM
echo "6. Validating all transferred files exist in VM..."

# Check secrets.yaml
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/secrets.yaml; then
    echo "ERROR: secrets.yaml does not exist in VM after transfer"
    exit 1
fi
echo "✓ secrets.yaml validation successful - file exists in VM"

# Check deployment.yaml
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/deployment.yaml; then
    echo "ERROR: deployment.yaml does not exist in VM after transfer"
    exit 1
fi
echo "✓ deployment.yaml validation successful - file exists in VM"

# Check service.yaml
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/service.yaml; then
    echo "ERROR: service.yaml does not exist in VM after transfer"
    exit 1
fi
echo "✓ service.yaml validation successful - file exists in VM"

# Check ingress.yaml
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/ingress.yaml; then
    echo "ERROR: ingress.yaml does not exist in VM after transfer"
    exit 1
fi
echo "✓ ingress.yaml validation successful - file exists in VM"

# 7. List all files in VM k8s directory
echo "7. Listing all files in VM k8s directory..."
multipass exec "$VM_NAME" -- ls -la /home/ubuntu/k8s/

echo "=== File Transfer Test Results ==="
echo "✓ All four YAML files (secrets.yaml, deployment.yaml, service.yaml, ingress.yaml) were successfully transferred to the VM"
echo "✓ All files were validated to exist in the VM after transfer"
echo "✓ File transfer functionality is working correctly"

echo "=== File Transfer Test Complete ==="