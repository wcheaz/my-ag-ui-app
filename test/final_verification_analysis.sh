#!/bin/bash

echo "=== Final SSE Streaming Fix Verification Analysis ==="
echo "Generated at: $(date)"
echo ""

# Check if we got any response
if [ ! -s /tmp/sse_response.txt ]; then
    echo "FAIL: No response received (empty file)"
    exit 1
fi

# Count the number of SSE events - look for both "event:" and data with event types
SSE_EVENTS=$(grep -c "^event:" /tmp/sse_response.txt 2>/dev/null || echo "0")
DATA_EVENTS=$(grep -c "^data:" /tmp/sse_response.txt 2>/dev/null || echo "0")

# Count data events with embedded event types
RUN_STARTED=$(grep -c "RUN_STARTED" /tmp/sse_response.txt 2>/dev/null || echo "0")
TEXT_EVENTS=$(grep -c "TEXT_MESSAGE" /tmp/sse_response.txt 2>/dev/null || echo "0")
TOOL_EVENTS=$(grep -c "TOOL_CALL" /tmp/sse_response.txt 2>/dev/null || echo "0")

# Trim any whitespace/newlines
SSE_EVENTS=$(echo "$SSE_EVENTS" | tr -d '[:space:]')
DATA_EVENTS=$(echo "$DATA_EVENTS" | tr -d '[:space:]')
RUN_STARTED=$(echo "$RUN_STARTED" | tr -d '[:space:]')
TEXT_EVENTS=$(echo "$TEXT_EVENTS" | tr -d '[:space:]')
TOOL_EVENTS=$(echo "$TOOL_EVENTS" | tr -d '[:space:]')

echo "Traditional SSE events (event:): $SSE_EVENTS"
echo "Data events (data:): $DATA_EVENTS"
echo "RUN_STARTED events: $RUN_STARTED"
echo "TEXT_MESSAGE events: $TEXT_EVENTS"
echo "TOOL_CALL events: $TOOL_EVENTS"

# Check for proper flow: run started, text messages, tool calls
if [ "$RUN_STARTED" -gt 0 ] && [ "$TEXT_EVENTS" -gt 0 ]; then
    echo "✅ Proper event flow detected (run started + text messages)"
    FLOW_CORRECT=true
else
    echo "⚠️  Improper event flow"
    FLOW_CORRECT=false
fi

# Check for completion - look for various completion indicators
if grep -q "event:.*complete\|event:.*done\|event:.*end\|\"type\":\"RUN_END\"\|\"type\":\"TEXT_MESSAGE_END\"" /tmp/sse_response.txt; then
    echo "✅ Completion event detected"
    COMPLETION_EVENT=true
else
    echo "⚠️  No explicit completion event detected"
    COMPLETION_EVENT=false
fi

# Check for actual procurement content (should contain procurement codes or similar)
if grep -q "procurement\|code\|specification\|NSN\|FSC\|chair\|ergonomic\|lumbar\|memory foam" /tmp/sse_response.txt; then
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

# Check for "Unsupported method" or "invalid_request" errors
if grep -q "Unsupported method\|invalid_request" /tmp/sse_response.txt; then
    echo "❌ Error: Contains 'Unsupported method' or 'invalid_request'"
    ERROR_PRESENT=true
else
    echo "✅ No 'Unsupported method' or 'invalid_request' errors detected"
    ERROR_PRESENT=false
fi

# Overall result determination
echo ""
echo "=== VERIFICATION RESULT ==="

# Use more appropriate criteria for this SSE format
if [ "$DATA_EVENTS" -gt 10 ] && [ "$FLOW_CORRECT" = true ] && [ "$PROCUREMENT_CONTENT" = true ] && [ "$SMALL_RESPONSE" = false ] && [ "$ERROR_PRESENT" = false ]; then
    echo "✅ PASS: SSE streaming fix is working correctly"
    echo "   - Multiple data events received ($DATA_EVENTS)"
    echo "   - Proper event flow detected"
    echo "   - Procurement content present"
    echo "   - Response size is adequate ($RESPONSE_SIZE bytes)"
    echo "   - No protocol errors detected"
    EXIT_CODE=0
else
    echo "❌ FAIL: SSE streaming fix needs further investigation"
    
    if [ "$DATA_EVENTS" -le 10 ]; then
        echo "   - Issue: Too few data events ($DATA_EVENTS)"
    fi
    
    if [ "$FLOW_CORRECT" = false ]; then
        echo "   - Issue: Improper event flow"
    fi
    
    if [ "$PROCUREMENT_CONTENT" = false ]; then
        echo "   - Issue: No procurement content in response"
    fi
    
    if [ "$SMALL_RESPONSE" = true ]; then
        echo "   - Issue: Response too small ($RESPONSE_SIZE bytes)"
    fi
    
    if [ "$ERROR_PRESENT" = true ]; then
        echo "   - Issue: Contains 'Unsupported method' or 'invalid_request' errors"
    fi
    
    EXIT_CODE=1
fi

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

exit $EXIT_CODE
