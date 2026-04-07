## Context

### Current State

The application is a Next.js 16.1.0 application using the App Router with TypeScript. The project structure places source code in `src/app/`, including API routes at `src/app/api/`. The application is containerized and deployed to a Kubernetes cluster running inside a Multipass VM.

### Problem Analysis

**Health Endpoint Issue:**
- The `src/app/api/health/route.ts` file exists and correctly returns HTTP 200 with JSON `{"status": "healthy"}`
- During Kubernetes deployment, pods fail readiness and liveness probes with HTTP 404 responses from `/api/health`
- Container logs show Next.js starts successfully ("Ready in 115ms") but the health endpoint is unreachable
- The 404 response is a Next.js-generated 404 page, indicating the route is not being served

**Root Cause Hypotheses:**
1. **Build Configuration Issue**: The API routes may not be included in the production build or standalone output
2. **Runtime Configuration Issue**: The production server may not be configured to serve API routes from the correct location
3. **Path Mismatch**: The health check probes may be hitting the wrong path (missing `/api` prefix)
4. **Container Filesystem Mismatch**: The built application structure may not match the expected file layout

### Constraints

- Cannot modify Kubernetes deployment manifest (already correctly configured)
- Cannot change probe configurations or timeouts (existing settings are appropriate)
- Must maintain backward compatibility with existing deployments
- Health endpoint must respond within 1 second to satisfy probe timeouts
- No authentication should be required for the health endpoint

### Stakeholders

- Development team responsible for maintaining the codebase
- DevOps team responsible for Kubernetes deployments
- Operations team responsible for monitoring and troubleshooting deployments

## Goals / Non-Goals

**Goals:**
1. Ensure the `/api/health` endpoint is accessible and returns HTTP 200 with JSON status in production
2. Reduce deployment log verbosity by suppressing unnecessary INFO-level debug output unless explicitly enabled
3. Maintain fast response time (< 1 second) for health check probes
4. Enable easier debugging through optional verbose mode flag

**Non-Goals:**
- Redesigning the Next.js application structure or build system
- Adding additional health checks or monitoring beyond the required endpoint
- Modifying the Kubernetes deployment manifest or probe configurations
- Implementing a new logging system (only conditional suppression of existing logs)
- Changing the API route file location or naming convention

## Decisions

### 1. Build Configuration Investigation and Fix

**Decision**: Investigate the Next.js build configuration to ensure API routes are included in the production standalone build.

**Rationale**: The health endpoint code exists but is not reachable at runtime. This suggests a build or runtime configuration issue where API routes are not being properly packaged or served. The Dockerfile uses Next.js standalone output mode, which requires specific configuration to include API routes.

**Alternatives Considered:**
- Modify the health endpoint to be at the root path `/health` instead of `/api/health`
  - Rejected: Would require changing Kubernetes deployment manifest, which is out of scope
- Switch from standalone build to full build
  - Rejected: Would increase image size and deviate from current optimization approach
- Add serverless/cloud functions for health endpoint
  - Rejected: Adds unnecessary complexity and dependencies

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
**Mitigation**: Test build process locally before deploying to production. Verify that the Docker image includes all necessary files and that the application starts correctly.

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
1. Examine the Dockerfile to understand build configuration
2. Check the Next.js configuration files (next.config.js/ts)
3. Inspect the built Docker image filesystem to verify API routes are included
4. Test the application locally with production build settings

### Phase 2: Implementation
1. Modify build configuration if needed to include API routes in standalone output
2. Update deployment scripts to respect VERBOSE environment variable
3. Test the updated build process and verify health endpoint accessibility
4. Deploy to test environment and verify probes pass

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
