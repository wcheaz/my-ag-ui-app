# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The deploy-all.sh script has critical failures that prevent successful Kubernetes deployment: secrets setup fails but continues execution, pods fail health checks with HTTP 404 errors, containers terminate immediately instead of staying running, and image verification fails. These issues cause deployments to fail and require manual intervention, blocking reliable automated deployments.

## What Changes

- **BREAKING**: Fix Kubernetes secrets setup to halt deployment on validation failure instead of continuing with invalid configuration
- Add proper error handling and exit codes for all deploy script steps
- Fix container health check endpoint configuration to ensure /api/health is properly accessible
- Add container startup verification to ensure application runs continuously instead of completing
- Improve image verification logic to handle registry catalog delays and provide accurate status
- Add comprehensive logging and error reporting for debugging deployment failures
- Implement proper rollback procedures when deployment steps fail

## Capabilities

### New Capabilities
- `deploy-error-handling`: Robust error handling and validation for all deployment steps with proper exit codes and failure recovery
- `container-health-checking`: Proper configuration of liveness and readiness probes with correct endpoint paths and response handling
- `deployment-verification`: Multi-step verification including image registry validation, secrets validation, and pod startup verification
- `deploy-logging`: Comprehensive logging infrastructure for deployment pipeline with structured error messages and debugging information

### Modified Capabilities
- None (this is a new deployment capability fixing fundamental issues)

## Impact

- **Affected Scripts**: deploy-all.sh, deploy_scripts/setup-k8s-secrets.sh, deploy_scripts/deploy-to-k8s.sh, deploy_scripts/push-docker-image.sh
- **Affected Configuration**: k8s/deployment.yaml (health check configuration), k8s/setup-secrets.sh (validation logic)
- **Dependencies**: No new dependencies required
- **Systems**: Kubernetes deployment pipeline, Microk8s registry, Docker image build and push workflow
- **Development Workflow**: Will enable reliable automated deployments through ralph-loops with proper error handling and rollback capabilities

## Specifications

container-health-checking/spec.md
## ADDED Requirements

### Requirement: Health check endpoint responds with HTTP 200
The application container SHALL respond to HTTP GET requests on /api/health endpoint with status code 200 when the application is ready to serve traffic.

#### Scenario: Health check returns 200 when application is ready
- **WHEN** Kubernetes liveness probe sends GET request to /api/health
- **THEN** application returns HTTP status 200
- **AND** response includes application status

#### Scenario: Health check returns 200 when application is starting
- **WHEN** Kubernetes readiness probe sends GET request to /api/health during application startup
- **THEN** application returns HTTP status 200 once ready
- **AND** application is marked as ready for traffic

### Requirement: Container runs continuously as a service
The application container SHALL run as a long-running service and not terminate after initialization, ensuring continuous availability.

#### Scenario: Container remains running after startup
- **WHEN** application container starts
- **THEN** container process runs continuously
- **AND** container does not exit with code 0
- **AND** container responds to health checks

### Requirement: Liveness probe detects application crashes
The Kubernetes liveness probe SHALL detect when the application has crashed or become unresponsive and trigger a container restart.

#### Scenario: Liveness probe triggers restart on failure
- **WHEN** liveness probe fails 3 consecutive times
- **THEN** Kubernetes restarts the container
- **AND** new container instance is created
- **AND** restart count is incremented

### Requirement: Readiness probe prevents traffic to unready containers
The Kubernetes readiness probe SHALL prevent traffic from being routed to containers that are not yet ready to serve requests.

#### Scenario: Readiness probe marks container as ready
- **WHEN** readiness probe succeeds for the first time
- **THEN** container is marked as ready
- **AND** traffic is routed to the container
- **AND** Kubernetes service includes the container in load balancing

#### Scenario: Readiness probe withholds traffic during startup
- **WHEN** container is starting and readiness probe has not yet succeeded
- **THEN** container is marked as not ready
- **AND** no traffic is routed to the container
- **AND** Kubernetes service excludes the container from load balancing

### Requirement: Health check endpoint path is configurable
The health check endpoint path SHALL be configurable through environment variables to support different application configurations.

#### Scenario: Health check path configured via environment variable
- **WHEN** HEALTH_CHECK_PATH environment variable is set to /custom/health
- **THEN** Kubernetes probes use /custom/health endpoint
- **AND** application responds to health checks at configured path

deploy-error-handling/spec.md
## ADDED Requirements

### Requirement: Deployment pipeline halts on secrets validation failure
The deployment pipeline SHALL immediately halt execution and return a non-zero exit code when Kubernetes secrets setup fails validation, preventing deployment with invalid configuration.

#### Scenario: Secrets validation failure stops deployment
- **WHEN** setup-k8s-secrets.sh detects invalid generated YAML file
- **THEN** script exits with error code 1
- **AND** deployment-all.sh stops execution
- **AND** error message is displayed indicating secrets validation failure

### Requirement: All deployment steps return proper exit codes
Each deployment script step SHALL return exit code 0 on success and non-zero on failure, enabling proper error propagation through the deployment pipeline.

#### Scenario: Successful deployment step returns exit code 0
- **WHEN** a deployment script step completes successfully
- **THEN** script returns exit code 0
- **AND** next deployment step executes

#### Scenario: Failed deployment step returns non-zero exit code
- **WHEN** a deployment script step encounters an error
- **THEN** script returns exit code 1 or higher
- **AND** deployment-all.sh stops execution
- **AND** error is logged with step name and failure reason

### Requirement: Deployment pipeline implements rollback on failure
When any deployment step fails after making changes, the pipeline SHALL attempt to rollback to the previous stable state to minimize downtime and system instability.

#### Scenario: Rollback after deployment failure
- **WHEN** a deployment step fails after modifying resources
- **THEN** pipeline executes rollback procedure
- **AND** attempts to restore previous stable deployment
- **AND** logs rollback status and any errors

### Requirement: Error messages provide actionable guidance
All deployment error messages SHALL include the specific step that failed, the error type, and recommended recovery steps to enable quick resolution.

#### Scenario: Error message includes actionable guidance
- **WHEN** a deployment step fails
- **THEN** error message displays step name
- **AND** error message includes error type
- **AND** error message provides 1-3 specific recovery steps

deploy-logging/spec.md
## ADDED Requirements

### Requirement: Deployment steps log start and completion
Each deployment step SHALL log a clear start message and completion message with timestamp to enable tracking of deployment progress.

#### Scenario: Step logs start and completion
- **WHEN** a deployment step begins
- **THEN** step logs "Starting <step-name>..." with timestamp
- **AND** step logs "✅ <step-name> completed successfully" with timestamp on success
- **AND** step logs "❌ <step-name> failed" with timestamp on failure

### Requirement: Errors are logged with structured format
All deployment errors SHALL be logged in a structured format including error type, diagnostic information, common causes, and recovery steps.

#### Scenario: Error logged with structured format
- **WHEN** a deployment error occurs
- **THEN** error log includes ERROR TYPE field
- **AND** error log includes DIAGNOSTIC field
- **AND** error log includes COMMON CAUSES list
- **AND** error log includes RECOVERY steps

### Requirement: Pod events are captured for debugging
The deployment pipeline SHALL capture and log Kubernetes pod events including pull errors, crash loops, and probe failures to aid in troubleshooting.

#### Scenario: Pod events logged during deployment
- **WHEN** pod status is checked
- **THEN** script captures pod events
- **AND** script logs warning events
- **AND** script logs error events
- **AND** script logs normal events for context

### Requirement: Deployment logs include environment context
Deployment logs SHALL include relevant environment context such as Kubernetes cluster status, registry status, and current deployment state to aid in debugging.

#### Scenario: Environment context logged
- **WHEN** deployment begins
- **THEN** log includes Kubernetes cluster accessibility status
- **AND** log includes registry connectivity status
- **AND** log includes current deployment state (new/update)
- **AND** log includes namespace information

### Requirement: Verbose mode provides detailed debugging output
The deployment pipeline SHALL support a verbose mode that outputs detailed debugging information including command outputs, intermediate states, and validation results.

#### Scenario: Verbose mode enabled
- **WHEN** VERBOSE=true environment variable is set
- **THEN** deployment outputs full command execution details
- **AND** deployment outputs validation results
- **AND** deployment outputs intermediate states
- **AND** deployment outputs detailed error information

### Requirement: Logs are written to file with rotation
Deployment logs SHALL be written to a timestamped log file with automatic rotation to prevent disk space exhaustion.

#### Scenario: Log file created with timestamp
- **WHEN** deployment begins
- **THEN** log file is created with timestamp in filename
- **AND** all deployment output is written to log file
- **AND** log file location is displayed to user

#### Scenario: Log rotation prevents disk exhaustion
- **WHEN** log file size exceeds 100MB
- **THEN** log file is rotated
- **AND** old log files are compressed
- **AND** only last 10 log files are retained

### Requirement: Deployment summary is logged at completion
The deployment pipeline SHALL log a summary at completion showing which steps succeeded, which failed, and overall deployment status.

#### Scenario: Successful deployment summary
- **WHEN** deployment completes successfully
- **THEN** summary logs all steps as completed
- **AND** summary logs overall status as SUCCESS
- **AND** summary logs total duration

#### Scenario: Failed deployment summary
- **WHEN** deployment fails
- **THEN** summary logs failed step
- **AND** summary logs overall status as FAILED
- **AND** summary logs error details
- **AND** summary logs steps completed before failure

deployment-verification/spec.md
## ADDED Requirements

### Requirement: Kubernetes secrets YAML is validated before application
The setup-k8s-secrets.sh script SHALL validate the generated secrets.yaml file using kubectl apply --dry-run=server before attempting to apply it to the cluster.

#### Scenario: Secrets validation passes with valid YAML
- **WHEN** secrets.yaml is generated with valid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server succeeds
- **AND** script proceeds to apply secrets
- **AND** secrets are applied to cluster

#### Scenario: Secrets validation fails with invalid YAML
- **WHEN** secrets.yaml contains invalid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server fails
- **AND** script exits with error code 1
- **AND** error message indicates validation failure
- **AND** deployment stops

### Requirement: Image registry verification handles catalog delays
The push-docker-image.sh script SHALL implement retry logic with exponential backoff when verifying image presence in registry catalog, accounting for catalog update delays.

#### Scenario: Image verification succeeds after retry
- **WHEN** image is pushed to registry but not yet in catalog
- **THEN** verification retries with exponential backoff
- **AND** verification succeeds after catalog updates
- **AND** deployment proceeds

#### Scenario: Image verification fails after maximum retries
- **WHEN** image verification fails after maximum retry attempts
- **THEN** script logs verification failure
- **AND** script exits with error code 1
- **AND** deployment stops
- **AND** error message includes manual verification steps

### Requirement: Pod startup is verified before marking deployment successful
The deploy-to-k8s.sh script SHALL verify that pods reach Running state and pass readiness checks before marking deployment as successful.

#### Scenario: Pod reaches Running state successfully
- **WHEN** deployment is applied
- **THEN** script polls pod status every 5 seconds
- **AND** script waits up to 5 minutes for Running state
- **AND** script verifies readiness probe passes
- **AND** deployment is marked successful

#### Scenario: Pod fails to reach Running state
- **WHEN** pod does not reach Running state within timeout
- **THEN** script logs pod status and events
- **AND** script exits with error code 1
- **AND** error message includes pod details and failure reason
- **AND** deployment stops

### Requirement: Deployment manifest is validated before application
The deploy-to-k8s.sh script SHALL validate the deployment.yaml manifest using kubectl apply --dry-run=server before applying it to the cluster.

#### Scenario: Manifest validation passes
- **WHEN** deployment.yaml contains valid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server succeeds
- **AND** script proceeds to apply deployment
- **AND** deployment is applied to cluster

#### Scenario: Manifest validation fails
- **WHEN** deployment.yaml contains invalid Kubernetes configuration
- **THEN** kubectl apply --dry-run=server fails
- **AND** script exits with error code 1
- **AND** error message indicates validation failure
- **AND** deployment stops

### Requirement: Registry connectivity is verified before image operations
The deployment pipeline SHALL verify that the Microk8s registry is accessible and responding before attempting to push or pull images.

#### Scenario: Registry connectivity verified successfully
- **WHEN** registry is accessible at localhost:32000
- **THEN** curl request to registry succeeds
- **AND** registry returns valid JSON response
- **AND** deployment proceeds with image operations

#### Scenario: Registry connectivity fails
- **WHEN** registry is not accessible
- **THEN** curl request to registry fails
- **AND** script exits with error code 1
- **AND** error message indicates registry connectivity failure
- **AND** deployment stops



## Design

## Context

The current deployment pipeline (deploy-all.sh) orchestrates multiple scripts to build, tag, push, and deploy a Docker containerized application to a Microk8s Kubernetes cluster. The pipeline consists of 6 main steps:

1. Setting up Kubernetes secrets (k8s/setup-secrets.sh)
2. Building Docker image (deploy_scripts/build-docker-image.sh)
3. Tagging Docker image (deploy_scripts/tag-docker-image.sh)
4. Setting up Microk8s registry (deploy_scripts/setup-microk8s-registry.sh)
5. Pushing Docker image (deploy_scripts/push-docker-image.sh)
6. Deploying to Kubernetes (deploy_scripts/deploy-to-k8s.sh)

**Current State Issues:**
- Secrets setup fails validation but continues execution (line 22-32 in deploy_log.md)
- Pods fail health checks with HTTP 404 on /api/health endpoint
- Containers terminate with exit code 0 instead of running continuously
- Image verification fails due to registry catalog delays
- No proper error handling or rollback mechanisms
- Insufficient logging for debugging deployment failures

**Constraints:**
- Deployment must work within Multipass VM environment
- Must use Microk8s local registry at localhost:32000
- Must support ralph-loops development workflow
- Cannot introduce new external dependencies
- Must maintain backward compatibility with existing deployment configuration

**Stakeholders:**
- Development team using ralph-loops for iterative development
- Operations team managing production deployments
- QA team requiring reliable deployment verification

## Goals / Non-Goals

**Goals:**
- Implement robust error handling with proper exit codes for all deployment steps
- Fix Kubernetes secrets validation to halt deployment on failure
- Ensure containers run continuously and respond to health checks
- Implement comprehensive verification at each deployment stage
- Add structured logging with actionable error messages
- Support rollback on deployment failures
- Enable reliable automated deployments through ralph-loops

**Non-Goals:**
- Changing the application code (only deployment infrastructure)
- Modifying the Kubernetes cluster configuration beyond deployment manifests
- Introducing new deployment tools or frameworks
- Changing the deployment architecture (still using Docker + Microk8s)
- Implementing advanced monitoring or observability (beyond deployment logs)

## Decisions

### 1. Error Handling Strategy

**Decision:** Implement strict error handling with `set -euo pipefail` and explicit exit codes for all scripts.

**Rationale:**
- `set -e` exits immediately on command failure
- `set -u` exits on undefined variable usage
- `set -o pipefail` catches errors in pipelines
- Explicit exit codes (0=success, 1=failure) enable proper error propagation
- This pattern is shell scripting best practice and ensures failures are not silently ignored

**Alternatives Considered:**
- Continue on error with warnings: Rejected because it leads to partial deployments
- Custom error handling framework: Rejected due to complexity and maintenance overhead
- Use error handling library: Rejected to avoid external dependencies

### 2. Secrets Validation Approach

**Decision:** Use `kubectl apply --dry-run=server` to validate secrets YAML before applying.

**Rationale:**
- Validates against actual Kubernetes API server
- Catches syntax errors, missing required fields, and invalid configurations
- Non-destructive (doesn't modify cluster state)
- Built-in Kubernetes tooling with no dependencies
- Provides clear error messages for debugging

**Alternatives Considered:**
- YAML syntax validation only: Rejected because it doesn't validate Kubernetes schema
- Apply and rollback on error: Rejected because it risks partial state changes
- Custom validation logic: Rejected due to complexity and potential for bugs

### 3. Health Check Endpoint Configuration

**Decision:** Ensure application exposes /api/health endpoint and configure Kubernetes probes with appropriate timeouts and intervals.

**Rationale:**
- /api/health is standard convention for health check endpoints
- Kubernetes probes are built-in and well-tested
- Proper timeouts prevent false positives from slow startups
- Separate liveness and readiness probes enable different failure handling

**Alternatives Considered:**
- Use TCP socket probe: Rejected because it doesn't verify application health
- Use exec probe: Rejected because it requires shell access in container
- Disable health checks: Rejected because it prevents detecting application failures

### 4. Container Startup Verification

**Decision:** Verify container runs continuously by checking it doesn't exit with code 0 and responds to health checks.

**Rationale:**
- Exit code 0 indicates normal termination, not a service
- Health check response confirms application is ready
- Prevents CrashLoopBackOff from containers that terminate immediately
- Enables detection of application startup issues

**Alternatives Considered:**
- Ignore exit code: Rejected because it masks fundamental application issues
- Use sleep command to keep container running: Rejected because it's a workaround, not a fix
- Modify application to run as daemon: Rejected because it's out of scope (infrastructure-only change)

### 5. Image Verification with Retry Logic

**Decision:** Implement exponential backoff retry when verifying image in registry catalog.

**Rationale:**
- Registry catalog updates are asynchronous and may have delays
- Exponential backoff reduces load on registry during delays
- Maximum retry limit prevents indefinite waiting
- Provides clear error message if verification ultimately fails
- Balances reliability with deployment speed

**Alternatives Considered:**
- Single verification attempt: Rejected because it fails due to catalog delays
- Fixed interval retry: Rejected because it's less efficient than exponential backoff
- Skip verification: Rejected because it risks deploying non-existent images

### 6. Logging Infrastructure

**Decision:** Implement structured logging with timestamps, log levels, and output to both console and timestamped log files.

**Rationale:**
- Structured logs enable programmatic parsing and analysis
- Timestamps enable timeline reconstruction for debugging
- Log levels (INFO, WARNING, ERROR) enable filtering
- Dual output (console + file) supports both interactive and automated use
- Timestamped log files enable historical analysis

**Alternatives Considered:**
- Console-only logging: Rejected because it doesn't persist for debugging
- File-only logging: Rejected because it doesn't provide real-time feedback
- Use logging framework: Rejected to avoid external dependencies

### 7. Rollback Strategy

**Decision:** Implement rollback by reapplying previous deployment manifest and restoring previous image tag.

**Rationale:**
- Kubernetes deployment resources support rolling updates
- Reapplying previous manifest triggers rollback
- Previous image tag is known from deployment history
- Minimal downtime with rolling update strategy
- No need for complex rollback infrastructure

**Alternatives Considered:**
- Delete and recreate deployment: Rejected because it causes downtime
- Use Helm rollback: Rejected because it introduces new dependency
- Manual rollback procedure: Rejected because it's error-prone and slow

## Risks / Trade-offs

### Risk 1: Increased Deployment Time Due to Verification Steps
**Risk:** Adding validation and verification steps will increase deployment time.

**Mitigation:**
- Use parallel verification where possible (e.g., registry connectivity and catalog check)
- Optimize retry intervals to balance speed and reliability
- Provide progress indicators to show verification is active
- Cache validation results when appropriate (e.g., secrets that haven't changed)

### Risk 2: False Positives in Health Checks
**Risk:** Health checks may fail due to temporary issues, causing unnecessary restarts.

**Mitigation:**
- Configure appropriate failure thresholds (3 consecutive failures)
- Set reasonable timeouts and intervals for probes
- Add startup probe to handle slow initializations
- Log health check failures for debugging

### Risk 3: Registry Catalog Delays Cause Verification Failures
**Risk:** Registry catalog may take longer than expected to update, causing verification to fail.

**Mitigation:**
- Implement exponential backoff with maximum retry limit
- Provide manual verification steps in error message
- Allow skipping verification with environment variable for advanced users
- Monitor and adjust retry parameters based on actual registry behavior

### Risk 4: Rollback May Fail If Previous State is Unavailable
**Risk:** Rollback may fail if previous deployment manifest or image is unavailable.

**Mitigation:**
- Archive previous deployment manifests with timestamps
- Keep previous image tags in registry (implement retention policy)
- Document manual rollback procedure as fallback
- Test rollback procedure regularly

### Risk 5: Increased Script Complexity
**Risk:** Adding error handling, validation, and logging increases script complexity and maintenance burden.

**Mitigation:**
- Extract common functions into shared library (deploy_scripts/common.sh)
- Add comprehensive comments and documentation
- Implement unit tests for critical functions
- Follow consistent patterns across all scripts

### Trade-off: Strict Error Handling vs. Flexibility
**Trade-off:** Strict error handling (`set -euo pipefail`) may cause deployments to fail for minor issues that could be ignored.

**Decision:** Prioritize strict error handling for reliability over flexibility. Minor issues should be fixed rather than ignored.

### Trade-off: Verification Time vs. Deployment Speed
**Trade-off:** Comprehensive verification increases deployment time but improves reliability.

**Decision:** Prioritize reliability over speed. Failed deployments are more costly than slightly slower deployments.

## Migration Plan

### Phase 1: Prepare Rollback Capability
1. Archive current deployment manifest as `k8s/deployment.yaml.backup`
2. Document current image tag and deployment state
3. Test rollback procedure manually

### Phase 2: Update Individual Scripts (in order)
1. Update `deploy_scripts/common.sh` with error handling and logging functions
2. Update `deploy_scripts/setup-k8s-secrets.sh` with validation
3. Update `deploy_scripts/build-docker-image.sh` with error handling
4. Update `deploy_scripts/tag-docker-image.sh` with error handling
5. Update `deploy_scripts/setup-microk8s-registry.sh` with verification
6. Update `deploy_scripts/push-docker-image.sh` with retry logic
7. Update `deploy_scripts/deploy-to-k8s.sh` with pod verification

### Phase 3: Update Main Script
1. Update `deploy-all.sh` to use new error handling
2. Add rollback capability
3. Update logging configuration

### Phase 4: Test Deployment
1. Test full deployment in development environment
2. Verify error handling with intentional failures
3. Test rollback procedure
4. Monitor logs and adjust parameters as needed

### Phase 5: Deploy to Production
1. Deploy during maintenance window
2. Monitor deployment closely
3. Verify health checks and pod status
4. Document any issues and adjustments

### Rollback Strategy
If deployment fails or causes issues:
1. Stop deployment pipeline
2. Reapply `k8s/deployment.yaml.backup` using `kubectl apply -f`
3. Restart deployment with previous image tag
4. Verify pods reach Running state
5. If rollback fails, follow manual rollback procedure in ROLLBACK_PROCEDURE.md

## Open Questions

1. **Health Check Endpoint Path:** Should the health check endpoint path be configurable via environment variable, or should we enforce `/api/health` as the standard?
   - **Decision:** Make it configurable via `HEALTH_CHECK_PATH` environment variable with `/api/health` as default

2. **Image Retention Policy:** How many previous image versions should be retained in the registry?
   - **Decision:** Retain last 5 versions to balance storage and rollback capability

3. **Log Retention:** How long should deployment log files be retained?
   - **Decision:** Retain logs for 30 days with automatic cleanup of older files

4. **Verification Timeout:** What is the maximum acceptable timeout for image verification?
   - **Decision:** 5 minutes with exponential backoff (1s, 2s, 4s, 8s, 16s, 32s, 64s)

5. **Health Check Intervals:** What are the optimal intervals for liveness and readiness probes?
   - **Decision:** Liveness: 10s interval, 30s initial delay; Readiness: 5s interval, 5s initial delay

## Current Task Context

## Current Task
- 1.1 Archive current deployment manifest as `k8s/deployment.yaml.backup`
