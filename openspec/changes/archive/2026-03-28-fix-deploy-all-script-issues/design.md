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
