#!/bin/bash

# Test script for Docker build verification
# This script tests the Docker build process locally

echo "Starting Docker build test..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker before running this test."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running. Please start Docker before running this test."
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
if docker build -t my-ag-ui-app:test .; then
    echo "SUCCESS: Docker image built successfully"
else
    echo "ERROR: Failed to build Docker image"
    exit 1
fi

# Verify the image was created
if docker images | grep -q "my-ag-ui-app.*test"; then
    echo "SUCCESS: Docker image verified in local registry"
else
    echo "ERROR: Docker image not found in local registry"
    exit 1
fi

# Check image size
IMAGE_SIZE=$(docker images my-ag-ui-app:test --format "{{.Size}}")
echo "Docker image size: $IMAGE_SIZE"

# Test container execution and HTTP response
echo "Testing container execution and HTTP response..."
CONTAINER_NAME="my-ag-ui-app-test-$$"

# Run container in background
docker run -d --name $CONTAINER_NAME -p 3000:3000 my-ag-ui-app:test

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 10

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "ERROR: Container failed to start"
    docker logs $CONTAINER_NAME 2>/dev/null || true
    docker rm -f $CONTAINER_NAME 2>/dev/null || true
    exit 1
fi

# Test HTTP response on port 3000
echo "Testing HTTP response on port 3000..."
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    echo "SUCCESS: Container responds to HTTP requests on port 3000"
else
    echo "ERROR: Container is not responding to HTTP requests on port 3000"
    echo "Container logs:"
    docker logs $CONTAINER_NAME
    docker rm -f $CONTAINER_NAME
    exit 1
fi

# Test health check endpoint
echo "Testing health check endpoint..."
if curl -f -s http://localhost:3000/ > /dev/null 2>&1; then
    echo "SUCCESS: Health check endpoint is responding"
else
    echo "WARNING: Health check endpoint is not responding (this may be expected)"
fi

# Clean up container
echo "Cleaning up test container..."
docker stop $CONTAINER_NAME >/dev/null 2>&1
docker rm $CONTAINER_NAME >/dev/null 2>&1

echo "Docker build test completed successfully!"