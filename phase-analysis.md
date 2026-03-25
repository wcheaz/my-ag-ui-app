# Deploy.sh Phase Analysis - Task 1.2

## Phase Boundaries Identified

Based on analysis of `deploy.sh` (6583 lines), the following distinct deployment phases have been identified:

### 1. Kubernetes Secrets Setup (Lines 5570-5635)
- **Start**: "Starting Kubernetes secrets setup..." (line 5570)
- **End**: "Kubernetes secrets setup completed successfully" (line 5635)
- **Status**: PROBLEMATIC (based on deploy_log_explanation.md)
- **Functionality**: Sets up Kubernetes secrets using `k8s/setup-secrets.sh`, validates environment variables

### 2. Docker Image Build (Lines ~5760-5788)
- **Start**: Docker build command execution (around line 5760)
- **End**: "Docker image 'my-ag-ui-app:latest' verified successfully" (line 5787)
- **Status**: SUCCESS
- **Functionality**: Builds Docker image `my-ag-ui-app:latest` using Dockerfile

### 3. Docker Image Tagging (Lines 5789-5801)
- **Start**: "Starting Docker image tagging for local registry..." (line 5791)
- **End**: "Docker image tagging for registry completed with comprehensive validation" (line 5800)
- **Status**: SUCCESS
- **Functionality**: Tags image for local registry as `localhost:32000/my-ag-ui-app:latest`

### 4. Microk8s Registry Setup (Lines 5816-5825)
- **Start**: "Starting microk8s registry setup..." (line 5817)
- **End**: "microk8s registry setup completed successfully" (line 5824)
- **Status**: SUCCESS
- **Functionality**: Enables and verifies microk8s local registry (localhost:32000)

### 5. Docker Registry Push (Lines 5828-5839)
- **Start**: "Starting Docker image push to microk8s registry..." (line 5829)
- **End**: "Docker image push to registry completed with comprehensive validation" (line 5838)
- **Status**: PARTIAL SUCCESS
- **Functionality**: Pushes tagged image to local registry with verification

### 6. Kubernetes Deployment (Lines 5852-6572)
- **Start**: "🚀 STARTING KUBERNETES DEPLOYMENT PHASE" (line 5853)
- **End**: "Kubernetes secrets setup and deployment completed successfully" (line 6571)
- **Status**: CRITICAL FAILURE
- **Functionality**: Applies deployment manifest, restarts deployment, verifies pods, sets up ingress

## Shared Dependencies Identified

### 1. Environment Variables
- `VM_NAME="my-ag-ui-app-k8s"` - Used across all phases for VM operations
- `LOG_FILE` - Common logging destination for all phases
- `PERFORMANCE_LOG_FILE` - Performance measurement across all phases

### 2. Common Functions
- `log()` - Centralized logging function (line 485)
- `start_phase_timing()` / `end_phase_timing()` - Performance measurement
- `handle_*_error()` functions - Error handling patterns
- Performance measurement functions (lines 492+)

### 3. Shared State
- Docker image name: `my-ag-ui-app:latest`
- Registry URL: `localhost:32000`
- Target image: `localhost:32000/my-ag-ui-app:latest`
- Kubernetes deployment name: `my-ag-ui-app`

### 4. Critical Dependencies Between Phases
1. **Docker Build → Image Tagging**: Requires built image `my-ag-ui-app:latest`
2. **Image Tagging → Registry Push**: Requires tagged image `localhost:32000/my-ag-ui-app:latest`
3. **Registry Push → Kubernetes Deployment**: Requires image in local registry
4. **Secrets Setup → Kubernetes Deployment**: Requires secrets to be configured before deployment

### 5. Common Infrastructure Dependencies
- Multipass VM access (`multipass exec "$VM_NAME"`)
- Microk8s cluster access (`microk8s kubectl`)
- Docker daemon access
- Network connectivity between host and VM

### 6. File Dependencies
- `k8s/setup-secrets.sh` - Required for secrets setup
- `k8s/deployment.yaml` - Required for Kubernetes deployment
- `k8s/service.yaml` - Required for service setup
- `k8s/ingress.yaml` - Required for ingress setup
- `.env` file - Optional environment variables for secrets

## Key Technical Functions to Extract

The following key functions will need to be extracted and adapted for modular scripts:

1. **Image Tagging Function**: `tag_image_for_local_registry()` (referenced line 5795)
2. **Registry Enable Function**: `enable_microk8s_registry()` (referenced line 5818)
3. **Registry Push Function**: `push_image_to_registry()` (referenced line 5833)
4. **Registry Verification Function**: `verify_microk8s_registry()` (referenced line 5846)
5. **Performance timing functions**: `start_phase_timing()`, `end_phase_timing()`
6. **Error handling functions**: Various `handle_*_error()` functions

## Debug Output Analysis

Based on `deploy_log_explanation.md`:
- **PROBLEMATIC phases (retain full debug)**: Secrets setup, Kubernetes deployment
- **SUCCESS phases (minimal debug)**: Docker build, Image tagging, Registry setup
- **PARTIAL SUCCESS phase (minimal debug)**: Registry push

This analysis provides the foundation for extracting modular scripts while maintaining all necessary dependencies and functionality.