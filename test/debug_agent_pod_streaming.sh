#!/bin/bash

# Script to check agent pod logs and resource usage during a streaming request

set -e

# Get agent pod name
AGENT_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=agent -o jsonpath='{.items[0].metadata.name}')

echo "=== Agent Pod Streaming Analysis ==="
echo "Agent Pod: $AGENT_POD"
echo ""

# Create a temporary file to capture logs
LOG_FILE="/tmp/agent_logs_$(date +%s).txt"

# Start tailing agent logs in background
echo "Starting to tail agent logs..."
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -f "$AGENT_POD" > "$LOG_FILE" &
TAIL_PID=$!

# Function to cleanup on exit
cleanup() {
    kill $TAIL_PID 2>/dev/null || true
    if [ -f "$LOG_FILE" ]; then
        echo "Logs saved to: $LOG_FILE"
    fi
}

trap cleanup EXIT

# Get initial resource usage and pod info
echo "=== Initial Agent Pod Status ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod "$AGENT_POD" | grep -A 5 -B 5 -E "(State|Restart|OOM|Memory|CPU)"
echo ""

echo "=== Initial Resource Usage ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pod "$AGENT_POD" 2>/dev/null || echo "Metrics server not available or pod metrics not ready"
echo ""

echo "=== INSTRUCTIONS ==="
echo "1. Open your browser and go to http://my-ag-ui-app.local/"
echo "2. Submit a procurement request (describe something you need)"
echo "3. Wait for the request to complete (or fail)"
echo "4. Press Enter when the request is done to continue..."
read -p ""

# Stop tailing
echo "Stopping log tailing..."
kill $TAIL_PID 2>/dev/null || true
wait $TAIL_PID 2>/dev/null || true

# Get final resource usage and pod info
echo ""
echo "=== Final Agent Pod Status ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod "$AGENT_POD" | grep -A 5 -B 5 -E "(State|Restart|OOM|Memory|CPU)"
echo ""

echo "=== Final Resource Usage ==="
multipass exec my-ag-ui-app-k8s -- microk8s kubectl top pod "$AGENT_POD" 2>/dev/null || echo "Metrics server not available or pod metrics not ready"
echo ""

# Get recent logs (last 50 lines)
echo "=== Recent Agent Pod Logs ==="
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
echo "To see the full logs: cat $LOG_FILE"