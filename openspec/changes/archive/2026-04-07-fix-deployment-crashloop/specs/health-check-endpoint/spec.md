## ADDED Requirements

### Requirement: Health endpoint responds with HTTP 200 when application is healthy
The application SHALL provide an HTTP GET endpoint at `/api/health` that returns HTTP status code 200 when the application is running and able to handle requests.

#### Scenario: Successful health check
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the application responds with HTTP status code 200
- **AND** the response body contains a JSON object with a `status` field set to `"healthy"`

### Requirement: Health endpoint returns JSON status object
The `/api/health` endpoint SHALL return a JSON response body that includes a `status` field indicating the application health state.

#### Scenario: Health check returns valid JSON
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the response `Content-Type` header is `application/json`
- **AND** the response body is valid JSON
- **AND** the JSON object contains a `status` field with value `"healthy"`

### Requirement: Health endpoint is accessible on port 3000
The `/api/health` endpoint SHALL be accessible on the application's configured HTTP port (default 3000) without requiring authentication.

#### Scenario: Health check accessible without authentication
- **WHEN** a client sends an HTTP GET request to `http://localhost:3000/api/health` without authentication headers
- **THEN** the application responds with HTTP status code 200
- **AND** the response body contains the health status JSON object

### Requirement: Health endpoint responds quickly
The `/api/health` endpoint SHALL respond within 1 second under normal operating conditions to satisfy Kubernetes readiness probe timeouts.

#### Scenario: Health check responds within timeout
- **WHEN** a client sends an HTTP GET request to `/api/health`
- **THEN** the application responds within 1000 milliseconds
- **AND** the response contains HTTP status code 200
