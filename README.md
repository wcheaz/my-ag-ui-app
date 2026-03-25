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

The project includes an automated deployment script that implements the microk8s registry approach:

```bash
./deploy.sh
```

The deployment script will:
1. **Validate lock files** - Ensures package.json and package-lock.json are synchronized for reproducible builds
2. **Provision a VM** using Multipass with 4 CPUs, 7.7GiB RAM, and 19.3GiB disk
3. **Install Microk8s** in the VM and enable required add-ons (dns, storage, ingress, registry)
4. **Enable Local Registry** - Sets up microk8s registry for local image distribution
5. **Build Docker Image** using the optimized multi-stage Dockerfile with dependency fallback
6. **Tag for Local Registry** - Tags image as `localhost:32000/my-ag-ui-app:latest`
7. **Push to Registry** - Pushes tagged image to microk8s local registry
8. **Deploy to Kubernetes** - Updates deployment to use local registry image
9. **Verify Deployment** - Confirms pods are running and provides access information

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
3. **Retry deployment**: Run `./deploy.sh` again

**Emergency bypass** (not recommended for regular use):
```bash
./deploy.sh --skip-deps-check
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

For detailed debugging information, see: `hidden/KUBERNETES-EXPLANATION.md`