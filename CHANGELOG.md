# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **YAML Path Errors in deploy.sh**: Fixed "path does not exist" errors during Kubernetes deployment
  - **Root Cause**: `secrets.yaml` file existed but was incomplete (contained empty values for sensitive data)
  - **Solution**: Added automatic detection and generation of `secrets.yaml` when incomplete
  - Added logic to run `setup-secrets.sh` automatically before applying Kubernetes manifests
  - Enhanced file validation to check for file completeness, not just existence
  - Added comprehensive debugging and logging features to prevent future YAML path issues
  - Improved error handling with clear recovery suggestions for common deployment issues
  - Added VM readiness validation before file operations
  - Enhanced kubectl command logging for better debugging visibility
  - Added working directory and file path logging throughout the script

### Changed
- **Environment Loading**: Migrated from custom `load_env()` function to `python-dotenv` library
  - Removed ~20 lines of custom environment variable parsing code from `agent/src/agent.py`
  - Added `python-dotenv` dependency to `agent/pyproject.toml`
  - Replaced manual parsing with industry-standard `load_dotenv()` function
  - Improved support for complex `.env` file formats (multiline values, quoted strings, comments)

### Cleanup
- **Project Organization**: Cleaned up project root directory and organized test files
  - Created `test/kubernetes/` directory for Kubernetes-related test scripts
  - Moved test scripts (`test_script_idempotency.sh`, `test_script.sh`, `test-container-build.sh`, `test-docker-build.sh`) to `test/kubernetes/` directory
  - Removed unnecessary deployment scripts (kept only `deploy.sh`)
  - Cleaned up log files (`deployment_test.log`, `deployment.log`, `test_deployment.log`, `vm-test.log`, `service-connectivity-test.log`)
  - Removed temporary files (`SCRIPT_IDEMPOTENCY_TEST_RESULTS.md`, `performance_analysis.md`, `env_loading_performance_results.txt`)
  - Removed TLS certificate files (`tls.crt`, `tls.key`)
  - Updated `.gitignore` to exclude `test/kubernetes/` directory
  - Verified project root directory is clean and organized

### Migration Notes
- **No Breaking Changes**: Existing `.env` files will continue to work without modification
- **Enhanced Compatibility**: The new parser supports additional `.env` file features:
  - Multiline values using double quotes
  - Comments after values (using `#`)
  - Variable expansion (`${VAR}` syntax)
  - Export statements
- **Performance**: No performance degradation - agent startup time remains unchanged
- **Security**: `python-dotenv` is a mature, widely-used library with active maintenance

### Technical Details
- Custom `load_env()` function (lines 90-106) was removed from `agent/src/agent.py`
- Added `from dotenv import load_dotenv` import
- Added `load_dotenv()` call at module level
- Maintains backward compatibility with existing `.env` file search paths
- No changes to how environment variables are used throughout the codebase

### Testing
- All existing tests pass without modification
- Comprehensive testing with various `.env` file formats
- Verified no performance impact on agent startup
- Security audit completed for `python-dotenv` dependency
- Edge case testing completed (multiline values, quoted strings, comments)