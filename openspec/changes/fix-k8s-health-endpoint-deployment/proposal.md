## Why

The Kubernetes deployment fails because the health check endpoint `/api/health` returns HTTP 404, causing readiness and liveness probe failures and preventing pods from becoming ready. Additionally, deployment logs are excessively verbose with unnecessary INFO-level messages even when verbose mode is disabled, making it difficult to identify the root cause of deployment failures.

## What Changes

- Create `/api/health` API route in Next.js application that returns HTTP 200 with JSON `{"status": "healthy"}`
- Suppress verbose debugging output in deployment scripts unless VERBOSE=true environment variable is explicitly set
- Remove redundant INFO-level logs that clutter deployment output during normal operations
- Ensure health endpoint responds quickly (<1 second) to satisfy Kubernetes probe timeouts

## Capabilities

### New Capabilities
- `health-endpoint-implementation`: Create and verify the `/api/health` API route returns HTTP 200 with JSON status

### Modified Capabilities
None (existing specs define requirements correctly; this change fixes implementation gaps)

## Non-goals

- Modifying the Kubernetes deployment manifest (deployment.yaml is already correctly configured)
- Changing probe configurations or timeouts (existing settings are appropriate)
- Adding additional monitoring or observability features beyond the health check
- Redesigning the logging system (only suppressing unnecessary debug output)

## Impact

- **Code**: Next.js API routes (create `app/api/health/route.ts` with health check handler)
- **Deployment scripts**: Scripts in `k8s/` directory to conditionally suppress debug output based on VERBOSE flag
- **Kubernetes**: No changes to deployment manifest or specs - health check already configured correctly
- **Verification**: Health endpoint will pass readiness/liveness probes, allowing pods to become ready
- **Operations**: Deployment logs will be cleaner and easier to debug by default, with optional verbose mode for troubleshooting
