## 1. Build Error Precision

- [x] 1.1 Remove tar cleanup commands from deploy_scripts/build-docker-image.sh lines 233-236
  - Done when: Lines 233-236 are deleted from the file
  - Verify by: Running `grep -n "multipass exec.*rm.*my-ag-ui-app.tar\|rm -f.*TAR_FILE" deploy_scripts/build-docker-image.sh` returns no results

- [x] 1.2 Replace global `set -e` with scoped error handling in deploy_scripts/build-docker-image.sh
  - Done when: Docker build and image load operations are wrapped in `(set -e ...)` subshell, cleanup uses `set +e`
  - Verify by: Running `grep -A 10 "set -e" deploy_scripts/build-docker-image.sh` shows scoped error handling only around critical operations

- [x] 1.3 Add explicit exit code checking for Docker build in deploy_scripts/build-docker-image.sh
  - Done when: Script captures `docker_build_status=${PIPESTATUS[0]}` and exits with `$docker_build_status` on build failure
  - Verify by: Running `grep -A 5 "PIPESTATUS\[" deploy_scripts/build-docker-image.sh` shows exit code capture and check

- [x] 1.4 Verify build script exits with code 0 on successful build despite cleanup failures
  - Done when: Manual test with Docker build succeeds, cleanup fails, script exits with code 0
  - Verify by: Running `deploy-all.sh` and confirming "STEP 2 FAILED" does not occur when build succeeds

## 2. VM Disk Space Management

- [x] 2.1 Add disk space verification before Docker image load in deploy_scripts/build-docker-image.sh
  - Done when: Script checks available space with `multipass exec "$VM_NAME" -- df -BM /` before image load
  - Verify by: Running `grep -A 2 "Checking VM disk space" deploy_scripts/build-docker-image.sh` shows df -BM command

- [x] 2.2 Add Docker system prune before image load in deploy_scripts/build-docker-image.sh
  - Done when: Script runs `multipass exec "$VM_NAME" -- docker system prune -f` before loading image
  - Verify by: Running `grep "docker system prune -f" deploy_scripts/build-docker-image.sh` returns the prune command

- [x] 2.3 Add minimum disk space threshold check with 500MB requirement
  - Done when: Script compares available space in MB against 500MB threshold using integer comparison
  - Verify by: Running `grep -A 4 "MIN_SPACE_MB=500" deploy_scripts/build-docker-image.sh` shows integer comparison

- [x] 2.4 Verify deployment succeeds without "no space left on device" errors
  - Done when: Docker image load completes successfully, deployment continues without disk space errors
  - Verify by: Running `deploy-all.sh` and confirming log contains no "no space left on device" errors

## 3. Node Version Compliance

- [x] 2.1 Update Dockerfile base image to node:20.19.0-alpine
  - Done when: Line 4 of Dockerfile reads `FROM node:20.19.0-alpine`
  - Verify by: Running `grep "^FROM node:" Dockerfile` returns `FROM node:20.19.0-alpine`

- [x] 3.2 Verify Docker build completes without EBADENGINE warnings
  - Done when: Docker build log contains no "EBADENGINE" or "Unsupported engine" warnings
  - Verify by: Running `docker build -t my-ag-ui-app:latest .` and checking log for warnings

## 4. Lock File Synchronization

- [x] 4.1 Run `npm install` locally to regenerate package-lock.json
  - Done when: package-lock.json is updated with React 19 type definitions (@types/react@19.x)
  - Verify by: Running `grep '"@types/react"' package-lock.json | head -1` shows version 19.x.x

- [x] 4.2 Commit updated package-lock.json to repository
  - Done when: `git status` shows package-lock.json modified, committed with message "Update package-lock.json for React 19 compatibility"
  - Verify by: Running `git log -1 --oneline` shows commit message containing package-lock.json update

- [x] 4.3 Verify npm ci succeeds during Docker build
  - Done when: Docker build log shows "npm ci completed - using reproducible dependencies" without fallback warning
  - Verify by: Running `docker build -t my-ag-ui-app:latest .` and checking build log for successful npm ci

## 5. Integration Testing

- [x] 5.1 Run full deployment pipeline with all fixes
  - Done when: `deploy-all.sh` completes successfully without "STEP 2 FAILED" error
  - Verify by: Running `./deploy-all.sh` and confirming all steps complete with success messages

- [x] 5.2 Verify deployment succeeds without disk space errors
   - Done when: Multiple deployment runs complete without "no space left on device" errors
   - Verify by: Running deployment 3 times and confirming Docker image load succeeds each time

- [x] 5.3 Verify rollback capability is preserved
  - Done when: Rollback function in deploy-all.sh uses k8s/deployment.yaml.backup and restores state on actual failure
  - Verify by: Checking that rollback is NOT triggered on successful deployment (only on real failures)

- [x] 5.4 Confirm no false negative build failures
  - Done when: Multiple deployment runs all complete without "STEP 2 FAILED" when Docker build succeeds
  - Verify by: Running deployment 3 times and confirming all succeed with exit code 0
