# Current Deployment Flow for Image Tag and Push Operations

## Overview
The deployment script currently executes Docker image tagging and push operations on the **host system**, which creates a connectivity problem because the host's Docker daemon cannot access the VM's microk8s registry at `localhost:32000`.

## Image Tagging Flow

### Location
- **File**: `deploy.sh`
- **Lines**: 5407-5418 (main call), 2622+ (function definition)

### Current Execution Context
- **Runs on**: Host system
- **Function**: `tag_image_for_local_registry()`

### Detailed Process
1. **Phase Timing**: Starts "DOCKER_IMAGE_TAGGING" phase timing
2. **Function Call**: `tag_image_for_local_registry()`
3. **Validation Steps**:
   - Checks if source image `my-ag-ui-app:latest` exists locally (on host)
   - Verifies Docker daemon accessibility (on host)
   - Removes any existing target tag `localhost:32000/my-ag-ui-app:latest`
4. **Tagging Command**: Executes `docker tag my-ag-ui-app:latest localhost:32000/my-ag-ui-app:latest` (on host)
5. **Post-Tagging Validation**:
   - Verifies tagged image exists locally (on host)
   - Validates source and tagged images have same image ID
6. **Result Handling**:
   - Success: Logs completion and ends timing
   - Failure: Calls `handle_secrets_error()` with detailed error analysis

## Image Push Flow

### Location
- **File**: `deploy.sh`
- **Lines**: 5443-5449+ (main call), 2316+ (function definition)

### Current Execution Context
- **Runs on**: Host system
- **Function**: `push_image_to_registry()`

### Detailed Process
1. **Phase Timing**: Starts "DOCKER_REGISTRY_PUSH" phase timing
2. **Function Call**: `push_image_to_registry()`
3. **Pre-Flight Checks**:
   - Verifies tagged image exists locally (on host)
   - Verifies microk8s registry is accessible (from host - **THIS IS WHERE PROBLEM OCCURS**)
   - Checks sufficient disk space for push operation
4. **Push Operation**:
   - Executes `docker push localhost:32000/my-ag-ui-app:latest` with retry logic (on host)
   - Uses exponential backoff with jitter for transient network issues
   - Includes comprehensive error analysis and logging
5. **Error Handling**:
   - Analyzes specific error patterns (network connectivity, authentication, image not found, registry unavailable)
   - Provides targeted recovery guidance
   - Implements retry logic for transient issues
6. **Result Handling**:
   - Success: Logs completion and ends timing
   - Failure: Calls `handle_secrets_error()` with detailed error analysis

## The Core Problem

### Root Cause
The host's Docker daemon tries to connect to `localhost:32000`, but:
- **On host**: `localhost:32000` resolves to host's localhost (registry not running)
- **In VM**: `localhost:32000` resolves to VM's localhost (microk8s registry running)

### Current Failure Pattern
1. Docker build succeeds on host
2. Image tagging succeeds on host
3. Microk8s registry verification fails from host (connection refused)
4. Docker push fails from host (connection refused)
5. Kubernetes deployment fails (ImagePullBackOff)

### Error Evidence
- **Registry Access**: `curl -k https://localhost:32000/v2/_catalog` fails on host
- **Push Command**: `docker push localhost:32000/my-ag-ui-app:latest` fails on host
- **Pod Status**: Pods remain in `ImagePullBackOff` state

## Solution Direction

Both image tagging and push operations need to be executed **within the VM** using `multipass exec` so that:
- `localhost:32000` resolves to the VM's microk8s registry
- The VM's Docker daemon can access the local registry
- Images are properly distributed for Kubernetes deployment

## Next Steps

1. **Task 2.1**: Modify image tag command to execute via `multipass exec` within VM
2. **Task 3.1**: Modify image push command to execute via `multipass exec` within VM
3. **Tasks 4.x**: Add registry accessibility verification within VM context
4. **Tasks 5.x**: Update error handling for VM-based operations
5. **Tasks 6.x**: Test complete VM-based deployment flow

## Key Files to Modify

- **Primary**: `deploy.sh`
  - `tag_image_for_local_registry()` function
  - `push_image_to_registry()` function
  - Main execution calls (lines 5412 and 5449)
- **Secondary**: Error handling and logging functions to provide VM-context messages