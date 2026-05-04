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
