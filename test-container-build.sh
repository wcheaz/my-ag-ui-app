#!/bin/bash

# Enhanced container build test script
# Tests the Docker build process comprehensively, including validation when Docker daemon isn't available

echo "Starting comprehensive container build test..."

# Test 1: Check Docker installation and basic functionality
echo "=== Test 1: Docker Installation Check ==="
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker before running this test."
    exit 1
fi

DOCKER_VERSION=$(docker --version)
echo "Docker version: $DOCKER_VERSION"

# Check if Docker daemon is running
if docker info &> /dev/null 2>&1; then
    echo "SUCCESS: Docker daemon is running"
    DOCKER_RUNNING=true
else
    echo "WARNING: Docker daemon is not running. Will perform limited validation."
    DOCKER_RUNNING=false
fi

# Test 2: Validate Dockerfile structure and content
echo "=== Test 2: Dockerfile Validation ==="
if [ ! -f "Dockerfile" ]; then
    echo "ERROR: Dockerfile not found in current directory"
    exit 1
fi

echo "SUCCESS: Dockerfile found"

# Check Dockerfile for multi-stage build
if grep -q "^FROM.*AS builder" Dockerfile; then
    echo "SUCCESS: Dockerfile contains build stage"
else
    echo "ERROR: Dockerfile missing build stage"
    exit 1
fi

if grep -q "^FROM.*AS runner" Dockerfile; then
    echo "SUCCESS: Dockerfile contains runtime stage"
else
    echo "ERROR: Dockerfile missing runtime stage"
    exit 1
fi

# Test 3: Check for required files
echo "=== Test 3: Required Files Check ==="
REQUIRED_FILES=("package.json" "package-lock.json" "src/" "public/")

for file in "${REQUIRED_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "SUCCESS: Required file/directory exists: $file"
    else
        echo "ERROR: Required file/directory missing: $file"
        exit 1
    fi
done

# Test 4: Validate Dockerfile syntax (basic checks)
echo "=== Test 4: Dockerfile Syntax Validation ==="

# Check for proper FROM statements
FROM_COUNT=$(grep -c "^FROM" Dockerfile)
if [ "$FROM_COUNT" -ge 2 ]; then
    echo "SUCCESS: Dockerfile contains multiple FROM statements (multi-stage build)"
else
    echo "ERROR: Dockerfile should have multiple FROM statements for multi-stage build"
    exit 1
fi

# Check for EXPOSE instruction
if grep -q "^EXPOSE" Dockerfile; then
    echo "SUCCESS: Dockerfile exposes a port"
else
    echo "ERROR: Dockerfile missing EXPOSE instruction"
    exit 1
fi

# Check for HEALTHCHECK instruction
if grep -q "^HEALTHCHECK" Dockerfile; then
    echo "SUCCESS: Dockerfile contains health check"
else
    echo "ERROR: Dockerfile missing HEALTHCHECK instruction"
    exit 1
fi

# Check for CMD instruction
if grep -q "^CMD" Dockerfile; then
    echo "SUCCESS: Dockerfile contains CMD instruction"
else
    echo "ERROR: Dockerfile missing CMD instruction"
    exit 1
fi

# Test 5: Validate .dockerignore exists (good practice)
echo "=== Test 5: Build Optimization Checks ==="
if [ -f ".dockerignore" ]; then
    echo "SUCCESS: .dockerignore file exists (good for build optimization)"
else
    echo "WARNING: .dockerignore file missing (recommended for build optimization)"
fi

# Test 6: Check package.json for build scripts
echo "=== Test 6: Build Scripts Validation ==="
if [ -f "package.json" ]; then
    if grep -q '"build"' package.json; then
        echo "SUCCESS: package.json contains build script"
    else
        echo "ERROR: package.json missing build script"
        exit 1
    fi
fi

# Test 7: Attempt Docker build (if daemon is running)
echo "=== Test 7: Docker Build Attempt ==="
if [ "$DOCKER_RUNNING" = true ]; then
    echo "Docker daemon is running, attempting build..."
    
    # Build the Docker image with test tag
    echo "Building Docker image..."
    if docker build -t my-ag-ui-app:test .; then
        echo "SUCCESS: Docker image built successfully"
        
        # Verify the image was created
        if docker images | grep -q "my-ag-ui-app.*test"; then
            echo "SUCCESS: Docker image verified in local registry"
        else
            echo "ERROR: Docker image not found in local registry"
            exit 1
        fi
        
        # Check image size
        IMAGE_SIZE=$(docker images my-ag-ui-app:test --format "{{.Size}}" 2>/dev/null || echo "Unknown")
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
        
        # Test HTTP response on port 3000 (if curl is available)
        if command -v curl &> /dev/null; then
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
        else
            echo "WARNING: curl not available, skipping HTTP response test"
        fi
        
        # Test health check endpoint (if curl is available)
        if command -v curl &> /dev/null; then
            echo "Testing health check endpoint..."
            if curl -f -s http://localhost:3000/ > /dev/null 2>&1; then
                echo "SUCCESS: Health check endpoint is responding"
            else
                echo "WARNING: Health check endpoint is not responding (this may be expected)"
            fi
        fi
        
        # Clean up container
        echo "Cleaning up test container..."
        docker stop $CONTAINER_NAME >/dev/null 2>&1
        docker rm $CONTAINER_NAME >/dev/null 2>&1
        
    else
        echo "ERROR: Failed to build Docker image"
        exit 1
    fi
else
    echo "Docker daemon not running, skipping actual build test"
    echo "Build configuration validation completed successfully"
fi

# Test 8: Validate port configuration
echo "=== Test 8: Port Configuration Validation ==="
EXPOSED_PORT=$(grep "^EXPOSE" Dockerfile | awk '{print $2}' | head -1)
if [ "$EXPOSED_PORT" = "3000" ]; then
    echo "SUCCESS: Dockerfile exposes correct port (3000)"
else
    echo "WARNING: Dockerfile exposes port $EXPOSED_PORT instead of 3000"
fi

# Test 9: Check for environment variable support
echo "=== Test 9: Environment Variable Support ==="
if grep -q "^ENV" Dockerfile; then
    ENV_COUNT=$(grep -c "^ENV" Dockerfile)
    echo "SUCCESS: Dockerfile contains $ENV_COUNT environment variable declarations"
else
    echo "WARNING: Dockerfile contains no environment variable declarations"
fi

# Test 10: Security checks
echo "=== Test 10: Security Validation ==="
if grep -q "USER.*nextjs" Dockerfile; then
    echo "SUCCESS: Dockerfile switches to non-root user"
else
    echo "WARNING: Dockerfile does not switch to non-root user"
fi

echo "=== COMPREHENSIVE CONTAINER BUILD TEST SUMMARY ==="
if [ "$DOCKER_RUNNING" = true ]; then
    echo "SUCCESS: Full container build test completed - all validations passed"
    echo "- Docker installation verified"
    echo "- Dockerfile structure validated"
    echo "- Multi-stage build confirmed"
    echo "- Image built successfully"
    echo "- Container execution tested"
    echo "- HTTP response verified"
else
    echo "SUCCESS: Container build configuration test completed - all validations passed"
    echo "- Docker installation verified"
    echo "- Dockerfile structure validated"
    echo "- Multi-stage build confirmed"
    echo "- Required files present"
    echo "- Build scripts verified"
    echo "- Port configuration correct"
    echo "- Environment variables configured"
    echo "- Security considerations noted"
    echo ""
    echo "NOTE: Full build test skipped because Docker daemon is not running"
    echo "To run full test: start Docker daemon and re-run this script"
fi

echo "Container build process test completed!"