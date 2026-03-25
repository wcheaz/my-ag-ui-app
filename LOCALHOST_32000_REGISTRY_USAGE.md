# Localhost:32000 Registry Endpoint Usage Guide

## Overview

This document provides detailed usage patterns and examples for working with the microk8s registry endpoint at `localhost:32000`. This guide focuses on the practical aspects of using the local registry endpoint for development and deployment workflows.

## Endpoint Basics

### Registry Endpoint
- **URL**: `http://localhost:32000`
- **Protocol**: HTTP (internal cluster access only)
- **Authentication**: None required (local cluster access)
- **Accessibility**: Only available within the multipass VM (`my-ag-ui-app-k8s`)

### Key URL Patterns
```bash
# Registry root (health check)
http://localhost:32000/v2/

# Catalog (list all repositories)
http://localhost:32000/v2/_catalog

# Tags for specific repository
http://localhost:32000/v2/my-ag-ui-app/tags/list

# Image manifests
http://localhost:32000/v2/my-ag-ui-app/manifests/latest
```

## Common Usage Patterns

### 1. Development Workflow

#### Building and Pushing Images
```bash
# Build image locally
docker build -t my-ag-ui-app:latest .

# Tag for local registry
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest

# Push to local registry
docker push localhost:32000/my-ag-ui-app:latest
```

#### Verifying Registry Contents
```bash
# Check registry catalog (should show repositories)
curl -s http://localhost:32000/v2/_catalog

# Check tags for our application
curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# Verify image exists in registry
curl -s http://localhost:32000/v2/my-ag-ui-app/manifests/latest
```

### 2. Deployment Usage

#### Kubernetes Deployment Reference
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
spec:
  template:
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest
        imagePullPolicy: IfNotPresent
```

#### Manual Deployment Commands
```bash
# Apply deployment with local registry image
kubectl apply -f k8s/deployment.yaml

# Watch pod creation and image pull
kubectl get pods -w

# Check pod events for image pull status
kubectl describe pod <pod-name> | grep -A 10 "Events"
```

### 3. Testing and Debugging

#### Registry Health Checks
```bash
# Basic registry connectivity test
curl -f http://localhost:32000/v2/ || echo "Registry not accessible"

# Complete registry health check
curl -s http://localhost:32000/v2/_catalog | jq .

# Test with specific image reference
curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list | jq .
```

#### Image Pull Testing
```bash
# Test local image pull
docker pull localhost:32000/my-ag-ui-app:latest

# Verify image exists locally
docker images | grep localhost:32000/my-ag-ui-app

# Run container from local registry image
docker run --rm -p 3000:3000 localhost:32000/my-ag-ui-app:latest
```

### 4. Automated Script Usage

#### Registry Verification in Scripts
```bash
#!/bin/bash

# Function to verify registry accessibility
verify_registry() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:32000/v2/ > /dev/null; then
            echo "Registry is accessible at localhost:32000"
            return 0
        fi
        
        echo "Waiting for registry... attempt $attempt/$max_attempts"
        sleep 2
        ((attempt++))
    done
    
    echo "ERROR: Registry not accessible at localhost:32000"
    return 1
}

# Function to verify image in registry
verify_image_in_registry() {
    local image_name="my-ag-ui-app"
    
    if curl -s "http://localhost:32000/v2/$image_name/tags/list" | grep -q "tags"; then
        echo "Image $image_name found in registry"
        return 0
    else
        echo "ERROR: Image $image_name not found in registry"
        return 1
    fi
}
```

## Error Handling Patterns

### Common Error Scenarios

#### 1. Registry Not Accessible
```bash
# Error: Connection refused
curl: (7) Failed to connect to localhost port 32000: Connection refused

# Solution: Enable microk8s registry
multipass exec my-ag-ui-app-k8s -- microk8s enable registry
```

#### 2. Image Not Found in Registry
```bash
# Error: manifest unknown
curl: (22) The requested URL returned error: 404

# Solution: Push image to registry first
docker push localhost:32000/my-ag-ui-app:latest
```

#### 3. Authentication Errors (should not occur with local registry)
```bash
# Error: no basic auth credentials
# Note: This should not happen with local registry
# If it occurs, the registry configuration is incorrect
```

### Error Recovery Commands
```bash
# Restart registry pod
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete pod -n container-registry -l app=registry

# Verify registry status after restart
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# Test registry accessibility
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog
```

## Integration Examples

### 1. CI/CD Pipeline Integration
```yaml
# Example GitHub Actions step for local registry testing
- name: Test Registry Accessibility
  run: |
    curl -f http://localhost:32000/v2/ || exit 1
    curl -s http://localhost:32000/v2/_catalog | jq .

- name: Verify Application Image
  run: |
    curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list | jq '.tags[]' | grep -q "latest"
```

### 2. Development Environment Setup
```bash
# Add to your .bashrc or .zshrc for quick registry commands
alias reg-status="curl -s http://localhost:32000/v2/_catalog | jq ."
alias reg-images="curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list | jq ."
alias reg-health="curl -f http://localhost:32000/v2/ && echo 'Registry OK'"

# Function to push current build
push-to-local-registry() {
    docker build -t my-ag-ui-app:latest .
    docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest
    docker push localhost:32000/my-ag-ui-app:latest
    echo "Image pushed to localhost:32000/my-ag-ui-app:latest"
}
```

## Best Practices

### 1. Development Usage
- Always use `localhost:32000` prefix for local registry references
- Test registry accessibility before pushing images
- Use `docker images | grep localhost:32000` to verify local images
- Regularly clean up unused local images with `docker image prune`

### 2. Deployment Usage
- Always specify `imagePullPolicy: IfNotPresent` for local registry images
- Verify image exists in registry before applying deployment
- Monitor pod events for image pull issues
- Use rolling updates to minimize downtime during updates

### 3. Testing Usage
- Include registry health checks in your test suite
- Test with actual image pulls from the registry
- Verify application functionality with registry-sourced images
- Test rollback procedures to previous image versions

## Troubleshooting Quick Reference

### Registry Access Issues
```bash
# Check if registry is running
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n container-registry

# Test registry connectivity
multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog

# Check registry service
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get svc -n container-registry
```

### Image Issues
```bash
# List local images
docker images | grep localhost:32000

# Remove local image
docker rmi localhost:32000/my-ag-ui-app:latest

# Force pull from registry
docker pull localhost:32000/my-ag-ui-app:latest
```

### Pod Issues
```bash
# Check pod status
kubectl get pods -l app=my-ag-ui-app

# Describe pod for image pull details
kubectl describe pod <pod-name> | grep -A 20 "Image:"

# View pod logs
kubectl logs <pod-name>
```

## Advanced Usage

### 1. Multiple Environments
```bash
# Tag for different environments
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:dev
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:staging
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:prod

# Push all tags
docker push localhost:32000/my-ag-ui-app:dev
docker push localhost:32000/my-ag-ui-app:staging
docker push localhost:32000/my-ag-ui-app:prod
```

### 2. Version Management
```bash
# Tag with version
docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:v1.0.0

# Push versioned image
docker push localhost:32000/my-ag-ui-app:v1.0.0

# List all versions
curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list | jq .
```

### 3. Registry API Usage
```bash
# Get repository list
repositories=$(curl -s http://localhost:32000/v2/_catalog | jq -r '.repositories[]')

# Get tags for each repository
for repo in $repositories; do
    echo "Repository: $repo"
    curl -s "http://localhost:32000/v2/$repo/tags/list" | jq -r '.tags[]' | sed 's/^/  - /'
done
```

## Conclusion

The `localhost:32000` registry endpoint provides a reliable, self-contained solution for local Kubernetes development. By following the usage patterns and examples in this guide, you can effectively integrate the local registry into your development, testing, and deployment workflows.

For more detailed information about registry configuration and troubleshooting, refer to the `REGISTRY_CONFIGURATION.md` and `REGISTRY_TROUBLESHOOTING.md` documents.

---

**Last Updated**: March 24, 2026  
**Maintainer**: Development Team  
**Version**: 1.0