#!/bin/bash

# Test script for ingress controller verification function
# This script tests the logic of the verify_ingress_controller function

set -e

# Source the deployment script to get the function
source ./deploy.sh

# Mock the multipass and microk8s commands for testing
mock_multipass_exec() {
    local vm_name="$1"
    shift
    local command="$@"
    
    # Mock different commands
    case "$command" in
        "microk8s status --wait"*)
            echo "microk8s is running"
            return 0
            ;;
        "microk8s status"*)
            echo "dns: enabled"
            echo "storage: enabled" 
            echo "ingress: enabled"
            echo "metrics-server: disabled"
            return 0
            ;;
        "microk8s kubectl get pods -n ingress"*)
            echo "NAME                                        READY   STATUS    RESTARTS   AGE"
            echo "nginx-ingress-microk8s-controller-xxxxx   1/1     Running   0          5m"
            return 0
            ;;
        "microk8s kubectl get service -n ingress"*)
            echo "NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE"
            echo "ingress-nginx-controller     NodePort   10.152.183.1   <none>        80:31234/TCP,443:32456/TCP   5m"
            return 0
            ;;
        "microk8s kubectl get deployment -n ingress"*)
            echo "NAME                       READY   UP-TO-DATE   AVAILABLE   AGE"
            echo "nginx-ingress-controller   1/1     1            1           5m"
            return 0
            ;;
        "microk8s kubectl get ingressclass"*)
            echo "NAME    CONTROLLER             PARAMETERS"
            echo "nginx   k8s.io/ingress-nginx   <none>"
            return 0
            ;;
        *)
            echo "Mocked command: $command"
            return 0
            ;;
    esac
}

# Override the actual multipass exec function
multipass() {
    if [ "$1" = "exec" ]; then
        mock_multipass_exec "$2" "${@:3}"
        return $?
    fi
    echo "Mocked multipass: $@"
    return 0
}

# Test the ingress controller verification function
echo "Testing ingress controller verification function..."

# Set VM_NAME for testing
VM_NAME="test-vm"

# Test the function
echo "Running verify_ingress_controller function..."
if verify_ingress_controller; then
    echo "SUCCESS: verify_ingress_controller function completed without errors"
else
    echo "FAILURE: verify_ingress_controller function failed"
    exit 1
fi

echo "All tests passed! The ingress controller verification function is working correctly."