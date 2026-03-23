## 0. Prerequisites - Fix Script Syntax Errors

- [x] 0.1 Investigate and fix `start_total_deployment_timing: command not found` error on line 408 of deploy.sh
- [x] 0.2 Investigate and fix syntax error near unexpected token `}` on line 2594 of deploy.sh
- [x] 0.3 Verify deploy.sh has no syntax errors by running `bash -n deploy.sh`
- [x] 0.4 Test that deploy.sh can be executed without immediate syntax errors

## 1. Core Function Implementation

- [x] 1.1 Create `setup_vm_docker()` function in deploy.sh with function signature and basic structure
- [x] 1.2 Implement Docker CLI availability check using `multipass exec <vm-name> -- docker --version`
- [x] 1.3 Implement Docker daemon status check using `multipass exec <vm-name> -- docker info`
- [x] 1.4 Implement Docker installation using official script `curl -fsSL https://get.docker.com | sh`
- [x] 1.5 Implement user addition to docker group using `sudo usermod -aG docker ubuntu`
- [x] 1.6 Implement Docker daemon startup verification with retry loop and exponential backoff
- [x] 1.7 Implement Docker command verification without sudo using `docker ps`

## 2. Error Handling and Logging

- [x] 2.1 Add comprehensive error handling for Docker CLI check failures
- [x] 2.2 Add comprehensive error handling for Docker installation failures (network, disk space, unknown errors)
- [x] 2.3 Add comprehensive error handling for Docker daemon startup failures
- [x] 2.4 Add comprehensive error handling for docker group membership failures
- [x] 2.5 Implement logging for each Docker setup step with timestamps
- [x] 2.6 Add specific error messages and recovery guidance for each failure scenario
- [x] 2.7 Add diagnostic information output for debugging purposes

## 3. Integration with Deployment Flow

- [x] 3.1 Identify the correct location in deploy.sh to call `setup_vm_docker()` (after VM provisioning, before image loading)
- [x] 3.2 Add function call to `setup_vm_docker()` in the deployment flow
- [x] 3.3 Ensure proper error propagation from `setup_vm_docker()` to stop deployment on failure
- [x] 3.4 Update deployment script to exit with non-zero status when Docker setup fails
- [x] 3.5 Verify that deployment stops correctly and does not proceed to image loading when Docker setup fails

## 4. Testing and Verification

- [x] 4.1 Test Docker setup with fresh VM (no Docker installed)
- [x] 4.2 Test Docker setup with existing VM (Docker already installed and running)
- [x] 4.3 Test Docker setup with VM that has Docker installed but daemon not running
- [x] 4.4 Test error handling when VM has no network connectivity
- [x] 4.5 Test error handling when VM has insufficient disk space
- [x] 4.6 Test full deployment flow end-to-end with Docker setup
- [x] 4.7 Verify image loading works correctly after Docker setup
- [x] 4.8 Verify Kubernetes deployment proceeds successfully after image loading

## 5. Documentation and Cleanup

- [x] 5.1 Add inline comments explaining each step of Docker setup
- [x] 5.2 Document Docker setup requirements in deployment documentation
- [x] 5.3 Document troubleshooting steps for common Docker setup issues
- [x] 5.4 Update README.md with Docker setup information if needed
- [x] 5.5 Review and clean up any temporary or debugging code
- [x] 5.6 Verify all error messages are clear and actionable

## 6. Edge Cases and Robustness

- [x] 6.1 Handle case where Docker installation script is not accessible
- [x] 6.2 Handle case where Docker daemon takes longer than expected to start
- [x] 6.3 Handle case where docker group membership doesn't activate immediately
- [x] 6.4 Add timeout handling for all Docker operations
- [x] 6.5 Handle case where VM is not accessible or multipass commands fail
- [x] 6.6 Verify idempotency - running setup multiple times should not cause issues

## 7. Performance Optimization

- [x] 7.1 Optimize Docker availability check to minimize execution time
- [x] 7.2 Implement caching or state tracking to avoid redundant checks
- [x] 7.3 Tune retry intervals and timeouts for optimal performance
- [x] 7.4 Measure and document performance impact on deployment time

## 8. Image Loading Verification and Debugging

- [x] 8.1 Investigate why Docker image load fails silently in VM
- [x] 8.2 Add detailed logging to image load command to capture stdout/stderr
- [x] 8.3 Verify `docker save` command is executing correctly on host
- [x] 8.4 Verify `docker load` command is being received and executed in VM
- [x] 8.5 Test image transfer manually using `multipass transfer` as alternative method
- [x] 8.6 Add explicit error checking after `docker load` command in VM
- [ ] 8.7 Verify image exists in VM immediately after load using `docker images`
- [ ] 8.8 Add retry logic for image load if first attempt fails
- [ ] 8.9 Implement image load verification with detailed error reporting
- [ ] 8.10 Test image loading with different methods (pipe vs file transfer)
- [ ] 8.11 Document the working image load method and update deployment script accordingly
- [ ] 8.12 Add comprehensive error messages for image load failures with specific recovery steps
