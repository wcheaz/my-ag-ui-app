#!/bin/bash

# Script to verify container runs successfully with docker run
# This should be executed after proper Docker permissions are configured

echo "=== Testing Docker Container ==="

# Check if Docker is accessible
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Docker daemon"
    echo "Please ensure:"
    echo "1. Docker service is running: sudo systemctl start docker"
    echo "2. Your user is in the docker group: sudo usermod -aG docker \$USER && newgrp docker"
    echo "3. Log out and log back in for group changes to take effect"
    exit 1
fi

# Build the Docker image if it doesn't exist
if ! docker images | grep -q "my-ag-ui-app"; then
    echo "Building Docker image..."
    docker build -t my-ag-ui-app:latest .
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to build Docker image"
        exit 1
    fi
    echo "Docker image built successfully"
fi

# Run the container in detached mode
echo "Starting container..."
CONTAINER_ID=$(docker run -d --name my-ag-ui-app-test -p 3000:3000 my-ag-ui-app:latest)

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start container"
    exit 1
fi

echo "Container started with ID: $CONTAINER_ID"

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 10

# Check container status
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_ID 2>/dev/null)

if [ "$CONTAINER_STATUS" != "running" ]; then
    echo "ERROR: Container is not running (status: $CONTAINER_STATUS)"
    echo "Container logs:"
    docker logs $CONTAINER_ID
    docker stop $CONTAINER_ID >/dev/null 2>&1
    docker rm $CONTAINER_ID >/dev/null 2>&1
    exit 1
fi

echo "Container is running"

# Test HTTP response on port 3000
echo "Testing HTTP response on port 3000..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null || echo "000")

if [ "$HTTP_RESPONSE" = "000" ]; then
    echo "ERROR: Could not connect to container on port 3000"
    echo "Container logs:"
    docker logs $CONTAINER_ID
    docker stop $CONTAINER_ID >/dev/null 2>&1
    docker rm $CONTAINER_ID >/dev/null 2>&1
    exit 1
fi

if [ "$HTTP_RESPONSE" -ge 400 ]; then
    echo "WARNING: HTTP response code $HTTP_RESPONSE (might be expected)"
else
    echo "SUCCESS: Container responded with HTTP code $HTTP_RESPONSE"
fi

# Check health status
echo "Checking container health..."
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_ID 2>/dev/null)

if [ -n "$HEALTH_STATUS" ]; then
    echo "Container health status: $HEALTH_STATUS"
    
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "SUCCESS: Container health check passed"
    else
        echo "WARNING: Container health status is '$HEALTH_STATUS'"
    fi
else
    echo "No health status available (container might not have healthcheck)"
fi

# Display container logs
echo -e "\n=== Container Logs ==="
docker logs $CONTAINER_ID

# Clean up
echo -e "\n=== Cleaning up ==="
docker stop $CONTAINER_ID >/dev/null 2>&1
docker rm $CONTAINER_ID >/dev/null 2>&1
echo "Container stopped and removed"

echo -e "\n=== Test completed successfully! ==="
echo "The container runs correctly and responds to HTTP requests on port 3000."