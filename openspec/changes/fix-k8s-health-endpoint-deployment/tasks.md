## 1. Investigation and Diagnosis

- [x] 1.1 Examine Dockerfile to understand build configuration and standalone output settings
  - **Done when**: Dockerfile is reviewed and relevant build output configuration sections are documented
- [ ] 1.2 Check for Next.js configuration files (next.config.js/ts) and analyze API route handling
  - **Done when**: All Next.js config files are read and API route configuration is documented
- [ ] 1.3 Build Docker image locally and inspect filesystem to verify API routes are included in standalone output
  - **Done when**: Docker build completes and inspection confirms presence/absence of API route files
- [ ] 1.4 Test application locally with production build settings and verify `/api/health` endpoint is accessible
  - **Done when**: Local production build runs and curl to `/api/health` returns HTTP 200 with JSON

## 2. Health Endpoint Build Configuration Fix

- [ ] 2.1 Modify Next.js build configuration to ensure API routes are included in standalone output (if required based on investigation)
  - **Done when**: Configuration file is updated and documented with specific changes made
- [ ] 2.2 Update Dockerfile if needed to ensure API routes are properly copied to production filesystem
  - **Done when**: Dockerfile changes are made and verified with dry-run build
- [ ] 2.3 Build updated Docker image and verify API route files exist in output
  - **Done when**: Build succeeds and inspection confirms `/api/health` route file is present in image
- [ ] 2.4 Test health endpoint accessibility from running container
  - **Done when**: Container starts and curl from inside container to `http://localhost:3000/api/health` returns HTTP 200

## 3. Conditional Logging Implementation

- [ ] 3.1 Add VERBOSE environment variable check to deploy_scripts/common.sh to conditionally suppress log_info output
  - **Done when**: common.sh log_info function checks VERBOSE flag and only outputs when VERBOSE=true
- [ ] 3.2 Update deploy-to-k8s.sh to suppress INFO/DEBUG messages unless VERBOSE=true
  - **Done when**: All INFO/DEBUG log statements in deploy-to-k8s.sh are wrapped in VERBOSE check
- [ ] 3.3 Update setup-k8s-secrets.sh to suppress INFO/DEBUG messages unless VERBOSE=true
  - **Done when**: All log_info DEBUG statements in setup-k8s-secrets.sh respect VERBOSE flag
- [ ] 3.4 Update setup-microk8s-registry.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All log_info statements in setup-microk8s-registry.sh respect VERBOSE flag
- [ ] 3.5 Update build-docker-image.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All INFO-level log statements in build-docker-image.sh respect VERBOSE flag
- [ ] 3.6 Update push-docker-image.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All INFO-level log statements in push-docker-image.sh respect VERBOSE flag
- [ ] 3.7 Update tag-docker-image.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All INFO-level log statements in tag-docker-image.sh respect VERBOSE flag
- [ ] 3.8 Test deployment scripts with VERBOSE=false to confirm clean log output
  - **Done when**: Dry-run execution shows only ERROR/WARN messages, INFO/DEBUG suppressed
- [ ] 3.9 Test deployment scripts with VERBOSE=true to verify detailed logging still works
  - **Done when**: Dry-run execution shows all log levels including INFO/DEBUG

## 4. Validation and Testing

- [ ] 4.1 Run full deployment pipeline with VERBOSE=false and verify health endpoint probe passes
  - **Done when**: Deployment completes successfully, pods reach Ready state, logs are clean
- [ ] 4.2 Run full deployment pipeline with VERBOSE=true and verify detailed logging is available
  - **Done when**: Deployment completes successfully, logs include detailed debug information
- [ ] 4.3 Verify health endpoint response time is < 1 second using curl performance measurement
  - **Done when**: curl command with time measurement confirms response under 1000ms threshold
- [ ] 4.4 Verify health endpoint returns HTTP 200 without authentication headers
  - **Done when**: curl without auth headers returns 200 and valid JSON with status "healthy"
- [ ] 4.5 Verify health endpoint returns appropriate error status (500/503) when explicitly failing
  - **Done when**: curl with `?fail=true` parameter returns 500/503 and JSON with error status
- [ ] 4.6 Confirm Kubernetes readiness and liveness probes pass consistently
  - **Done when**: `kubectl get pods` shows Ready=1/1 and no Unhealthy probe warnings in events

## 5. Documentation and Cleanup

- [ ] 5.1 Update deployment documentation to explain VERBOSE flag usage and when to use verbose mode
  - **Done when**: Documentation includes VERBOSE flag description and troubleshooting guidance
- [ ] 5.2 Clean up any temporary test artifacts or debug files created during investigation
  - **Done when**: Temporary files are removed and repository is in clean state
- [ ] 5.3 Commit changes with descriptive commit message referencing this change
  - **Done when**: Git commit is created with message describing health endpoint and logging fixes
