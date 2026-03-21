# Product Requirements Document

*Generated from OpenSpec artifacts*

## Proposal

## Why

The application currently lacks a standardized, production-ready deployment infrastructure. Containerization and Kubernetes deployment will provide scalability, portability, and consistent deployment environments. Running the cluster within a multipass-managed VM offers isolation and resource control while maintaining simplicity for development and testing workflows.

## What Changes

- **Containerize the application** using Docker with optimized multi-stage builds
- **Create a multipass VM** to host the Kubernetes cluster with appropriate resource allocation
- **Deploy microk8s** within the VM to provide a lightweight Kubernetes distribution
- **Set up Kubernetes manifests** for deployment, service, and ingress resources
- **Configure ingress** to expose the application externally with proper routing
- **Automate the entire deployment process** for ralph-loop execution without human interaction
- **Update README.md** with cluster setup and access instructions
- **Create hidden/KUBERNETES-EXPLANATION.md** with technical implementation details

## Capabilities

### New Capabilities
- `containerization`: Docker containerization of the application with optimized builds and production-ready configuration
- `kubernetes-deployment`: Kubernetes deployment using microk8s with deployment, service, and ingress manifests
- `vm-provisioning`: Automated VM creation and management using multipass with appropriate CPU, memory, and disk allocation
- `ingress-setup`: Ingress controller configuration and routing rules for external application access
- `deployment-automation`: Fully automated deployment pipeline suitable for ralph-loop execution with no human interaction required

### Modified Capabilities
- None (no existing spec-level requirement changes)

## Impact

- **Code**: New Dockerfile, Kubernetes manifests (deployment.yaml, service.yaml, ingress.yaml), deployment scripts
- **Dependencies**: Requires Docker, multipass, and microk8s installed on the host system
- **Documentation**: Updates to README.md with deployment instructions; new hidden/KUBERNETES-EXPLANATION.md with technical details
- **Development Workflow**: New automated deployment process that can be executed by ralph-loop without manual intervention
- **Infrastructure**: Introduces VM-based deployment model with multipass and microk8s as the infrastructure layer

## Specifications

containerization/spec.md
## ADDED Requirements

### Requirement: Application must be containerized using Docker
The system SHALL provide a Dockerfile that builds a production-ready container image of the application using multi-stage builds to optimize image size and security.

#### Scenario: Successful container build
- **WHEN** user executes `docker build -t my-ag-ui-app:latest .`
- **THEN** Docker builds the image successfully without errors
- **AND** the image size is optimized using multi-stage builds
- **AND** the image contains only runtime dependencies

#### Scenario: Container runs successfully
- **WHEN** user executes `docker run -p 3000:3000 my-ag-ui-app:latest`
- **THEN** the container starts without errors
- **AND** the application is accessible on port 3000
- **AND** the application responds to HTTP requests

### Requirement: Dockerfile must use multi-stage builds
The system SHALL use multi-stage Docker builds to separate build-time and runtime dependencies, reducing final image size and improving security.

#### Scenario: Build stage separates dependencies
- **WHEN** Dockerfile is examined
- **THEN** it contains at least two stages (build and runtime)
- **AND** the build stage includes all build dependencies
- **AND** the runtime stage includes only runtime dependencies

#### Scenario: Final image is optimized
- **WHEN** final image is built
- **THEN** it does not contain build tools (npm, gcc, etc.)
- **AND** it does not contain development dependencies
- **AND** the image size is minimized

### Requirement: Container must expose correct ports
The system SHALL configure the Dockerfile to expose the application on port 3000 (Next.js default) for internal communication.

#### Scenario: Port is exposed in Dockerfile
- **WHEN** Dockerfile is examined
- **THEN** it contains `EXPOSE 3000`
- **AND** the application is configured to listen on port 3000

#### Scenario: Container accepts connections on exposed port
- **WHEN** container is running
- **THEN** it accepts HTTP connections on port 3000
- **AND** responds with the application content

### Requirement: Container must use appropriate base image
The system SHALL use a lightweight, production-ready base image (e.g., node:alpine) for the runtime stage to minimize image size and attack surface.

#### Scenario: Base image is lightweight
- **WHEN** Dockerfile is examined
- **THEN** the runtime stage uses an Alpine-based image
- **AND** the base image is tagged with a specific version (not `latest`)

#### Scenario: Container has minimal attack surface
- **WHEN** container is built
- **THEN** it contains only essential packages
- **AND** it does not include unnecessary system tools

### Requirement: Container must handle environment variables
The system SHALL support environment variable configuration for runtime settings, including database connections, API keys, and other configuration values.

#### Scenario: Environment variables are passed to container
- **WHEN** container is started with `-e` flags
- **THEN** the application receives the environment variables
- **AND** the application uses them for configuration

#### Scenario: Application fails gracefully with missing required variables
- **WHEN** container is started without required environment variables
- **THEN** the application logs an error message
- **AND** the container exits with a non-zero status code

### Requirement: Container must include health check
The system SHALL include a health check mechanism to allow orchestrators to determine if the container is running correctly.

#### Scenario: Health check endpoint exists
- **WHEN** container is running
- **THEN** the application responds to `/health` or `/api/health` endpoint
- **AND** returns HTTP 200 status when healthy

#### Scenario: Health check fails when application is unhealthy
- **WHEN** application is not functioning correctly
- **THEN** the health check endpoint returns a non-200 status
- **AND** the orchestrator can detect the unhealthy state

deployment-automation/spec.md
## ADDED Requirements

### Requirement: System must provide fully automated deployment script
The system SHALL provide a single bash script that automates the entire deployment process from VM creation to application access, requiring no human interaction.

#### Scenario: Deployment script executes successfully
- **WHEN** `./deploy.sh` is executed
- **THEN** the entire deployment process completes without user input
- **AND** all steps are executed in the correct order
- **AND** the application is accessible at the end

#### Scenario: Deployment script is idempotent
- **WHEN** the deployment script is executed multiple times
- **THEN** it handles existing resources correctly
- **AND** does not create duplicate resources
- **AND** updates existing resources if needed

### Requirement: Deployment script must include pre-deployment checks
The system SHALL verify that all required tools (multipass, Docker) are installed and that sufficient system resources are available before starting deployment.

#### Scenario: Multipass installation is checked
- **WHEN** deployment script starts
- **THEN** it checks if multipass is installed
- **AND** proceeds if installed
- **OR** fails with clear error message if not installed

#### Scenario: Docker installation is checked
- **WHEN** deployment script starts
- **THEN** it checks if Docker is installed
- **AND** proceeds if installed
- **OR** fails with clear error message if not installed

#### Scenario: System resources are checked
- **WHEN** deployment script starts
- **THEN** it verifies sufficient system resources are available
- **AND** proceeds if resources are sufficient
- **OR** fails with clear error message if resources are insufficient

### Requirement: Deployment script must handle errors gracefully
The system SHALL detect and handle errors at each step of the deployment process, providing clear error messages and recovery suggestions.

#### Scenario: VM creation fails
- **WHEN** VM creation fails
- **THEN** the deployment script detects the failure
- **AND** provides a clear error message
- **AND** suggests recovery steps
- **AND** exits with a non-zero status code

#### Scenario: Microk8s installation fails
- **WHEN** microk8s installation fails
- **THEN** the deployment script detects the failure
- **AND** provides a clear error message
- **AND** suggests recovery steps
- **AND** exits with a non-zero status code

#### Scenario: Container build fails
- **WHEN** container build fails
- **THEN** the deployment script detects the failure
- **AND** provides a clear error message
- **AND** suggests recovery steps
- **AND** exits with a non-zero status code

### Requirement: Deployment script must provide progress feedback
The system SHALL display clear progress messages throughout the deployment process, indicating which step is being executed and its status.

#### Scenario: Progress is displayed
- **WHEN** deployment script is running
- **THEN** it displays the current step being executed
- **AND** it displays the status of each step (in progress, completed, failed)
- **AND** it provides estimated time remaining if possible

#### Scenario: Completion is confirmed
- **WHEN** deployment is complete
- **THEN** it displays a success message
- **AND** provides the application access URL
- **AND** provides next steps or additional information

### Requirement: Deployment script must support ralph-loop execution
The system SHALL be compatible with ralph-loop automation, requiring no human interaction and providing appropriate exit codes for success/failure.

#### Scenario: Script runs without human interaction
- **WHEN** deployment script is executed by ralph-loop
- **THEN** it completes without requiring any user input
- **AND** all prompts are answered automatically
- **AND** all decisions are made automatically

#### Scenario: Exit codes are appropriate
- **WHEN** deployment succeeds
- **THEN** the script exits with code 0
- **WHEN** deployment fails
- **THEN** the script exits with a non-zero code
- **AND** the exit code indicates the type of failure

### Requirement: Deployment script must include cleanup capability
The system SHALL provide a way to clean up all deployed resources (VM, Kubernetes resources, containers) when they are no longer needed.

#### Scenario: Cleanup script is provided
- **WHEN** `./cleanup.sh` or similar is executed
- **THEN** it removes Kubernetes resources
- **AND** it removes the VM
- **AND** it cleans up any temporary files
- **AND** it confirms cleanup completion

#### Scenario: Cleanup is idempotent
- **WHEN** cleanup script is executed multiple times
- **THEN** it handles non-existent resources gracefully
- **AND** does not fail if resources are already removed

### Requirement: Deployment script must support environment configuration
The system SHALL allow configuration of deployment parameters (VM name, resources, application settings) through environment variables or configuration files.

#### Scenario: Environment variables are supported
- **WHEN** deployment script is executed with environment variables
- **THEN** it uses the provided values
- **AND** applies them to the deployment

#### Scenario: Configuration file is supported
- **WHEN** a configuration file is provided
- **THEN** the deployment script reads the configuration
- **AND** applies the settings to the deployment

### Requirement: Deployment script must include verification steps
The system SHALL verify each step of the deployment process before proceeding to the next step, ensuring resources are created correctly.

#### Scenario: VM creation is verified
- **WHEN** VM is created
- **THEN** the deployment script verifies the VM is running
- **AND** verifies the VM has the correct resources
- **AND** proceeds only if verification succeeds

#### Scenario: Microk8s installation is verified
- **WHEN** microk8s is installed
- **THEN** the deployment script verifies microk8s is ready
- **AND** verifies required add-ons are enabled
- **AND** proceeds only if verification succeeds

#### Scenario: Application deployment is verified
- **WHEN** application is deployed
- **THEN** the deployment script verifies pods are running
- **AND** verifies the application is accessible
- **AND** proceeds only if verification succeeds

### Requirement: Deployment script must handle timeouts
The system SHALL implement appropriate timeouts for each step of the deployment process to prevent indefinite hanging.

#### Scenario: Timeout is configured for each step
- **WHEN** deployment script is executed
- **THEN** each step has a timeout configured
- **AND** the timeout is appropriate for the step

#### Scenario: Timeout is handled gracefully
- **WHEN** a step times out
- **THEN** the deployment script detects the timeout
- **AND** provides a clear error message
- **AND** suggests recovery steps

### Requirement: Deployment script must provide logging
The system SHALL log all deployment activities to a file for debugging and auditing purposes.

#### Scenario: Deployment is logged
- **WHEN** deployment script is executed
- **THEN** it logs all activities to a file
- **AND** includes timestamps for each action
- **AND** includes error messages and stack traces if applicable

#### Scenario: Logs are accessible
- **WHEN** deployment is complete or fails
- **THEN** the log file is available
- **AND** can be reviewed for troubleshooting

### Requirement: Deployment script must support dry-run mode
The system SHALL support a dry-run mode that shows what would be deployed without actually creating resources.

#### Scenario: Dry-run mode is available
- **WHEN** deployment script is executed with dry-run flag
- **THEN** it displays what would be deployed
- **AND** does not create any resources
- **AND** validates the deployment plan

### Requirement: Deployment script must support rollback
The system SHALL provide a way to rollback the deployment to a previous state if issues occur after deployment.

#### Scenario: Rollback is supported
- **WHEN** rollback is initiated
- **THEN** it removes the current deployment
- **AND** restores the previous state if available
- **OR** cleans up all resources if no previous state exists

#### Scenario: Rollback is documented
- **WHEN** rollback is needed
- **THEN** documentation explains how to perform rollback
- **AND** provides the rollback commands

### Requirement: Deployment script must follow best practices
The system SHALL follow industry best practices for deployment automation, including idempotency, error handling, and security.

#### Scenario: Idempotency is maintained
- **WHEN** deployment script is executed multiple times
- **THEN** it produces the same result
- **AND** does not create duplicate resources

#### Scenario: Security best practices are followed
- **WHEN** deployment script is executed
- **THEN** it does not hardcode sensitive information
- **AND** it uses environment variables for secrets
- **AND** it follows the principle of least privilege

### Requirement: Deployment script must be well-documented
The system SHALL include comprehensive documentation for the deployment script, including usage instructions, configuration options, and troubleshooting guide.

#### Scenario: Usage is documented
- **WHEN** deployment script documentation is reviewed
- **THEN** it includes usage instructions
- **AND** it includes configuration options
- **AND** it includes examples

#### Scenario: Troubleshooting is documented
- **WHEN** issues occur during deployment
- **THEN** documentation provides troubleshooting steps
- **AND** includes common issues and solutions
- **AND** includes error message explanations

### Requirement: Deployment script must support testing
The system SHALL provide a way to test the deployment process without affecting production resources.

#### Scenario: Test mode is available
- **WHEN** deployment script is executed in test mode
- **THEN** it uses test resources
- **AND** does not affect production resources
- **AND** can be used for validation

#### Scenario: Test results are reported
- **WHEN** test deployment is complete
- **THEN** it reports the test results
- **AND** indicates success or failure
- **AND** provides details for debugging

### Requirement: Deployment script must handle network issues
The system SHALL detect and handle network connectivity issues during deployment, with appropriate retry logic and error messages.

#### Scenario: Network issues are detected
- **WHEN** network connectivity fails
- **THEN** the deployment script detects the failure
- **AND** provides a clear error message
- **AND** suggests recovery steps

#### Scenario: Retry logic is implemented
- **WHEN** a network request fails
- **THEN** the deployment script retries the request
- **AND** uses exponential backoff
- **AND** eventually succeeds or fails with clear error

ingress-setup/spec.md
## ADDED Requirements

### Requirement: System must enable microk8s ingress add-on
The system SHALL enable the microk8s ingress add-on to provide ingress controller functionality for external application access.

#### Scenario: Ingress add-on is enabled
- **WHEN** `microk8s enable ingress` is executed
- **THEN** the ingress add-on is installed
- **AND** the ingress controller is running
- **AND** the ingress service is available

#### Scenario: Ingress add-on status is verified
- **WHEN** `microk8s status` is checked
- **THEN** the ingress add-on shows as "enabled"
- **AND** the ingress pods are running

### Requirement: System must provide ingress manifest
The system SHALL provide an ingress.yaml manifest that defines how external traffic is routed to the application service.

#### Scenario: Ingress manifest is applied
- **WHEN** `microk8s kubectl apply -f ingress.yaml` is executed
- **THEN** the ingress resource is created
- **AND** the ingress is in the "Ready" state
- **AND** the ingress has an address assigned

#### Scenario: Ingress manifest is valid
- **WHEN** ingress manifest is examined
- **THEN** it specifies the correct ingress class
- **AND** it specifies the correct service name
- **AND** it specifies the correct service port

### Requirement: Ingress must route traffic to application service
The system SHALL configure the ingress to route external HTTP traffic to the application service on port 80.

#### Scenario: Ingress routes to correct service
- **WHEN** ingress manifest is examined
- **THEN** it specifies the application service name
- **AND** it specifies service port 80
- **AND** the backend service is correctly configured

#### Scenario: External traffic reaches application
- **WHEN** HTTP requests are made to the ingress endpoint
- **THEN** they are routed to the application service
- **AND** the application responds correctly

### Requirement: Ingress must support path-based routing
The system SHALL configure the ingress to support path-based routing, allowing the application to be accessed at specific paths if needed.

#### Scenario: Path-based routing is configured
- **WHEN** ingress manifest is examined
- **THEN** it includes path rules if needed
- **AND** paths are correctly mapped to the service

#### Scenario: Requests are routed based on path
- **WHEN** requests are made to specific paths
- **THEN** they are routed according to the ingress rules
- **AND** the application receives the correct requests

### Requirement: Ingress must provide external access
The system SHALL configure the ingress to expose the application externally, allowing access from outside the Kubernetes cluster.

#### Scenario: Ingress provides external endpoint
- **WHEN** ingress is ready
- **THEN** it has an external IP or hostname
- **AND** the application can be accessed from outside the cluster

#### Scenario: Application is accessible via ingress
- **WHEN** a browser or HTTP client accesses the ingress endpoint
- **THEN** the application is displayed
- **AND** all functionality works correctly

### Requirement: Ingress must handle host-based routing
The system SHALL configure the ingress to support host-based routing, allowing the application to be accessed via a specific hostname.

#### Scenario: Host-based routing is configured
- **WHEN** ingress manifest is examined
- **THEN** it includes host rules if needed
- **AND** the hostname is correctly specified

#### Scenario: Requests are routed based on host
- **WHEN** requests are made to the configured hostname
- **THEN** they are routed to the application
- **AND** the application responds correctly

### Requirement: Ingress must support SSL/TLS termination
The system SHALL configure the ingress to support SSL/TLS termination for secure access to the application.

#### Scenario: SSL/TLS is configured
- **WHEN** SSL/TLS certificates are provided
- **THEN** the ingress is configured with the certificates
- **AND** HTTPS traffic is supported

#### Scenario: HTTPS requests are handled
- **WHEN** HTTPS requests are made to the ingress
- **THEN** they are terminated at the ingress
- **AND** the application receives plain HTTP traffic

### Requirement: Ingress must provide health endpoints
The system SHALL ensure that the ingress can be monitored and its health status can be checked.

#### Scenario: Ingress health can be checked
- **WHEN** ingress status is queried
- **THEN** the ingress health status is returned
- **AND** any issues are reported

#### Scenario: Ingress logs are available
- **WHEN** ingress logs are examined
- **THEN** they show incoming requests
- **AND** they show routing decisions
- **AND** they show any errors

### Requirement: Ingress must handle connection errors gracefully
The system SHALL configure the ingress to handle connection errors and provide appropriate error responses.

#### Scenario: Backend service is unavailable
- **WHEN** the application service is unavailable
- **THEN** the ingress returns an appropriate error (502, 503, or 504)
- **AND** the error message is clear

#### Scenario: Connection timeout
- **WHEN** the backend service times out
- **THEN** the ingress returns a timeout error
- **AND** the error message indicates a timeout

### Requirement: Ingress must support load balancing
The system SHALL configure the ingress to distribute traffic across multiple application pods if replicas are configured.

#### Scenario: Traffic is distributed across pods
- **WHEN** multiple application pods are running
- **THEN** the ingress distributes traffic across all pods
- **AND** load balancing is even

#### Scenario: Pod failure is handled
- **WHEN** a pod becomes unhealthy
- **THEN** the ingress stops routing traffic to that pod
- **AND** traffic is routed to healthy pods

### Requirement: Ingress must provide access documentation
The system SHALL document how to access the application through the ingress, including URLs, authentication, and any special requirements.

#### Scenario: Access instructions are documented
- **WHEN** README.md is examined
- **THEN** it includes instructions for accessing the application
- **AND** it provides the ingress URL or hostname
- **AND** it explains any authentication requirements

#### Scenario: Access troubleshooting is documented
- **WHEN** access issues occur
- **THEN** documentation provides troubleshooting steps
- **AND** common issues and solutions are listed

### Requirement: Ingress must support configuration updates
The system SHALL allow the ingress configuration to be updated without downtime, supporting rolling updates to routing rules.

#### Scenario: Ingress configuration is updated
- **WHEN** ingress manifest is updated
- **THEN** the changes are applied without downtime
- **AND** traffic continues to flow during the update

#### Scenario: Ingress updates are validated
- **WHEN** ingress configuration is changed
- **THEN** the new configuration is validated
- **AND** invalid changes are rejected with clear error messages

### Requirement: Ingress must provide metrics and monitoring
The system SHALL ensure that ingress metrics are available for monitoring and performance analysis.

#### Scenario: Ingress metrics are available
- **WHEN** ingress metrics are queried
- **THEN** request counts, response times, and error rates are available
- **AND** metrics can be used for monitoring

#### Scenario: Ingress performance can be analyzed
- **WHEN** ingress performance is analyzed
- **THEN** bottlenecks can be identified
- **AND** optimization opportunities can be found

kubernetes-deployment/spec.md
## ADDED Requirements

### Requirement: System must provide Kubernetes deployment manifest
The system SHALL provide a deployment.yaml manifest that defines how the application container is deployed in Kubernetes, including replicas, resource limits, and health checks.

#### Scenario: Deployment manifest is valid
- **WHEN** `microk8s kubectl apply -f deployment.yaml` is executed
- **THEN** Kubernetes creates the deployment without errors
- **AND** the deployment is in the "Available" state

#### Scenario: Deployment creates correct number of replicas
- **WHEN** deployment is applied
- **THEN** it creates the specified number of replica pods
- **AND** all pods are running and ready

### Requirement: Deployment must include resource limits
The system SHALL configure CPU and memory requests and limits for the deployment to prevent resource exhaustion and ensure fair resource allocation.

#### Scenario: Resource limits are set
- **WHEN** deployment manifest is examined
- **THEN** it includes `resources.requests.cpu` and `resources.requests.memory`
- **AND** it includes `resources.limits.cpu` and `resources.limits.memory`

#### Scenario: Pods respect resource limits
- **WHEN** pods are running
- **THEN** they do not exceed the configured CPU and memory limits
- **AND** Kubernetes enforces the limits

### Requirement: Deployment must include health checks
The system SHALL configure liveness and readiness probes to ensure Kubernetes can detect and restart unhealthy pods, and only route traffic to ready pods.

#### Scenario: Liveness probe is configured
- **WHEN** deployment manifest is examined
- **THEN** it includes a `livenessProbe` section
- **AND** the probe checks the `/health` endpoint
- **AND** it has appropriate failure thresholds and intervals

#### Scenario: Readiness probe is configured
- **WHEN** deployment manifest is examined
- **THEN** it includes a `readinessProbe` section
- **AND** the probe checks the `/health` endpoint
- **AND** it has appropriate failure thresholds and intervals

#### Scenario: Unhealthy pods are restarted
- **WHEN** a pod becomes unhealthy (fails liveness probe)
- **THEN** Kubernetes restarts the pod automatically
- **AND** the pod returns to a healthy state

### Requirement: Deployment must use environment variables and secrets
The system SHALL configure environment variables for the application using Kubernetes secrets for sensitive data and ConfigMaps for non-sensitive configuration, referencing .env.example for required variables.

#### Scenario: Environment variables are configured
- **WHEN** deployment manifest is examined
- **THEN** it includes environment variable references from secrets or ConfigMaps
- **AND** sensitive variables (API keys, tokens) use Kubernetes secrets
- **AND** non-sensitive variables use ConfigMaps or direct values

#### Scenario: .env.example is available as reference
- **WHEN** .env.example file is examined
- **THEN** it lists all required environment variables
- **THEN** it can be read by ralph-loop automation
- **AND** it provides documentation for each variable

#### Scenario: Secrets are created and applied
- **WHEN** deployment script is executed
- **THEN** Kubernetes secrets are created from provided values
- **AND** secrets are applied to the cluster before deployment
- **AND** secrets are not logged or exposed in plain text

### Requirement: System must provide Kubernetes service manifest
The system SHALL provide a service.yaml manifest that defines how the application is exposed within the cluster, including port configuration and selector.

#### Scenario: Service manifest is valid
- **WHEN** `microk8s kubectl apply -f service.yaml` is executed
- **THEN** Kubernetes creates the service without errors
- **AND** the service is in the "Active" state

#### Scenario: Service routes traffic to pods
- **WHEN** traffic is sent to the service
- **THEN** it is correctly routed to the application pods
- **AND** the application responds to requests

### Requirement: Service must use correct port configuration
The system SHALL configure the service to listen on port 80 (for ingress) and forward to port 3000 (application port).

#### Scenario: Service exposes correct ports
- **WHEN** service manifest is examined
- **THEN** it specifies `port: 80` (service port)
- **AND** it specifies `targetPort: 3000` (container port)

#### Scenario: Service accepts connections on configured port
- **WHEN** connections are made to the service on port 80
- **THEN** they are forwarded to the application on port 3000
- **AND** the application responds correctly

### Requirement: System must provide Kubernetes ingress manifest
The system SHALL provide an ingress.yaml manifest that defines how the application is exposed externally, including host rules and path routing.

#### Scenario: Ingress manifest is valid
- **WHEN** `microk8s kubectl apply -f ingress.yaml` is executed
- **THEN** Kubernetes creates the ingress without errors
- **AND** the ingress is in the "Ready" state

#### Scenario: Ingress exposes application externally
- **WHEN** ingress is configured
- **THEN** the application is accessible from outside the cluster
- **AND** HTTP requests are routed to the service

### Requirement: Ingress must use correct routing configuration
The system SHALL configure the ingress to route traffic from the host to the application service, with appropriate path rules.

#### Scenario: Ingress routes to correct service
- **WHEN** ingress manifest is examined
- **THEN** it specifies the correct service name
- **AND** it specifies the correct service port (80)

#### Scenario: Ingress handles path routing
- **WHEN** requests are made to the ingress host
- **THEN** they are routed to the application service
- **AND** the application receives the requests correctly

### Requirement: System must use microk8s as Kubernetes distribution
The system SHALL use microk8s as the Kubernetes distribution, configured with appropriate add-ons for the application.

#### Scenario: Microk8s is installed and running
- **WHEN** deployment script is executed
- **THEN** microk8s is installed in the VM
- **AND** microk8s is in the "Ready" state
- **AND** required add-ons (dns, storage, ingress) are enabled

#### Scenario: Microk8s add-ons are enabled
- **WHEN** `microk8s status` is checked
- **THEN** dns add-on is enabled
- **AND** storage add-on is enabled
- **AND** ingress add-on is enabled

### Requirement: System must handle container image deployment
The system SHALL build the container image and deploy it to the Kubernetes cluster, either using a local registry or loading the image directly into microk8s.

#### Scenario: Container image is built
- **WHEN** deployment script is executed
- **THEN** the Docker image is built successfully
- **AND** the image is tagged appropriately

#### Scenario: Container image is available to cluster
- **WHEN** deployment is applied
- **THEN** the Kubernetes cluster can pull the container image
- **AND** the pods start with the correct image

### Requirement: System must provide deployment verification
The system SHALL include verification steps to ensure the deployment is successful, including pod status checks and application access tests.

#### Scenario: Deployment status is verified
- **WHEN** deployment is complete
- **THEN** all pods are in the "Running" state
- **AND** all pods are "Ready"
- **AND** the deployment is "Available"

#### Scenario: Application access is verified
- **WHEN** application is accessed via ingress
- **THEN** it responds with HTTP 200 status
- **AND** the application content is displayed correctly

vm-provisioning/spec.md
## ADDED Requirements

### Requirement: System must create multipass VM with specified resources
The system SHALL create a multipass VM with 4 CPUs, 7.7GiB RAM, and 19.3GiB disk to host the Kubernetes cluster (matching outlook-monitor-vm specs).

#### Scenario: VM is created with correct CPU allocation
- **WHEN** `multipass launch --cpus 4 --memory 7.7G --disk 19.3G <vm-name>` is executed
- **THEN** VM is created successfully
- **AND** VM has 4 CPUs allocated

#### Scenario: VM is created with correct memory allocation
- **WHEN** VM creation is complete
- **THEN** VM has 7.7GiB of RAM allocated
- **AND** memory is available to the VM

#### Scenario: VM is created with correct disk allocation
- **WHEN** VM creation is complete
- **THEN** VM has 19.3GiB of disk space allocated
- **AND** disk space is available to the VM

### Requirement: System must verify multipass installation
The system SHALL check that multipass is installed on the host system before attempting to create a VM.

#### Scenario: Multipass is installed
- **WHEN** deployment script is executed
- **THEN** it checks for multipass installation
- **AND** proceeds with VM creation if multipass is found

#### Scenario: Multipass is not installed
- **WHEN** multipass is not installed
- **THEN** the deployment script fails with a clear error message
- **AND** provides installation instructions

### Requirement: System must wait for VM to be ready
The system SHALL wait for the VM to be fully initialized and ready before proceeding with microk8s installation.

#### Scenario: VM becomes ready
- **WHEN** VM is created
- **THEN** the deployment script waits for the VM to be ready
- **AND** verifies VM status before proceeding

#### Scenario: VM readiness is verified
- **WHEN** `multipass exec <vm-name> -- uptime` is executed
- **THEN** the command succeeds
- **AND** the VM is responsive

### Requirement: System must configure VM networking
The system SHALL ensure the VM has proper network connectivity to allow Kubernetes cluster communication and external access.

#### Scenario: VM has network connectivity
- **WHEN** VM is created
- **THEN** it has a valid IP address
- **AND** can communicate with external networks
- **AND** can pull container images

#### Scenario: VM networking is verified
- **WHEN** network tests are run
- **THEN** DNS resolution works
- **AND** outbound connectivity works
- **AND** the VM can be accessed from the host

### Requirement: System must handle VM naming
The system SHALL use a consistent naming convention for the VM to avoid conflicts and ensure easy identification.

#### Scenario: VM name is unique
- **WHEN** VM is created
- **THEN** it uses a unique name that doesn't conflict with existing VMs
- **AND** the name is descriptive (e.g., "my-ag-ui-app-k8s")

#### Scenario: VM name is used consistently
- **WHEN** commands are executed against the VM
- **THEN** they all use the same VM name
- **AND** the VM is easily identifiable

### Requirement: System must provide VM cleanup capability
The system SHALL provide a way to clean up the VM when it is no longer needed, including stopping and deleting the VM.

#### Scenario: VM can be stopped
- **WHEN** `multipass stop <vm-name>` is executed
- **THEN** the VM stops gracefully
- **AND** resources are freed

#### Scenario: VM can be deleted
- **WHEN** `multipass delete <vm-name>` is executed
- **THEN** the VM is marked for deletion
- **AND** `multipass purge` removes the VM completely

### Requirement: System must verify VM resources meet microk8s requirements
The system SHALL ensure the VM has sufficient resources to run microk8s (minimum 2 CPUs, 4GB RAM).

#### Scenario: VM resources meet minimum requirements
- **WHEN** VM is created
- **THEN** it has at least 2 CPUs
- **AND** it has at least 4GB of RAM
- **AND** microk8s can be installed successfully

#### Scenario: VM resources are sufficient for application
- **WHEN** application is deployed
- **THEN** the VM has enough resources to run the application
- **AND** the application performs adequately

### Requirement: System must handle VM creation failures
The system SHALL detect and handle VM creation failures with appropriate error messages and recovery steps.

#### Scenario: VM creation fails
- **WHEN** VM creation fails
- **THEN** the deployment script detects the failure
- **AND** provides a clear error message
- **AND** suggests recovery steps

#### Scenario: VM creation is retried
- **WHEN** VM creation fails
- **THEN** the deployment script can retry the operation
- **AND** eventually succeeds or provides clear failure information

### Requirement: System must provide VM status information
The system SHALL provide information about the VM status, including running state, resource usage, and IP address.

#### Scenario: VM status is displayed
- **WHEN** `multipass info <vm-name>` is executed
- **THEN** it shows the VM state (running, stopped, etc.)
- **AND** it shows resource allocation
- **AND** it shows IP address

#### Scenario: VM status is monitored
- **WHEN** deployment is in progress
- **THEN** the deployment script monitors VM status
- **AND** proceeds only when VM is ready

### Requirement: System must support VM access
The system SHALL allow access to the VM for debugging and management purposes.

#### Scenario: VM can be accessed via SSH
- **WHEN** `multipass shell <vm-name>` is executed
- **THEN** an SSH session is established
- **AND** commands can be executed in the VM

#### Scenario: Commands can be executed in VM
- **WHEN** `multipass exec <vm-name> -- <command>` is executed
- **THEN** the command runs in the VM
- **AND** output is returned to the host

### Requirement: System must handle VM resource scaling
The system SHALL provide guidance on scaling VM resources if the application requires more resources.

#### Scenario: VM resources can be scaled
- **WHEN** application requires more resources
- **THEN** documentation provides instructions for scaling
- **AND** the VM can be recreated with more resources

#### Scenario: Resource scaling is documented
- **WHEN** scaling is needed
- **THEN** the documentation explains how to scale
- **AND** provides recommended resource values



## Design

## Context

The application is currently a Next.js application with a Python agent component. It runs locally but lacks a standardized deployment infrastructure. The goal is to create a production-ready deployment pipeline using containerization and Kubernetes, running within a VM for isolation and resource control.

**Current State:**
- Application runs locally with `npm run dev` and agent scripts
- Dockerfile exists but may need optimization for production
- No Kubernetes deployment manifests
- No automated deployment pipeline
- No VM-based infrastructure

**Constraints:**
- Deployment must be fully automated for ralph-loop execution (no human interaction)
- Must use multipass for VM management
- Must use microk8s for Kubernetes cluster
- Must provide ingress for external access
- Must follow best practices for containerization and Kubernetes

**Stakeholders:**
- Development team (needs reliable deployment process)
- ralph-loop automation (needs fully automated deployment)
- End users (need accessible application)

## Goals / Non-Goals

**Goals:**
- Containerize the application with optimized multi-stage Docker builds
- Create an automated multipass VM provisioning process
- Deploy microk8s within the VM with appropriate configuration
- Create Kubernetes manifests (deployment, service, ingress) for the application
- Set up ingress controller and routing for external access
- Automate the entire deployment pipeline for ralph-loop execution
- Document deployment process in README.md
- Provide technical details in hidden/KUBERNETES-EXPLANATION.md

**Non-Goals:**
- Multi-cluster deployment (single cluster only)
- High availability setup (single node cluster)
- Advanced monitoring/logging beyond basic setup
- CI/CD pipeline integration (deployment automation only)
- Production-grade security hardening (basic security only)

## Decisions

### 1. Multi-stage Docker Build

**Decision:** Use multi-stage Docker builds to optimize image size and security.

**Rationale:**
- Reduces final image size by excluding build dependencies
- Improves security by minimizing attack surface
- Separates build-time and runtime dependencies
- Industry best practice for production containers

**Alternatives Considered:**
- Single-stage build: Simpler but larger images, less secure
- BuildKit cache mounts: More complex caching, not necessary for this use case

### 2. Multipass VM Configuration

**Decision:** Allocate 4 CPUs, 7.7GiB RAM, and 19.3GiB disk for the VM (matching outlook-monitor-vm specs exactly).

**Rationale:**
- Sufficient resources for microk8s and the application with headroom
- Matches proven configuration from existing outlook-monitor-vm (4 CPUs, 7.7GiB RAM, 19.3GiB disk)
- Well above microk8s minimum requirements (2 CPUs, 4GB RAM)
- Allows room for future expansion and multiple replicas
- Provides good performance for development and testing

**Alternatives Considered:**
- 2 CPUs, 4GB RAM: Meets minimum but less headroom for growth
- 1 CPU, 2GB RAM: Below microk8s minimum, would fail
- 8 CPUs, 16GB RAM: Overkill for single-node cluster, wastes resources

### 3. Microk8s Add-ons

**Decision:** Enable `dns`, `storage`, and `ingress` add-ons by default.

**Rationale:**
- `dns`: Required for service discovery
- `storage`: Required for persistent volumes (if needed later)
- `ingress`: Required for external application access
- Minimal set to keep cluster lightweight

**Alternatives Considered:**
- All add-ons enabled: Unnecessary bloat, larger attack surface
- Only ingress: Would lack DNS, causing service resolution issues

### 4. Kubernetes Deployment Strategy

**Decision:** Use separate Deployment, Service, and Ingress manifests.

**Rationale:**
- Separation of concerns (deployment vs networking)
- Easier to manage and update individual components
- Follows Kubernetes best practices
- Allows independent scaling and configuration

**Alternatives Considered:**
- Single manifest file: Harder to maintain, less flexible
- Helm charts: Overkill for single application, adds complexity

### 5. Ingress Controller

**Decision:** Use microk8s built-in ingress controller (NGINX-based).

**Rationale:**
- Pre-configured with microk8s, no additional setup
- Lightweight and performant
- Sufficient for single-application deployment
- Well-documented and widely used

**Alternatives Considered:**
- Traefik: More features but unnecessary complexity
- Ambassador API Gateway: Overkill for this use case

### 6. Deployment Automation

**Decision:** Create a single bash script that orchestrates the entire deployment.

**Rationale:**
- Simple and maintainable
- Easy to execute by ralph-loop
- All steps in one place for visibility
- Can be easily debugged if issues arise

**Alternatives Considered:**
- Multiple scripts: More complex, harder to orchestrate
- Ansible/Terraform: Overkill for this scope, adds dependencies

### 7. Application Port Configuration

**Decision:** Use port 3000 internally (Next.js default) and expose via ingress on port 80/443.

**Rationale:**
- Maintains Next.js default configuration
- Standard HTTP/HTTPS ports for external access
- Ingress handles SSL termination (if needed later)

**Alternatives Considered:**
- Custom internal port: Unnecessary deviation from defaults
- Direct port exposure: Less flexible, no ingress benefits

### 8. Health Checks

**Decision:** Implement liveness and readiness probes in the deployment.

**Rationale:**
- Ensures application is running and ready to serve traffic
- Allows Kubernetes to restart unhealthy pods
- Prevents routing traffic to unready pods
- Production best practice

**Alternatives Considered:**
- No health checks: Risk of routing to dead pods
- Only liveness probe: Doesn't ensure readiness before traffic

## Risks / Trade-offs

### Risk 1: Multipass Installation
**Risk:** Multipass may not be installed on the host system, causing deployment failure.

**Mitigation:** Include installation check in deployment script with clear error messages and installation instructions in README.

### Risk 2: Microk8s Resource Constraints
**Risk:** VM may run out of resources under load, causing application instability.

**Mitigation:** Monitor resource usage during testing; provide recommendations for scaling VM resources in documentation.

### Risk 3: Ingress DNS Resolution
**Risk:** Application may not be accessible via hostname if DNS is not properly configured.

**Mitigation:** Use localhost/127.0.0.1 for local testing; document DNS configuration for production use; provide fallback IP-based access instructions.

### Risk 4: Container Image Build Failures
**Risk:** Docker build may fail due to missing dependencies or configuration issues.

**Mitigation:** Test build process thoroughly; include build validation in deployment script; provide troubleshooting steps in documentation.

### Risk 5: Ralph-loop Execution Time
**Risk:** Deployment may take too long for ralph-loop timeouts.

**Mitigation:** Optimize build process; use Docker layer caching; provide timeout configuration recommendations; break deployment into phases if needed.

### Risk 6: Network Connectivity Issues
**Risk:** VM may not have proper network connectivity for pulling images or accessing services.

**Mitigation:** Configure VM networking properly during provisioning; include network diagnostics in deployment script; document network requirements.

### Trade-off 1: Single-node vs Multi-node Cluster
**Trade-off:** Single-node cluster is simpler but lacks high availability.

**Decision:** Accept trade-off for simplicity and resource efficiency; document that this is not HA-ready.

### Trade-off 2: Automated vs Manual Configuration
**Trade-off:** Full automation reduces flexibility but ensures consistency.

**Decision:** Prioritize automation for ralph-loop compatibility; provide manual override options in documentation.

### Trade-off 3: Development vs Production Configuration
**Trade-off:** Optimizing for production may complicate development workflow.

**Decision:** Use production-ready configuration for both; provide development-specific overrides if needed.

## Migration Plan

### Deployment Steps

1. **Pre-deployment Checks**
   - Verify multipass is installed
   - Verify Docker is installed
   - Check available system resources

2. **VM Provisioning**
   - Create multipass VM with specified resources
   - Wait for VM to be ready
   - Verify VM networking

3. **Microk8s Installation**
   - Install microk8s in VM
   - Enable required add-ons (dns, storage, ingress)
   - Wait for microk8s to be ready
   - Verify cluster status

4. **Container Build**
   - Build Docker image with multi-stage build
   - Tag image appropriately
   - Push to local registry (if needed)

5. **Kubernetes Deployment**
   - Apply deployment manifest
   - Apply service manifest
   - Apply ingress manifest
   - Wait for pods to be ready
   - Verify deployment status

6. **Access Configuration**
   - Get ingress endpoint
   - Test application access
   - Document access URL

7. **Documentation Update**
   - Update README.md with deployment instructions
   - Create hidden/KUBERNETES-EXPLANATION.md with technical details

### Rollback Strategy

1. **Delete Kubernetes resources** (ingress, service, deployment)
2. **Delete microk8s cluster** (if needed)
3. **Delete multipass VM** (if needed)
4. **Restore previous application state** (if applicable)

### Rollback Commands

```bash
# Delete Kubernetes resources
microk8s kubectl delete -f k8s/

# Delete VM (if needed)
multipass delete <vm-name>
multipass purge
```

## Open Questions

1. **SSL/TLS Configuration:** Should SSL be configured for ingress? If so, use self-signed certificates or Let's Encrypt?
   - *Decision point:* For local development, self-signed certificates are acceptable. For production, Let's Encrypt should be used.

2. **Persistent Storage:** Does the application require persistent storage for any data?
   - *Decision point:* If yes, configure PVCs in deployment manifest. If no, omit storage configuration.

3. **Resource Limits:** Should CPU and memory limits be set for the deployment?
   - *Decision point:* Yes, set reasonable limits to prevent resource exhaustion. Values to be determined during testing.

4. **Image Registry:** Should images be pushed to a registry or used directly from local build?
   - *Decision point:* For simplicity, use local images. For production, use a proper registry (Docker Hub, ECR, etc.).

5. **Environment Variables:** What environment variables need to be configured for the application?
   - *Decision point:* Review existing .env files and document required variables for Kubernetes deployment.

6. **Health Check Endpoints:** What endpoints should be used for liveness and readiness probes?
   - *Decision point:* Use Next.js default health endpoint or create a custom /health endpoint.

7. **Logging Strategy:** How should application logs be collected and monitored?
   - *Decision point:* Use microk8s logs for basic monitoring. Advanced logging can be added later if needed.

8. **Backup Strategy:** How should application data be backed up?
   - *Decision point:* If persistent storage is used, implement volume snapshots or regular backups.

## Current Task Context

## Current Task
- 11.1 Identify required environment variables for the application
## Completed Tasks for Git Commit
- [x] 1.1 Review and optimize existing Dockerfile for multi-stage builds
- [x] 1.2 Create build stage with all build dependencies (Node.js, npm)
- [x] 1.3 Create runtime stage with lightweight Alpine base image
- [x] 1.4 Configure Dockerfile to expose port 3000
- [x] 1.5 Add health check endpoint configuration to Dockerfile
- [x] 1.6 Configure environment variable support in Dockerfile
- [x] 1.7 Test Docker build locally to ensure it works correctly
- [x] 1.8 Verify container runs successfully with `docker run`
- [x] 1.9 Verify container responds to HTTP requests on port 3000
- [x] 2.1 Create k8s/deployment.yaml with deployment configuration
- [x] 2.2 Configure deployment with appropriate replica count (start with 1)
- [x] 2.3 Add resource requests and limits to deployment (CPU and memory)
- [x] 2.4 Configure liveness probe in deployment manifest
- [x] 2.5 Configure readiness probe in deployment manifest
- [x] 2.6 Create k8s/service.yaml with service configuration
- [x] 2.7 Configure service to listen on port 80 and forward to port 3000
- [x] 2.8 Set up service selector to match deployment pods
- [x] 2.9 Create k8s/ingress.yaml with ingress configuration
- [x] 2.10 Configure ingress to route traffic to the service
- [x] 2.11 Set up ingress class for microk8s ingress controller
- [x] 2.12 Add host-based routing configuration (if needed)
- [x] 2.13 Test Kubernetes manifests locally with `microk8s kubectl apply --dry-run`
- [x] 3.1 Create VM provisioning script section in deployment script
- [x] 3.2 Add multipass installation check to deployment script
- [x] 3.3 Configure VM creation with 4 CPUs, 7.7GiB RAM, 19.3GiB disk
- [x] 3.4 Add VM readiness verification to deployment script
- [x] 3.5 Configure VM networking verification
- [x] 3.6 Add VM status monitoring during deployment
- [x] 3.7 Implement VM cleanup capability in cleanup script
- [x] 3.8 Add VM error handling and recovery suggestions
- [x] 3.9 Test VM creation and deletion
- [x] 4.1 Create microk8s installation section in deployment script
- [x] 4.2 Install microk8s in the VM
- [x] 4.3 Enable dns add-on in microk8s
- [x] 4.4 Enable storage add-on in microk8s
- [x] 4.5 Enable ingress add-on in microk8s
- [x] 4.6 Wait for microk8s to be ready
- [x] 4.7 Verify microk8s status after installation
- [x] 4.8 Add microk8s error handling to deployment script
- [x] 4.9 Test microk8s installation and add-on enablement
- [x] 5.1 Build Docker image in deployment script
- [x] 5.2 Tag Docker image appropriately
- [x] 5.3 Load Docker image into microk8s (or configure image pull)
- [x] 5.4 Create Kubernetes secrets for sensitive environment variables
- [x] 5.5 Apply deployment manifest to microk8s cluster
- [x] 5.6 Apply service manifest to microk8s cluster
- [x] 5.7 Apply ingress manifest to microk8s cluster
- [x] 5.8 Wait for pods to be ready
- [x] 5.9 Verify deployment status
- [x] 5.10 Verify application is accessible via ingress
- [x] 6.1 Verify ingress controller is running
- [x] 6.2 Get ingress endpoint URL/IP
- [x] 6.3 Test application access via ingress
- [x] 6.4 Configure SSL/TLS certificates (if needed)
- [x] 6.5 Test HTTPS access (if SSL is configured)
- [x] 6.6 Verify ingress logs are working
- [x] 6.7 Test ingress error handling
- [x] 6.8 Verify load balancing across pods (if replicas > 1)
- [x] 7.1 Create main deployment script (deploy.sh)
- [x] 7.2 Add pre-deployment checks (multipass, Docker, resources)
- [x] 7.3 Add VM provisioning section
- [x] 7.4 Add microk8s installation section
- [x] 7.5 Add container build section
- [x] 7.6 Add Kubernetes deployment section
- [x] 7.7 Add verification steps after each section
- [x] 7.8 Add progress feedback messages throughout script
- [x] 7.9 Add error handling for each step
- [x] 7.10 Add timeout configuration for each step
- [x] 7.11 Add logging to file throughout script
- [x] 7.12 Make script executable
- [x] 7.13 Test full deployment script execution
- [x] 7.14 Verify script is idempotent (can run multiple times)
- [x] 7.15 Verify script works with ralph-loop (no human interaction)
- [x] 7.16 Verify appropriate exit codes (0 for success, non-zero for failure)
- [x] 8.1 Create cleanup script (cleanup.sh)
- [x] 8.2 Add Kubernetes resource cleanup (delete ingress, service, deployment)
- [x] 8.3 Add microk8s cleanup (optional)
- [x] 8.4 Add VM deletion (multipass delete and purge)
- [x] 8.5 Add cleanup confirmation prompt (or flag for non-interactive)
- [x] 8.6 Add error handling for cleanup failures
- [x] 8.7 Make cleanup script executable
- [x] 8.8 Test cleanup script
- [x] 9.1 Update README.md with deployment prerequisites (multipass, Docker)
- [x] 9.2 Add deployment instructions to README.md
- [x] 9.3 Add application access instructions to README.md (URL, hostname)
- [x] 9.4 Add troubleshooting section to README.md
- [x] 9.5 Create hidden/KUBERNETES-EXPLANATION.md
- [x] 9.6 Document VM configuration in KUBERNETES-EXPLANATION.md
- [x] 9.7 Document microk8s configuration in KUBERNETES-EXPLANATION.md
- [x] 9.8 Document Kubernetes manifests in KUBERNETES-EXPLANATION.md
- [x] 9.9 Document ingress configuration in KUBERNETES-EXPLANATION.md
- [x] 9.10 Document deployment script usage in KUBERNETES-EXPLANATION.md
- [x] 9.11 Document environment variables in KUBERNETES-EXPLANATION.md
- [x] 9.12 Document resource scaling recommendations in KUBERNETES-EXPLANATION.md
- [x] 9.13 Document rollback procedures in KUBERNETES-EXPLANATION.md
- [x] 9.14 Document common issues and solutions in KUBERNETES-EXPLANATION.md
- [x] 10.1 Test container build process
- [x] 10.2 Test container execution locally
- [x] 10.3 Test VM creation and deletion
- [x] 10.4 Test microk8s installation
- [x] 10.5 Test Kubernetes deployment
- [x] 10.6 Test service connectivity
- [x] 10.7 Test ingress routing
- [x] 10.8 Test application access via ingress
- [x] 10.9 Test health checks (liveness and readiness)
- [x] 10.10 Test resource limits
- [x] 10.11 Test deployment script end-to-end
- [x] 10.12 Test cleanup script
- [x] 10.13 Test error handling (simulate failures)
- [x] 10.14 Test script idempotency
- [x] 10.15 Test with ralph-loop automation
- [x] 10.16 Verify all requirements from specs are met
