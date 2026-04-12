#!/bin/bash

# Script to collect current Kubernetes cluster state for SSE streaming diagnosis
# This script runs through multipass exec my-ag-ui-app-k8s to gather cluster information

set -e

echo "=== K8s Cluster State Report ==="
echo "Generated at: $(date)"
echo ""

# Get all pods
echo "1. All pods in the cluster:"
echo "================================="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -o wide
echo ""

# Get deployment descriptions
echo "2. Deployment descriptions:"
echo "================================="
echo "--- Agent deployment ---"
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe deployment agent
echo ""
echo "--- Frontend deployment ---"
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe deployment my-ag-ui-app
echo ""

# Get ingress configuration
echo "3. Ingress configuration:"
echo "================================="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get ingress -o yaml
echo ""

# Get agent pod logs
echo "4. Agent pod logs (last 50 lines):"
echo "================================="
AGENT_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=agent -o jsonpath='{.items[0].metadata.name}')
if [ -n "$AGENT_POD" ]; then
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs "$AGENT_POD" --tail=50
else
    echo "ERROR: Agent pod not found"
fi
echo ""

# Get ingress controller logs
echo "5. Ingress controller logs (last 50 lines):"
echo "================================="
INGRESS_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[0].metadata.name}')
if [ -n "$INGRESS_POD" ]; then
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -n ingress "$INGRESS_POD" --tail=50
else
    echo "ERROR: Ingress controller pod not found"
fi
echo ""

# Get agent pod description (for OOMKilled or restart events)
echo "6. Agent pod description (checking for OOMKilled/restarts):"
echo "================================="
if [ -n "$AGENT_POD" ]; then
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod "$AGENT_POD"
else
    echo "ERROR: Agent pod not found"
fi
echo ""

echo "=== End of Report ==="