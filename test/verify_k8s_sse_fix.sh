#!/bin/bash

# Script to verify SSE streaming fix by submitting a real procurement request
# and validating the complete response

set -e

echo "=== SSE Streaming Fix Verification ==="
echo "Testing end-to-end SSE streaming in Kubernetes deployment"
echo "Generated at: $(date)"
echo ""

# First, test the health endpoint
echo "=== Testing Health Endpoint ==="
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://my-ag-ui-app.local/api/copilotkit)
if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "✅ Health endpoint is accessible (HTTP $HEALTH_RESPONSE)"
else
    echo "⚠️  Health endpoint returned HTTP $HEALTH_RESPONSE"
fi

# Create a CopilotKit-compatible request payload
# Based on CopilotKit protocol, we need proper structure with method field
cat > /tmp/procurement_request.json << 'EOF'
{
  "method": "text",
  "messages": [
    {
      "role": "user",
      "content": "I need a procurement plan for an ergonomic office chair with adjustable lumbar support, breathable mesh back, and memory foam cushion. The chair should be suitable for 8+ hours of daily use and support users up to 300 pounds."
    }
  ],
  "threadId": "verification-test-$(date +%s)"
}
EOF

# Test the SSE endpoint
echo "=== Testing SSE Streaming ==="
echo "Sending procurement request to http://my-ag-ui-app.local/api/copilotkit..."
echo "Request payload:"
cat /tmp/procurement_request.json
echo ""

# Use curl to receive the SSE stream with proper headers
echo "Response (SSE stream):"
echo "----------------------------------------"

# Capture the full response to a file while also displaying it
timeout 120 curl -s -N \
  -H 'Content-Type: application/json' \
  -H 'Accept: text/event-stream' \
  -X POST \
  http://my-ag-ui-app.local/api/copilotkit \
  -d @/tmp/procurement_request.json \
  -o /tmp/sse_response.txt

echo ""
echo "----------------------------------------"

# Analyze the response
echo "=== Response Analysis ==="

# Check if we got any response
if [ ! -s /tmp/sse_response.txt ]; then
    echo "FAIL: No response received (empty file)"
    exit 1
fi

# Count the number of SSE events
SSE_EVENTS=$(grep -c "^event:" /tmp/sse_response.txt 2>/dev/null || echo "0")
DATA_EVENTS=$(grep -c "^data:" /tmp/sse_response.txt 2>/dev/null || echo "0")

echo "SSE events received: $SSE_EVENTS"
echo "Data events received: $DATA_EVENTS"

# Check for terminal event (indicates completion)
if grep -q "event:.*complete\|event:.*done\|event:.*end" /tmp/sse_response.txt; then
    echo "✅ Terminal event detected (stream completed normally)"
    TERMINAL_EVENT=true
else
    echo "⚠️  No terminal event detected (stream may be incomplete)"
    TERMINAL_EVENT=false
fi

# Check for actual procurement content (should contain procurement codes or similar)
if grep -q "procurement\|code\|specification\|NSN\|FSC" /tmp/sse_response.txt; then
    echo "✅ Procurement content detected in response"
    PROCUREMENT_CONTENT=true
else
    echo "⚠️  No procurement content detected in response"
    PROCUREMENT_CONTENT=false
fi

# Check response size (should be substantial for a real procurement response)
RESPONSE_SIZE=$(wc -c < /tmp/sse_response.txt)
echo "Response size: $RESPONSE_SIZE bytes"

if [ "$RESPONSE_SIZE" -lt 500 ]; then
    echo "⚠️  Response size seems small for a complete procurement"
    SMALL_RESPONSE=true
else
    echo "✅ Response size appears adequate"
    SMALL_RESPONSE=false
fi

# Overall result determination
echo ""
echo "=== VERIFICATION RESULT ==="

if [ "$SSE_EVENTS" -gt 1 ] && [ "$DATA_EVENTS" -gt 1 ] && [ "$TERMINAL_EVENT" = true ] && [ "$PROCUREMENT_CONTENT" = true ] && [ "$SMALL_RESPONSE" = false ]; then
    echo "✅ PASS: SSE streaming fix is working correctly"
    echo "   - Multiple SSE events received"
    echo "   - Terminal event indicates complete stream"
    echo "   - Procurement content present"
    echo "   - Response size is adequate"
    EXIT_CODE=0
else
    echo "❌ FAIL: SSE streaming fix needs further investigation"
    
    if [ "$SSE_EVENTS" -le 1 ]; then
        echo "   - Issue: Too few SSE events ($SSE_EVENTS)"
    fi
    
    if [ "$DATA_EVENTS" -le 1 ]; then
        echo "   - Issue: Too few data events ($DATA_EVENTS)"
    fi
    
    if [ "$TERMINAL_EVENT" = false ]; then
        echo "   - Issue: No terminal event detected"
    fi
    
    if [ "$PROCUREMENT_CONTENT" = false ]; then
        echo "   - Issue: No procurement content in response"
    fi
    
    if [ "$SMALL_RESPONSE" = true ]; then
        echo "   - Issue: Response too small ($RESPONSE_SIZE bytes)"
    fi
    
    EXIT_CODE=1
fi

# Save detailed response for debugging
echo ""
echo "Full response saved to: /tmp/sse_response.txt"
echo "First 500 characters of response:"
head -c 500 /tmp/sse_response.txt
echo ""
if [ "$RESPONSE_SIZE" -gt 500 ]; then
    echo "..."
    echo "Last 200 characters of response:"
    tail -c 200 /tmp/sse_response.txt
fi

# Clean up
rm -f /tmp/procurement_request.json

exit $EXIT_CODE