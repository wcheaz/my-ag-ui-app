# CopilotKit <> PydanticAI Starter

This is a starter template for building AI agents using [PydanticAI](https://ai.pydantic.dev/) and [CopilotKit](https://copilotkit.ai). It provides a modern Next.js application with an integrated investment analyst agent that can research stocks, analyze market data, and provide investment insights.

## Prerequisites

### For Development
- OpenAI API Key (for the PydanticAI agent)
- Python 3.12+
- uv
- Node.js 20+ 
- Any of the following package managers:
  - pnpm (recommended)
  - npm
  - yarn
  - bun

### For Kubernetes Deployment
- [Multipass](https://multipass.run/) - For VM management
- [Docker](https://www.docker.com/) - For containerization
- Microk8s (automatically installed by deployment script)

> **Note:** For reproducible production deployments, this repository tracks **package-lock.json** to ensure consistent dependency versions across all environments. When updating dependencies:
> 1. Run `npm install` to update the lock file
> 2. Commit both **package.json** AND **package-lock.json** together
> 3. This ensures Docker builds use exactly the same dependency versions everywhere

## Getting Started

1. Install dependencies using your preferred package manager:
```bash
# Using pnpm (recommended)
pnpm install

# Using npm
npm install

# Using yarn
yarn install

# Using bun
bun install
```

> **Note:** This will automatically setup the Python environment as well.
>
> If you have manual isseus, you can run:
>
> ```sh
> npm run install:agent
> ```


3. Set up your OpenAI API key:

Create a `.env` file inside the `agent` folder with the following content:

```
OPENAI_API_KEY=sk-...your-openai-key-here...
```


4. Start the development server:
```bash
# Using pnpm
pnpm dev

# Using npm
npm run dev

# Using yarn
yarn dev

# Using bun
bun run dev
```

This will start both the UI and agent servers concurrently.

## Kubernetes Deployment

### Microk8s Registry Approach

This project uses a **microk8s registry approach** for Kubernetes deployments, which provides a more reliable and efficient deployment workflow compared to the traditional Docker daemon method.

#### Why Microk8s Registry?

- **Eliminates Docker Daemon Complexity**: No need to manage Docker daemon in the VM
- **Faster Deployments**: Standard Docker registry operations are optimized
- **Better Reliability**: Built-in Kubernetes registry integration
- **Standard Workflow**: Uses industry-standard Docker registry patterns
- **Improved Debugging**: Standard Docker debugging tools and error messages

#### Registry Workflow

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Build Image   │───▶│ Tag for Registry │───▶│ Push to Registry│───▶│ Deploy to K8s   │
│   (Dockerfile)   │    │ (localhost:32000)│    │ (microk8s)      │    │ (Running Pods)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Key Components

1. **Local Registry**: `microk8s enable registry` (accessible at `localhost:32000`)
2. **Docker Build**: Builds application images using standard Dockerfile
3. **Image Tagging**: Tags images for local registry (`localhost:32000/app-name:latest`)
4. **Registry Push**: Pushes images to local microk8s registry
5. **Kubernetes Deployment**: Deploys pods that pull images directly from local registry
6. **Ingress Access**: Provides external access to the application

### Automated Deployment

The project includes a modular deployment system that implements the microk8s registry approach:

#### Full Deployment (Recommended)

To run the complete deployment pipeline with all phases:

```bash
./deploy-all.sh
```

This orchestrator script executes all deployment phases in sequence:
1. **Setup Kubernetes Secrets** - Configures secrets for the application with validation
2. **Build Docker Image** - Builds the application container image with dependency validation
3. **Tag Docker Image** - Tags image for local registry with comprehensive verification
4. **Setup Microk8s Registry** - Configures microk8s registry with connectivity verification
5. **Push Docker Image** - Pushes tagged image to microk8s registry with exponential backoff verification
6. **Deploy to Kubernetes** - Deploys application to Kubernetes cluster with pod status monitoring

##### Enhanced Deployment Features

The deployment pipeline includes robust error handling and monitoring:

**🔍 VERBOSE Mode**
The VERBOSE environment variable controls the level of detail in deployment logging. This feature helps operators focus on actual errors during normal deployments while providing detailed debugging information when needed.

#### VERBOSE Flag Usage

**Default Behavior (VERBOSE=false or unset)**
- Shows only ERROR and WARN level messages
- Suppresses INFO and DEBUG level messages
- Provides clean, focused output for normal deployments
- Ideal for production deployments and automated CI/CD pipelines

**Verbose Mode (VERBOSE=true)**
- Shows all log levels including INFO and DEBUG
- Provides detailed debugging information
- Includes environment context and step-by-step execution details
- Essential for troubleshooting deployment issues

#### When to Use Verbose Mode

**Use VERBOSE=true when:**
- Troubleshooting deployment failures
- Investigating intermittent issues
- Debugging new deployment configurations
- Understanding deployment pipeline behavior
- Gathering diagnostic information for support requests
- Developing or modifying deployment scripts

**Use VERBOSE=false (default) when:**
- Running regular deployments
- Automated CI/CD pipeline executions
- Production deployments
- Quick deployment status checks
- When you only care about errors and warnings

#### Examples

**Enable verbose mode:**
```bash
VERBOSE=true ./deploy-all.sh
```

**Default (non-verbose) mode:**
```bash
./deploy-all.sh
# or explicitly:
VERBOSE=false ./deploy-all.sh
```

**Verbose mode for individual scripts:**
```bash
VERBOSE=true ./deploy_scripts/setup-k8s-secrets.sh
VERBOSE=true ./deploy_scripts/deploy-to-k8s.sh
```

#### Troubleshooting with Verbose Mode

When encountering deployment issues, enable verbose mode to:

1. **Identify the failure point**: Look for ERROR messages with detailed context
2. **Check environment configuration**: Verbose mode shows environment variable values and system state
3. **Understand timing issues**: Detailed timestamps help identify timeout or performance problems
4. **Verify resource availability**: See detailed resource checks and connectivity tests
5. **Debug authentication problems**: Detailed secret and credential handling information

#### Common Verbose Mode Patterns

**Successful operation in verbose mode:**
```
[2026-04-07 11:13:27] INFO: 🚀 STARTING DEPLOYMENT PIPELINE
[2026-04-07 11:13:27] INFO: Environment: development
[2026-04-07 11:13:27] INFO: Verbose mode: true
[2026-04-07 11:13:27] INFO: 📋 Step 1: Setting up Kubernetes secrets...
[2026-04-07 11:13:27] INFO: Kubernetes secrets setup completed successfully
...
```

**Error detection in verbose mode:**
```
[2026-04-07 11:15:35] ERROR: ❌ READINESS PROBE VERIFICATION FAILED
[2026-04-07 11:15:35] ERROR TYPE: READINESS_PROBE_FAILURE
[2026-04-07 11:15:35] DIAGNOSTIC: Readiness probe verification failed
[2026-04-07 11:15:35] COMMON CAUSES: Application failed readiness probe verification
[2026-04-07 11:15:35] RECOVERY: 1. Check application logs...
```

#### Verbose Mode Performance Impact

- **Log volume**: Verbose mode generates 5-10x more log output
- **Performance**: Minimal impact on deployment execution time
- **Storage**: Logs are automatically rotated and cleaned up
- **Network**: No additional network traffic (logs are local)

**🔄 Automatic Rollback**
If any deployment step fails, the system automatically:
1. Logs structured error messages with recovery steps
2. Initiates rollback procedure to restore previous deployment state
3. Applies backup deployment manifest to maintain service availability

**📋 Structured Error Handling**
All errors include:
- Error type classification
- Detailed diagnostic information
- Common causes analysis
- Step-by-step recovery instructions

**📊 Logging and Monitoring**
- Timestamped log files created in `/tmp/deploy-*.log`
- Automatic log rotation (100MB limit, keeps last 10 files)
- Deployment summary with step status and duration
- Environment context logging (Kubernetes, registry, VM status)

#### Individual Phase Scripts

Each deployment phase can be executed independently for testing and debugging:

```bash
# Setup Kubernetes secrets (FULL debug output)
./deploy_scripts/setup-k8s-secrets.sh

# Build Docker image (MINIMAL debug output)
./deploy_scripts/build-docker-image.sh

# Tag Docker image (MINIMAL debug output)
./deploy_scripts/tag-docker-image.sh

# Setup Microk8s registry (MINIMAL debug output)
./deploy_scripts/setup-microk8s-registry.sh

# Push Docker image (MINIMAL debug output)
./deploy_scripts/push-docker-image.sh

# Deploy to Kubernetes (FULL debug output)
./deploy_scripts/deploy-to-k8s.sh
```

#### Debug Output Control

Each script has optimized debug output levels based on phase status:

- **FULL debug output** (problematic phases): `setup-k8s-secrets.sh`, `deploy-to-k8s.sh`
- **MINIMAL debug output** (successful phases): `build-docker-image.sh`, `tag-docker-image.sh`, `setup-microk8s-registry.sh`, `push-docker-image.sh`

To temporarily enable full debug output for all phases:

```bash
DEBUG=all ./deploy-all.sh
# Or for individual scripts:
DEBUG=all ./deploy_scripts/build-docker-image.sh
```

#### Phase Details

1. **Setup Kubernetes Secrets** (`setup-k8s-secrets.sh`)
   - Configures Kubernetes secrets for the application
   - **Debug Level**: FULL (problematic phase - retains all debug output)
   - Validates and configures environment variables and secrets

2. **Build Docker Image** (`build-docker-image.sh`)
   - Builds application Docker image using optimized multi-stage Dockerfile
   - **Debug Level**: MINIMAL (successful phase - essential status only)
   - Validates lock files for reproducible builds

3. **Tag Docker Image** (`tag-docker-image.sh`)
   - Tags Docker image for local registry (`localhost:32000/my-ag-ui-app:latest`)
   - **Debug Level**: MINIMAL (successful phase - success confirmation only)

4. **Setup Microk8s Registry** (`setup-microk8s-registry.sh`)
   - Provisions VM using Multipass with 4 CPUs, 7.7GiB RAM, 19.3GiB disk
   - Installs Microk8s and enables required add-ons (dns, storage, ingress, registry)
   - **Debug Level**: MINIMAL (successful phase - essential status only)

5. **Push Docker Image** (`push-docker-image.sh`)
   - Pushes tagged image to microk8s local registry
   - **Debug Level**: MINIMAL (partial success phase - critical status only)

6. **Deploy to Kubernetes** (`deploy-to-k8s.sh`)
   - Deploys application to Kubernetes cluster using local registry image
   - Verifies deployment and provides access information
   - **Debug Level**: FULL (critical failure phase - retains all debug output)

### Prerequisites

Before running the deployment script, ensure you have:
- [Multipass](https://multipass.run/) installed
- [Docker](https://www.docker.com/) installed (on your local machine for building images)
- Sufficient system resources (the VM requires 4 CPUs, 7.7GiB RAM, 19.3GiB disk)

> **Note**: With the microk8s registry approach, Docker is only required on your local machine for building images. The VM does not need Docker daemon setup.

### Microk8s Registry Setup

The deployment script automatically sets up the microk8s registry in the VM, eliminating the need for complex Docker daemon configuration.

#### Automatic Registry Setup Process

The script performs these registry setup steps automatically:

1. **Microk8s Installation** - Installs microk8s in the VM with required add-ons
2. **Registry Enablement** - Enables the built-in microk8s registry (`microk8s enable registry`)
3. **Registry Verification** - Confirms the registry is accessible at `localhost:32000`
4. **Image Preparation** - Builds and tags images for the local registry
5. **Registry Integration** - Configures Kubernetes to use the local registry

#### Registry Configuration Details

The deployment uses the following registry configuration:

- **Registry URL**: `localhost:32000`
- **Image Reference**: `localhost:32000/my-ag-ui-app:latest`
- **Registry Access**: The registry is accessible within the Kubernetes cluster at `http://localhost:32000`
- **Registry API**: Docker Registry API v2 at `http://localhost:32000/v2/`
- **Registry Catalog**: Available at `http://localhost:32000/v2/_catalog`

#### Key Registry Features

- **Local Only**: The registry runs entirely within the VM, no external network access required
- **No Authentication**: The local microk8s registry does not require authentication
- **Persistent Storage**: Images persist across VM restarts
- **Kubernetes Integration**: Native integration with microk8s without additional configuration
- **Standard Docker API**: Compatible with standard Docker client commands

#### Deployment Manifest Configuration

The Kubernetes deployment manifest (`k8s/deployment.yaml`) has been updated to use the local registry:

```yaml
spec:
  template:
    spec:
      containers:
      - name: my-ag-ui-app
        image: localhost:32000/my-ag-ui-app:latest
```

This ensures that:
- Pods pull images from the local registry instead of Docker Hub
- No external network access is required for image pulls
- Deployment works reliably in the local development environment

### Benefits of Modular Deployment

The modular deployment system provides several advantages over the previous monolithic approach:

#### 1. **Isolated Testing and Debugging**
- Each deployment phase can be tested independently
- Run specific phases to isolate and fix issues quickly
- Debug output is optimized for each phase's status (successful vs problematic)

#### 2. **Reduced Context Token Consumption**
- Smaller, focused scripts consume fewer context tokens during development
- Only load the specific phase you're working on
- Improved ralph-loop development experience

#### 3. **Flexible Deployment Workflow**
- Run full deployment with `./deploy-all.sh` for standard deployments
- Execute individual phases for targeted testing and debugging
- Easy to integrate with CI/CD pipelines

#### 4. **Better Maintainability**
- Each script has a single responsibility
- Clear separation of concerns makes code easier to understand
- Consistent error handling across all scripts

#### 5. **Progressive Debugging**
- Successful phases have minimal debug output (less noise)
- Problematic phases retain full debug output (more details)
- Temporary full debugging available with `DEBUG=all` flag

#### Registry Setup Requirements

- **Network Connectivity**: The VM must have internet access to download microk8s packages during installation
- **Disk Space**: Approximately 200MB additional space is required for microk8s registry storage
- **VM Access**: The deployment script must be able to execute commands in the VM via `multipass exec`

#### Registry Setup Troubleshooting

If registry setup fails during deployment:

1. **Network Issues**: Ensure the VM has internet connectivity
    ```bash
    multipass exec my-ag-ui-app-k8s -- ping -c 3 google.com
    ```

2. **Microk8s Status**: Check if microk8s is running properly
    ```bash
    multipass exec my-ag-ui-app-k8s -- microk8s status
    ```

3. **Registry Status**: Verify the microk8s registry is enabled and accessible
    ```bash
    multipass exec my-ag-ui-app-k8s -- curl -s http://localhost:32000/v2/_catalog
    ```

4. **Manual Registry Setup**: If automatic setup fails, you can enable the registry manually
    ```bash
    multipass shell my-ag-ui-app-k8s
    microk8s enable registry
    ```

#### Registry Setup Idempotency

The registry setup process is designed to be idempotent - you can run the deployment script multiple times without causing issues. The script will:
- Skip microk8s installation if already present and running
- Only enable registry if not already enabled
- Continue with the deployment process without duplication

#### Advanced Registry Configuration

For advanced use cases, you can customize the microk8s registry behavior:

1. **Registry Size**: The default registry size is 20GB. This can be increased if needed
2. **Registry Persistence**: Images are persisted in the registry across VM restarts
3. **Registry Access**: The registry is only accessible within the Kubernetes cluster by default
4. **External Registry**: You can configure external registry access if needed

### Accessing the Application

After successful deployment, the application will be accessible via:
- **HTTP**: `http://localhost` (if ingress is properly configured)
- **Alternative**: Check the deployment script output for the specific ingress endpoint

### Cleanup

To remove all deployed resources and clean up the environment:

```bash
./cleanup.sh
```

The cleanup script will:
1. **Remove Kubernetes resources** (deployment, service, ingress)
2. **Delete the Multipass VM** (confirm when prompted)
3. **Clean up any temporary files**

### Manual Deployment (Advanced)

For manual deployment or troubleshooting, you can:
1. Create the VM: `multipass launch --name my-ag-ui-app-vm --cpus 4 --memory 7.7G --disk 19.3G`
2. Install microk8s: Follow microk8s installation guide
3. Build and deploy: Use the individual Kubernetes manifests in the `k8s/` directory

## Available Scripts
The following scripts can also be run using your preferred package manager:
- `dev` - Starts both UI and agent servers in development mode
- `dev:debug` - Starts development servers with debug logging enabled
- `dev:ui` - Starts only the Next.js UI server
- `dev:agent` - Starts only the PydanticAI agent server
- `build` - Builds the Next.js application for production
- `start` - Starts the production server
- `lint` - Runs ESLint for code linting
- `install:agent` - Installs Python dependencies for the agent

## Health Check Endpoint

The application provides a `/api/health` endpoint for Kubernetes health monitoring and container lifecycle management.

### Endpoint Details

- **URL**: `/api/health`
- **Method**: GET
- **Authentication**: None required
- **Response**: HTTP 200 with JSON body
- **Response Body**:
  ```json
  {
    "status": "healthy"
  }
  ```

### Purpose

This health check endpoint is used by Kubernetes for:
- **Readiness probes**: Determines when the application is ready to receive traffic
- **Liveness probes**: Determines if the application is still running and healthy
- **Container lifecycle management**: Prevents containers from exiting with code 0

### Testing the Endpoint

You can test the health endpoint locally during development:

```bash
# When the development server is running
curl http://localhost:3000/api/health

# Expected response:
# {"status":"healthy"}
```

### Kubernetes Configuration

The health endpoint is configured in the Kubernetes deployment manifest with:
- **Readiness probe**: Path `/api/health`, port 3000, 10s interval, 1s timeout
- **Liveness probe**: Path `/api/health`, port 3000, 10s interval, 1s timeout, 30s initial delay

This ensures that:
- Pods only receive traffic when the application is healthy
- Unhealthy pods are automatically restarted
- The deployment remains stable during rolling updates

## Documentation

The main UI component is in `src/app/page.tsx`. You can:
- Modify the theme colors and styling
- Add new frontend actions
- Customize the CopilotKit sidebar appearance

## 📚 Documentation

- [PydanticAI Documentation](https://ai.pydantic.dev) - Learn more about PydanticAI and its features
- [CopilotKit Documentation](https://docs.copilotkit.ai) - Explore CopilotKit's capabilities
- [Next.js Documentation](https://nextjs.org/docs) - Learn about Next.js features and API

## Contributing

Feel free to submit issues and enhancement requests! This starter is designed to be easily extensible.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Troubleshooting

### Agent Connection Issues
If you see "I'm having trouble connecting to my tools", make sure:
1. The PydanticAI agent is running on port 8000
2. Your OpenAI API key is set correctly
3. Both servers started successfully

### Python Dependencies
If you encounter Python import errors:
```bash
cd agent
uv sync
uv run src/main.py
```

### Deployment YAML Path Errors
If you encounter "path does not exist" errors during Kubernetes deployment:

#### Issue: Incomplete secrets.yaml
The deployment script now automatically detects and fixes incomplete `secrets.yaml` files. If you see errors related to secrets:

1. **Ensure environment variables are set** (or the script will prompt for them):
   ```bash
   export OPENAI_API_KEY="your-api-key"
   export OPENAI_BASE_URL="https://api.openai.com/v1"
   export OPENAI_MODEL="gpt-4"
   export EMBEDDING_MODEL="text-embedding-3-small"
   export LOGFIRE_TOKEN="your-logfire-token"
   ```

2. **Run from correct directory**: The deployment script must be run from:
   ```
   openspec/changes/containerize-kubernetes-multipass-microk8s/
   ```

3. **Manual secrets generation**: If automatic generation fails:
   ```bash
   cd openspec/changes/containerize-kubernetes-multipass-microk8s/
   ./k8s/setup-secrets.sh
   ```

#### Issue: VM not ready
If the script reports VM-related errors:
1. **Check VM status**: `multipass info my-ag-ui-app-k8s`
2. **Start VM if needed**: `multipass start my-ag-ui-app-k8s`
3. **Delete and recreate VM**: `multipass delete --purge my-ag-ui-app-k8s`

#### Issue: File location errors
The script expects YAML files in:
```
openspec/changes/containerize-kubernetes-multipass-microk8s/k8s/
```

Ensure all these files exist:
- `secrets.yaml` (will be auto-generated if incomplete)
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`

#### Issue: Lock file sync errors
The deployment script validates that package.json and package-lock.json are synchronized before building. If you encounter lock file sync errors:

1. **Update lock file**: Run `npm install` to synchronize package-lock.json with package.json
2. **Commit both files**: Commit the updated package-lock.json along with package.json
3. **Retry deployment**: Run `./deploy-all.sh` again

**Emergency bypass** (not recommended for regular use):
```bash
SKIP_DEPS_CHECK=true ./deploy-all.sh
```
> **Warning**: Skipping dependency validation may result in non-reproducible builds and deployment inconsistencies. Only use this for emergency deployments when immediate fixes are needed.

**Why this matters**: Synchronized lock files ensure every deployment uses exactly the same dependency versions, preventing "works on my machine" issues and making builds reproducible across different environments.

#### Docker Setup Issues
If you encounter Docker-related errors during deployment:

1. **"docker: command not found"**: This indicates Docker is not installed in the VM
   - The deployment script should handle this automatically
   - If it fails, run manual installation as described in "Docker Setup Troubleshooting" above

2. **"Docker daemon in VM: not running"**: The Docker daemon is not started
   - Wait a few moments for the daemon to start
   - Check status: `multipass exec my-ag-ui-app-k8s -- docker info`
   - Restart daemon: `multipass exec my-ag-ui-app-k8s -- sudo systemctl start docker`

3. **"permission denied" when running Docker commands**: User is not in docker group
   - Add user to group: `multipass exec my-ag-ui-app-k8s -- sudo usermod -aG docker ubuntu`
   - Activate group: `multipass exec my-ag-ui-app-k8s -- newgrp docker`

4. **Image loading fails**: Docker is not ready to accept images
   - Verify Docker is running: `multipass exec my-ag-ui-app-k8s -- docker ps`
   - Check disk space: `multipass exec my-ag-ui-app-k8s -- df -h`

## Deployment Troubleshooting

This section covers common deployment issues and their solutions.

### 1. Image Verification Timeout

**Symptoms**:
```
ERROR TYPE: IMAGE_VERIFICATION_TIMEOUT
DIAGNOSTIC: Image verification failed after 7 attempts with exponential backoff
```

**Causes**:
- Registry catalog update delays
- Registry connectivity issues
- Microk8s registry service problems

**Solutions**:
1. **Verify image exists in registry**:
   ```bash
   curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list
   ```

2. **Check registry status**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -n registry
   ```

3. **Wait and retry**: The verification uses exponential backoff, so waiting a few minutes and retrying often resolves the issue

4. **Proceed with deployment**: If image exists, you can skip verification by temporarily modifying the script

### 2. Rollback Procedure Failed

**Symptoms**:
```
ERROR: ❌ ROLLBACK FAILED: Could not apply backup deployment manifest
ERROR:    Manual intervention required to restore deployment state
```

**Causes**:
- Backup deployment manifest missing
- VM connectivity issues
- Kubernetes permission issues

**Solutions**:
1. **Check backup file exists**:
   ```bash
   ls -la k8s/deployment.yaml.backup
   ```

2. **Manual rollback**:
   ```bash
   multipass transfer k8s/deployment.yaml.backup my-ag-ui-app-k8s:/home/ubuntu/backup.yaml
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/backup.yaml
   ```

3. **Create backup from current deployment**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o yaml > k8s/deployment.yaml.backup
   ```

### 3. Kubernetes Secrets Validation Failure

**Symptoms**:
```
ERROR TYPE: KUBERNETES SECRETS VALIDATION FAILURE
DIAGNOSTIC: Generated secrets YAML file is invalid or incompatible with Kubernetes API server
```

**Causes**:
- Missing environment variables
- Invalid base64 encoding
- YAML syntax errors
- Kubernetes connectivity issues

**Solutions**:
1. **Check required environment variables**:
   ```bash
   echo "Required: OPENAI_API_KEY, OPENAI_BASE_URL, OPENAI_MODEL, EMBEDDING_MODEL"
   export OPENAI_API_KEY="your-key"  # Set missing variables
   ```

2. **Verify Kubernetes connectivity**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl cluster-info
   ```

3. **Check permissions**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl auth can-i create secret
   ```

4. **Regenerate secrets file**:
   ```bash
   ./deploy_scripts/setup-k8s-secrets.sh
   ```

### 4. Application CrashLoopBackOff

**Symptoms**:
```bash
my-ag-ui-app-6dc4f774d4-kddvv   0/1     CrashLoopBackOff   88 (90s ago)    4h48m
```

**Causes**:
- Application-level issues (not deployment pipeline issues)
- Missing environment variables in pods
- Health check endpoint failures
- Resource constraints

**Solutions**:
1. **Check pod logs**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs <pod-name>
   ```

2. **Describe pod for details**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl describe pod <pod-name>
   ```

3. **Check environment variables in pod**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl exec <pod-name> -- env
   ```

4. **Note**: This is typically an application-level issue that requires developer attention

### 5. VM Connectivity Issues

**Symptoms**:
```
ERROR: Failed to connect to VM
multipass: command not found
```

**Causes**:
- Multipass not installed
- VM not running
- Network connectivity issues

**Solutions**:
1. **Check Multipass status**:
   ```bash
   multipass list
   ```

2. **Start VM if not running**:
   ```bash
   multipass start my-ag-ui-app-k8s
   ```

3. **Install Multipass** (if missing):
   ```bash
   # Ubuntu/Debian
   sudo snap install multipass
   
   # macOS
   brew install multipass
   ```

### 6. Log File Synchronization Issues

**Symptoms**:
```
ERROR: package.json and package-lock.json are out of sync
```

**Causes**:
- Dependencies updated without updating lock file
- Manual editing of package-lock.json
- Merge conflicts in lock file

**Solutions**:
1. **Fix synchronization**:
   ```bash
   npm install
   ```

2. **Verify fix**:
   ```bash
   npm ci --dry-run
   ```

3. **Commit both files**:
   ```bash
   git add package.json package-lock.json
   git commit -m "Fix lock file synchronization"
   ```

### 7. Permission Issues

**Symptoms**:
```
ERROR: permission denied
ERROR: insufficient permissions
```

**Causes**:
- Not in Kubernetes admin group
- Multipass user permission issues
- Docker group membership

**Solutions**:
1. **Check Kubernetes permissions**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- microk8s kubectl auth can-i create deployment
   ```

2. **Add user to Docker group**:
   ```bash
   multipass exec my-ag-ui-app-k8s -- sudo usermod -aG docker ubuntu
   multipass exec my-ag-ui-app-k8s -- newgrp docker
   ```

### 8. Getting More Debug Information

**Enable Verbose Logging**:
```bash
VERBOSE=true ./deploy-all.sh
```

**Check Log Files**:
```bash
# List recent deployment logs
ls -la /tmp/deploy-*.log | tail -5

# View latest log file
tail -f /tmp/deploy-$(ls -t /tmp/deploy-*.log | head -1 | cut -d/ -f3)
```

**Environment Context Check**:
```bash
# Check deployment environment status
VERBOSE=true ./deploy-all.sh 2>&1 | grep -A 10 "ENVIRONMENT CONTEXT"
```

### 9. Emergency Recovery Procedures

**Complete Environment Reset**:
```bash
# Delete current deployment
multipass exec my-ag-ui-app-k8s -- microk8s kubectl delete deployment my-ag-ui-app

# Apply backup deployment
multipass exec my-ag-ui-app-k8s -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml.backup

# Wait for recovery
multipass exec my-ag-ui-app-k8s -- microk8s kubectl wait --for=condition=ready pod -l app=my-ag-ui-app --timeout=300s
```

**VM Recreate (Last Resort)**:
```bash
# Delete and recreate VM
multipass delete my-ag-ui-app-k8s
multipass purge
multipass launch --name my-ag-ui-app-k8s --memory 4G --cpus 2
```

### 10. When to Get Help

If you encounter issues not covered here:

1. **Check deployment logs**: `/tmp/deploy-*.log`
2. **Review rollback procedures**: `ROLLBACK_PROCEDURE.md`
3. **Check environment variables**: `SETUP.md`
4. **Create GitHub issue** with:
   - Complete error messages
   - Relevant log excerpts
   - Environment information
   - Steps you've already tried

For detailed debugging information, see: `hidden/KUBERNETES-EXPLANATION.md`