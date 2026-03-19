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

echo "Docker build test completed successfully!"