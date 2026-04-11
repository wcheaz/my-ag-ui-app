## MODIFIED Requirements

### Requirement: Deployment must use environment variables and secrets
The system SHALL configure environment variables for the application using Kubernetes secrets for sensitive data and ConfigMaps for non-sensitive configuration, referencing .env.example for required variables. The frontend deployment manifest MUST include an `env` entry setting `AGENT_URL` to `http://agent-service:8000/` and MUST mount all keys from `my-ag-ui-app-secrets` Secret and `my-ag-ui-app-config` ConfigMap via `envFrom`.

#### Scenario: Environment variables are configured
- **WHEN** deployment manifest is examined
- **THEN** it includes environment variable references from secrets or ConfigMaps
- **AND** sensitive variables (API keys, tokens) use Kubernetes secrets
- **AND** non-sensitive variables use ConfigMaps or direct values

#### Scenario: AGENT_URL is set in frontend deployment
- **WHEN** `k8s/deployment.yaml` is examined
- **THEN** it includes an `env` entry with `name: AGENT_URL` and `value: "http://agent-service:8000/"`
- **AND** the value is a literal string (not derived from a ConfigMap or Secret)

#### Scenario: Frontend deployment mounts secrets via envFrom
- **WHEN** `k8s/deployment.yaml` is examined
- **THEN** it includes `envFrom` with `secretRef.name: my-ag-ui-app-secrets`
- **AND** it includes `envFrom` with `configMapRef.name: my-ag-ui-app-config`

#### Scenario: Frontend pod receives secrets at runtime
- **WHEN** a frontend pod is running
- **THEN** the environment contains `AGENT_URL` equal to `http://agent-service:8000/`
- **AND** the environment contains `openai-api-key`, `openai-base-url`, `openai-model` from the mounted Secret

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
