# Shared Functions, Variables, and State Analysis

## Overview
This document analyzes the shared functions, variables, and state between the deployment phases that will be extracted into modular scripts.

## Phase Boundaries
Based on the analysis of `deploy.sh`, the deployment consists of the following distinct phases:

1. **Setup Kubernetes Secrets** - Configure Kubernetes secrets and validation
2. **Build Docker Image** - Build the application Docker image
3. **Tag Docker Image** - Tag the image for the local registry
4. **Setup Microk8s Registry** - Enable and verify the microk8s registry
5. **Push Docker Image** - Push the tagged image to the registry
6. **Deploy to Kubernetes** - Deploy the application to Kubernetes

## Shared Functions

### Core Logging and Performance Functions
These functions are used across multiple phases for logging and performance tracking:

1. **`log()`** (line 485)
   - **Purpose**: Primary logging function that writes to both stdout and log file
   - **Usage**: Used by ALL phases for consistent logging
   - **Dependencies**: `LOG_FILE` variable
   - **Phase Impact**: Essential for all phases - must be included in each script

2. **`start_phase_timing()`** (line 522)
   - **Purpose**: Start timing measurement for a deployment phase
   - **Usage**: Used by phases that need performance measurement
   - **Dependencies**: `PHASE_START_TIMES` associative array
   - **Phase Impact**: Used by build, push, and deployment phases

3. **`end_phase_timing()`** (line 530)
   - **Purpose**: End timing measurement and calculate duration
   - **Usage**: Used by phases that need performance measurement
   - **Dependencies**: `PHASE_START_TIMES`, `PHASE_END_TIMES`, `PHASE_DURATIONS`
   - **Phase Impact**: Used by build, push, and deployment phases

4. **`get_phase_duration()`** (line 550)
   - **Purpose**: Retrieve the duration of a completed phase
   - **Usage**: Used for reporting and analysis
   - **Dependencies**: `PHASE_DURATIONS` associative array
   - **Phase Impact**: Used by performance reporting phases

### Error Handling Functions
These functions provide comprehensive error handling across phases:

5. **`handle_registry_inaccessible_error()`** (line 2132)
   - **Purpose**: Handle registry accessibility issues with detailed diagnostics
   - **Usage**: Used by registry setup and image push phases
   - **Dependencies**: `VM_NAME` variable
   - **Phase Impact**: Critical for phases 4 and 5 (registry operations)

6. **`handle_image_pull_failure_error()`** (line 2248)
   - **Purpose**: Handle image pull failures in Kubernetes deployment
   - **Usage**: Used by Kubernetes deployment phase
   - **Dependencies**: `VM_NAME` variable
   - **Phase Impact**: Critical for phase 6 (Kubernetes deployment)

### Docker State Management Functions
These functions manage Docker state caching and are used across VM-related operations:

7. **`create_docker_state_cache()`** (line 738)
   - **Purpose**: Create cache of Docker setup state to optimize subsequent deployments
   - **Usage**: Used by VM Docker setup operations
   - **Dependencies**: `VM_NAME`, `DOCKER_STATE_FILE`, multiple cache state variables
   - **Phase Impact**: Used by VM Docker setup (part of build process)

8. **`load_docker_state_cache()`** (line 775)
   - **Purpose**: Load cached Docker state to avoid redundant setup
   - **Usage**: Used by VM Docker setup operations
   - **Dependencies**: `DOCKER_STATE_FILE`, cache state variables
   - **Phase Impact**: Used by VM Docker setup

9. **`is_docker_state_cache_valid()`** (line 850)
   - **Purpose**: Check if cached Docker state is still valid
   - **Usage**: Used by VM Docker setup operations
   - **Dependencies**: Cache state variables, `DOCKER_STATE_FILE`
   - **Phase Impact**: Used by VM Docker setup

### Registry Functions
These functions handle microk8s registry operations:

10. **`verify_microk8s_registry()`** (line 2363)
    - **Purpose**: Verify microk8s registry is running and accessible
    - **Usage**: Used by registry setup and image push phases
    - **Dependencies**: `VM_NAME`, `LOG_FILE`
    - **Phase Impact**: Critical for phases 4 and 5

11. **`enable_microk8s_registry()`** (line 2547)
    - **Purpose**: Enable microk8s registry for local image distribution
    - **Usage**: Used by registry setup phase
    - **Dependencies**: `VM_NAME`, `LOG_FILE`, calls `verify_microk8s_registry()`
    - **Phase Impact**: Critical for phase 4

### Image Operations Functions
These functions handle Docker image operations:

12. **`push_image_to_registry()`** (line 2669)
    - **Purpose**: Push Docker image to microk8s registry with retry logic
    - **Usage**: Used by image push phase
    - **Dependencies**: `VM_NAME`, `LOG_FILE`, `verify_microk8s_registry()`
    - **Phase Impact**: Critical for phase 5

13. **`tag_image_for_local_registry()`** (line 2982)
    - **Purpose**: Tag Docker image for local microk8s registry
    - **Usage**: Used by image tagging phase
    - **Dependencies**: `VM_NAME`, `LOG_FILE`
    - **Phase Impact**: Critical for phase 3

### VM and System Functions
These functions handle VM operations and system-level checks:

14. **`setup_vm_docker()`** (line 3299)
    - **Purpose**: Set up Docker in the VM with caching and error handling
    - **Usage**: Used by Docker-related phases that need VM operations
    - **Dependencies**: `VM_NAME`, `LOG_FILE`, Docker state functions
    - **Phase Impact**: Used by phases 2 and possibly others needing VM Docker access

15. **`check_disk_space()`** (line 5491)
    - **Purpose**: Check if sufficient disk space is available for operations
    - **Usage**: Used by build, push, and other space-intensive operations
    - **Dependencies**: None (self-contained)
    - **Phase Impact**: Used by phases 2 and 5

## Shared Variables

### Core Configuration Variables
These variables define core configuration used across multiple phases:

1. **`VM_NAME`** (line 421)
   - **Value**: `"my-ag-ui-app-k8s"`
   - **Usage**: Used by ALL phases that interact with the VM via multipass
   - **Phase Impact**: Essential for phases 1, 4, 5, 6

2. **`LOG_FILE`** (line 418)
   - **Value**: `"/tmp/deploy-$(date +%Y%m%d-%H%M%S).log"`
   - **Usage**: Used by ALL phases for logging output
   - **Phase Impact**: Essential for ALL phases

### Docker State Variables
These variables manage Docker state caching:

3. **`DOCKER_STATE_FILE`** (line 428)
   - **Value**: `"/tmp/docker-setup-state-${VM_NAME}.json"`
   - **Usage**: Used by Docker state management functions
   - **Phase Impact**: Used by VM Docker setup operations

4. **`CACHE_VALIDITY_MINUTES`** (line 429)
   - **Value**: `30`
   - **Usage**: Determines how long Docker state cache remains valid
   - **Phase Impact**: Used by Docker state management

5. **Cache State Variables** (lines 432-438)
   - `DOCKER_STATE_LOADED=false`
   - `CACHED_DOCKER_CLI_AVAILABLE=false`
   - `CACHED_DOCKER_DAEMON_RUNNING=false`
   - `CACHED_USER_IN_DOCKER_GROUP=false`
   - `CACHED_DOCKER_NO_SUDO_WORKING=false`
   - `CACHE_TIMESTAMP=""`
   - `CACHE_IS_VALID=false`
   - **Usage**: Track Docker setup state in memory
   - **Phase Impact**: Used by Docker state management functions

### Performance Tracking Variables
These variables track performance metrics:

6. **`PERFORMANCE_LOG_FILE`** (line 493)
   - **Value**: `"/tmp/deploy-performance-$(date +%Y%m%d-%H%M%S).log"`
   - **Usage**: Stores detailed performance metrics
   - **Phase Impact**: Used by performance measurement functions

7. **Performance Arrays** (lines 515-520)
   - `PHASE_START_TIMES` (associative array)
   - `PHASE_END_TIMES` (associative array)
   - `PHASE_DURATIONS` (associative array)
   - `TOTAL_DEPLOYMENT_START_TIME`
   - `TOTAL_DEPLOYMENT_END_TIME`
   - **Usage**: Track timing information for performance analysis
   - **Phase Impact**: Used by timing functions across phases

### Build Configuration Variables
These variables configure build behavior:

8. **`SKIP_DEPS_CHECK`** (line 5213)
   - **Value**: `false`
   - **Usage**: Controls whether to skip dependency validation
   - **Phase Impact**: Used by build phase (phase 2)

### Kubernetes Configuration Variables
These variables configure Kubernetes deployment:

9. **`REQUIRED_VARS`** (line 5610)
   - **Value**: `("OPENAI_API_KEY" "OPENAI_BASE_URL" "OPENAI_MODEL" "EMBEDDING_MODEL")`
   - **Usage**: Defines required environment variables for the application
   - **Phase Impact**: Used by Kubernetes secrets setup (phase 1)

10. **`MISSING_VARS`** (line 5611)
    - **Value**: `()`
    - **Usage**: Tracks missing required environment variables
    - **Phase Impact**: Used by Kubernetes secrets setup

### Deployment Timeout Variables
These variables configure deployment timeouts:

11. **`MAX_POD_WAIT_ATTEMPTS`** (line 6156)
    - **Value**: `20`
    - **Usage**: Maximum attempts to wait for pods to be ready
    - **Phase Impact**: Used by Kubernetes deployment (phase 6)

12. **`POD_WAIT_ATTEMPT`** (line 6157)
    - **Value**: `1`
    - **Usage**: Current attempt count for pod readiness
    - **Phase Impact**: Used by Kubernetes deployment

13. **`INITIAL_STATUS_CHECK`** (line 6158)
    - **Value**: `true`
    - **Usage**: Controls initial status check behavior
    - **Phase Impact**: Used by Kubernetes deployment

## Shared State Between Phases

### File-Based State
The deployment process maintains state through several files:

1. **Log Files**:
   - `LOG_FILE`: `/tmp/deploy-$(date +%Y%m%d-%H%M%S).log`
   - `PERFORMANCE_LOG_FILE`: `/tmp/deploy-performance-$(date +%Y%m%d-%H%M%S).log`
   - **Impact**: All phases write to these files for logging and performance tracking

2. **Docker State Cache**:
   - `DOCKER_STATE_FILE`: `/tmp/docker-setup-state-${VM_NAME}.json`
   - **Impact**: Cached Docker setup state affects VM operations in multiple phases

3. **Docker Images**:
   - `my-ag-ui-app:latest`: Built image
   - `localhost:32000/my-ag-ui-app:latest`: Registry-tagged image
   - **Impact**: Images are passed between build, tag, push, and deployment phases

### In-Memory State
The deployment process maintains state in bash variables:

1. **Cache State**:
   - Docker setup cache variables (`CACHED_*`, `CACHE_*`)
   - **Impact**: Affects whether Docker setup is skipped in subsequent runs

2. **Performance State**:
   - Timing arrays and variables (`PHASE_*`, `TOTAL_*`)
   - **Impact**: Tracks performance across all phases

3. **Configuration State**:
   - Configuration variables (`VM_NAME`, `SKIP_DEPS_CHECK`, etc.)
   - **Impact**: Affects behavior of all phases

### External System State
The deployment process relies on and modifies external systems:

1. **VM State**:
   - VM existence and accessibility
   - Docker daemon status in VM
   - Microk8s status in VM
   - **Impact**: Affects all phases that interact with the VM

2. **Docker Registry State**:
   - Microk8s registry availability
   - Image presence in registry
   - **Impact**: Critical for push and deployment phases

3. **Kubernetes State**:
   - Deployment status
   - Pod status
   - Service status
   - **Impact**: Critical for deployment phase

## Phase Dependencies

### Data Flow Dependencies
```
Phase 1 (Secrets) ──┐
                    ├─→ Phase 6 (Deploy)
Phase 2 (Build) ────┐    │
                    ├─→ Phase 3 (Tag) ──→ Phase 4 (Registry) ──→ Phase 5 (Push) ──┘
```

### Shared Component Dependencies

#### ALL Phases Depend On:
- `log()` function
- `LOG_FILE` variable
- Basic bash utilities

#### VM-Related Phases (1, 4, 5, 6) Depend On:
- `VM_NAME` variable
- VM accessibility (external state)

#### Docker-Related Phases (2, 3, 4, 5) Depend On:
- Docker state management functions
- `DOCKER_STATE_*` variables
- Docker daemon in VM

#### Performance-Monitored Phases (2, 5, 6) Depend On:
- Timing functions (`start_phase_timing`, `end_phase_timing`)
- Performance variables (`PHASE_*` arrays)

#### Registry-Related Phases (4, 5) Depend On:
- Registry functions (`verify_microk8s_registry`, `enable_microk8s_registry`)
- Error handling functions (`handle_registry_inaccessible_error`)

#### Kubernetes-Related Phases (1, 6) Depend On:
- Configuration variables (`REQUIRED_VARS`, `MISSING_VARS`)
- Deployment timeout variables
- Kubernetes deployment functions

## Recommendations for Modular Scripts

### 1. Common Functions to Include in All Scripts:
- `log()` function
- Basic error handling pattern

### 2. Phase-Specific Function Groups:
- **Secrets Phase**: Configuration validation, Kubernetes secrets functions
- **Build Phase**: Docker build functions, disk space check, performance timing
- **Tag Phase**: Image tagging functions, VM operations
- **Registry Phase**: Registry setup and verification functions
- **Push Phase**: Image push functions with retry logic, registry verification
- **Deploy Phase**: Kubernetes deployment functions, error handling, performance timing

### 3. Shared Variables to Replicate:
Each script should define its own copy of essential variables:
- `VM_NAME`
- `LOG_FILE` (script-specific)
- Phase-specific configuration variables

### 4. State Management Strategy:
- Use files for inter-script communication when needed
- Each script should be self-contained for its primary operations
- Use return codes and standard output for simple status communication
- Consider using temporary files for complex data sharing between scripts

This analysis provides the foundation for extracting modular scripts while maintaining the necessary shared functionality and state management.

## Current Debug Output Levels by Phase

Based on the analysis in `deploy_log_explanation.md`, the current debug output levels for each phase are as follows:

### Phase 1: Kubernetes Secrets Setup (Lines 1-32)
**Status: ⚠️ PROBLEMATIC**
**Debug Level: FULL**
- **Current Debug Output**: Extensive verbose logging including validation errors and success/failure reporting
- **Reason for Full Debug**: The phase shows inconsistent behavior (reports both failure and success), making detailed debugging essential
- **Key Issues**: 
  - "ERROR: Generated YAML file is invalid" reported but step marked as "completed successfully"
  - Validation inconsistency suggests potential secrets configuration problems
- **Debug Retention Strategy**: Retain full verbose debug output due to problematic nature

### Phase 2: Docker Image Build (Lines 49-151)
**Status: ✅ SUCCESS**
**Debug Level: MINIMAL**
- **Current Debug Output**: Successful build completion messages, Next.js build status, image size information
- **Reason for Minimal Debug**: Phase completes successfully without errors, reducing need for verbose logging
- **Key Information Retained**:
  - Built image name: `my-ag-ui-app:latest`
  - Build success confirmation
  - Image size: 546MB
- **Debug Optimization Strategy**: Remove verbose debug output, keep only essential status messages

### Phase 3: Docker Image Tagging (Lines 154-201)
**Status: ✅ SUCCESS**
**Debug Level: MINIMAL**
- **Current Debug Output**: Tagging success confirmation, image ID verification
- **Reason for Minimal Debug**: Phase works reliably with consistent success
- **Key Information Retained**:
  - Tagged image name: `localhost:32000/my-ag-ui-app:latest`
  - Image ID verification: `9bb7f1915756`
  - Success confirmation
- **Debug Optimization Strategy**: Remove verbose debug output, keep only success confirmation

### Phase 4: Microk8s Registry Setup (Lines 202-297)
**Status: ✅ SUCCESS**
**Debug Level: MINIMAL**
- **Current Debug Output**: Registry status verification, pod information, API connectivity tests
- **Reason for Minimal Debug**: Registry setup works reliably and consistently
- **Key Information Retained**:
  - Registry pod name: `registry-6cf7b9fcc-4kfg7`
  - Service endpoint: `localhost:32000`
  - API connectivity status
- **Debug Optimization Strategy**: Remove verbose debug output, keep only essential status messages

### Phase 5: Docker Registry Push (Lines 298-448)
**Status: ⚠️ PARTIAL SUCCESS**
**Debug Level: MINIMAL**
- **Current Debug Output**: Push progress, verification attempts, timing issue warnings
- **Reason for Minimal Debug**: Push succeeds but verification fails due to timing issues
- **Key Issues**:
  - Image push completes successfully (line 402)
  - Image verification fails - image not found in registry catalog after 5 attempts
  - Timing issue rather than critical failure
- **Debug Retention Strategy**: Minimize debug output but keep critical status and error messages for the verification issue

### Phase 6: Kubernetes Deployment (Lines 523-885)
**Status: ❌ CRITICAL FAILURE**
**Debug Level: FULL**
- **Current Debug Output**: Extensive pod status information, health check failure details, restart counts, event logs
- **Reason for Full Debug**: Critical failure with health checks causing pods to enter CrashLoopBackOff state
- **Key Issues**:
  - Pod 1: `my-ag-ui-app-78d9b4f9d9-97chw` - Running but NOT Ready, HTTP 404 on health checks
  - Pod 2: `my-ag-ui-app-d84bd959b-fpnlv` - CrashLoopBackOff with 7 restarts
  - Health check endpoint `/api/health` returning 404 instead of 200
- **Debug Retention Strategy**: Retain full verbose debug output due to critical failure nature

## Debug Output Optimization Strategy

### For SUCCESS Phases (2, 3, 4):
- **Action**: Remove verbose debug output
- **Retention**: Keep only essential status messages and success confirmations
- **Rationale**: These phases work reliably, reducing context token consumption

### For PROBLEMATIC Phase (1):
- **Action**: Retain full verbose debug output
- **Retention**: Keep all current debug information including validation errors
- **Rationale**: Inconsistent success/failure reporting requires detailed debugging

### For PARTIAL SUCCESS Phase (5):
- **Action**: Minimize debug output but retain critical error messages
- **Retention**: Keep push status and verification failure details
- **Rationale**: Timing issue needs visibility but not full verbose logging

### For CRITICAL FAILURE Phase (6):
- **Action**: Retain full verbose debug output
- **Retention**: Keep all pod status, health check, and event information
- **Rationale**: Critical failure requires maximum debugging visibility

### DEBUG=all Flag Implementation:
All modular scripts should support a `DEBUG=all` flag that temporarily enables full verbose output for any phase, allowing comprehensive debugging when needed regardless of the phase's normal debug level.