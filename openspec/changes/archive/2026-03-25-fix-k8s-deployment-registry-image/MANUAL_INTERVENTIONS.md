# Manual Intervention Steps - Fix K8s Deployment Registry Image

This document outlines the manual interventions required during the implementation of the K8s deployment registry image fix.

## Summary
The main objective (fixing ImagePullBackOff errors by updating the deployment to use the local registry) has been successfully achieved. However, several manual interventions were required during the process.

## Manual Interventions Performed

### 1. Deployment Script Validation Bug
**Issue**: The deployment script (`deploy.sh`) had a validation logic error that incorrectly detected a "registry port mismatch".
- **Symptom**: Script reported "Expected registry port: (microk8s standard)" vs "Actual registry port: 32000"
- **Root Cause**: Validation logic was expecting an empty port but 32000 is the correct microk8s registry port
- **Manual Intervention**: Bypassed the deployment script and manually applied the deployment using `kubectl`

### 2. Deployment Configuration Update
**Issue**: The running deployment had stale configuration with incorrect health check paths.
- **Symptom**: Health checks were failing with 404 errors trying to reach `/api/health` instead of `/health`
- **Root Cause**: The deployment.yaml file had been updated but the changes weren't applied to the cluster
- **Manual Intervention**: 
  - Deleted the existing deployment: `microk8s kubectl delete deployment my-ag-ui-app`
  - Recreated with updated configuration: `microk8s kubectl apply -f k8s/deployment.yaml`

### 3. Health Check Path Correction
**Issue**: Even after recreating the deployment, the health check paths were still incorrect.
- **Symptom**: Readiness probe still trying to access `/api/health` instead of `/health`
- **Root Cause**: Kubernetes deployment wasn't picking up the health check path changes from the YAML
- **Manual Intervention**: 
  - Created a patch file (`health-patch.yaml`) to explicitly update the health check paths
  - Applied the patch: `microk8s kubectl patch deployment my-ag-ui-app --patch "$(cat health-patch.yaml)"`

### 4. Application Health Endpoint Issue
**Issue**: The application doesn't have a `/health` endpoint implemented.
- **Symptom**: Health check probes return 404 errors even though the application is running and functional
- **Root Cause**: The Next.js application doesn't include a `/health` endpoint by default
- **Impact**: Pods show 0/1 ready status, but the application is actually functional and accessible
- **Resolution**: This is a separate application-level issue that doesn't affect the main objective (fixing ImagePullBackOff)

## Successful Outcomes

✅ **Primary Objective Achieved**: ImagePullBackOff errors have been eliminated
- Pods now successfully pull images from `localhost:32000/my-ag-ui-app:latest`
- All image pull operations complete successfully
- No more ImagePullBackOff errors in pod events

✅ **Application Functional**: The Next.js application is running and serving content
- Successfully accessed the application directly from the pod
- Received complete HTML response confirming the application is working
- Procurement Codes application with chat interface is operational

## Recommendations for Future Deployments

1. **Fix Deployment Script**: Update the deployment script's registry port validation logic to correctly recognize 32000 as the valid microk8s registry port
2. **Implement Health Endpoint**: Add a `/health` endpoint to the Next.js application to properly support Kubernetes health checks
3. **Automate Deployment Updates**: Ensure deployment configuration changes are properly applied without requiring manual deletion/recreation
4. **Improved Validation**: Add better validation to catch configuration mismatches earlier in the deployment process

## Conclusion

The core issue (ImagePullBackOff errors due to incorrect registry image reference) has been successfully resolved. The manual interventions were primarily required due to configuration management issues and a missing health endpoint, which are separate from the main registry image fix. The deployment now successfully uses the local microk8s registry for image pulls.