#!/bin/bash

# Test script to verify build-docker-image.sh correctly handles failed Docker builds
# This is for task 4.3: Test build script with failed Docker build to verify correct error reporting

set -e

echo "=== Testing build script with failed Docker build ==="

# Create backup of original Dockerfile
if [ -f "Dockerfile" ]; then
    cp Dockerfile Dockerfile.backup
    echo "✅ Backed up original Dockerfile"
else
    echo "❌ Original Dockerfile not found"
    exit 1
fi

# Create a Dockerfile that will definitely fail
cat > Dockerfile << 'EOF'
FROM alpine:latest
# This command will fail - non-existent package
RUN apk add --no-cache this-package-does-not-exist-12345
CMD ["echo", "test"]
EOF

echo "✅ Created Dockerfile that will fail during build"

# Clean up any existing my-ag-ui-app:latest image to ensure clean test
if docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    docker rmi my-ag-ui-app:latest >/dev/null 2>&1 || true
    echo "✅ Cleaned up existing my-ag-ui-app:latest image"
fi

# Run the build script and capture exit code and output
echo "=== Running build script with failing Docker build ==="

# Set up environment variables for the build script
export LOG_FILE="/tmp/test-build-$(date +%Y%m%d-%H%M%S).log"
export VERBOSE=true

# Create a temporary log file to capture output
TEMP_LOG=$(mktemp)
BUILD_OUTPUT=$(./deploy_scripts/build-docker-image.sh 2>&1) || BUILD_EXIT_CODE=$?
echo "$BUILD_OUTPUT" > "$TEMP_LOG"

# Also capture the LOG_FILE content if it exists
if [ -f "$LOG_FILE" ]; then
    echo "" >> "$TEMP_LOG"
    echo "=== LOG_FILE content ===" >> "$TEMP_LOG"
    cat "$LOG_FILE" >> "$TEMP_LOG"
    rm -f "$LOG_FILE"
fi

# Check if the build script correctly failed
if [ -z "$BUILD_EXIT_CODE" ]; then
    echo "❌ FAILURE: Build script did not fail when it should have"
    echo "   Expected: non-zero exit code"
    echo "   Actual: exit code 0 (success)"
    cat "$TEMP_LOG"
    rm -f "$TEMP_LOG"
    
    # Restore original Dockerfile
    mv Dockerfile.backup Dockerfile
    exit 1
fi

echo "✅ Build script correctly failed with exit code $BUILD_EXIT_CODE"

# Check if Docker build error is visible in the output
if ! grep -q "ERROR: failed to solve" "$TEMP_LOG" && ! grep -q "this-package-does-not-exist" "$TEMP_LOG"; then
    echo "❌ FAILURE: Build script did not show Docker build error"
    echo "   Expected: Docker build error details in output"
    echo "   Actual output:"
    cat "$TEMP_LOG"
    rm -f "$TEMP_LOG"
    
    # Restore original Dockerfile
    mv Dockerfile.backup Dockerfile
    exit 1
fi

echo "✅ Build script correctly shows Docker build error details"

# Verify that no my-ag-ui-app:latest image was created
if docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    echo "❌ FAILURE: my-ag-ui-app:latest image exists when it shouldn't"
    echo "   The build failed but image was still created"
    docker images my-ag-ui-app:latest
    docker rmi my-ag-ui-app:latest >/dev/null 2>&1 || true
    rm -f "$TEMP_LOG"
    
    # Restore original Dockerfile
    mv Dockerfile.backup Dockerfile
    exit 1
fi

echo "✅ No my-ag-ui-app:latest image was created (as expected for failed build)"

# Clean up
rm -f "$TEMP_LOG"

# Restore original Dockerfile
mv Dockerfile.backup Dockerfile
echo "✅ Restored original Dockerfile"

echo ""
echo "=== TEST RESULT: SUCCESS ==="
echo "✅ Build script correctly handles failed Docker builds"
echo "   - Exits with non-zero code when Docker build fails"
echo "   - Logs appropriate error message"
echo "   - Does not create image when build fails"

exit 0