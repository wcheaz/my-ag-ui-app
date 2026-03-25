#!/bin/bash

# Test script to verify application responds to HTTP requests
# This is for task 5.5: Verify application responds to HTTP requests

echo "=== TASK 5.5: VERIFY APPLICATION RESPONDS TO HTTP REQUESTS ==="
echo "Testing application HTTP responsiveness..."

# Set default values
APP_PORT=8000
MAX_RETRIES=10
RETRY_DELAY=3
HEALTH_ENDPOINT="/"

# Check if npm is available
echo "Step 1: Checking npm availability..."
if ! command -v npm >/dev/null 2>&1; then
    echo "❌ ERROR: npm is not available"
    echo "RECOVERY: Install Node.js and npm"
    exit 1
fi
echo "✅ npm is available"

# Check if package.json exists
echo "Step 2: Checking package.json..."
if [ ! -f "package.json" ]; then
    echo "❌ ERROR: package.json does not exist"
    echo "RECOVERY: Ensure you are in the correct project directory"
    exit 1
fi
echo "✅ package.json exists"

# Start the application in background
echo "Step 3: Starting application locally..."
echo "Port: $APP_PORT"
echo "This will start the application and test HTTP responsiveness..."

# Start application in background
npm run dev > app_test.log 2>&1 &
APP_PID=$!
echo "Application started with PID: $APP_PID"
echo "Log file: app_test.log"

# Wait for application to initialize
echo "Step 4: Waiting for application to initialize..."
sleep 10

# Test HTTP requests
echo "Step 5: Testing HTTP requests..."
echo "Testing URL: http://localhost:$APP_PORT$HEALTH_ENDPOINT"

attempt=1
http_test_passed=false

while [ $attempt -le $MAX_RETRIES ]; do
    echo "HTTP test attempt $attempt/$MAX_RETRIES..."
    
    # Test HTTP request
    if curl -s -f "http://localhost:$APP_PORT$HEALTH_ENDPOINT" >/dev/null 2>&1; then
        echo "✅ SUCCESS: Application responds to HTTP requests"
        
        # Get additional response information
        echo ""
        echo "=== HTTP RESPONSE DETAILS ==="
        echo "URL: http://localhost:$APP_PORT$HEALTH_ENDPOINT"
        echo "Test Command: curl -s http://localhost:$APP_PORT$HEALTH_ENDPOINT"
        
        # Show response headers
        echo ""
        echo "=== RESPONSE HEADERS ==="
        curl -s -I "http://localhost:$APP_PORT$HEALTH_ENDPOINT" | head -10
        
        # Show response body (first few lines)
        echo ""
        echo "=== RESPONSE BODY (first 200 chars) ==="
        curl -s "http://localhost:$APP_PORT$HEALTH_ENDPOINT" | head -c 200
        
        http_test_passed=true
        break
    fi
    
    echo "HTTP test attempt $attempt failed, waiting $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
    attempt=$((attempt + 1))
done

# Clean up
echo ""
echo "Step 6: Cleaning up..."
if kill -0 $APP_PID 2>/dev/null; then
    echo "Stopping application (PID: $APP_PID)..."
    kill $APP_PID 2>/dev/null
    # Wait a moment for graceful shutdown
    sleep 3
    # Force kill if still running
    if kill -0 $APP_PID 2>/dev/null; then
        echo "Force killing application..."
        kill -9 $APP_PID 2>/dev/null
    fi
fi

# Clean up any processes on port 8000
echo "Cleaning up any remaining processes on port $APP_PORT..."
fuser -k $APP_PORT/tcp 2>/dev/null || true

# Final result
if [ "$http_test_passed" = true ]; then
    echo ""
    echo "✅ TASK 5.5: VERIFY APPLICATION RESPONDS TO HTTP REQUESTS - COMPLETED"
    echo "   Application successfully responds to HTTP requests"
    echo "   HTTP accessibility: VERIFIED and WORKING"
    echo "   Local deployment: CONFIRMED functional"
    
    exit 0
else
    echo ""
    echo "❌ ERROR: Application does not respond to HTTP requests after $MAX_RETRIES attempts"
    echo ""
    echo "TROUBLESHOOTING STEPS:"
    echo "1. Check application logs: cat app_test.log"
    echo "2. Verify port $APP_PORT is available: netstat -tlnp | grep $APP_PORT"
    echo "3. Check if application started correctly: ps aux | grep -v grep | grep node"
    echo "4. Test manual startup: npm run dev"
    echo "5. Check Node.js dependencies: npm install"
    
    exit 1
fi