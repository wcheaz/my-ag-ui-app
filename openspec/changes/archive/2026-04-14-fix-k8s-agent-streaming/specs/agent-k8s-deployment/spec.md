## MODIFIED Requirements

### Requirement: Agent deployment must support long-running SSE connections
The agent Deployment SHALL be configured with uvicorn settings appropriate for SSE streaming, including sufficient timeout values and keep-alive configuration. The resource limits SHALL accommodate the memory requirements of LLM processing during streaming.

#### Scenario: Agent uvicorn allows long-running connections
- **WHEN** the agent container starts
- **THEN** uvicorn is configured with appropriate timeout settings for SSE
- **AND** the uvicorn process does not kill idle connections prematurely

#### Scenario: Agent pod has sufficient memory for streaming
- **WHEN** the agent processes a procurement request
- **THEN** the pod does not exceed its memory limit
- **AND** no OOMKilled events appear in pod status
- **AND** `kubectl describe pod <agent-pod>` shows no memory-related restarts

#### Scenario: Agent container logs show complete request processing
- **WHEN** a procurement request is submitted to the K8s deployment
- **THEN** agent pod logs show the request being received
- **AND** agent pod logs show the full processing pipeline (rules loaded, components clarified, code generated)
- **AND** agent pod logs show the response being sent (not interrupted)
