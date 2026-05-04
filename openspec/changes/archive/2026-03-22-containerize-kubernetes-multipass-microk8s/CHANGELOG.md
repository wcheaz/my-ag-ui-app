# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete containerization setup with Docker multi-stage builds
- Kubernetes manifests for deployment, service, and ingress
- VM provisioning with multipass integration
- Microk8s installation and configuration
- Automated deployment script (deploy.sh) with comprehensive error handling
- Cleanup script (cleanup.sh) for resource management
- Documentation including README.md and KUBERNETES-EXPLANATION.md
- Comprehensive test suite for all components

### Changed
- Project structure organization:
  - Created test/kubernetes/ directory for test scripts
  - Moved all test scripts from root directory to test/kubernetes/
  - Cleaned up log files from root directory
  - Updated .gitignore to exclude test/kubernetes/ directory
- Removed unnecessary deployment scripts, keeping only deploy.sh
- Removed temporary files and artifacts that are no longer needed

### Fixed
- Environment variable configuration and validation
- Ingress routing and error handling
- Health checks and resource limits
- Script idempotency and ralph-loop automation compatibility
- VM name variable issue causing "instance "" does not exist" error in multipass exec commands
- VM_NAME variable initialization and validation in deployment script
- Kubernetes manifest file path errors causing "path does not exist" errors during kubectl apply
- YAML file copy and generation process in deployment script
- Working directory and file path validation in VM
- File transfer mechanism for copying YAML files from host to VM before kubectl operations

## [1.0.0] - 2026-03-21

### Added
- Initial implementation of containerized application deployment
- Support for Kubernetes on microk8s via multipass VM
- Complete deployment automation with comprehensive error handling
- Full documentation and testing suite