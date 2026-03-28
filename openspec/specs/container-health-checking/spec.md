## ADDED Requirements

### Requirement: Health check endpoint responds with HTTP 200
The application container SHALL respond to HTTP GET requests on /api/health endpoint with status code 200 when the application is ready to serve traffic.

#### Scenario: Health check returns 200 when application is ready
- **WHEN** Kubernetes liveness probe sends GET request to /api/health
- **THEN** application returns HTTP status 200
- **AND** response includes application status

#### Scenario: Health check returns 200 when application is starting
- **WHEN** Kubernetes readiness probe sends GET request to /api/health during application startup
- **THEN** application returns HTTP status 200 once ready
- **AND** application is marked as ready for traffic

### Requirement: Container runs continuously as a service
The application container SHALL run as a long-running service and not terminate after initialization, ensuring continuous availability.

#### Scenario: Container remains running after startup
- **WHEN** application container starts
- **THEN** container process runs continuously
- **AND** container does not exit with code 0
- **AND** container responds to health checks

### Requirement: Liveness probe detects application crashes
The Kubernetes liveness probe SHALL detect when the application has crashed or become unresponsive and trigger a container restart.

#### Scenario: Liveness probe triggers restart on failure
- **WHEN** liveness probe fails 3 consecutive times
- **THEN** Kubernetes restarts the container
- **AND** new container instance is created
- **AND** restart count is incremented

### Requirement: Readiness probe prevents traffic to unready containers
The Kubernetes readiness probe SHALL prevent traffic from being routed to containers that are not yet ready to serve requests.

#### Scenario: Readiness probe marks container as ready
- **WHEN** readiness probe succeeds for the first time
- **THEN** container is marked as ready
- **AND** traffic is routed to the container
- **AND** Kubernetes service includes the container in load balancing

#### Scenario: Readiness probe withholds traffic during startup
- **WHEN** container is starting and readiness probe has not yet succeeded
- **THEN** container is marked as not ready
- **AND** no traffic is routed to the container
- **AND** Kubernetes service excludes the container from load balancing

### Requirement: Health check endpoint path is configurable
The health check endpoint path SHALL be configurable through environment variables to support different application configurations.

#### Scenario: Health check path configured via environment variable
- **WHEN** HEALTH_CHECK_PATH environment variable is set to /custom/health
- **THEN** Kubernetes probes use /custom/health endpoint
- **AND** application responds to health checks at configured path
