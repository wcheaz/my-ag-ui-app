# Deployment Testing Documentation
# =================================

This document describes how to test the complete deployment flow from build to running pods using the microk8s registry approach.

## Overview

The deployment process has been updated to use a microk8s local registry instead of the previous Docker daemon loading approach. This provides several benefits:

- **Eliminates external network dependencies** - Images are stored locally
- **Faster deployment times** - No image pulling from external registries  
- **Simplified deployment process** - No complex VM Docker daemon setup required
- **Better reliability** - Images are readily available in the local registry

## Test Scripts

We provide two test scripts for validating the deployment:

### 1. Comprehensive Deployment Flow Test (`test-complete-deployment-flow.sh`)

This script tests the entire deployment flow from build to running pods, including:

- **Environment validation** - Checks prerequisites (multipass, microk8s, docker)
- **Pre-deployment validation** - Verifies project files and deployment manifests
- **Docker build tests** - Tests image building and local availability
- **Microk8s registry tests** - Tests registry enablement and accessibility
- **Registry operations tests** - Tests image push and verification
- **Kubernetes deployment tests** - Tests deployment application and pod status
- **Application access tests** - Tests external application access
- **Cleanup tests** - Optional resource cleanup

#### Usage

```bash
# Quick validation tests (recommended first)
./test-complete-deployment-flow.sh quick

# Complete end-to-end deployment test (full deployment)
./test-complete-deployment-flow.sh full

# Full test with cleanup
./test-complete-deployment-flow.sh full cleanup

# Full test with complete cleanup (removes VM)
./test-complete-deployment-flow.sh full cleanup remove-vm

# Show help
./test-complete-deployment-flow.sh --help
```

#### Test Types

| Type | Description | Duration | Resources Required |
|------|-------------|----------|-------------------|
| `quick` | Basic validation and environment checks | 1-2 minutes | Minimal |
| `full` | Complete end-to-end deployment test | 10-20 minutes | VM, storage, network |
| `manual` | Interactive testing with prompts | Variable | User interaction |
| `automated` | Automated testing for CI/CD pipelines | 5-10 minutes | CI/CD environment |

### 2. Registry Approach Integration Test (`test-registry-approach.sh`)

This script specifically tests the microk8s registry approach integration, ensuring that:

- Registry enablement works correctly
- Image push and verification functions properly
- Deployment manifest uses registry image reference
- Expected benefits of registry approach are validated

#### Usage

```bash
# Run all registry approach tests
./test-registry-approach.sh

# Test specific phase
./test-registry-approach.sh 1    # Registry enablement
./test-registry-approach.sh 2    # Image build and tag
./test-registry-approach.sh 3    # Image push to registry
./test-registry-approach.sh 4    # Kubernetes deployment
./test-registry-approach.sh 5    # End-to-end validation
./test-registry-approach.sh 6    # Benefits validation

# Show help
./test-registry-approach.sh --help
```

## Test Phases Detailed

### Phase 1: Environment Validation

**Purpose**: Verify all prerequisites are available for testing

**Checks**:
- ✅ multipass command available
- ✅ microk8s command available  
- ✅ docker command available
- ✅ Sufficient disk space (>10% free)
- ✅ Network connectivity

**Expected Result**: All checks pass

**Failure Actions**: Install missing components or resolve issues

### Phase 2: Pre-deployment Validation

**Purpose**: Verify project structure and required files

**Checks**:
- ✅ package.json exists
- ✅ package-lock.json exists
- ✅ Dockerfile exists
- ✅ k8s/deployment.yaml exists
- ✅ deploy.sh exists and is executable

**Expected Result**: All required files present

**Failure Actions**: Check project structure or generate missing files

### Phase 3: Docker Build Tests

**Purpose**: Test Docker image building for local registry

**Checks**:
- ✅ Docker daemon accessible
- ✅ Docker build completes successfully
- ✅ Image tagged correctly (localhost:32000/my-ag-ui-app:latest)
- ✅ Image exists locally

**Expected Result**: Image built and tagged correctly

**Failure Actions**: Check Dockerfile, fix build errors

### Phase 4: Microk8s Registry Tests

**Purpose**: Test microk8s registry setup and accessibility

**Checks**:
- ✅ microk8s is running
- ✅ microk8s registry enabled
- ✅ Registry accessible at localhost:32000
- ✅ Registry API responding

**Expected Result**: Registry ready for image operations

**Failure Actions**: Enable registry, check microk8s status

### Phase 5: Registry Operations Tests

**Purpose**: Test image push to registry and verification

**Checks**:
- ✅ Pre-push registry accessibility
- ✅ Image push to registry successful
- ✅ Image appears in registry catalog
- ✅ Registry manifest accessible

**Expected Result**: Image successfully pushed and verified in registry

**Failure Actions**: Check network, retry push, verify registry status

### Phase 6: Kubernetes Deployment Tests

**Purpose**: Test Kubernetes deployment using registry image

**Checks**:
- ✅ VM exists and running (if needed)
- ✅ microk8s accessible in VM
- ✅ Deployment manifest applies successfully
- ✅ Pods reach Running status
- ✅ No ImagePullBackOff errors (registry benefit)

**Expected Result**: Deployment successful with pods running

**Failure Actions**: Check deployment manifest, verify registry access

### Phase 7: Application Access Tests

**Purpose**: Test external application access

**Checks**:
- ✅ VM IP address obtained
- ✅ Ingress controller running
- ✅ Application accessible via ingress
- ✅ Application responds correctly

**Expected Result**: Application accessible externally

**Failure Actions**: Check ingress configuration, wait for propagation

## Testing Strategies

### 1. Development Testing

For day-to-day development and validation:

```bash
# Quick check that everything is ready
./test-registry-approach.sh

# If registry approach passes, test deployment
./deploy.sh
```

### 2. Pre-production Testing

Before deploying to production:

```bash
# Comprehensive validation
./test-complete-deployment-flow.sh full
```

### 3. CI/CD Pipeline Testing

For automated testing in CI/CD:

```bash
# Automated testing suitable for CI/CD
./test-complete-deployment-flow.sh automated
```

### 4. Troubleshooting Testing

When experiencing deployment issues:

```bash
# Test registry approach first
./test-registry-approach.sh

# If registry passes, test full deployment
./test-complete-deployment-flow.sh full
```

## Expected Test Results

### Successful Registry Approach Test

```
================================================
  REGISTRY APPROACH TEST SUMMARY
================================================
Tests Passed: 15
Tests Failed: 0
Total Tests: 15

🎉 ALL TESTS PASSED!

✅ Registry approach is properly implemented and integrated
✅ Ready for end-to-end deployment testing
✅ All expected benefits are validated
```

### Successful Complete Deployment Test

```
================================================
  DEPLOYMENT TEST SUMMARY
================================================
Total tests: 28
Passed: 28
Failed: 0

🎉 All tests passed! 🎉

The deployment flow is ready for production use
```

## Troubleshooting Test Failures

### Common Issues and Solutions

#### Issue: "microk8s not found"
**Solution**: Install microk8s
```bash
sudo snap install microk8s --classic
sudo usermod -aG microk8s $USER
newgrp microk8s
```

#### Issue: "Docker daemon not accessible"
**Solution**: Start Docker daemon and check permissions
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
```

#### Issue: "Registry not accessible"
**Solution**: Enable microk8s registry
```bash
microk8s enable registry
```

#### Issue: "Image push failed"
**Solution**: Check registry status and retry
```bash
curl -s http://localhost:32000/v2/_catalog
docker push localhost:32000/my-ag-ui-app:latest
```

#### Issue: "Pods in ImagePullBackOff"
**Solution**: Verify registry and deployment
```bash
# Check registry
curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list

# Check deployment image reference
kubectl get deployment my-ag-ui-app -o yaml
```

### Debug Commands

#### Check Registry Status
```bash
microk8s status
curl -s http://localhost:32000/v2/_catalog
curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
```

#### Check Docker Images
```bash
docker images localhost:32000/my-ag-ui-app:latest
```

#### Check Kubernetes Deployment
```bash
kubectl get deployment my-ag-ui-app
kubectl get pods -l app=my-ag-ui-app
kubectl describe pods -l app=my-ag-ui-app
```

#### Check Application Access
```bash
kubectl get ingress my-ag-ui-app-ingress
curl http://<vm-ip>
```

## Benefits Verification

The test scripts verify that the registry approach provides the expected benefits:

### ✅ Eliminated VM Docker Daemon Setup
- No complex Docker installation in VM required
- Registry handles image distribution automatically

### ✅ Faster Deployment Times
- Images pushed once to local registry
- No VM image loading delays
- Pods start immediately (no ImagePullBackOff)

### ✅ Simplified Deployment Process
- Single image push command
- Automatic image distribution
- Built-in verification and error handling

### ✅ Better Reliability
- Local registry always accessible
- No external network dependencies
- Comprehensive retry and error handling

### ✅ Comprehensive Verification
- Multi-level image verification
- Registry accessibility checks
- Deployment status validation

## Running Tests in Different Environments

### Local Development
- Use `quick` test type for fast validation
- Run registry approach test before full deployment
- Manual testing of application features

### CI/CD Pipeline
- Use `automated` test type
- Run on every commit
- Fail builds if tests fail
- Generate test reports

### Staging Environment
- Use `full` test type with cleanup
- Test before production deployment
- Verify all integration points

### Production Deployment
- Pre-deployment validation with `quick` tests
- Monitor deployment with provided debug commands
- Have rollback procedure ready

## Conclusion

The comprehensive testing framework ensures that:

1. **Registry approach is properly implemented** - All components work together correctly
2. **Deployment process is reliable** - Errors are caught and handled gracefully
3. **Expected benefits are realized** - Performance and reliability improvements are verified
4. **Issues can be diagnosed** - Clear error messages and debugging procedures provided

Run the test scripts regularly to ensure continued deployment reliability and to catch any regressions early.