#!/bin/bash

# Test script to verify agent SSE endpoint is working
# This script tests the agent SSE endpoint directly with a properly formatted request

set -e

echo "=== Agent SSE Endpoint Test ==="
echo "Testing agent SSE connectivity with proper AG-UI protocol format"
echo "Generated at: $(date)"
echo ""

# Create debug pod with curl
echo "Creating debug pod with curl..."
multipass exec my-ag-ui-app-k8s -- microk8s kubectl run debug-agent-test --image=curlimages/curl --restart=Never -- sleep 600
echo "Waiting for debug pod to be ready..."
multipass exec my-ag-ui-app-k8s -- microk8s kubectl wait --for=condition=Ready pod/debug-agent-test --timeout=60s
echo "Debug pod is ready"
echo ""

# Test with properly formatted AG-UI request
echo "Testing agent SSE endpoint with proper AG-UI format:"
echo "======================================================"

# Create a proper AG-UI request payload
cat > /tmp/test_agent_sse.json << 'EOF'
{
  "method": "agent/run",
  "params": {
    "agentId": "my_agent"
  },
  "body": {
    "threadId": "test-thread-123",
    "runId": "test-run-456",
    "state": {},
    "messages": [
      {
        "id": "msg-1",
        "role": "user",
        "content": "hello"
      }
    ],
    "tools": [],
    "context": [],
    "forwardedProps": {}
  }
}
EOF

# Test the agent SSE endpoint
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i debug-agent-test -- sh -c "
curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://agent-service:8000/ -d '\$(cat)' --max-time 30 | head -c 200
" < /tmp/test_agent_sse.json | grep -q 'event:\|data:'; then
    echo "PASS: Agent SSE endpoint is working with proper AG-UI format"
else
    echo "FAIL: Agent SSE endpoint failed with proper AG-UI format"
    # Show the actual response for debugging
    echo "Actual response:"
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i debug-agent-test -- sh -c "
    curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://agent-service:8000/ -d '\$(cat)' --max-time 30
    " < /tmp/test_agent_sse.json
fi

echo ""

# Clean up
rm -f /tmp/test_agent_sse.json
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod debug-agent-test --force
echo "Debug pod removed"
echo ""

echo "=== End of Agent SSE Test ==="