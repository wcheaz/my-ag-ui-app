## 1. Core Function Implementation

- [x] 1.1 Create `setup_vm_docker()` function in deploy.sh with function signature and basic structure
- [x] 1.2 Implement Docker CLI availability check using `multipass exec <vm-name> -- docker --version`
- [ ] 1.3 Implement Docker daemon status check using `multipass exec <vm-name> -- docker info`
- [ ] 1.4 Implement Docker installation using official script `curl -fsSL https://get.docker.com | sh`
- [ ] 1.5 Implement user addition to docker group using `sudo usermod -aG docker ubuntu`
- [ ] 1.6 Implement Docker daemon startup verification with retry loop and exponential backoff
- [ ] 1.7 Implement Docker command verification without sudo using `docker ps`

## 2. Error Handling and Logging

- [ ] 2.1 Add comprehensive error handling for Docker CLI check failures
- [ ] 2.2 Add comprehensive error handling for Docker installation failures (network, disk space, unknown errors)
- [ ] 2.3 Add comprehensive error handling for Docker daemon startup failures
- [ ] 2.4 Add comprehensive error handling for docker group membership failures
- [ ] 2.5 Implement logging for each Docker setup step with timestamps
- [ ] 2.6 Add specific error messages and recovery guidance for each failure scenario
- [ ] 2.7 Add diagnostic information output for debugging purposes

## 3. Integration with Deployment Flow

- [ ] 3.1 Identify the correct location in deploy.sh to call `setup_vm_docker()` (after VM provisioning, before image loading)
- [ ] 3.2 Add function call to `setup_vm_docker()` in the deployment flow
- [ ] 3.3 Ensure proper error propagation from `setup_vm_docker()` to stop deployment on failure
- [ ] 3.4 Update deployment script to exit with non-zero status when Docker setup fails
- [ ] 3.5 Verify that deployment stops correctly and does not proceed to image loading when Docker setup fails

## 4. Testing and Verification

- [ ] 4.1 Test Docker setup with fresh VM (no Docker installed)
- [ ] 4.2 Test Docker setup with existing VM (Docker already installed and running)
- [ ] 4.3 Test Docker setup with VM that has Docker installed but daemon not running
- [ ] 4.4 Test error handling when VM has no network connectivity
- [ ] 4.5 Test error handling when VM has insufficient disk space
- [ ] 4.6 Test full deployment flow end-to-end with Docker setup
- [ ] 4.7 Verify image loading works correctly after Docker setup
- [ ] 4.8 Verify Kubernetes deployment proceeds successfully after image loading

## 5. Documentation and Cleanup

- [ ] 5.1 Add inline comments explaining each step of Docker setup
- [ ] 5.2 Document Docker setup requirements in deployment documentation
- [ ] 5.3 Document troubleshooting steps for common Docker setup issues
- [ ] 5.4 Update README.md with Docker setup information if needed
- [ ] 5.5 Review and clean up any temporary or debugging code
- [ ] 5.6 Verify all error messages are clear and actionable

## 6. Edge Cases and Robustness

- [ ] 6.1 Handle case where Docker installation script is not accessible
- [ ] 6.2 Handle case where Docker daemon takes longer than expected to start
- [ ] 6.3 Handle case where docker group membership doesn't activate immediately
- [ ] 6.4 Add timeout handling for all Docker operations
- [ ] 6.5 Handle case where VM is not accessible or multipass commands fail
- [ ] 6.6 Verify idempotency - running setup multiple times should not cause issues

## 7. Performance Optimization

- [ ] 7.1 Optimize Docker availability check to minimize execution time
- [ ] 7.2 Implement caching or state tracking to avoid redundant checks
- [ ] 7.3 Tune retry intervals and timeouts for optimal performance
- [ ] 7.4 Measure and document performance impact on deployment time
