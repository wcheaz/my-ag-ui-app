# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

container-lifecycle-management/spec.md
## ADDED Requirements

### Requirement: Container runs as persistent server process
The application container SHALL run as a persistent server process that stays alive and continues to handle HTTP requests indefinitely when started in production mode.

#### Scenario: Container stays running after startup
- **WHEN** the container is started with production configuration
- **THEN** the container process does not exit after initial startup
- **AND** the container continues to run and accept HTTP requests
- **AND** the container exit code is not 0 (indicating successful completion)

### Requirement: Container does not exit with code 0 in production mode
The application container SHALL NOT exit with exit code 0 when running in production mode, as this indicates the application completed successfully rather than running as a server.

#### Scenario: Container exit code is non-zero or process stays running
- **WHEN** the container is started in production mode
- **THEN** the container process does not terminate with exit code 0
- **AND** the container remains running as a server process

### Requirement: Production server listens on configured port
The application container SHALL start an HTTP server that listens on the configured port (default 3000) and remains ready to accept connections.

#### Scenario: Server listens on port 3000
- **WHEN** the container starts in production mode
- **THEN** an HTTP server process is listening on port 3000
- **AND** the server remains listening and accepting connections
- **AND** the server does not shut down after serving initial requests

### Requirement: Container handles graceful shutdown signals
The application container SHALL handle SIGTERM signals gracefully by shutting down the server process cleanly without crashing.

#### Scenario: Graceful shutdown on SIGTERM
- **WHEN** the container receives a SIGTERM signal
- **THEN** the application initiates graceful shutdown
- **AND** the server stops accepting new connections
- **AND** in-flight requests are allowed to complete
- **AND** the container exits with code 0 after shutdown completes

health-check-endpoint/spec.md
## ADDED Requirements

### Requirement: Health endpoint responds with HTTP 200 when application is healthy
The application SHALL provide an HTTP GET endpoint at `/api/health` that returns HTTP status code 200 when the application is running and able to handle requests.

#### Scenario: Successful health check
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the application responds with HTTP status code 200
- **AND** the response body contains a JSON object with a `status` field set to `"healthy"`

### Requirement: Health endpoint returns JSON status object
The `/api/health` endpoint SHALL return a JSON response body that includes a `status` field indicating the application health state.

#### Scenario: Health check returns valid JSON
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the response `Content-Type` header is `application/json`
- **AND** the response body is valid JSON
- **AND** the JSON object contains a `status` field with value `"healthy"`

### Requirement: Health endpoint is accessible on port 3000
The `/api/health` endpoint SHALL be accessible on the application's configured HTTP port (default 3000) without requiring authentication.

#### Scenario: Health check accessible without authentication
- **WHEN** a client sends an HTTP GET request to `http://localhost:3000/api/health` without authentication headers
- **THEN** the application responds with HTTP status code 200
- **AND** the response body contains the health status JSON object

### Requirement: Health endpoint responds quickly
The `/api/health` endpoint SHALL respond within 1 second under normal operating conditions to satisfy Kubernetes readiness probe timeouts.

#### Scenario: Health check responds within timeout
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the application responds within 1000 milliseconds
- **AND** the response contains HTTP status code 200



## Design

## Context

The current deployment fails because the Next.js application container exits with code 0 after startup instead of running as a persistent server process. Additionally, the Kubernetes health checks fail because the `/api/health` endpoint does not exist, returning HTTP 404. This causes pods to enter CrashLoopBackOff state, preventing the application from serving traffic.

**Current State:**
- Next.js application builds successfully in Docker
- Application starts and shows "Ready in 116ms" message
- Container exits immediately with code 0 instead of staying running
- Kubernetes readiness and liveness probes fail with HTTP 404 on `/api/health`
- Automated rollback fails due to version conflicts

**Constraints:**
- Must maintain compatibility with existing Kubernetes deployment configuration
- Must not modify core application business logic
- Must work with Microk8s registry at localhost:32000
- Must satisfy Kubernetes probe timeouts (readiness probe: 60s timeout, 10s interval)

**Stakeholders:**
- Development team: Needs reliable deployment process
- Operations team: Needs predictable container behavior
- End users: Need application availability

## Goals / Non-Goals

**Goals:**
- Add `/api/health` endpoint that returns HTTP 200 with JSON status
- Configure Next.js to run as a persistent server process in production
- Fix Kubernetes rollback mechanism to handle version conflicts
- Ensure container stays running and handles requests indefinitely

**Non-Goals:**
- Implementing advanced health checks (database connectivity, external services)
- Modifying core application features or business logic
- Changing Kubernetes cluster configuration or Microk8s setup
- Implementing monitoring or observability beyond basic health checks
- Changing deployment pipeline beyond fixing rollback mechanism

## Decisions

### Decision 1: Use Next.js API Routes for health endpoint

**Choice:** Implement `/api/health` as a Next.js API route in the `app/api/health/route.ts` file (App Router) or `pages/api/health.ts` (Pages Router).

**Rationale:**
- Next.js API routes are built-in and require no additional dependencies
- API routes run in the same process as the Next.js server, ensuring consistency
- Simple implementation with minimal code changes
- Automatically handles request/response lifecycle

**Alternatives Considered:**
- Custom Express server: Would require significant refactoring and additional dependencies
- Separate health check service: Adds complexity and operational overhead
- Next.js middleware: Not suitable for standalone endpoint responses

### Decision 2: Use Next.js standalone output for production builds

**Choice:** Configure Next.js to use standalone output mode in `next.config.ts` to create a minimal production build.

**Rationale:**
- Standalone mode produces a self-contained deployment with only necessary files
- Reduces image size and improves startup time
- Explicitly designed for containerized deployments
- Provides clear separation between development and production builds

**Alternatives Considered:**
- Default Next.js build: Includes development dependencies and larger image size
- Custom server implementation: More complex and harder to maintain
- Serverless deployment: Not applicable to Kubernetes deployment

### Decision 3: Use Node.js production mode with explicit server start

**Choice:** Configure Dockerfile to run Next.js in production mode with `NODE_ENV=production` and use `npm start` to start the server.

**Rationale:**
- Production mode enables optimizations and disables development features
- `npm start` is the standard Next.js production startup command
- Explicit production environment prevents accidental development configuration
- Aligns with Next.js best practices for containerized deployments

**Alternatives Considered:**
- Development mode: Includes debugging features and slower performance
- Custom startup script: Adds complexity without clear benefits
- Direct node command: Less maintainable and harder to understand

### Decision 4: Fix Kubernetes rollback by using resource version tracking

**Choice:** Implement rollback mechanism that retrieves current resource version before applying changes and handles conflicts gracefully.

**Rationale:**
- Kubernetes resource versions prevent race conditions during concurrent updates
- Graceful conflict handling prevents deployment pipeline failures
- Maintains deployment history and enables reliable rollbacks
- Follows Kubernetes best practices for deployment management

**Alternatives Considered:**
- Force apply changes: Risk of overwriting concurrent updates
- Ignore conflicts: Leads to unpredictable deployment behavior
- Manual rollback: Increases operational overhead and error risk

### Decision 5: Configure health check probes with appropriate timeouts

**Choice:** Set Kubernetes readiness and liveness probes with 10-second intervals, 60-second timeouts, and 3 failure thresholds.

**Rationale:**
- 10-second intervals balance responsiveness with resource usage
- 60-second timeout accommodates Next.js startup time
- 3 failure threshold prevents false positives from transient issues
- Aligns with Kubernetes best practices for web applications

**Alternatives Considered:**
- Shorter intervals: Increases cluster load and false positives
- Longer timeouts: Delays detection of actual failures
- Single failure threshold: Too sensitive to transient issues

## Risks / Trade-offs

### Risk 1: Next.js startup time may exceed probe timeout

**Risk:** Next.js application may take longer than 60 seconds to start, causing readiness probe to fail.

**Mitigation:**
- Monitor actual startup time during development and testing
- Adjust probe timeouts based on observed startup performance
- Consider implementing startup probe with longer timeout if needed
- Optimize Next.js build for faster startup (code splitting, lazy loading)

### Risk 2: Health endpoint may not detect all failure modes

**Risk:** Simple health endpoint returning HTTP 200 may not detect database connectivity issues or other dependency failures.

**Mitigation:**
- Document that current health check is minimal and basic
- Add TODO comment for future enhancement with dependency checks
- Monitor application logs for errors not caught by health check
- Consider adding separate readiness/liveness endpoints in future iterations

### Risk 3: Container may still exit unexpectedly

**Risk:** Despite production mode configuration, container may exit due to unhandled errors or exceptions.

**Mitigation:**
- Implement proper error handling in Next.js application
- Add global error handlers to prevent uncaught exceptions
- Monitor container logs for error patterns
- Implement restart policy in Kubernetes deployment configuration

### Risk 4: Rollback fix may introduce new deployment issues

**Risk:** Changes to rollback mechanism may introduce bugs or edge cases that affect deployment reliability.

**Mitigation:**
- Test rollback mechanism thoroughly in development environment
- Implement comprehensive logging for rollback operations
- Add manual rollback procedure as fallback
- Monitor deployment pipeline for issues after changes

### Trade-off 1: Simplicity vs. Comprehensive Health Checks

**Trade-off:** Current design uses minimal health check for simplicity, but this means not all failure modes are detected.

**Decision:** Prioritize simplicity and reliability over comprehensive monitoring in this iteration. Future enhancements can add dependency checks.

### Trade-off 2: Standard Next.js vs. Custom Server Configuration

**Trade-off:** Using standard Next.js configuration is simpler but may not provide all the control of a custom server.

**Decision:** Use standard Next.js configuration to maintain simplicity and leverage Next.js optimizations. Custom server can be considered if standard approach proves insufficient.

## Migration Plan

### Deployment Steps

1. **Update Next.js configuration**
   - Modify `next.config.ts` to enable standalone output mode
   - Test production build locally

2. **Add health check endpoint**
   - Create `app/api/health/route.ts` (or `pages/api/health.ts` based on router)
   - Implement endpoint returning HTTP 200 with JSON status
   - Test endpoint locally

3. **Update Dockerfile**
   - Set `NODE_ENV=production` environment variable
   - Use standalone output from Next.js build
   - Ensure `npm start` is used as CMD
   - Test container locally to verify it stays running

4. **Update Kubernetes deployment configuration**
   - Configure readiness and liveness probes for `/api/health`
   - Set appropriate timeouts and intervals
   - Test deployment in development cluster

5. **Fix rollback mechanism**
   - Update deployment script to handle resource version conflicts
   - Test rollback with intentional conflicts
   - Verify rollback restores previous deployment state

6. **Deploy to production**
   - Run updated deployment script
   - Monitor pod startup and health checks
   - Verify application is serving traffic
   - Monitor logs for errors

### Rollback Strategy

**Automatic Rollback:**
- Kubernetes will automatically rollback if deployment fails
- Rollback uses previous deployment configuration
- Monitor rollback completion and verify application health

**Manual Rollback:**
- If automatic rollback fails, manually apply previous deployment manifest:
  ```bash
  kubectl apply -f k8s/deployment.yaml.backup
  ```
- Verify pods are healthy and serving traffic
- Check logs for any issues

**Rollback Verification:**
- Confirm pods are running and not in CrashLoopBackOff
- Verify health check endpoint returns HTTP 200
- Check application logs for errors
- Test application functionality

## Open Questions

None at this time. All technical decisions have been made and documented.

## Current Task Context

## Current Task
- 1.1 Update `next.config.ts` to enable standalone output mode
