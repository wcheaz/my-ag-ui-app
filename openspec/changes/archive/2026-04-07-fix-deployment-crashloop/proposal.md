## Why

The Kubernetes deployment is failing because application pods enter CrashLoopBackOff state. The application starts successfully but exits with code 0 instead of staying running, and health checks fail with HTTP 404 because the `/api/health` endpoint does not exist. This prevents the application from serving traffic and makes deployments unreliable.

## What Changes

- Add a `/api/health` endpoint to the Next.js application that returns HTTP 200 with a simple health status
- Configure the Next.js production build to run as a long-running server process instead of exiting after startup
- Fix the Kubernetes deployment rollback mechanism to handle version conflicts gracefully
- Update the Dockerfile to ensure the container stays running in production mode

## Capabilities

### New Capabilities

- `health-check-endpoint`: Application provides a `/api/health` endpoint that responds with HTTP 200 and a JSON status object when the application is healthy
- `container-lifecycle-management`: Application container runs as a persistent server process that stays alive and handles requests indefinitely

### Modified Capabilities

None

## Impact

- **Affected code**: Next.js application (need to add health check API route), Dockerfile (production server configuration)
- **Affected configuration**: Kubernetes deployment.yaml (health check configuration), next.config.ts (production build settings)
- **Affected systems**: Kubernetes deployment pipeline, container runtime, health monitoring

## Non-goals

- Modifying the application's core business logic or features
- Changing the deployment pipeline beyond fixing the rollback mechanism
- Implementing advanced health checks (e.g., database connectivity, external service dependencies)
- Changing the Kubernetes cluster configuration or Microk8s setup
- Implementing monitoring or observability beyond basic health checks
