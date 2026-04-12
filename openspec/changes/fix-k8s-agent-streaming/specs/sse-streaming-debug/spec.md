## ADDED Requirements

### Requirement: SSE streaming MUST work end-to-end through the Kubernetes deployment
The system SHALL ensure that Server-Sent Events from the agent reach the browser without truncation, buffering, or timeout when accessed through the Kubernetes deployment at `http://my-ag-ui-app.local/`. The complete agent response (including procurement code and justification) MUST be delivered to the user.

#### Scenario: Agent streams complete response through Kubernetes
- **WHEN** a user submits a procurement material description at `http://my-ag-ui-app.local/`
- **THEN** the agent acknowledges the request
- **AND** the agent processes the request with full analysis
- **AND** the agent streams the complete response including procurement code and justification
- **AND** the browser receives all SSE events without truncation

#### Scenario: SSE response matches local development behavior
- **WHEN** the same procurement request is submitted in both local dev and Kubernetes
- **THEN** the Kubernetes response contains the same procurement code as the local response
- **AND** both responses include complete analysis and justification

### Requirement: System MUST provide diagnostic script for SSE chain verification
The system SHALL provide a script (`test/debug_k8s_sse_streaming.sh`) that tests SSE connectivity at each hop in the chain: agent pod health, agent service SSE, frontend-to-agent proxy, and ingress. The script MUST produce a report identifying which hop (if any) fails.

#### Scenario: Diagnostic script tests agent pod health
- **WHEN** `test/debug_k8s_sse_streaming.sh` is executed
- **THEN** it tests `GET /api/health` on the agent pod IP directly
- **AND** reports success or failure with HTTP status code

#### Scenario: Diagnostic script tests agent service SSE
- **WHEN** `test/debug_k8s_sse_streaming.sh` is executed
- **THEN** it tests SSE connectivity to `agent-service:8000` from within a frontend pod
- **AND** reports whether SSE events are received

#### Scenario: Diagnostic script tests CopilotKit proxy
- **WHEN** `test/debug_k8s_sse_streaming.sh` is executed
- **THEN** it tests `POST /api/copilotkit` on the frontend pod
- **AND** reports whether the CopilotKit runtime proxies SSE events correctly

#### Scenario: Diagnostic script produces a summary report
- **WHEN** `test/debug_k8s_sse_streaming.sh` completes all hops
- **THEN** it outputs a summary table showing pass/fail for each hop
- **AND** it identifies the specific hop where SSE streaming breaks (if any)

### Requirement: System MUST provide verification test for SSE streaming fix
The system SHALL provide a test (`test/verify_k8s_sse_fix.sh`) that submits a real procurement request to the Kubernetes deployment and validates the response contains a complete procurement code.

#### Scenario: Verification test confirms complete response
- **WHEN** `test/verify_k8s_sse_fix.sh` is executed
- **THEN** it submits a test procurement request to `http://my-ag-ui-app.local/`
- **AND** it validates the response contains SSE events
- **AND** it validates the response is not truncated (ends with a terminal event)
- **AND** it exits with code 0 on success

#### Scenario: Verification test detects truncated response
- **WHEN** the agent response is truncated or missing in Kubernetes
- **THEN** `test/verify_k8s_sse_fix.sh` exits with non-zero code
- **AND** it reports which validation failed
