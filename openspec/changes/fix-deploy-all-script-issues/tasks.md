## 1. Preparation and Rollback Setup

- [x] 1.1 Archive current deployment manifest as `k8s/deployment.yaml.backup`
- [x] 1.2 Document current image tag and deployment state in `openspec/changes/fix-deploy-all-script-issues/DEPLOYMENT_STATE.md`
- [x] 1.3 Test manual rollback procedure by reapplying backup manifest
- [x] 1.4 Verify rollback procedure restores pods to Running state

## 2. Common Infrastructure

- [x] 2.1 Add `set -euo pipefail` to `deploy_scripts/common.sh` for strict error handling
- [x] 2.2 Implement `log_info()` function in `deploy_scripts/common.sh` with timestamp and INFO level
- [x] 2.3 Implement `log_warning()` function in `deploy_scripts/common.sh` with timestamp and WARNING level
- [x] 2.4 Implement `log_error()` function in `deploy_scripts/common.sh` with timestamp and ERROR level
- [x] 2.5 Implement `log_structured_error()` function in `deploy_scripts/common.sh` with ERROR TYPE, DIAGNOSTIC, COMMON CAUSES, and RECOVERY fields
- [x] 2.6 Implement `setup_log_file()` function in `deploy_scripts/common.sh` to create timestamped log file
- [x] 2.7 Implement `cleanup_old_logs()` function in `deploy_scripts/common.sh` to rotate logs older than 100MB
- [x] 2.8 Implement `verify_command()` function in `deploy_scripts/common.sh` to check command exit code and log errors
- [x] 2.9 Add `HEALTH_CHECK_PATH` environment variable support with default `/api/health` to `deploy_scripts/common.sh`

## 3. Secrets Setup Script Updates

- [x] 3.1 Add error handling functions import to `deploy_scripts/setup-k8s-secrets.sh`
- [x] 3.2 Implement secrets YAML validation using `kubectl apply --dry-run=server` before applying
- [x] 3.3 Add exit code 1 on validation failure with structured error message
- [x] 3.4 Add logging for secrets setup start and completion with timestamps
- [x] 3.5 Add detailed error message with recovery steps when validation fails
- [x] 3.6 Test secrets validation with invalid YAML to verify error handling
- [x] 3.7 Test secrets validation with valid YAML to verify successful application

## 4. Docker Build Script Updates

- [x] 4.1 Add error handling functions import to `deploy_scripts/build-docker-image.sh`
- [x] 4.2 Add logging for build start and completion with timestamps
- [x] 4.3 Add exit code 1 on build failure with error details
- [ ] 4.4 Log build output on success and failure for debugging
- [ ] 4.5 Test build failure scenario to verify error handling

## 5. Docker Tag Script Updates

- [ ] 5.1 Add error handling functions import to `deploy_scripts/tag-docker-image.sh`
- [ ] 5.2 Add logging for tagging start and completion with timestamps
- [ ] 5.3 Add exit code 1 on tagging failure with error details
- [ ] 5.4 Verify tagged image exists after successful tagging
- [ ] 5.5 Test tagging failure scenario to verify error handling

## 6. Microk8s Registry Setup Script Updates

- [ ] 6.1 Add error handling functions import to `deploy_scripts/setup-microk8s-registry.sh`
- [ ] 6.2 Implement registry connectivity verification using `curl` before enabling registry
- [ ] 6.3 Add logging for registry setup start and completion with timestamps
- [ ] 6.4 Add exit code 1 on registry setup failure with error details
- [ ] 6.5 Verify registry returns valid JSON response on connectivity check
- [ ] 6.6 Test registry connectivity failure scenario to verify error handling

## 7. Docker Push Script Updates

- [ ] 7.1 Add error handling functions import to `deploy_scripts/push-docker-image.sh`
- [ ] 7.2 Implement image verification with exponential backoff retry logic (1s, 2s, 4s, 8s, 16s, 32s, 64s)
- [ ] 7.3 Add maximum retry limit of 7 attempts for image verification
- [ ] 7.4 Add logging for push start and completion with timestamps
- [ ] 7.5 Add exit code 1 on push failure or verification timeout with error details
- [ ] 7.6 Provide manual verification steps in error message when verification fails
- [ ] 7.7 Test image verification with registry catalog delays to verify retry logic
- [ ] 7.8 Test push failure scenario to verify error handling

## 8. Kubernetes Deployment Script Updates

- [ ] 8.1 Add error handling functions import to `deploy_scripts/deploy-to-k8s.sh`
- [ ] 8.2 Implement deployment manifest validation using `kubectl apply --dry-run=server` before applying
- [ ] 8.3 Add pod status polling every 5 seconds with 5-minute timeout for Running state
- [ ] 8.4 Verify readiness probe passes before marking deployment successful
- [ ] 8.5 Capture and log Kubernetes pod events (pull errors, crash loops, probe failures)
- [ ] 8.6 Add logging for deployment start and completion with timestamps
- [ ] 8.7 Add exit code 1 on deployment failure with pod details and error reason
- [ ] 8.8 Test manifest validation with invalid YAML to verify error handling
- [ ] 8.9 Test pod startup verification with successful deployment
- [ ] 8.10 Test pod startup failure scenario to verify error handling and logging

## 9. Health Check Configuration

- [ ] 9.1 Verify application exposes `/api/health` endpoint that returns HTTP 200
- [ ] 9.2 Review `k8s/deployment.yaml` health check configuration
- [ ] 9.3 Update liveness probe configuration: 10s interval, 30s initial delay, 3 failure threshold
- [ ] 9.4 Update readiness probe configuration: 5s interval, 5s initial delay, 3 failure threshold
- [ ] 9.5 Add `HEALTH_CHECK_PATH` environment variable support to deployment manifest
- [ ] 9.6 Test health checks with application running to verify HTTP 200 response
- [ ] 9.7 Test health check failure scenario to verify pod restart behavior

## 10. Container Startup Verification

- [ ] 10.1 Add container startup verification to check container doesn't exit with code 0
- [ ] 10.2 Add logging for container state changes (Creating, Running, Terminated)
- [ ] 10.3 Verify container runs continuously and responds to health checks
- [ ] 10.4 Test container termination scenario to verify error detection
- [ ] 10.5 Test container startup scenario to verify successful verification

## 11. Main Deployment Script Updates

- [ ] 11.1 Add `set -euo pipefail` to `deploy-all.sh` for strict error handling
- [ ] 11.2 Import error handling functions from `deploy_scripts/common.sh`
- [ ] 11.3 Call `setup_log_file()` at script start to create timestamped log file
- [ ] 11.4 Add deployment summary logging at completion with step status and duration
- [ ] 11.5 Implement rollback function that reapplies `k8s/deployment.yaml.backup` on failure
- [ ] 11.6 Add rollback call after any deployment step failure
- [ ] 11.7 Add environment context logging (Kubernetes status, registry status, deployment state)
- [ ] 11.8 Add VERBOSE mode support with `VERBOSE=true` environment variable for detailed debugging
- [ ] 11.9 Test full deployment with successful outcome
- [ ] 11.10 Test deployment failure scenario to verify rollback procedure
- [ ] 11.11 Test deployment with VERBOSE mode enabled to verify detailed logging

## 12. Testing and Validation

- [ ] 12.1 Test complete deployment pipeline in development environment
- [ ] 12.2 Verify error handling with intentional failures at each step
- [ ] 12.3 Verify rollback procedure restores previous deployment state
- [ ] 12.4 Verify health checks pass with running application
- [ ] 12.5 Verify image verification handles registry catalog delays correctly
- [ ] 12.6 Verify logs contain structured error messages with recovery steps
- [ ] 12.7 Verify log file rotation prevents disk exhaustion
- [ ] 12.8 Verify deployment summary shows accurate step status and duration
- [ ] 12.9 Monitor deployment logs and adjust parameters as needed
- [ ] 12.10 Document any issues found and adjustments made

## 13. Documentation

- [ ] 13.1 Update README.md with new deployment procedure
- [ ] 13.2 Document error handling and rollback procedures in ROLLBACK_PROCEDURE.md
- [ ] 13.3 Document environment variables (HEALTH_CHECK_PATH, VERBOSE) in SETUP.md
- [ ] 13.4 Add troubleshooting section to README.md for common deployment issues
- [ ] 13.5 Document log file location and retention policy
- [ ] 13.6 Document image retention policy (last 5 versions)
