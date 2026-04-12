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

# Test 1: Agent pod health directly using Python's built-in urllib
echo "1. Testing agent pod health directly (HTTP to pod IP):"
echo "========================================================"
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i "$AGENT_POD" -- python3 -c "
import urllib.request
import urllib.error
import json
import sys
try:
    req = urllib.request.Request('http://localhost:8000/api/health')
    with urllib.request.urlopen(req, timeout=5) as response:
        if response.status == 200:
            data = json.loads(response.read().decode())
            print('Status:', response.status)
            print('Response:', data)
            print('PASS: Agent health endpoint accessible')
            sys.exit(0)
        else:
            print('FAIL: Agent health endpoint returned', response.status)
            sys.exit(1)
except Exception as e:
    print('FAIL: Agent health endpoint error:', str(e))
    sys.exit(1)
"; then
    echo "PASS: Agent pod health endpoint is accessible from within agent"
else
    echo "FAIL: Agent pod health endpoint is not accessible from within agent"
fi
echo ""

# Test 2: Agent service from frontend pod using Node.js
echo "2. Testing agent service from frontend pod:"
echo "=========================================="
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i "$FRONTEND_POD" -- node -e "
const http = require('http');
const options = {
  hostname: 'agent-service',
  port: 8000,
  path: '/api/health',
  method: 'GET',
  timeout: 5000
};
const req = http.request(options, (res) => {
  console.log('Status:', res.statusCode);
  if (res.statusCode === 200) {
    console.log('PASS: Agent service accessible from frontend');
    process.exit(0);
  } else {
    console.log('FAIL: Agent service returned non-200');
    process.exit(1);
  }
});
req.on('error', (e) => {
  console.log('FAIL: Agent service error:', e.message);
  process.exit(1);
});
req.on('timeout', () => {
  console.log('FAIL: Agent service timeout');
  req.destroy();
  process.exit(1);
});
req.end();
"; then
    echo "PASS: Agent service is accessible from frontend pod"
else
    echo "FAIL: Agent service is not accessible from frontend pod"
fi
echo ""

# Test 3: SSE stream connection to agent service (basic connectivity)
echo "3. Testing SSE stream connection to agent service:"
echo "=================================================="
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i "$FRONTEND_POD" -- node -e "
const http = require('http');
const data = JSON.stringify({
  messages: [{ role: 'user', content: 'hello' }],
  threadId: 'test-123'
});
const options = {
  hostname: 'agent-service',
  port: 8000,
  path: '/',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream',
    'Content-Length': data.length
  },
  timeout: 10000
};
const req = http.request(options, (res) => {
  console.log('Status:', res.statusCode);
  console.log('Headers:', JSON.stringify(res.headers, null, 2));
  if ([200, 422].includes(res.statusCode)) {
    // 200 or 422 means we connected (422 likely means invalid format but connection works)
    console.log('PASS: Agent SSE endpoint connected');
    process.exit(0);
  } else {
    console.log('FAIL: Agent SSE endpoint returned', res.statusCode);
    process.exit(1);
  }
});
req.on('error', (e) => {
  console.log('FAIL: Agent SSE connection error:', e.message);
  process.exit(1);
});
req.on('timeout', () => {
  console.log('FAIL: Agent SSE connection timeout');
  req.destroy();
  process.exit(1);
});
req.write(data);
req.end();
"; then
    echo "PASS: Agent SSE endpoint is connectable"
else
    echo "FAIL: Agent SSE endpoint is not connectable"
fi
echo ""

# Test 4: CopilotKit SSE connection from frontend pod
echo "4. Testing CopilotKit SSE connection from frontend pod:"
echo "======================================================"
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec -i "$FRONTEND_POD" -- node -e "
const http = require('http');
const data = JSON.stringify({
  messages: [{ role: 'user', content: 'hello' }],
  threadId: 'test-123'
});
const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/copilotkit',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream',
    'Content-Length': data.length
  },
  timeout: 10000
};
const req = http.request(options, (res) => {
  console.log('Status:', res.statusCode);
  console.log('Headers:', JSON.stringify(res.headers, null, 2));
  if ([200, 400, 422].includes(res.statusCode)) {
    // 200, 400, or 422 means we connected (errors likely mean invalid format but connection works)
    console.log('PASS: CopilotKit SSE endpoint connected');
    process.exit(0);
  } else {
    console.log('FAIL: CopilotKit SSE endpoint returned', res.statusCode);
    process.exit(1);
  }
});
req.on('error', (e) => {
  console.log('FAIL: CopilotKit SSE connection error:', e.message);
  process.exit(1);
});
req.on('timeout', () => {
  console.log('FAIL: CopilotKit SSE connection timeout');
  req.destroy();
  process.exit(1);
});
req.write(data);
req.end();
"; then
    echo "PASS: CopilotKit SSE endpoint is connectable"
else
    echo "FAIL: CopilotKit SSE endpoint is not connectable"
fi
echo ""

# Test 5: Full external path through ingress
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

if curl -s -N -H 'Content-Type: application/json' -H 'Accept: text/event-stream' -X POST http://my-ag-ui-app.local/api/copilotkit -d @/tmp/test_agui_request.json --max-time 30 -w "HTTP Status: %{http_code}\n" | head -c 200; then
    echo "PASS: Full external path through ingress is connectable"
else
    echo "FAIL: Full external path through ingress is not connectable"
fi

# Clean up
rm -f /tmp/test_agui_request.json
echo ""

echo "=== End of Diagnostic Report ==="