## 1. Next.js Configuration

- [x] 1.1 Update `next.config.ts` to enable standalone output mode
  - Done when: `next.config.ts` contains `output: 'standalone'` in the export configuration
  - Verify by: Running `npm run build` and confirming standalone output is generated in `.next/standalone`

- [x] 1.2 Test production build locally with standalone output
  - Done when: Production build completes successfully and standalone directory contains all necessary files
  - Verify by: Running `npm run build` and checking `.next/standalone/` directory exists with required files

## 2. Health Check Endpoint Implementation

- [x] 2.1 Create `/api/health` API route in Next.js application
  - Done when: API route file exists at `app/api/health/route.ts` or `pages/api/health.ts` (depending on router used)
  - Verify by: Checking the file exists and contains a GET handler function

- [x] 2.2 Implement health endpoint to return HTTP 200 with JSON status
  - Done when: Endpoint returns HTTP 200 with JSON body containing `{"status": "healthy"}`
  - Verify by: Running `curl http://localhost:3000/api/health` and confirming response is `{"status":"healthy"}` with status code 200

- [x] 2.3 Test health endpoint responds within 1 second
  - Done when: Endpoint consistently responds within 1000ms under normal conditions
  - Verify by: Running `time curl http://localhost:3000/api/health` and confirming real time is < 1s

- [x] 2.4 Verify health endpoint is accessible without authentication
  - Done when: Endpoint returns HTTP 200 when called without authentication headers
  - Verify by: Running `curl http://localhost:3000/api/health` without auth headers and confirming 200 response

## 3. Docker Configuration

- [x] 3.1 Update Dockerfile to set NODE_ENV=production
  - Done when: Dockerfile contains `ENV NODE_ENV=production` before build steps
  - Verify by: Inspecting Dockerfile and confirming environment variable is set

- [x] 3.2 Configure Dockerfile to use Next.js standalone output
  - Done when: Dockerfile copies `.next/standalone` directory and sets it as working directory
  - Verify by: Building Docker image and checking container filesystem contains standalone output

- [x] 3.3 Update Dockerfile CMD to use `npm start` for production server
  - Done when: Dockerfile CMD is `["npm", "start"]` or equivalent production server command
  - Verify by: Inspecting Dockerfile and confirming CMD starts production server

- [x] 3.4 Test Docker container stays running in production mode
  - Done when: Container starts and stays running without exiting with code 0
  - Verify by: Running `docker run -p 3000:3000 my-ag-ui-app:latest` and confirming container remains running

- [x] 3.5 Verify container does not exit with code 0 in production mode
  - Done when: Container process does not terminate with exit code 0 after startup
  - Verify by: Running container and checking exit code is not 0 or process stays running

## 4. Kubernetes Configuration

- [x] 4.1 Update `k8s/deployment.yaml` to configure readiness probe for `/api/health`
  - Done when: Deployment manifest contains readinessProbe with path `/api/health`, port 3000, initialDelaySeconds 10, periodSeconds 10, timeoutSeconds 1, failureThreshold 3
  - Verify by: Inspecting `k8s/deployment.yaml` and confirming readinessProbe configuration

- [x] 4.2 Update `k8s/deployment.yaml` to configure liveness probe for `/api/health`
  - Done when: Deployment manifest contains livenessProbe with path `/api/health`, port 3000, initialDelaySeconds 30, periodSeconds 10, timeoutSeconds 1, failureThreshold 3
  - Verify by: Inspecting `k8s/deployment.yaml` and confirming livenessProbe configuration

- [x] 4.3 Verify probe timeouts accommodate Next.js startup time
  - Done when: Probes are configured with appropriate timeouts (1s for readiness, 1s for liveness, with 30s initial delay for liveness)
  - Verify by: Checking deployment manifest and confirming timeoutSeconds values

## 5. Rollback Mechanism Fix

- [x] 5.1 Identify current rollback implementation in deployment scripts
  - Done when: Rollback logic is located in deployment scripts (e.g., `deploy-all.sh` or `deploy-to-k8s.sh`)
  - Verify by: Searching deployment scripts for rollback-related code

- [x] 5.2 Update rollback script to handle resource version conflicts
  - Done when: Rollback script retrieves current resource version before applying changes and handles conflicts gracefully
  - Verify by: Reviewing updated rollback code and confirming conflict handling logic

- [x] 5.3 Test rollback mechanism with intentional version conflicts
  - Done when: Rollback successfully handles version conflicts and restores previous deployment state
  - Verify by: Creating intentional conflict and running rollback, confirming previous deployment is restored

- [x] 5.4 Verify rollback restores previous deployment configuration
  - Done when: Rollback applies backup deployment manifest and pods return to healthy state
  - Verify by: Running rollback and checking pods are healthy with previous configuration

## 6. Integration Testing

- [x] 6.1 Build Docker image with all changes
  - Done when: Docker image builds successfully without errors
  - Verify by: Running `docker build -t my-ag-ui-app:latest .` and confirming successful build

- [x] 6.2 Push Docker image to local registry
  - Done when: Image is pushed to `localhost:32000/my-ag-ui-app:latest`
  - Verify by: Running `docker push localhost:32000/my-ag-ui-app:latest` and confirming push succeeds

- [x] 6.3 Deploy updated image to Kubernetes cluster
  - Done when: Deployment manifest is applied and pods start with new image
  - Verify by: Running `kubectl apply -f k8s/deployment.yaml` and checking pods are starting

- [x] 6.4 Verify pods reach Ready state without CrashLoopBackOff
  - Done when: All pods are in Running state with Ready condition true
  - Verify by: Running `kubectl get pods` and confirming no pods are in CrashLoopBackOff

- [x] 6.5 Verify health check endpoint is accessible from within cluster
  - Done when: Health endpoint returns HTTP 200 when accessed from within cluster
  - Verify by: Running `kubectl exec -it <pod-name> -- curl http://localhost:3000/api/health` and confirming 200 response

- [x] 6.6 Verify application is serving traffic
  - Done when: Application responds to HTTP requests on configured service
  - Verify by: Accessing application through service endpoint and confirming successful response

## 7. Documentation and Cleanup

- [x] 7.1 Document health check endpoint in application README
  - Done when: README.md includes description of `/api/health` endpoint and its purpose
  - Verify by: Checking README.md and confirming health check documentation exists

- [ ] 7.2 Update deployment documentation with new configuration
  - Done when: Deployment docs (e.g., SETUP.md or DEPLOYMENT.md) reflect new health check and container lifecycle configuration
  - Verify by: Reviewing deployment docs and confirming updates are present

- [ ] 7.3 Create test file for health endpoint verification
  - Done when: Test file `test/test_health_endpoint.py` exists and can verify health endpoint functionality
  - Verify by: Running test file and confirming it passes

- [ ] 7.4 Create test file for container lifecycle verification
  - Done when: Test file `test/test_container_lifecycle.py` exists and can verify container stays running
  - Verify by: Running test file and confirming it passes
