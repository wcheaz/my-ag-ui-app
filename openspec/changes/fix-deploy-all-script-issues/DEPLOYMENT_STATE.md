# Current Deployment State Documentation

## Documented: 2026-03-26

## Current Image Information
- **Image Tag**: `localhost:32000/my-ag-ui-app:latest`
- **Image ID**: `localhost:32000/my-ag-ui-app@sha256:9bb7f19157560c1ab63f2e6173528cca2e296fb3b25378e6aa41f46c698b775f`
- **Registry**: Microk8s local registry at `localhost:32000`
- **Image Pull Policy**: `IfNotPresent`

## Current Deployment Status
- **Deployment Name**: `my-ag-ui-app`
- **Namespace**: `default`
- **Replicas**: 1 (configured), 2 (actual - during rolling update)
- **Available Replicas**: 0
- **Updated Replicas**: 1
- **Unavailable Replicas**: 2

## Current Pod States (as of last deployment attempt)
Based on deployment logs from 2026-03-25:

### Pod: my-ag-ui-app-55f799774-hdmr7
- **Status**: CrashLoopBackOff → Running
- **Restarts**: 13+ (indicating continuous restarts)
- **Issue**: Failing liveness probe, container keeps restarting
- **Last State**: Terminated with exit code 0 (should not happen for a service)

### Pod: my-ag-ui-app-64b87d7b5-9pmvm
- **Status**: Running (but not Ready)
- **Restarts**: 1+
- **Issue**: Health check failures (HTTP 404 on `/api/health`)
- **Ready Status**: False (not passing readiness probes)

### Pod: my-ag-ui-app-79c6cd9b56-b6pq6
- **Status**: Running (but not Ready)
- **Restarts**: 4+
- **Issue**: Health check failures (HTTP 404 on `/api/health`)
- **Ready Status**: False (not passing readiness probes)

## Current Issues Identified

### 1. Health Check Failures
- **Liveness Probe**: HTTP 404 on `/api/health` endpoint
- **Readiness Probe**: HTTP 404 on `/api/health` endpoint
- **Current Configuration**:
  - Liveness: 30s initial delay, 10s period, 5s timeout, 3 failure threshold
  - Readiness: 5s initial delay, 5s period, 3s timeout, 3 failure threshold

### 2. Container Lifecycle Issues
- **Problem**: Containers terminating with exit code 0
- **Expected**: Containers should run continuously as a service
- **Actual**: Containers start, run briefly, then complete (exit code 0)
- **Result**: Continuous restart loops (CrashLoopBackOff)

### 3. Deployment Availability
- **Status**: MinimumReplicasUnavailable
- **Impact**: Application is not accessible/available
- **Reason**: Pods are not passing readiness probes

## Environment Variables
The deployment is configured with the following environment variables:

### From Secrets (my-ag-ui-app-secrets)
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `OPENAI_MODEL`
- `EMBEDDING_MODEL`
- `LOGFIRE_TOKEN`

### From ConfigMap (my-ag-ui-app-config)
- `LLM_MAX_TOKENS`
- `LLM_CONTEXT_WINDOW`

## Resource Configuration
- **CPU Requests**: 100m
- **CPU Limits**: 500m
- **Memory Requests**: 256Mi
- **Memory Limits**: 512Mi

## Application Port
- **Container Port**: 3000 (HTTP)
- **Service Port**: N/A (service not documented in current state)

## Health Check Endpoints
- **Current Path**: `/health` (in deployment.yaml), `/api/health` (in actual running pods)
- **Mismatch**: Deployment manifest specifies `/health` but pods are configured for `/api/health`
- **Port**: 3000

## Deployment Manifest Location
- **Primary**: `k8s/deployment.yaml`
- **Backup**: `k8s/deployment.yaml.backup` (created during rollback preparation)

## Required Fixes
1. **Health Check Path**: Standardize on `/api/health` endpoint
2. **Container Lifecycle**: Fix application to run continuously (not exit with code 0)
3. **Application Endpoint**: Ensure `/api/health` endpoint exists and returns HTTP 200
4. **Error Handling**: Add proper error handling to deployment scripts
5. **Rollback**: Test rollback procedure using backup manifest

## Next Steps
This documentation serves as the baseline state before implementing fixes to the deployment pipeline and application health checks.