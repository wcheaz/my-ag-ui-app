## Why

The current [`deploy.sh`](deploy.sh) script is 338KB and contains extensive debug logging throughout all phases, consuming excessive context tokens during ralph-loop development sessions. This makes it difficult to focus on problematic sections and increases development time. The script needs to be modularized and optimized to retain debug output only for problematic phases while removing it from working sections.

## What Changes

- **Split [`deploy.sh`](deploy.sh) into modular scripts** - Each deployment phase becomes a separate, independently executable script in a dedicated `deploy_scripts/` directory:
  - `deploy_scripts/setup-k8s-secrets.sh` - Kubernetes secrets configuration (PROBLEMATIC - retain debug)
  - `deploy_scripts/build-docker-image.sh` - Docker image build (SUCCESS - remove debug)
  - `deploy_scripts/tag-docker-image.sh` - Docker image tagging (SUCCESS - remove debug)
  - `deploy_scripts/setup-microk8s-registry.sh` - Microk8s registry setup (SUCCESS - remove debug)
  - `deploy_scripts/push-docker-image.sh` - Docker registry push (PARTIAL SUCCESS - minimal debug)
  - `deploy_scripts/deploy-to-k8s.sh` - Kubernetes deployment (CRITICAL FAILURE - retain debug)

- **Optimize debug output** - Remove verbose debug logging from working phases, retain only for problematic phases:
  - Remove debug output from successful phases (Docker build, tagging, registry setup)
  - Retain debug output for problematic phases (secrets setup, Kubernetes deployment)
  - Add minimal debug output for partially successful phases (registry push)

- **Create master orchestrator** - Replace [`deploy.sh`](deploy.sh) with a new `deploy-all.sh` in project root that executes all modular scripts from `deploy_scripts/` in sequence with proper error handling

- **BREAKING**: The monolithic [`deploy.sh`](deploy.sh) will be replaced with `deploy-all.sh` (orchestrator in project root) and modular scripts in `deploy_scripts/` directory. Existing workflows that directly invoke [`deploy.sh`](deploy.sh) will need to be updated to use the new orchestrator or individual scripts.

## Capabilities

### New Capabilities
- `modular-deploy-scripts`: Split deployment into independently executable scripts for each phase, enabling isolated testing and debugging
- `debug-optimization`: Optimize debug output by removing verbose logging from working phases while retaining it for problematic sections

### Modified Capabilities
- (None - this is a refactoring of deployment scripts, not a change to application behavior or requirements)

## Impact

- **Scripts**: [`deploy.sh`](deploy.sh) (338KB) will be replaced by:
  - `deploy-all.sh` in project root (orchestrator, ~2-5KB)
  - `deploy_scripts/` directory containing 6 modular scripts (~50-80KB each)
- **Project Structure**: Keeps project root uncluttered by organizing helper scripts in dedicated `deploy_scripts/` directory
- **Development Workflow**: Ralph-loop development will consume fewer context tokens and enable focused debugging on problematic phases
- **Debugging**: Each phase can be tested independently by running scripts directly from `deploy_scripts/`, making it easier to isolate and fix issues
- **Deployment**: Existing deployment workflows will need to use the new `deploy-all.sh` orchestrator or individual scripts from `deploy_scripts/`
- **Maintenance**: Smaller, focused scripts are easier to understand, modify, and maintain
