# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

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

## Specifications

debug-optimization/spec.md
## ADDED Requirements

### Requirement: Debug output is removed from successful deployment phases
The system SHALL remove verbose debug logging from deployment phases that are working correctly (Docker build, image tagging, Microk8s registry setup) to reduce context token consumption during ralph-loop development.

#### Scenario: Successful phases have minimal output
- **WHEN** `deploy_scripts/build-docker-image.sh` executes successfully
- **THEN** only essential status messages are displayed
- **AND** verbose debug logging is removed

#### Scenario: Tagging phase has minimal output
- **WHEN** `deploy_scripts/tag-docker-image.sh` executes successfully
- **THEN** only success confirmation is displayed
- **AND** verbose debug logging is removed

#### Scenario: Registry setup has minimal output
- **WHEN** `deploy_scripts/setup-microk8s-registry.sh` executes successfully
- **THEN** only essential status messages are displayed
- **AND** verbose debug logging is removed

### Requirement: Debug output is retained for problematic deployment phases
The system SHALL retain verbose debug logging for deployment phases that are failing or problematic (Kubernetes secrets setup, Kubernetes deployment) to enable effective debugging during ralph-loop development.

#### Scenario: Secrets setup retains debug output
- **WHEN** `deploy_scripts/setup-k8s-secrets.sh` executes
- **THEN** verbose debug logging is displayed
- **AND** all validation and configuration details are shown

#### Scenario: Kubernetes deployment retains debug output
- **WHEN** `deploy_scripts/deploy-to-k8s.sh` executes
- **THEN** verbose debug logging is displayed
- **AND** all pod status, health check, and error details are shown

### Requirement: Partial success phases have minimal debug output
The system SHALL provide minimal debug output for deployment phases with partial success (Docker registry push) to balance debugging needs with context token efficiency.

#### Scenario: Registry push has minimal debug output
- **WHEN** `deploy_scripts/push-docker-image.sh` executes
- **THEN** only critical status and error messages are displayed
- **AND** verbose debug logging is minimized

#### Scenario: Registry push errors are visible
- **WHEN** `deploy_scripts/push-docker-image.sh` encounters an error
- **THEN** error messages and relevant context are displayed
- **AND** excessive debug output is avoided

### Requirement: Debug output levels are clearly documented
Each modular script SHALL include comments or documentation indicating the debug output level (full, minimal, or none) to help developers understand the debugging capabilities of each phase.

#### Scenario: Script debug level is documented
- **WHEN** a developer reads a modular script
- **THEN** the script includes comments indicating debug output level
- **AND** the level matches the phase status (problematic, successful, partial)

#### Scenario: Debug levels match phase status
- **WHEN** reviewing all modular scripts
- **THEN** problematic phases have full debug output documented
- **AND** successful phases have minimal debug output documented
- **AND** partial success phases have minimal debug output documented

### Requirement: Debug output can be optionally enabled for all phases
The system SHALL provide an optional flag or environment variable to enable verbose debug output for all deployment phases, allowing developers to temporarily increase debugging when needed.

#### Scenario: Enable debug for all phases
- **WHEN** a user sets `DEBUG=all` environment variable
- **THEN** all modular scripts display verbose debug output
- **AND** debugging information is available for all phases

#### Scenario: Default behavior maintains optimization
- **WHEN** no debug flag is set
- **THEN** scripts use optimized debug output levels
- **AND** context token consumption is minimized

modular-deploy-scripts/spec.md
## ADDED Requirements

### Requirement: Deployment scripts are modularized into independent phase-specific scripts
The system SHALL split the monolithic [`deploy.sh`](deploy.sh) script into separate, independently executable scripts for each deployment phase, organized in a `deploy_scripts/` directory.

#### Scenario: All deployment phases have corresponding modular scripts
- **WHEN** the deployment refactoring is complete
- **THEN** the `deploy_scripts/` directory contains scripts for all six deployment phases

### Requirement: Each modular script is independently executable
Each script in `deploy_scripts/` SHALL be executable independently without requiring other scripts to run first, enabling isolated testing and debugging of individual phases.

#### Scenario: Execute single deployment phase script
- **WHEN** a user runs `./deploy_scripts/setup-k8s-secrets.sh`
- **THEN** only the Kubernetes secrets setup phase executes
- **AND** the script does not depend on other scripts running first

#### Scenario: Execute any modular script independently
- **WHEN** a user runs any script from `deploy_scripts/` directory
- **THEN** that specific phase executes successfully
- **AND** the script can be run in isolation for testing

### Requirement: Master orchestrator executes all modular scripts in sequence
The system SHALL provide a `deploy-all.sh` script in the project root that executes all modular scripts from `deploy_scripts/` in the correct deployment sequence with proper error handling.

#### Scenario: Execute full deployment via orchestrator
- **WHEN** a user runs `./deploy-all.sh` from project root
- **THEN** all six modular scripts execute in sequence
- **AND** execution stops immediately if any script fails
- **AND** error messages indicate which phase failed

#### Scenario: Orchestrator maintains deployment order
- **WHEN** `deploy-all.sh` executes
- **THEN** scripts execute in the correct order: secrets, build, tag, registry, push, deploy
- **AND** each script completes successfully before the next begins

### Requirement: Modular scripts use consistent error handling
Each modular script SHALL use consistent error handling with exit codes and error messages that clearly indicate the failure point.

#### Scenario: Script fails with clear error message
- **WHEN** a modular script encounters an error
- **THEN** the script exits with a non-zero exit code
- **AND** an error message indicates which phase and operation failed

#### Scenario: Orchestrator detects script failure
- **WHEN** a modular script exits with non-zero code
- **THEN** the orchestrator stops execution
- **AND** reports which script failed

### Requirement: Project root remains uncluttered
The system SHALL keep the project root directory uncluttered by placing all helper scripts in the dedicated `deploy_scripts/` directory, with only the master orchestrator in the root.

#### Scenario: Project root contains only orchestrator
- **WHEN** the refactoring is complete
- **THEN** project root contains only `deploy-all.sh` (replacing `deploy.sh`)
- **AND** all other deployment scripts are in `deploy_scripts/` directory

#### Scenario: Helper scripts are organized in dedicated directory
- **WHEN** a user lists the `deploy_scripts/` directory
- **THEN** all six modular scripts are present and organized
- **AND** each script name clearly indicates its purpose



## Design

## Context

The current [`deploy.sh`](deploy.sh) script is a 338KB monolithic bash script that handles all deployment phases in a single file. This creates several problems:

1. **Context Token Consumption**: The entire script is loaded into ralph-loop development sessions, consuming excessive tokens and making it difficult to focus on specific problematic sections
2. **Debugging Difficulty**: Extensive debug logging throughout all phases makes it hard to isolate issues - working phases produce as much output as failing phases
3. **Maintenance Burden**: A single large file is difficult to understand, modify, and test in isolation
4. **Testing Inefficiency**: Cannot test individual phases without running the entire deployment pipeline

Based on [`deploy_log_explanation.md`](deploy_log_explanation.md), the current deployment status is:
- **PROBLEMATIC**: Kubernetes secrets setup (validation inconsistency)
- **SUCCESS**: Docker build, image tagging, Microk8s registry setup
- **PARTIAL SUCCESS**: Docker registry push (timing issue with verification)
- **CRITICAL FAILURE**: Kubernetes deployment (health check failures)

The refactoring will split the monolithic script into modular components while maintaining the same deployment functionality.

## Goals / Non-Goals

**Goals:**
- Reduce context token consumption during ralph-loop development by splitting [`deploy.sh`](deploy.sh) into smaller, focused scripts
- Enable isolated testing and debugging of individual deployment phases
- Optimize debug output by removing verbose logging from working phases while retaining it for problematic phases
- Maintain project root cleanliness by organizing helper scripts in a dedicated `deploy_scripts/` directory
- Preserve all existing deployment functionality without breaking the deployment process

**Non-Goals:**
- Changing the deployment process or workflow (only refactoring implementation)
- Modifying application behavior or requirements
- Adding new deployment features or capabilities
- Changing the Kubernetes configuration or application health checks
- Optimizing deployment performance (focus is on developer experience, not execution speed)

## Decisions

### Decision 1: Modular Script Architecture
**Choice**: Split [`deploy.sh`](deploy.sh) into 6 independently executable scripts in `deploy_scripts/` directory, with a master orchestrator in project root

**Rationale**:
- Each script can be tested and debugged in isolation, reducing context tokens needed for focused development
- Clear separation of concerns makes each script easier to understand and maintain
- Scripts can be executed independently or via orchestrator, providing flexibility
- Organizing in `deploy_scripts/` keeps project root uncluttered while maintaining discoverability

**Alternatives Considered**:
- **Single script with functions**: Would still require loading entire file, not solving context token issue
- **Makefile-based approach**: Would introduce new dependency and learning curve, bash scripts are more accessible
- **Ansible/Terraform**: Overkill for this use case, would require significant infrastructure changes

### Decision 2: Debug Output Strategy
**Choice**: Phase-specific debug levels based on deployment status (problematic, successful, partial)

**Rationale**:
- Retains debugging capability where needed (problematic phases) while reducing noise elsewhere
- Aligns with current deployment status from [`deploy_log_explanation.md`](deploy_log_explanation.md)
- Reduces context token consumption by removing verbose output from working phases
- Optional `DEBUG=all` flag provides flexibility for temporary full debugging

**Alternatives Considered**:
- **Remove all debug output**: Would make debugging impossible when issues arise
- **Keep all debug output**: Would not solve context token consumption problem
- **Use logging levels (INFO, DEBUG, ERROR)**: More complex to implement, phase-specific approach is simpler and more targeted

### Decision 3: Error Handling Pattern
**Choice**: Consistent error handling with `set -e` and explicit exit codes, plus clear error messages

**Rationale**:
- `set -e` ensures scripts stop immediately on errors, preventing cascading failures
- Explicit exit codes allow orchestrator to detect and report failures
- Clear error messages help developers quickly identify which phase and operation failed
- Consistent pattern across all scripts improves maintainability

**Alternatives Considered**:
- **Continue on error**: Would make debugging harder as failures might be masked
- **Custom error handling framework**: Overkill for this refactoring, standard bash error handling is sufficient

### Decision 4: Orchestrator Implementation
**Choice**: Simple bash script that executes modular scripts in sequence with error checking

**Rationale**:
- Minimal implementation reduces complexity and maintenance burden
- Easy to understand and modify
- No additional dependencies required
- Preserves existing deployment workflow (replace [`deploy.sh`](deploy.sh) with `deploy-all.sh`)

**Alternatives Considered**:
- **Makefile**: Would require learning Make syntax, bash is more accessible
- **Python orchestrator**: Would introduce Python dependency, overkill for simple sequential execution
- **Parallel execution**: Would complicate error handling and debugging, sequential is safer

### Decision 5: Script Naming Convention
**Choice**: Descriptive kebab-case names with clear phase indication

**Rationale**:
- Names like `setup-k8s-secrets.sh` clearly indicate the phase and operation
- Consistent naming convention improves discoverability
- kebab-case is standard for bash scripts and easy to read

**Alternatives Considered**:
- **Numeric prefixes (01-secrets.sh, 02-build.sh)**: Would enforce order but reduce readability
- **Abbreviated names**: Would be harder to understand for new developers
- **CamelCase**: Less common for bash scripts

## Risks / Trade-offs

### Risk 1: Breaking Existing Workflows
**Risk**: Existing workflows that directly invoke [`deploy.sh`](deploy.sh) will break after replacement with `deploy-all.sh`

**Mitigation**:
- Document the breaking change clearly in proposal and design
- Provide migration guide for updating workflows
- Consider creating a compatibility wrapper that calls `deploy-all.sh` if needed

### Risk 2: Script Dependencies
**Risk**: Modular scripts may have hidden dependencies on each other (e.g., environment variables, state)

**Mitigation**:
- Design each script to be truly independent
- Use configuration files or environment variables for shared state
- Test each script in isolation during development
- Document any required prerequisites in script headers

### Risk 3: Debug Output Removal
**Risk**: Removing debug output from successful phases may make it harder to diagnose new issues if those phases start failing

**Mitigation**:
- Provide `DEBUG=all` flag to temporarily enable full debugging
- Keep original [`deploy.sh`](deploy.sh) in archive for reference if needed
- Document how to re-enable debug output for specific phases
- Consider adding verbose flag per script

### Risk 4: Context Token Savings May Be Limited
**Risk**: If ralph-loop loads all scripts from `deploy_scripts/` directory anyway, context token savings may be minimal

**Mitigation**:
- Design scripts to be loaded only when needed (e.g., use source commands selectively)
- Measure actual context token consumption before and after refactoring
- If savings are minimal, focus on other benefits (isolated testing, maintainability)

### Risk 5: Increased File Count
**Risk**: Having 7 scripts instead of 1 may increase complexity for simple deployments

**Mitigation**:
- Keep orchestrator simple for common use case (full deployment)
- Document how to use individual scripts for advanced scenarios
- Ensure orchestrator is the default/recommended approach for most users

## Migration Plan

### Phase 1: Analysis and Preparation
1. Analyze current [`deploy.sh`](deploy.sh) to identify distinct phases and their boundaries
2. Identify shared functions, variables, and dependencies across phases
3. Document current debug output levels and which lines are verbose
4. Create `deploy_scripts/` directory structure

### Phase 2: Extract Modular Scripts
1. Extract each phase into a separate script in `deploy_scripts/`:
   - `setup-k8s-secrets.sh` (PROBLEMATIC - retain full debug)
   - `build-docker-image.sh` (SUCCESS - remove debug)
   - `tag-docker-image.sh` (SUCCESS - remove debug)
   - `setup-microk8s-registry.sh` (SUCCESS - remove debug)
   - `push-docker-image.sh` (PARTIAL SUCCESS - minimal debug)
   - `deploy-to-k8s.sh` (CRITICAL FAILURE - retain full debug)
2. Add debug level documentation comments to each script
3. Implement `DEBUG=all` flag support in each script
4. Test each script independently to ensure it works in isolation

### Phase 3: Create Orchestrator
1. Create `deploy-all.sh` in project root
2. Implement sequential execution of all modular scripts
3. Add error handling to stop on failure and report which script failed
4. Test orchestrator with full deployment pipeline

### Phase 4: Validation and Rollout
1. Test all scripts in isolation and via orchestrator
2. Verify deployment functionality matches original [`deploy.sh`](deploy.sh)
3. Measure context token consumption improvement
4. Archive original [`deploy.sh`](deploy.sh) for reference
5. Update documentation and workflows to use new scripts
6. Monitor for issues and gather feedback

### Rollback Strategy
- Keep original [`deploy.sh`](deploy.sh) archived in `archive/` directory
- If critical issues arise, restore [`deploy.sh`](deploy.sh) and remove `deploy-all.sh`
- Document rollback procedure in deployment documentation

## Open Questions

1. **Debug Flag Implementation**: Should `DEBUG=all` be an environment variable or a command-line flag? (Environment variable is simpler to implement and use)

2. **Shared State Management**: How should shared state (e.g., image ID, registry URL) be passed between scripts? (Environment variables or config file - to be decided during implementation)

3. **Script Dependencies**: Are there any hidden dependencies between phases that need to be documented? (To be identified during Phase 1 analysis)

4. **Context Token Measurement**: How will we measure the actual context token savings? (To be determined based on ralph-loop capabilities)

5. **Compatibility Wrapper**: Should we create a compatibility wrapper that allows existing workflows to continue using `deploy.sh` command? (Depends on how many existing workflows exist)

## Current Task Context

## Current Task
- 1.1 Create `deploy_scripts/` directory in project root
