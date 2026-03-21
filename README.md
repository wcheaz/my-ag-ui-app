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

> **Note:** This repository ignores lock files (package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb) to avoid conflicts between different package managers. Each developer should generate their own lock file using their preferred package manager. After that, make sure to delete it from the .gitignore.

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
1. **Provision a VM** using Multipass with 4 CPUs, 7.7GiB RAM, and 19.3GiB disk
2. **Install Microk8s** in the VM and enable required add-ons (dns, storage, ingress)
3. **Build the Docker image** using the optimized multi-stage Dockerfile
4. **Deploy to Kubernetes** using the provided manifests (deployment, service, ingress)
5. **Verify the deployment** and provide access information

### Prerequisites

Before running the deployment script, ensure you have:
- [Multipass](https://multipass.run/) installed
- [Docker](https://www.docker.com/) installed
- Sufficient system resources (the VM requires 4 CPUs, 7.7GiB RAM, 19.3GiB disk)

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

For detailed debugging information, see: `hidden/KUBERNETES-EXPLANATION.md`