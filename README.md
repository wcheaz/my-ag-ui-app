# Procurement Code Generator

An AI-powered procurement assistant designed to generate standardized procurement codes from natural language item descriptions. The system leverages a confirm-before-generate workflow with structured disambiguation to ensure high-accuracy code assignment, combined with RAG-backed citation tracking.

Built with [PydanticAI](https://ai.pydantic.dev/), [CopilotKit](https://copilotkit.ai), [Next.js](https://nextjs.org), and [LlamaIndex](https://www.llamaindex.ai/).

---

## Project Overview

The **Procurement Code Generator** parses user-entered natural language descriptions (e.g., *"stainless steel hex bolt, 2 inch, grade 8"*) and suggests the appropriate standardized procurement codes. 

### Key Features
- **Conversational Copilot Interface**: Utilizes a `CopilotKit` sidebar to allow users to interact with the agent, ask questions, clarify attributes, and trigger actions contextually.
- **Disambiguation Workflow**: The agent detects ambiguous description components and asks the user for clarification before assigning codes, preventing incorrect assumptions.
- **RAG-Backed Citations**: Uses `LlamaIndex` to query an external Knowledge Base, returning exact citations and source documents that inform specific code selections.
- **Dynamic Accent Colors**: The agent can dynamically change the UI theme color to match the context or status.
- **File Upload & Export**: Users can upload CSV, Excel, or text files to act as context and export the generated procurement codes to TXT, CSV, or XLSX formats.

### Core Workflow
1. **Input**: User describes an item in plain text or uploads a file.
2. **Analysis**: The agent reads the code generation rules from `agent/data/CODE_GENERATION.md` and identifies ambiguous components.
3. **Clarification**: If components are ambiguous, the agent asks clarifying questions instead of guessing.
4. **Generation & Verification**: A structured procurement code is built matching the verified components.
5. **Citations & Saving**: Source citations are fetched via RAG, and the final code is persisted to the session state.

---

## Development Environment Setup

### Prerequisites
- **Node.js**: Version 20+
- **Python**: Version 3.12+
- **uv**: Python package installer and virtual environment manager (highly recommended; see [astral.sh/uv](https://docs.astral.sh/uv/))
- **pnpm**: Node package manager (or npm/yarn/bun)

### Step 1: Configure Environment Variables

The project uses environment variables for LLM connectivity, agent behavior, and logging. Create a `.env` file in the project root (and/or `agent/` directory) and populate it based on `.env.example`:

```bash
# LLM Provider Configuration (DeepSeek / OpenAI Compatible)
OPENAI_API_KEY=sk-your-actual-api-key-here
OPENAI_BASE_URL=https://api.deepseek.com       # Or provider URL (e.g., https://api.openai.com/v1)
OPENAI_MODEL=deepseek-chat                     # Or other model (e.g., gpt-4o, deepseek-reasoner)

# Procurement Agent Settings
LLM_MAX_TOKENS=4096
LLM_CONTEXT_WINDOW=8192
EMBEDDING_MODEL=text-embedding-3-small
AGENT_URL=http://localhost:8000

# Confidence Gap Thresholds (Optional JSON)
# gap_ratio: minimum (top_score - second_score) / top_score to auto-resolve
# min_top_score: minimum score the top match must have to auto-resolve
# Format: {"component_key": {"gap_ratio": 0.5, "min_top_score": 0.7}}
COMPONENT_CONFIDENCE_THRESHOLDS={"size_category":{"gap_ratio":0.3,"min_top_score":0.6}}

# Observability (Optional)
LOGFIRE_TOKEN=your-logfire-token
```

### Step 2: Install Dependencies

#### Option A: Automated Setup (Recommended)
Run the automated script in the root directory to check requirements, install package managers (`uv`, `pnpm`), and install all dependencies:
```bash
./setup.sh
```

#### Option B: Manual Setup
1. Install Node.js dependencies:
   ```bash
   pnpm install
   ```
2. Set up Python virtual environment and dependencies using `uv` (inside the `agent` folder):
   ```bash
   cd agent
   uv sync
   cd ..
   ```

> [!IMPORTANT]
> **Package Lock File Consistency**: This repository tracks `package-lock.json` for reproducible builds. Always commit both `package.json` and `package-lock.json` together. If you update `package.json`, run `npm install` to regenerate the lock file before deploying.

### Step 3: Run the Application

Start both the Next.js UI development server and the FastAPI PydanticAI agent server concurrently:
```bash
pnpm dev
```

- **Next.js UI**: [http://localhost:3000](http://localhost:3000)
- **FastAPI Agent**: [http://localhost:8000](http://localhost:8000)

---

## Architectural Overview

This project consists of a decoupled frontend-backend architecture designed for secure, auditable AI agent operations. For details on the architecture diagram, refer to `hidden/architecture/ARCHITECTURE_DIAGRAM_PDF.md`.

### High-Level Architecture Component Details

```
┌─────────────────────────────────┐
│     Frontend (Next.js App)      │
│   ┌─────────────────────────┐   │
│   │  CopilotKit Chat UI     │   │
│   └────────────┬────────────┘   │
└────────────────┼────────────────┘
                 │ HTTP / WebSockets
                 ▼
┌─────────────────────────────────┐
│     Backend (FastAPI App)       │
│   ┌─────────────────────────┐   │
│   │    PydanticAI Agent     │◀──┼───────┐ RAG
│   └────────────┬────────────┘   │       ▼
└────────────────┼────────────────┘  ┌──────────────┐
                 │                   │ LlamaIndex   │
                 │ * Data egress     │ Knowledge    │
                 ▼                   │ Base         │
        ┌─────────────────┐          └──────────────┘
        │   LLM Provider  │
        │ (Gemini/DeepSeek│
        └─────────────────┘
```

#### 1. Frontend (`src/app` / `src/components`)
- **Core Technologies**: Next.js 16, React 19, Vanilla CSS, TailwindCSS 4.
- **Integration**: `CopilotKit` (v1.51.2) acts as the state manager and UI wrapper for the conversational agent, handling user prompt state and streaming agent responses.
- **Communication**: Interacts with the backend server via HTTP and WebSockets for real-time chat functionality.

#### 2. Backend (`agent/src`)
- **Core Technologies**: Python 3.12+, PydanticAI, FastAPI, Uvicorn.
- **Agent (`agent.py`)**: Uses PydanticAI to orchestrate LLM requests, register agent tools, and validate the multi-component state structure.
- **Retrieval-Augmented Generation (RAG)**: Integrates `LlamaIndex` (`agent/src/rag/`) to query source documents and extract verified citations.
- **In-Memory State**: Manages active conversation sessions and accumulated codes inside an in-memory `ProcurementState`.

#### 3. Agent Tools

| Tool | Purpose |
| ---- | ------- |
| `read_code_generation_file` | Loads code generation rules (must be called first) |
| `clarify_components` | Parses descriptions and identifies ambiguous components |
| `save_procurement_code` | Validates and saves a code (blocks if components are ambiguous) |
| `query_rag_system` | Retrieves citations and matching rules from the indexed knowledge base |
| `get_citation_sources` | Returns accumulated citation sources for audit trails |

### Data Egress & Zero Data Retention (ZDR)

Connections between the backend agent and the external **LLM Provider** represent data leaving the internal secure boundary (indicated by the asterisk `*` in the diagram). To ensure data privacy:

Using **Google Cloud Vertex AI** (Gemini) as an example, the following compliance parameters apply:
- **Model Training**: Data sent through the API is **never** used to train foundation models.
- **In-Memory Caching (Default)**: In-memory transient caching (up to 24 hours) is active by default to optimize latency. This is ZDR-compliant but can be disabled at the project/region level if desired.
- **Abuse Monitoring**: Managed LLM providers may log queries temporarily for abuse detection. Achieving strict ZDR requires requesting an abuse-monitoring opt-out from the cloud provider.
- **Session Resumption**: Disabled by default.

---

## Available Scripts

Manage the dev environment and builds using the following `npm`/`pnpm` scripts:

- `pnpm dev` — Starts both Next.js UI and PydanticAI agent concurrently.
- `pnpm dev:debug` — Runs both servers with debug logging enabled.
- `pnpm dev:ui` — Next.js UI server only (port 3000).
- `pnpm dev:agent` — PydanticAI FastAPI backend only (port 8000).
- `pnpm build` — Compiles production Next.js frontend build.
- `pnpm start` — Starts Next.js production server.
- `pnpm lint` — Runs ESLint on frontend source files.
- `pnpm install:agent` — Installs Python dependencies separately.

---

## Health Check

The service exposes a health check endpoint at `/api/health` returning `{"status":"healthy"}`. This is used by Kubernetes liveness and readiness probes.

```bash
# Query locally
curl http://localhost:3000/api/health

# Query inside the K8s VM
multipass exec my-ag-ui-app-k8s -- curl http://localhost:3000/api/health
```

---

## Kubernetes Deployment

Deployments use MicroK8s inside a Multipass VM.

> [!NOTE]
> Setting up the local VM and MicroK8s cluster is a prerequisite. If you don't have the VM configured yet, please follow the step-by-step guide in [KUBERNETES-SETUP.md](KUBERNETES-SETUP.md) first.

Once your VM is running and configured, the deployment pipeline builds the Docker image locally, pushes it to the container registry running at port `32000` inside the VM, and deploys it to the cluster.

### Automated Deployment

Run the main pipeline:
```bash
./deploy-all.sh
```

Enable verbose logging:
```bash
VERBOSE=true ./deploy-all.sh
```

### Manual/Phase-based Deployment
You can trigger individual deployment phases from `deploy_scripts/`:
- `setup-k8s-secrets.sh` — Configure Kubernetes secrets (API keys)
- `build-docker-image.sh` — Build container image
- `tag-docker-image.sh` — Tag image for registry
- `setup-microk8s-registry.sh` — Provision VM and configure MicroK8s
- `push-docker-image.sh` — Push tag to local registry
- `deploy-to-k8s.sh` — Apply K8s deployment manifests

### Accessing the App in VM
The deployment script displays the access URL upon completion. To fetch it manually:
```bash
multipass info my-ag-ui-app-k8s | grep IPv4
```
Map the IP to `my-ag-ui-app.local` in your local `/etc/hosts` file for hostname-based access.

### Cleanup
To tear down K8s pods and clean up registry storage:
```bash
./cleanup.sh
```

---

## Troubleshooting

- **Agent Connection Issues**: Confirm FastAPI is active at port `8000` and `AGENT_URL` is set correctly in `.env`.
- **Python Import Errors**: Navigate to `agent/` and run `uv sync` to ensure the virtual environment and dependencies are aligned.
- **VM State / Access**: Check VM status with `multipass list`. Start/recreate using:
  ```bash
  multipass start my-ag-ui-app-k8s
  # To purge and start fresh:
  multipass delete --purge my-ag-ui-app-k8s
  ```
- **Lock File Sync Errors**: If `package.json` and `package-lock.json` fall out of sync, run `npm install` and commit both files. If needed in emergencies, bypass check with:
  ```bash
  SKIP_DEPS_CHECK=true ./deploy-all.sh
  ```
- **CrashLoopBackOff Logs**: Read pod logs directly inside the VM:
  ```bash
  multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs <pod-name>
  ```

---

## License

MIT
