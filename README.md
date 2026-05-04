# Procurement Code Generator

An AI-powered procurement code assistant that generates standardized procurement codes from natural language item descriptions. Uses a confirm-before-generate workflow with disambiguation to ensure accurate code assignment.

Built with [PydanticAI](https://ai.pydantic.dev/), [CopilotKit](https://copilotkit.ai), [Next.js](https://nextjs.org), and [LlamaIndex](https://www.llamaindex.ai/).

## How It Works

1. **Describe an item** — Enter a natural language description (e.g., "stainless steel hex bolt, 2 inch, grade 8")
2. **Disambiguation** — The agent detects ambiguous components and presents clarification options before generating a code
3. **Code generation** — A structured procurement code is produced following the rules in `agent/data/CODE_GENERATION.md`
4. **Citations** — RAG-backed citations show which source material informed each code component

The agent enforces a strict workflow: it reads the code generation rules, identifies ambiguous components, resolves them through iterative clarification, and only then generates a code. It will ask for clarification rather than guess silently.

### Code Structure

Procurement codes follow a multi-component format (major category, manufacturing method, object shape, material type, quality grade, size category). Each component is independently validated and disambiguated.

### Frontend Features

- **CopilotKit sidebar** for conversational interaction
- **File upload** — Attach CSV, Excel, or text files as context for batch or reference-based code generation
- **Export** — Download generated codes as TXT, CSV, or XLSX
- **Theme color** — Agent can dynamically change the UI accent color

## Prerequisites

- OpenAI API Key
- Python 3.12+, [uv](https://docs.astral.sh/uv/), Node.js 20+
- pnpm (recommended), npm, yarn, or bun

> This repo tracks **package-lock.json** for reproducible builds. Always commit both `package.json` and `package-lock.json` together.

## Getting Started

1. Install dependencies:

   ```bash
   pnpm install   # or npm/yarn/bun install
   ```

   This also sets up the Python environment. If issues occur, run `npm run install:agent`.

1. Create `agent/.env`:

   ```text
   OPENAI_API_KEY=sk-...your-key-here...
   ```

1. Start dev server:

   ```bash
   pnpm dev   # or npm/yarn/bun run dev
   ```

   Starts both the Next.js UI (port 3000) and PydanticAI agent server concurrently.

## Available Scripts

- `dev` — UI + agent in dev mode
- `dev:debug` — dev servers with debug logging
- `dev:ui` — Next.js UI only
- `dev:agent` — PydanticAI agent only
- `build` — Production build
- `start` — Start production server
- `lint` — ESLint
- `install:agent` — Install Python dependencies

## Architecture

```text
src/app/page.tsx              # Main UI — CopilotKit sidebar + procurement codes display
src/components/
  procurement-codes.tsx       # Code list, delete, export (TXT/CSV/XLSX)
src/lib/types.ts              # Shared state types
agent/src/
  agent.py                    # Agent logic, disambiguation workflow, tools
  main.py                     # ASGI app entrypoint (uvicorn)
  rag/                        # LlamaIndex RAG pipeline (indexing, querying, citations)
agent/data/
  CODE_GENERATION.md          # Procurement code generation rules
```

### Agent Tools

| Tool | Purpose |
| ---- | ------- |
| `read_code_generation_file` | Loads code generation rules (must be called first) |
| `clarify_components` | Parses description and identifies ambiguous components |
| `save_procurement_code` | Validates and saves a code (blocks if components are ambiguous) |
| `query_rag_system` | Retrieves citations from indexed documents |
| `get_citation_sources` | Returns accumulated citation sources |

## Health Check

`GET /api/health` returns `{"status":"healthy"}`. Used by Kubernetes readiness/liveness probes.

```bash
# Local
curl http://localhost:3000/api/health

# In VM after K8s deployment
multipass exec my-ag-ui-app-k8s -- curl http://localhost:3000/api/health
```

## Kubernetes Deployment

Uses a microk8s registry approach: build image locally, push to `localhost:32000` registry in the VM, deploy.

### Deploy

```bash
./deploy-all.sh
```

Or run individual phases from `deploy_scripts/`:

- `setup-k8s-secrets.sh` — Configure K8s secrets
- `build-docker-image.sh` — Build container image
- `tag-docker-image.sh` — Tag for registry
- `setup-microk8s-registry.sh` — Provision VM, install microk8s
- `push-docker-image.sh` — Push to registry
- `deploy-to-k8s.sh` — Deploy to cluster

Enable verbose logging: `VERBOSE=true ./deploy-all.sh`

### Access

The script outputs the access URL after deployment. To find it manually:

   ```bash
   multipass info my-ag-ui-app-k8s | grep IPv4
   ```

For hostname access, add to `/etc/hosts`: `<VM-IP> my-ag-ui-app.local`

### Cleanup

```bash
./cleanup.sh
```

### Environment Variables

Set these before deploying (or the script will prompt):

   ```bash
   export OPENAI_API_KEY="your-key"
   export OPENAI_BASE_URL="https://api.openai.com/v1"
   export OPENAI_MODEL="gpt-4"
   export EMBEDDING_MODEL="text-embedding-3-small"
   ```

## Troubleshooting

**Agent connection issues** ("trouble connecting to tools"): Ensure agent is running on port 8000, API key is correct, and both servers started.

**Python import errors**: `cd agent && uv sync && uv run src/main.py`

**VM not ready**: `multipass info my-ag-ui-app-k8s`, `multipass start my-ag-ui-app-k8s`, or `multipass delete --purge my-ag-ui-app-k8s` to recreate.

**Lock file sync errors**: Run `npm install`, commit both `package.json` and `package-lock.json`. Emergency bypass: `SKIP_DEPS_CHECK=true ./deploy-all.sh`.

**Pod CrashLoopBackOff**: Check logs with `multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs <pod-name>`.

**Verbose debug logs**: `VERBOSE=true ./deploy-all.sh`. Logs saved to `/tmp/deploy-*.log`.

**Emergency reset**:

   ```bash
   multipass delete my-ag-ui-app-k8s && multipass purge
   # Then re-run ./deploy-all.sh
   ```

## License

MIT
