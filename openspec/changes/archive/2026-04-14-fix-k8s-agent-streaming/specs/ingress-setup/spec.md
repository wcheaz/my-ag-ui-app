## MODIFIED Requirements

### Requirement: Ingress must support SSE streaming without buffering or truncation
The ingress SHALL be configured with NGINX annotations that disable response buffering, disable request buffering, extend read and send timeouts to 3600 seconds, and set the connection proxy header to keep-alive. These annotations MUST be applied correctly and the NGINX ingress controller MUST reload the configuration after changes.

#### Scenario: Ingress SSE annotations are present and correct
- **WHEN** `k8s/ingress.yaml` is examined
- **THEN** it includes `nginx.ingress.kubernetes.io/proxy-buffering: "off"`
- **AND** it includes `nginx.ingress.kubernetes.io/proxy-request-buffering: "off"`
- **AND** it includes `nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"`
- **AND** it includes `nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"`
- **AND** it includes `nginx.ingress.kubernetes.io/connection-proxy-header: "keep-alive"`

#### Scenario: Ingress does not buffer SSE responses
- **WHEN** SSE events are streamed from the frontend through the ingress
- **THEN** each event arrives at the client immediately (not batched)
- **AND** no events are lost due to buffering

#### Scenario: Ingress does not timeout during long agent processing
- **WHEN** the agent takes more than 60 seconds to produce a response
- **THEN** the ingress connection remains open
- **AND** the SSE stream continues without interruption

#### Scenario: Ingress annotations are verified as active on the cluster
- **WHEN** `multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe ingress my-ag-ui-app-ingress` is executed
- **THEN** all SSE-related annotations appear in the output
- **AND** the ingress shows the updated configuration
