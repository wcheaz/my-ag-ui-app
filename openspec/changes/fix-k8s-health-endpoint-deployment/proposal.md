## Why

The Kubernetes deployment fails because the health check endpoint `/api/health` returns HTTP 404, causing readiness and liveness probe failures and preventing pods from becoming ready. Analysis of deploy logs shows:

1. **Health Endpoint Not Accessible**: Despite the route being successfully compiled by Next.js (visible in build output), the `/api/health` endpoint returns HTTP 404 when accessed by Kubernetes probes from within the container
2. **Bash Script Syntax Error**: The `deploy-to-k8s.sh` script has a syntax error on line 800 causing deployment failures
3. **Deprecated Next.js Config**: The `next.config.ts` uses deprecated `experimental.serverComponentsExternalPackages` which causes build warnings
4. **Excessive Logging**: Deployment logs are excessively verbose with unnecessary INFO-level messages even when verbose mode is disabled, making it difficult to identify the root cause of deployment failures

## What Changes

- Fix bash script syntax error on line 800 of `deploy-to-k8s.sh`
- Remove deprecated `experimental.serverComponentsExternalPackages` from `next.config.ts`
- Verify and fix standalone build configuration to ensure API routes are accessible at runtime
- Test `/api/health` endpoint accessibility from within the VM/container (not from host machine)
- Suppress verbose debugging output in deployment scripts unless VERBOSE=true environment variable is explicitly set
- Remove redundant INFO-level logs that clutter deployment output during normal operations
- Ensure health endpoint responds quickly (<1 second) to satisfy Kubernetes probe timeouts

## Capabilities

### New Capabilities
- `health-endpoint-implementation`: Create and verify the `/api/health` API route returns HTTP 200 with JSON status

### Modified Capabilities
- `health-endpoint-implementation`: Fix implementation gap - route exists but is not accessible due to build/runtime configuration issues

## Non-goals

- Modifying the Kubernetes deployment manifest (deployment.yaml is already correctly configured)
- Changing probe configurations or timeouts (existing settings are appropriate)
- Adding additional monitoring or observability features beyond the health check
- Redesigning the logging system (only suppressing unnecessary debug output)
- Testing endpoints from host machine (cluster runs inside Multipass VM, must test from within VM)

## Impact

- **Code**: Next.js API routes (`src/app/api/health/route.ts` exists but needs accessibility fix), configuration files (next.config.ts)
- **Deployment scripts**: `deploy-to-k8s.sh` (fix syntax error), all scripts in `deploy_scripts/` directory to conditionally suppress debug output based on VERBOSE flag
- **Dockerfile**: Verify standalone build output includes API routes properly
- **Kubernetes**: No changes to deployment manifest or specs - health check already configured correctly
- **Verification**: Health endpoint will pass readiness/liveness probes when accessed from within container, allowing pods to become ready
- **Operations**: Deployment logs will be cleaner and easier to debug by default, with optional verbose mode for troubleshooting. Health endpoint testing must be done from within VM using `multipass exec`
