#!/bin/bash

# Script to test SSE connectivity at each hop in the Kubernetes deployment
# This script tests 5 different hops to isolate where SSE streaming breaks

set -e

echo "=== SSE Connectivity Diagnostic Report ==="
echo "Generated at: $(date)"
echo ""

# Get pod names and IPs
AGENT_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=agent -o jsonpath='{.items[0].metadata.name}')
FRONTEND_POD=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].metadata.name}')

if [ -z "$AGENT_POD" ]; then
    echo "ERROR: Agent pod not found"
    exit 1
fi

if [ -z "$FRONTEND_POD" ]; then
    echo "ERROR: Frontend pod not found"
    exit 1
fi

AGENT_POD_IP=$(multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pod "$AGENT_POD" -o jsonpath='{.status.podIP}')

echo "Agent pod: $AGENT_POD (IP: $AGENT_POD_IP)"
echo "Frontend pod: $FRONTEND_POD"
echo ""

# Create debug pod with curl
echo "Creating debug pod with curl..."
multipass exec my-ag-ui-app-k8s -- microk8s kubectl run debug-sse --image=curlimages/curl --restart=Never -- sleep 600
echo "Waiting for debug pod to be ready..."
multipass exec my-ag-ui-app-k8s -- microk8s kubectl wait --for=condition=Ready pod/debug-sse --timeout=60s
echo "Debug pod is ready"
echo ""

# Test 1: Agent pod health directly using curl
echo "1. Testing agent pod health directly (HTTP to pod IP):"
echo "========================================================"
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i debug-sse -- curl -s "http://$AGENT_POD_IP:8000/api/health" | grep -q "ok\|healthy\|ready"; then
    echo "PASS: Agent pod health endpoint is accessible via pod IP"
else
    echo "FAIL: Agent pod health endpoint is not accessible via pod IP"
fi
echo ""

# Test 2: Agent service from frontend pod using curl
echo "2. Testing agent service from frontend pod:"
echo "=========================================="
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i debug-sse -- curl -s -N --max-time 10 "http://agent-service:8000/api/health" | grep -q "ok\|healthy\|ready"; then
    echo "PASS: Agent service is accessible from frontend pod"
else
    echo "FAIL: Agent service is not accessible from frontend pod"
fi
echo ""

# Test 3: SSE stream connection to agent service using curl
echo "3. Testing SSE stream connection to agent service:"
echo "=================================================="
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i debug-sse -- sh -c "
echo '{\"messages\": [{\"role\": \"user\", \"content\": \"hello\"}], \"threadId\": \"test-123\"}' | curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://agent-service:8000/ --max-time 10 | head -c 100 | grep -q 'event:\|data:'
"; then
    echo "PASS: Agent SSE endpoint is connectable"
else
    echo "FAIL: Agent SSE endpoint is not connectable"
fi
echo ""

# Test 4: CopilotKit SSE connection from frontend pod using curl
echo "4. Testing CopilotKit SSE connection from frontend pod:"
echo "======================================================"
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i debug-sse -- sh -c "
echo '{\"messages\": [{\"role\": \"user\", \"content\": \"hello\"}], \"threadId\": \"test-123\"}' | curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://my-ag-ui-app-service:3000/api/copilotkit --max-time 10 | head -c 100 | grep -q 'event:\|data:'
"; then
    echo "PASS: CopilotKit SSE endpoint is connectable"
else
    echo "FAIL: CopilotKit SSE endpoint is not connectable"
fi
echo ""

# Test 5: Full external path through ingress using curl
echo "5. Testing full external path through ingress:"
echo "=============================================="
# Create a test request file
cat > /tmp/test_agui_request.json << 'EOF'
{
  "messages": [
    {
      "role": "user",
      "content": "hello"
    }
  ],
  "threadId": "test-123"
}
EOF

if curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://my-ag-ui-app.local/api/copilotkit -d @/tmp/test_agui_request.json --max-time 30 | head -c 100 | grep -q 'event:\|data:'; then
    echo "PASS: Full external path through ingress is connectable"
else
    echo "FAIL: Full external path through ingress is not connectable"
fi

# Clean up
rm -f /tmp/test_agui_request.json
echo ""

# Remove debug pod
echo "Cleaning up debug pod..."
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod debug-sse --force
echo "Debug pod removed"
echo ""

echo "=== End of Diagnostic Report ==="