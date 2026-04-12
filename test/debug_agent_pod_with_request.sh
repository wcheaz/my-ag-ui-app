#!/bin/bash

# Script to make a test request to the agent and check logs

set -e

# Get agent pod name
AGENT_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=agent -o jsonpath='{.items[0].metadata.name}')

echo "=== Agent Pod Streaming Analysis ==="
echo "Agent Pod: $AGENT_POD"
echo ""

# Get initial resource usage and pod info
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

# Create a test request file
cat > /tmp/test_agui_request.json << 'EOF'
{
  "messages": [
    {
      "role": "user",
      "content": "I need a simple procurement plan for a basic office chair with ergonomic features"
    }
  ],
  "threadId": "test-streaming-123"
}
EOF

echo "=== Making Test Request ==="
echo "Sending request to http://my-ag-ui-app.local/api/copilotkit..."

# Make the request with a timeout and capture the response
echo "Request sent. Waiting for response..."
timeout 60 curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://my-ag-ui-app.local/api/copilotkit -d @/tmp/test_agui_request.json > /tmp/test_response.txt 2>&1 &

REQUEST_PID=$!

# Wait a bit for the request to be processed
sleep 5

# Check if the request is still running
if kill -0 $REQUEST_PID 2>/dev/null; then
    echo "Request is still being processed..."
    
    # Wait for the request to complete or timeout
    wait $REQUEST_PID
    REQUEST_STATUS=$?
    
    if [ $REQUEST_STATUS -eq 0 ]; then
        echo "Request completed successfully."
    elif [ $REQUEST_STATUS -eq 124 ]; then
        echo "Request timed out after 60 seconds."
    else
        echo "Request failed with status $REQUEST_STATUS."
    fi
else
    echo "Request already completed."
fi

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

# Show the response we got
echo ""
echo "=== Response Received ==="
if [ -f /tmp/test_response.txt ]; then
    echo "Response (first 500 chars):"
    head -c 500 /tmp/test_response.txt
    echo ""
    echo "Full response saved to: /tmp/test_response.txt"
else
    echo "No response captured."
fi

echo ""
echo "=== ANALYSIS COMPLETE ==="
echo "The agent pod logs and resource usage have been captured."

# Clean up
rm -f /tmp/test_agui_request.json