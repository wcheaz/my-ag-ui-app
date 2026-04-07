## 1. Bash Script Syntax Fix

- [x] 1.1 Investigate bash script syntax error on line 800 of deploy-to-k8s.sh
  - **Done when**: Error cause is identified (likely `local` outside of function scope due to missing brace/quote)
- [x] 1.2 Fix the syntax error to ensure all `local` declarations are within function scope
  - **Done when**: Script passes bash syntax validation and runs without error
- [x] 1.3 Test fixed deployment script with dry-run to verify it completes without errors
  - **Done when**: `bash -n deploy-to-k8s.sh` shows no syntax errors, script runs successfully

## 2. Next.js Configuration Cleanup

- [x] 2.1 Remove deprecated `experimental.serverComponentsExternalPackages` from next.config.ts
  - **Done when**: The experimental object is removed from config while keeping `serverExternalPackages` at root
- [x] 2.2 Rebuild Docker image to verify build warnings are eliminated
  - **Done when**: `docker build` completes without Next.js config warnings

## 3. Health Endpoint Build Configuration Investigation

- [x] 3.1 Examine Dockerfile to understand standalone output structure and what files are copied
  - **Done when**: Dockerfile review documents all `.next` subdirectories being copied
- [x] 3.2 Build Docker image and inspect filesystem to find where API routes are compiled
  - **Done when**: Build completes and inspection shows API route file locations (e.g., `.next/server/`)
- [x] 3.3 Test health endpoint from within VM container using `multipass exec`
  - **Done when**: `multipass exec my-ag-ui-app-k8s -- docker exec <container> wget http://localhost:3000/api/health` returns 200
- [x] 3.4 If API routes not accessible, modify Dockerfile to copy `.next/server` directory
  - **Done when**: Dockerfile includes `COPY --from=builder /app/.next/server ./.next/server`
- [x] 3.5 Rebuild and retest health endpoint accessibility within VM container
  - **Done when**: Health endpoint returns HTTP 200 from within container, accessible to Kubernetes probes

## 4. Conditional Logging Implementation

- [ ] 4.1 Add VERBOSE environment variable check to deploy_scripts/common.sh to conditionally suppress log_info output
  - **Done when**: common.sh log_info function checks VERBOSE flag and only outputs when VERBOSE=true
- [ ] 4.2 Update deploy-to-k8s.sh to suppress INFO/DEBUG messages unless VERBOSE=true
  - **Done when**: All INFO/DEBUG log statements in deploy-to-k8s.sh are wrapped in VERBOSE check
- [ ] 4.3 Update setup-k8s-secrets.sh to suppress INFO/DEBUG messages unless VERBOSE=true
  - **Done when**: All log_info DEBUG statements in setup-k8s-secrets.sh respect VERBOSE flag
- [ ] 4.4 Update setup-microk8s-registry.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All log_info statements in setup-microk8s-registry.sh respect VERBOSE flag
- [ ] 4.5 Update build-docker-image.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All INFO-level log statements in build-docker-image.sh respect VERBOSE flag
- [ ] 4.6 Update push-docker-image.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All INFO-level log statements in push-docker-image.sh respect VERBOSE flag
- [ ] 4.7 Update tag-docker-image.sh to suppress INFO messages unless VERBOSE=true
  - **Done when**: All INFO-level log statements in tag-docker-image.sh respect VERBOSE flag
- [ ] 4.8 Test deployment scripts with VERBOSE=false to confirm clean log output
  - **Done when**: Dry-run execution shows only ERROR/WARN messages, INFO/DEBUG suppressed
- [ ] 4.9 Test deployment scripts with VERBOSE=true to verify detailed logging still works
  - **Done when**: Dry-run execution shows all log levels including INFO/DEBUG

## 5. Validation and Testing

- [ ] 5.1 Run full deployment pipeline with VERBOSE=false and verify health endpoint probe passes
  - **Done when**: Deployment completes successfully, pods reach Ready state, logs are clean
- [ ] 5.2 Run full deployment pipeline with VERBOSE=true and verify detailed logging is available
  - **Done when**: Deployment completes successfully, logs include detailed debug information
- [ ] 5.3 Verify health endpoint response time is < 1 second using curl performance measurement from within VM
  - **Done when**: `multipass exec my-ag-ui-app-k8s -- curl -w '%{time_total}' http://<pod-ip>:3000/api/health` confirms response under 1000ms
- [ ] 5.4 Verify health endpoint returns HTTP 200 without authentication headers
  - **Done when**: curl from within VM without auth headers returns 200 and valid JSON with status "healthy"
- [ ] 5.5 Verify health endpoint returns appropriate error status (500/503) when explicitly failing
  - **Done when**: curl from within VM with `?fail=true` parameter returns 500/503 and JSON with error status
- [ ] 5.6 Confirm Kubernetes readiness and liveness probes pass consistently
  - **Done when**: `multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods` shows Ready=1/1 and no Unhealthy probe warnings in events

## 6. Documentation and Cleanup

- [ ] 6.1 Update deployment documentation to explain VERBOSE flag usage and when to use verbose mode
  - **Done when**: Documentation includes VERBOSE flag description and troubleshooting guidance
- [ ] 6.2 Document requirement to test endpoints from within VM (not from host machine)
  - **Done when**: README/docs note cluster runs in Multipass VM and testing requires `multipass exec`
- [ ] 6.3 Clean up any temporary test artifacts or debug files created during investigation
  - **Done when**: Temporary files are removed and repository is in clean state
- [ ] 6.4 Commit changes with descriptive commit message referencing this change
  - **Done when**: Git commit is created with message describing bash fix, config cleanup, health endpoint and logging fixes
