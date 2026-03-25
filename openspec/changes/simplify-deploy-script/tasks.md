## 1. Setup and Preparation

- [x] 1.1 Create `deploy_scripts/` directory in project root
- [x] 1.2 Analyze [`deploy.sh`](deploy.sh) to identify phase boundaries and shared dependencies
- [x] 1.3 Document shared functions, variables, and state between phases
- [x] 1.4 Document current debug output levels for each phase based on [`deploy_log_explanation.md`](deploy_log_explanation.md)
- [x] 1.5 Archive original [`deploy.sh`](deploy.sh) to `archive/deploy.sh.original` for reference

## 2. Extract Modular Scripts

### 2.1 Setup Kubernetes Secrets Script
- [x] 2.1.1 Extract Kubernetes secrets setup phase from [`deploy.sh`](deploy.sh) to `deploy_scripts/setup-k8s-secrets.sh`
- [x] 2.1.2 Add shebang and error handling (`set -e`) to script
- [x] 2.1.3 Retain full verbose debug output (PROBLEMATIC phase)
- [x] 2.1.4 Add debug level documentation comment: `# DEBUG LEVEL: FULL (problematic phase)`
- [x] 2.1.5 Implement `DEBUG=all` flag support to enable/disable verbose output
- [x] 2.1.6 Test script independently: `./deploy_scripts/setup-k8s-secrets.sh`

### 2.2 Build Docker Image Script
- [x] 2.2.1 Extract Docker build phase from [`deploy.sh`](deploy.sh) to `deploy_scripts/build-docker-image.sh`
- [x] 2.2.2 Add shebang and error handling (`set -e`) to script
- [x] 2.2.3 Remove verbose debug output, keep only essential status messages (SUCCESS phase)
- [x] 2.2.4 Add debug level documentation comment: `# DEBUG LEVEL: MINIMAL (successful phase)`
- [x] 2.2.5 Implement `DEBUG=all` flag support to enable/disable verbose output
- [x] 2.2.6 Test script independently: `./deploy_scripts/build-docker-image.sh`

### 2.3 Tag Docker Image Script
- [x] 2.3.1 Extract Docker image tagging phase from [`deploy.sh`](deploy.sh) to `deploy_scripts/tag-docker-image.sh`
- [x] 2.3.2 Add shebang and error handling (`set -e`) to script
- [x] 2.3.3 Remove verbose debug output, keep only success confirmation (SUCCESS phase)
- [x] 2.3.4 Add debug level documentation comment: `# DEBUG LEVEL: MINIMAL (successful phase)`
- [x] 2.3.5 Implement `DEBUG=all` flag support to enable/disable verbose output
- [x] 2.3.6 Test script independently: `./deploy_scripts/tag-docker-image.sh`

### 2.4 Setup Microk8s Registry Script
- [x] 2.4.1 Extract Microk8s registry setup phase from [`deploy.sh`](deploy.sh) to `deploy_scripts/setup-microk8s-registry.sh`
- [x] 2.4.2 Add shebang and error handling (`set -e`) to script
- [x] 2.4.3 Remove verbose debug output, keep only essential status messages (SUCCESS phase)
- [x] 2.4.4 Add debug level documentation comment: `# DEBUG LEVEL: MINIMAL (successful phase)`
- [x] 2.4.5 Implement `DEBUG=all` flag support to enable/disable verbose output
- [x] 2.4.6 Test script independently: `./deploy_scripts/setup-microk8s-registry.sh`

### 2.5 Push Docker Image Script
- [x] 2.5.1 Extract Docker registry push phase from [`deploy.sh`](deploy.sh) to `deploy_scripts/push-docker-image.sh`
- [x] 2.5.2 Add shebang and error handling (`set -e`) to script
- [x] 2.5.3 Minimize debug output, keep only critical status and error messages (PARTIAL SUCCESS phase)
- [x] 2.5.4 Add debug level documentation comment: `# DEBUG LEVEL: MINIMAL (partial success phase)`
- [x] 2.5.5 Implement `DEBUG=all` flag support to enable/disable verbose output
- [x] 2.5.6 Test script independently: `./deploy_scripts/push-docker-image.sh`

### 2.6 Deploy to Kubernetes Script
- [x] 2.6.1 Extract Kubernetes deployment phase from [`deploy.sh`](deploy.sh) to `deploy_scripts/deploy-to-k8s.sh`
- [x] 2.6.2 Add shebang and error handling (`set -e`) to script
- [x] 2.6.3 Retain full verbose debug output (CRITICAL FAILURE phase)
- [x] 2.6.4 Add debug level documentation comment: `# DEBUG LEVEL: FULL (critical failure phase)`
- [x] 2.6.5 Implement `DEBUG=all` flag support to enable/disable verbose output
- [x] 2.6.6 Test script independently: `./deploy_scripts/deploy-to-k8s.sh`

## 3. Create Orchestrator

- [x] 3.1 Create `deploy-all.sh` in project root with shebang
- [x] 3.2 Add error handling (`set -e`) to orchestrator
- [ ] 3.3 Implement sequential execution of all 6 modular scripts in correct order:
  - `deploy_scripts/setup-k8s-secrets.sh`
  - `deploy_scripts/build-docker-image.sh`
  - `deploy_scripts/tag-docker-image.sh`
  - `deploy_scripts/setup-microk8s-registry.sh`
  - `deploy_scripts/push-docker-image.sh`
  - `deploy_scripts/deploy-to-k8s.sh`
- [ ] 3.4 Add error checking after each script execution
- [ ] 3.5 Implement clear error messages indicating which script failed
- [ ] 3.6 Add success message when all scripts complete successfully
- [ ] 3.7 Add usage comment or help text at top of script
- [ ] 3.8 Test orchestrator: `./deploy-all.sh`

## 4. Validation and Testing

- [ ] 4.1 Test each modular script independently and verify it works in isolation
- [ ] 4.2 Test orchestrator with full deployment pipeline
- [ ] 4.3 Verify deployment functionality matches original [`deploy.sh`](deploy.sh) behavior
- [ ] 4.4 Test `DEBUG=all` flag on each script to verify verbose output can be enabled
- [ ] 4.5 Verify error handling works correctly (orchestrator stops on failure)
- [ ] 4.6 Test that scripts can be executed from project root directory
- [ ] 4.7 Verify project root contains only `deploy-all.sh` (no other deployment scripts)
- [ ] 4.8 Verify `deploy_scripts/` directory contains all 6 modular scripts

## 5. Documentation and Rollout

- [ ] 5.1 Update [`README.md`](README.md) to document new deployment scripts structure
- [ ] 5.2 Document how to use individual scripts for isolated testing
- [ ] 5.3 Document how to use `deploy-all.sh` for full deployment
- [ ] 5.4 Document `DEBUG=all` flag usage for temporary full debugging
- [ ] 5.5 Document debug level for each script (full, minimal)
- [ ] 5.6 Update any existing workflows that reference [`deploy.sh`](deploy.sh) to use `deploy-all.sh`
- [ ] 5.7 Add migration notes to [`CHANGELOG.md`](CHANGELOG.md)
- [ ] 5.8 Create rollback procedure documentation in case issues arise

## 6. Final Verification

- [ ] 6.1 Measure context token consumption before and after refactoring
- [ ] 6.2 Verify all scripts are executable (`chmod +x`)
- [ ] 6.3 Verify all scripts have consistent error handling
- [ ] 6.4 Verify all scripts have debug level documentation comments
- [ ] 6.5 Verify all scripts support `DEBUG=all` flag
- [ ] 6.6 Perform end-to-end deployment test using `deploy-all.sh`
- [ ] 6.7 Verify deployment succeeds and application is accessible
- [ ] 6.8 Archive original [`deploy.sh`](deploy.sh) permanently to `archive/deploy.sh.original`
- [ ] 6.9 Remove original [`deploy.sh`](deploy.sh) from project root
