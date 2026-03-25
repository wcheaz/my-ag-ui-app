# Current Deployment Flow for Image Tag and Push Operations

## Overview
The deployment script successfully executes Docker image tagging and push operations **within the VM**, ensuring proper connectivity to the microk8s registry at `localhost:32000`. The deployment has been updated to use the local registry image reference `localhost:32000/my-ag-ui-app:latest`.

## Current Successful Deployment Flow

### Image Build, Tag, and Push Workflow

#### 1. Image Building (Host System)
- **Location**: `deploy.sh` (lines 5713-5742)
- **Execution**: Host system
- **Process**:
  1. Builds Docker image as `my-ag-ui-app:latest` on host
  2. Validates successful build locally
  3. Prepares image for VM transfer

#### 2. Image Transfer to VM (Host → VM)
- **Location**: `deploy.sh` (lines 5417+)
- **Execution**: Host to VM via multipass
- **Process**:
  1. Transfers `my-ag-ui-app:latest` image from host to VM
  2. Uses `multipass exec` for VM operations
  3. Validates image exists in VM after transfer

#### 3. Image Tagging (Within VM)
- **Location**: `deploy.sh` (function `tag_image_for_local_registry()`)
- **Execution**: Within VM via `multipass exec`
- **Process**:
  1. **Phase Timing**: Starts "DOCKER_IMAGE_TAGGING" phase timing
  2. **Function Call**: `tag_image_for_local_registry()` within VM
  3. **Validation Steps**:
     - Checks if source image `my-ag-ui-app:latest` exists in VM
     - Verifies Docker daemon accessibility in VM
     - Removes any existing target tag `localhost:32000/my-ag-ui-app:latest`
  4. **Tagging Command**: Executes `docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest` (in VM)
  5. **Post-Tagging Validation**:
     - Verifies tagged image exists in VM
     - Validates source and tagged images have same image ID
  6. **Result Handling**:
     - Success: Logs completion and ends timing
     - Failure: Calls error handling with detailed analysis

#### 4. Image Push to Registry (Within VM)
- **Location**: `deploy.sh` (function `push_image_to_registry()`)
- **Execution**: Within VM via `multipass exec`
- **Process**:
  1. **Phase Timing**: Starts "DOCKER_REGISTRY_PUSH" phase timing
  2. **Function Call**: `push_image_to_registry()` within VM
  3. **Pre-Flight Checks**:
     - Verifies tagged image exists in VM
     - Verifies microk8s registry is accessible (from VM - **SUCCESSFUL**)
     - Checks sufficient disk space for push operation
  4. **Push Operation**:
     - Executes `docker push localhost:32000/my-ag-ui-app:latest` with retry logic (in VM)
     - Uses exponential backoff with jitter for transient network issues
     - Includes comprehensive error analysis and logging
  5. **Error Handling**:
     - Analyzes specific error patterns (network connectivity, authentication, image not found, registry unavailable)
     - Provides targeted recovery guidance
     - Implements retry logic for transient issues
  6. **Result Handling**:
     - Success: Logs completion and ends timing
     - Failure: Calls error handling with detailed analysis

#### 5. Kubernetes Deployment (Updated Image Reference)
- **Location**: `k8s/deployment.yaml`
- **Image Reference**: `localhost:32000/my-ag-ui-app:latest` (successfully updated)
- **Process**:
  1. Applies deployment manifest with local registry image reference
  2. Kubernetes pulls image from `localhost:32000/my-ag-ui-app:latest`
  3. Pods start successfully without ImagePullBackOff errors
  4. Application runs with image from local registry

## Success Pattern

### Current Successful Deployment Pattern
1. Docker build succeeds on host
2. Image transferred to VM successfully
3. Image tagging succeeds in VM (access to localhost:32000)
4. Microk8s registry verification succeeds in VM
5. Docker push succeeds in VM (registry accessible at localhost:32000)
6. Kubernetes deployment succeeds (pods pull from localhost:32000/my-ag-ui-app:latest)
7. Pods reach Running state successfully

### Success Evidence
- **Registry Access**: `curl -s http://localhost:32000/v2/_catalog` succeeds in VM
- **Push Command**: `docker push localhost:32000/my-ag-ui-app:latest` succeeds in VM
- **Pod Status**: Pods reach Running state without ImagePullBackOff
- **Deployment Image**: `kubectl get deployment` shows `localhost:32000/my-ag-ui-app:latest`

## Completed Implementation

### ✅ Successfully Implemented
1. **VM-based Image Operations**: All Docker operations now execute within VM context
2. **Registry Accessibility**: microk8s registry accessible at `localhost:32000` within VM
3. **Updated Deployment Manifest**: `k8s/deployment.yaml` uses `localhost:32000/my-ag-ui-app:latest`
4. **End-to-End Flow**: Complete build → transfer → tag → push → deploy → verify pipeline
5. **Error Handling**: Comprehensive error handling for VM-based operations
6. **Registry Integration**: Seamless integration with microk8s local registry

### Key Configuration Changes
- **Primary**: `k8s/deployment.yaml` updated to use `localhost:32000/my-ag-ui-app:latest`
- **Supporting**: `deploy.sh` enhanced with VM-based Docker operations
- **Validation**: Comprehensive testing and verification of registry operations

## Documentation References

For additional details on the registry configuration, see:
- `REGISTRY_CONFIGURATION.md` - Comprehensive registry setup and configuration
- `REGISTRY_TROUBLESHOOTING.md` - Troubleshooting guide for registry issues
- `README.md` - Project overview and deployment instructions