# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

health-endpoint-implementation/spec.md
## ADDED Requirements

### Requirement: Health endpoint route exists in Next.js application
The application SHALL include a Next.js API route file at `app/api/health/route.ts` that implements the health check functionality.

#### Scenario: Health endpoint route file exists
- **WHEN** the application source code is examined
- **THEN** a file exists at `app/api/health/route.ts`
- **AND** the file exports a GET request handler

### Requirement: Health endpoint returns HTTP 200 status code
The `/api/health` API route SHALL respond to HTTP GET requests with status code 200 when the application is ready to serve traffic.

#### Scenario: Health endpoint returns 200
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the API route returns HTTP status code 200
- **AND** the response Content-Type header is `application/json`

### Requirement: Health endpoint returns JSON status object
The `/api/health` API route SHALL return a JSON response body containing a `status` field set to `"healthy"`.

#### Scenario: Health endpoint returns healthy status
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the response body is valid JSON
- **AND** the JSON object contains a `status` field with value `"healthy"`

### Requirement: Health endpoint responds within timeout
The `/api/health` API route SHALL respond within 1000 milliseconds to satisfy Kubernetes readiness probe timeouts.

#### Scenario: Health endpoint responds quickly
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the API route responds within 1000 milliseconds
- **AND** the response contains HTTP status code 200
- **AND** the response body contains valid JSON with status `"healthy"`

### Requirement: Health endpoint requires no authentication
The `/api/health` API route SHALL not require authentication headers or session validation, allowing Kubernetes probes to access it without credentials.

#### Scenario: Health endpoint accessible without authentication
- **WHEN** a client sends an HTTP GET request to `/api/health` without authentication headers
- **THEN** the API route returns HTTP status code 200
- **AND** the response body contains the health status JSON object

### Requirement: Health endpoint handles request errors gracefully
The `/api/health` API route SHALL return appropriate HTTP error status codes (500 or 503) if the application is not healthy, rather than 404.

#### Scenario: Health endpoint returns error on unhealthy state
- **WHEN** the application is in an unhealthy state and cannot serve traffic
- **THEN** the API route returns HTTP status code 503 or 500
- **AND** the response body is valid JSON
- **AND** the JSON object contains a `status` field indicating the unhealthy state



## Design

## Context

### Current State

The application is a Next.js 16.1.0 application using the App Router with TypeScript. The project structure places source code in `src/app/`, including API routes at `src/app/api/`. The application is containerized and deployed to a Kubernetes cluster running inside a Multipass VM.

### Problem Analysis

**Health Endpoint Issue:**
- The `src/app/api/health/route.ts` file exists and correctly returns HTTP 200 with JSON `{"status": "healthy"}`
- Next.js build output confirms `/api/health` is compiled as a dynamic API route
- During Kubernetes deployment, pods fail readiness and liveness probes with HTTP 404 responses from `/api/health`
- Container logs show Next.js starts successfully ("Ready in 115ms") but the health endpoint is unreachable
- The 404 response is a Next.js-generated 404 page, indicating the route is not being served
- Accessing endpoint from within container returns 404, suggesting runtime/build configuration issue

**Bash Script Error:**
- `deploy-to-k8s.sh` has a syntax error on line 800: "local: can only be used in a function"
- This error prevents deployment from completing successfully
- Likely cause: `local` variable declaration is outside of a function scope

**Next.js Configuration Warning:**
- `next.config.ts` uses deprecated `experimental.serverComponentsExternalPackages`
- Build warning indicates this should be renamed to `serverExternalPackages`
- The config already has the correct `serverExternalPackages` setting (line 5), but also has the deprecated one

**Root Cause Hypotheses:**
1. **Build Configuration Issue**: The API routes may not be included in the production standalone output despite being compiled
2. **Runtime Configuration Issue**: The production server may not be configured to serve API routes from the correct location in standalone mode
3. **Standalone Output Structure**: Next.js 16 standalone build may place API routes in a location not accessible to `node server.js`
4. **Dockerfile Copy Strategy**: The Dockerfile copies `.next/standalone` but may be missing additional files needed for API routes
5. **Bash Script Syntax**: The `local` declaration on line 800 is outside of function scope due to missing brace or quote issue

### Constraints

- Cannot modify Kubernetes deployment manifest (already correctly configured)
- Cannot change probe configurations or timeouts (existing settings are appropriate)
- Must maintain backward compatibility with existing deployments
- Health endpoint must respond within 1 second to satisfy probe timeouts
- No authentication should be required for the health endpoint
- **VM Constraint**: Cluster runs inside Multipass VM, cannot access container endpoints directly from host machine
- Must test health endpoint accessibility from within VM using `multipass exec` commands
- Cannot run containers on host machine for testing (must test within VM environment)

### Stakeholders

- Development team responsible for maintaining the codebase
- DevOps team responsible for Kubernetes deployments
- Operations team responsible for monitoring and troubleshooting deployments

## Goals / Non-Goals

**Goals:**
1. Fix bash script syntax error on line 800 of `deploy-to-k8s.sh`
2. Remove deprecated Next.js configuration option to eliminate build warnings
3. Ensure the `/api/health` endpoint is accessible and returns HTTP 200 with JSON status in production
4. Verify standalone build includes API routes and makes them accessible at runtime
5. Reduce deployment log verbosity by suppressing unnecessary INFO-level debug output unless explicitly enabled
6. Maintain fast response time (< 1 second) for health check probes
7. Enable easier debugging through optional verbose mode flag

**Non-Goals:**
- Redesigning the Next.js application structure or build system
- Adding additional health checks or monitoring beyond the required endpoint
- Modifying the Kubernetes deployment manifest or probe configurations
- Implementing a new logging system (only conditional suppression of existing logs)
- Changing the API route file location or naming convention

## Decisions

### 1. Build Configuration Investigation and Fix

**Decision**: Investigate the Next.js build configuration to ensure API routes are included in the production standalone build.

**Rationale**: The health endpoint code exists and is compiled (visible in build output as `/api/health` route), but returns 404 at runtime. This suggests the standalone build may not be including API routes in the correct location for the `node server.js` runtime. Need to verify if additional files or build settings are required for API routes in standalone mode.

**Alternatives Considered:**
- Modify the health endpoint to be at the root path `/health` instead of `/api/health`
  - Rejected: Would require changing Kubernetes deployment manifest, which is out of scope
- Switch from standalone build to full build
  - Rejected: Would increase image size and deviate from current optimization approach
- Copy additional `.next` directories to container
  - May be required: Next.js standalone may need additional files for API routes
- Add custom server.js to handle API routes
  - Rejected: Should work with default Next.js standalone server

### 2. Runtime Server Configuration Verification

**Decision**: Verify that the Next.js production server is configured to serve API routes from the correct directory structure.

**Rationale**: In the standalone build mode, Next.js may serve static files from a different location than API routes. The server startup configuration needs to correctly map API routes to the standalone output structure.

**Alternatives Considered:**
- Custom server implementation
  - Rejected: Over-engineering; Next.js default server should work with correct config
- Reverse proxy to route requests
  - Rejected: Adds complexity and potential failure points

### 3. Conditional Logging Implementation

**Decision**: Implement a VERBOSE environment variable check to suppress debug output in deployment scripts.

**Rationale**: Current deployment logs contain excessive INFO-level messages that clutter output and obscure actual errors. Adding a VERBOSE flag allows operators to get detailed debugging information when needed while keeping normal deployments clean.

**Implementation Approach**:
- Default: Suppress INFO-level debug messages, only show ERROR and WARN
- When `VERBOSE=true`: Show all log levels including INFO and DEBUG
- Apply to all deployment scripts in `deploy_scripts/` directory

**Alternatives Considered:**
- Always show all logs
  - Rejected: Defeats the purpose of cleaner logs; hard to find actual errors
- Never show debug information
  - Rejected: Makes troubleshooting difficult when issues occur
- Separate log levels for different scripts
  - Rejected: Inconsistent behavior; confusing for operators

### 4. Health Endpoint File Location

**Decision**: Keep the health endpoint at `src/app/api/health/route.ts` and fix the build/runtime configuration to serve it correctly.

**Rationale**: The file is already in the correct location for Next.js App Router. Moving it would deviate from best practices and is not necessary. The issue is likely in how the application is being built or served.

**Alternatives Considered:**
- Move to root of `/api/health/route.ts`
  - Rejected: Next.js App Router expects routes under `src/app/` directory
- Convert to server component
  - Rejected: API routes in App Router are always server components; current implementation is correct

## Risks / Trade-offs

### Risk: Build configuration changes may break existing deployments
**Mitigation**: Test build process locally before deploying to production. Verify that the Docker image includes all necessary files and that the application starts correctly. Maintain previous Docker image tags for rollback capability.

### Risk: Fixing bash script may introduce new syntax errors
**Mitigation**: Use shellcheck or similar tool to validate bash syntax before deploying. Test script locally with dry-run flags.

### Risk: Removing Next.js config option may break standalone build
**Mitigation**: Test build after removing deprecated option. Verify API routes still compile and are included in standalone output.

### Risk: Suppressing logs may hide useful debugging information
**Mitigation**: Keep VERBOSE flag easily accessible and documented. Ensure ERROR and WARN level messages always appear. Update documentation to explain when to use verbose mode.

### Risk: Health endpoint may still not be accessible after configuration fixes
**Mitigation**: Add manual verification steps during deployment to test the endpoint from inside the container. Consider adding a startup probe that waits longer before checking readiness.

### Risk: Conditional logging implementation may introduce bugs in error handling
**Mitigation**: Thoroughly test deployment scripts with both VERBOSE=true and VERBOSE=false scenarios. Ensure error handling paths are not affected by logging changes.

### Trade-off: Complexity vs. maintainability
Adding conditional logging increases script complexity slightly, but significantly improves operational maintainability by making logs easier to read.

## Migration Plan

### Phase 1: Investigation and Diagnosis
1. Fix bash script syntax error on line 800 of `deploy-to-k8s.sh`
2. Remove deprecated Next.js configuration option from `next.config.ts`
3. Examine the Dockerfile to understand build configuration and standalone output structure
4. Check the Next.js configuration files (next.config.js/ts) for API route settings
5. Inspect the built Docker image filesystem to verify API routes are included in standalone output
6. Test the application locally with production build settings to verify standalone server works
7. Test health endpoint from within VM container using `multipass exec` commands

### Phase 2: Implementation
1. Fix bash script syntax error on line 800 of `deploy-to-k8s.sh`
2. Remove deprecated Next.js configuration option from `next.config.ts`
3. Verify and potentially modify Dockerfile to ensure `.next/server` directory is copied if needed for API routes
4. Modify build configuration if needed to include API routes in standalone output
5. Update deployment scripts to respect VERBOSE environment variable
6. Test the updated build process and verify health endpoint accessibility
7. Test health endpoint from within VM container using `multipass exec` commands
8. Deploy to test environment and verify probes pass

### Phase 3: Validation
1. Run deployment with VERBOSE=false to confirm clean log output
2. Run deployment with VERBOSE=true to verify detailed logging still works
3. Verify health endpoint responds within 1 second timeout
4. Confirm pods reach Ready state and can serve traffic

### Rollback Strategy
- If health endpoint still fails after fixes, revert to previous working state
- Maintain previous Docker image tags for rollback capability
- Kubernetes deployment already has rolling update strategy, allowing automatic rollback if pods fail

## Open Questions

1. What is the exact configuration causing the health endpoint to return 404 in production builds?
2. Are there any Next.js configuration files (next.config.js/ts) that need to be modified?
3. Does the standalone build mode require special handling for API routes?
4. What specific deployment scripts need VERBOSE flag implementation?
5. Should the health endpoint include additional diagnostics (version, dependencies, etc.) or keep it minimal?

## Current Task Context

## Current Task
- 1.1 Investigate bash script syntax error on line 800 of deploy-to-k8s.sh
