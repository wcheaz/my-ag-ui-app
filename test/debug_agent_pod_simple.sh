#!/bin/bash

# Script to check agent pod logs and resource usage during a streaming request
# This version doesn't require exec into containers

set -e

# Get agent pod name
AGENT_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=agent -o jsonpath='{.items[0].metadata.name}')

echo "=== Agent Pod Streaming Analysis ==="
echo "Agent Pod: $AGENT_POD"
echo ""

# Get current resource usage and pod info
echo "=== Initial Agent Pod Status ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod "$AGENT_POD" | grep -A 5 -B 5 -E "(State|Restart|OOM|Memory|CPU)"
echo ""

echo "=== Initial Resource Usage ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pod "$AGENT_POD" 2>/dev/null || echo "Metrics server not available or pod metrics not ready"
echo ""

# Get recent logs (last 20 lines)
echo "=== Recent Agent Pod Logs (Before Request) ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs "$AGENT_POD" --tail=20
echo ""

echo "=== INSTRUCTIONS ==="
echo "1. Open your browser and go to http://my-ag-ui-app.local/"
echo "2. Submit a procurement request (describe something you need)"
echo "3. Wait for the request to complete (or fail)"
echo "4. Press Enter when the request is done to continue..."
read -p ""

# Get final resource usage and pod info
echo ""
echo "=== Final Agent Pod Status ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod "$AGENT_POD" | grep -A 5 -B 5 -E "(State|Restart|OOM|Memory|CPU)"
echo ""

echo "=== Final Resource Usage ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pod "$AGENT_POD" 2>/dev/null || echo "Metrics server not available or pod metrics not ready"
echo ""

# Get recent logs after the request (last 50 lines)
echo "=== Recent Agent Pod Logs (After Request) ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs "$AGENT_POD" --tail=50
echo ""

# Check if OOMKilled
echo "=== OOM Check ==="
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod "$AGENT_POD" | grep -q "OOMKilled"; then
    echo "WARNING: Agent pod was OOMKilled!"
else
    echo "Agent pod was not OOMKilled."
fi

# Check restarts
echo ""
echo "=== Restart Check ==="
RESTARTS=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pod "$AGENT_POD" -o jsonpath='{.status.containerStatuses[0].restartCount}')
echo "Agent pod has restarted $RESTARTS times."

echo ""
echo "=== ANALYSIS COMPLETE ==="
echo "The agent pod logs and resource usage have been captured."