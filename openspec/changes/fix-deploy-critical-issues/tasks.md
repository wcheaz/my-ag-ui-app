## 1. Docker Cleanup Idempotency

- [x] 1.1 Modify cleanup-resources.sh to stop containers with label `app=my-ag-ui-app` before image deletion
- [x] 1.2 Modify cleanup-resources.sh to remove stopped containers before deleting images
- [x] 1.3 Modify cleanup-resources.sh to use non-zero exit only for critical failures, warnings for non-critical failures

## 2. Build Verification Accuracy

- [x] 2.1 Modify build-docker-image.sh to use Docker build exit code for success determination
- [x] 2.2 Modify build-docker-image.sh to verify image exists using `docker images my-ag-ui-app:latest` query
- [x] 2.3 Remove any output parsing logic in build-docker-image.sh that determines success from text patterns

## 3. Deployment Rollback Safety

- [ ] 3.1 Modify deploy-all.sh to create backup of k8s/deployment.yaml at k8s/deployment.yaml.backup after Step 3 (tagging) and before Step 4 (registry setup)
- [ ] 3.2 Modify deploy-all.sh to overwrite existing backup file silently
- [ ] 3.3 Add verification in deploy-all.sh to confirm backup file exists and content matches original before proceeding

## 4. Testing

- [ ] 4.1 Test Docker cleanup with stopped containers referencing images to verify no conflict errors
- [ ] 4.2 Test build script with successful Docker build to verify false negative does not occur
- [ ] 4.3 Test build script with failed Docker build to verify correct error reporting
- [ ] 4.4 Test backup creation during deployment to verify file is created at correct point
- [ ] 4.5 Test rollback function with backup present to verify successful state restoration
