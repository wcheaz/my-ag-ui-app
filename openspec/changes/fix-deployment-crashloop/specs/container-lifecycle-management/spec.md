## ADDED Requirements

### Requirement: Container runs as persistent server process
The application container SHALL run as a persistent server process that stays alive and continues to handle HTTP requests indefinitely when started in production mode.

#### Scenario: Container stays running after startup
- **WHEN** the container is started with production configuration
- **THEN** the container process does not exit after initial startup
- **AND** the container continues to run and accept HTTP requests
- **AND** the container exit code is not 0 (indicating successful completion)

### Requirement: Container does not exit with code 0 in production mode
The application container SHALL NOT exit with exit code 0 when running in production mode, as this indicates the application completed successfully rather than running as a server.

#### Scenario: Container exit code is non-zero or process stays running
- **WHEN** the container is started in production mode
- **THEN** the container process does not terminate with exit code 0
- **AND** the container remains running as a server process

### Requirement: Production server listens on configured port
The application container SHALL start an HTTP server that listens on the configured port (default 3000) and remains ready to accept connections.

#### Scenario: Server listens on port 3000
- **WHEN** the container starts in production mode
- **THEN** an HTTP server process is listening on port 3000
- **AND** the server remains listening and accepting connections
- **AND** the server does not shut down after serving initial requests

### Requirement: Container handles graceful shutdown signals
The application container SHALL handle SIGTERM signals gracefully by shutting down the server process cleanly without crashing.

#### Scenario: Graceful shutdown on SIGTERM
- **WHEN** the container receives a SIGTERM signal
- **THEN** the application initiates graceful shutdown
- **AND** the server stops accepting new connections
- **AND** in-flight requests are allowed to complete
- **AND** the container exits with code 0 after shutdown completes
