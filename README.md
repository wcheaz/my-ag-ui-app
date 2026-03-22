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

### Automated Deployment

The project includes an automated deployment script that sets up the entire Kubernetes infrastructure:

```bash
./deploy.sh
```

The deployment script will:
1. **Validate lock files** - Ensures package.json and package-lock.json are synchronized for reproducible builds
2. **Provision a VM** using Multipass with 4 CPUs, 7.7GiB RAM, and 19.3GiB disk
3. **Setup Docker in VM** - Automatically installs and configures Docker daemon in the VM
4. **Install Microk8s** in the VM and enable required add-ons (dns, storage, ingress)
5. **Build the Docker image** using the optimized multi-stage Dockerfile with dependency fallback
6. **Load Docker image into VM** - Transfers the built image to the VM's Docker daemon
7. **Deploy to Kubernetes** using the provided manifests (deployment, service, ingress)
8. **Verify the deployment** and provide access information

### Prerequisites

Before running the deployment script, ensure you have:
- [Multipass](https://multipass.run/) installed
- [Docker](https://www.docker.com/) installed
- Sufficient system resources (the VM requires 4 CPUs, 7.7GiB RAM, 19.3GiB disk)

### Docker Setup in VM

The deployment script automatically handles Docker installation and configuration in the multipass VM. This process ensures Docker is available for loading and running container images within the Kubernetes cluster.

#### Automatic Docker Setup Process

The script performs these Docker setup steps automatically:

1. **Docker Availability Check** - Verifies if Docker is already installed in the VM
2. **Docker Installation** - If not present, installs Docker using the official Ubuntu installation script
3. **User Configuration** - Adds the default user (`ubuntu`) to the docker group for sudo-less operation
4. **Daemon Startup** - Ensures the Docker daemon is running and ready to accept commands
5. **Readiness Verification** - Confirms Docker is operational before proceeding with image loading

#### Docker Setup Requirements

- **Network Connectivity**: The VM must have internet access to download Docker packages during installation
- **Disk Space**: Approximately 500MB additional space is required for Docker packages and dependencies
- **VM Access**: The deployment script must be able to execute commands in the VM via `multipass exec`

#### Docker Setup Troubleshooting

If Docker setup fails during deployment:

1. **Network Issues**: Ensure the VM has internet connectivity
   ```bash
   multipass exec my-ag-ui-app-k8s -- ping -c 3 google.com
   ```

2. **Manual Docker Installation**: If automatic setup fails, you can install Docker manually:
   ```bash
   multipass shell my-ag-ui-app-k8s
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker ubuntu
   # Log out and back in, or run: newgrp docker
   ```

3. **Docker Daemon Status**: Check if Docker daemon is running:
   ```bash
   multipass exec my-ag-ui-app-k8s -- docker info
   ```

4. **Permission Issues**: If you encounter permission errors, ensure the user is in the docker group:
   ```bash
   multipass exec my-ag-ui-app-k8s -- groups ubuntu
   ```

#### Docker Setup Idempotency

The Docker setup process is designed to be idempotent - you can run the deployment script multiple times without causing issues. The script will:
- Skip installation if Docker is already present and running
- Only perform necessary setup steps
- Continue with the deployment process without duplication

#### Advanced Docker Configuration

For advanced use cases, you can customize Docker behavior in the VM:

1. **Docker Version**: The script installs the latest stable Docker version. For specific version requirements, manual installation may be needed
2. **Docker Daemon Settings**: Default Docker settings are used. Custom daemon configurations can be applied after deployment
3. **Docker Registry**: The script uses Docker Hub by default. Private registry configuration can be added manually if needed

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