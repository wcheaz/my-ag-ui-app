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

**Decision:** Allocate 2 CPUs, 4GB RAM, and 20GB disk for the VM.

**Rationale:**
- Sufficient resources for microk8s and the application
- Reasonable balance between performance and host resource usage
- Meets microk8s minimum requirements (2 CPUs, 4GB RAM)
- Allows room for future expansion

**Alternatives Considered:**
- 1 CPU, 2GB RAM: Below microk8s minimum, would fail
- 4 CPUs, 8GB RAM: Overkill for single-node cluster, wastes resources

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
