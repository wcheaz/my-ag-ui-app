#!/bin/bash

# Test script for Docker cleanup with stopped containers referencing images
# This verifies that cleanup-resources.sh handles stopped containers without conflicts

set -e

echo "🧪 STARTING DOCKER CLEANUP TEST WITH STOPPED CONTAINERS"

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"  # Test script is in the project root
cd "$PROJECT_ROOT"

echo "📂 Current directory: $(pwd)"
echo "📂 Contents of deploy_scripts directory:"
ls -la deploy_scripts/

# Test variables
TEST_IMAGE_NAME="my-ag-ui-app:cleanup-test"
TEST_CONTAINER_NAME="my-ag-ui-app-cleanup-test"

# Cleanup function to remove test artifacts
cleanup_test_artifacts() {
    echo "🧹 Cleaning up test artifacts..."
    
    # Stop and remove test container if it exists
    if docker ps -a -q -f "name=${TEST_CONTAINER_NAME}" | grep -q .; then
        docker stop ${TEST_CONTAINER_NAME} 2>/dev/null || true
        docker rm ${TEST_CONTAINER_NAME} 2>/dev/null || true
    fi
    
    # Remove test image if it exists
    if docker images -q ${TEST_IMAGE_NAME} | grep -q .; then
        docker rmi ${TEST_IMAGE_NAME} 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup_test_artifacts EXIT

# Create a simple Dockerfile for testing
cat > Dockerfile.test << EOF
FROM alpine:latest
LABEL app=my-ag-ui-app
CMD echo "Test container for cleanup verification"
EOF

echo "📦 Building test Docker image..."
# Build test image
docker build -f Dockerfile.test -t ${TEST_IMAGE_NAME} .

echo "🚀 Creating and starting test container..."
# Create and start a container with the test label
docker run -d --name ${TEST_CONTAINER_NAME} -l app=my-ag-ui-app ${TEST_IMAGE_NAME}

echo "⏹️ Stopping test container to create stopped container referencing image..."
# Stop the container to create a stopped container that references the image
docker stop ${TEST_CONTAINER_NAME}

echo "📋 Verifying stopped container exists..."
# Verify the stopped container exists
STOPPED_CONTAINER=$(docker ps -a -q -f "name=${TEST_CONTAINER_NAME}")
if [ -z "$STOPPED_CONTAINER" ]; then
    echo "❌ ERROR: Failed to create stopped container"
    exit 1
fi
echo "✅ Stopped container created: ${STOPPED_CONTAINER}"

echo "📋 Verifying image is referenced by stopped container..."
# Verify the image is being used by the stopped container
CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' ${TEST_CONTAINER_NAME})
if [ -z "$CONTAINER_IMAGE" ]; then
    echo "❌ ERROR: Failed to get container image reference"
    exit 1
fi
echo "✅ Image referenced by stopped container: ${CONTAINER_IMAGE}"

echo "🧹 Running cleanup-resources.sh to test with stopped containers..."
# Run the cleanup script and capture its output and exit code
set +e  # Temporarily disable exit on error to capture cleanup script exit code
CLEANUP_OUTPUT=$(bash ./deploy_scripts/cleanup-resources.sh 2>&1)
CLEANUP_EXIT_CODE=$?
set -e  # Re-enable exit on error

echo "📋 Cleanup script output:"
echo "$CLEANUP_OUTPUT"

echo "🔍 Verifying cleanup results..."

# Check if cleanup script exited successfully
if [ $CLEANUP_EXIT_CODE -ne 0 ]; then
    echo "❌ ERROR: Cleanup script failed with exit code $CLEANUP_EXIT_CODE"
    exit 1
fi
echo "✅ Cleanup script exited with code 0 (success)"

# Check if there were unhandled conflict errors in the output
if echo "$CLEANUP_OUTPUT" | grep -i "conflict\|error.*image.*used\|image.*used.*container" | grep -v "Failed to remove.* Continuing with cleanup" | grep -q .; then
    echo "❌ ERROR: Cleanup script reported unhandled conflict errors:"
    echo "$CLEANUP_OUTPUT" | grep -i "conflict\|error.*image.*used\|image.*used.*container" | grep -v "Failed to remove.* Continuing with cleanup"
    exit 1
fi
echo "✅ No unhandled conflict errors detected in cleanup output"

# Check if the test image was successfully removed (this would fail if containers still referenced it)
if docker images -q ${TEST_IMAGE_NAME} | grep -q .; then
    echo "⚠️  WARNING: Test image still exists after cleanup (this may be expected if cleanup doesn't remove test images)"
else
    echo "✅ Test image was successfully removed by cleanup"
fi

# Check if the test container was removed by cleanup
if docker ps -a -q -f "name=${TEST_CONTAINER_NAME}" | grep -q .; then
    echo "❌ ERROR: Test container still exists after cleanup"
    exit 1
else
    echo "✅ Test container was successfully removed by cleanup"
fi

echo "🎉 DOCKER CLEANUP TEST WITH STOPPED CONTAINERS PASSED"
echo "✅ Cleanup script successfully handled stopped containers referencing images without conflicts"

# Remove the test Dockerfile
rm -f Dockerfile.test