# Environment Setup for DeepSeek API

This project is configured to use DeepSeek's OpenAI-compatible API. Follow these steps to set up your environment variables.

## Step 1: Get your DeepSeek API Key

1. Go to [DeepSeek's platform](https://platform.deepseek.com/)
2. Sign up or log in
3. Navigate to the API section
4. Create a new API key
5. Copy your API key

## Step 2: Configure Environment Variables

The project uses a `.env` file for configuration. This file is already created and git-ignored for security.

### Option A: Edit the `.env` file directly

Open the `.env` file in the project root and replace the placeholder:

```bash
# OpenAI-compatible API Configuration
OPENAI_API_KEY=sk-your-actual-deepseek-api-key-here
OPENAI_BASE_URL=https://api.deepseek.com
OPENAI_MODEL=deepseek-chat
```

### Option B: Set environment variables in your shell

For zsh (default on macOS):
```bash
echo 'export OPENAI_API_KEY="sk-your-actual-deepseek-api-key-here"' >> ~/.zshrc
echo 'export OPENAI_BASE_URL="https://api.deepseek.com"' >> ~/.zshrc
echo 'export OPENAI_MODEL="deepseek-chat"' >> ~/.zshrc
source ~/.zshrc
```

For bash:
```bash
echo 'export OPENAI_API_KEY="sk-your-actual-deepseek-api-key-here"' >> ~/.bashrc
echo 'export OPENAI_BASE_URL="https://api.deepseek.com"' >> ~/.bashrc
echo 'export OPENAI_MODEL="deepseek-chat"' >> ~/.bashrc
source ~/.bashrc
```

## Step 3: Install Dependencies

### Option A: Automated Setup (Recommended)

Run the automated setup script that handles all dependency installation:

```bash
./setup.sh
```

This script will:
- Check for Node.js 20+ and Python 3.12+ prerequisites
- Install pnpm if not present
- Install uv (Python package installer) if not present
- Install all Node.js dependencies
- Update Next.js to fix security vulnerability
- Install Python dependencies

### Option B: Manual Setup

#### Prerequisites

Make sure you have the following installed:
- Node.js 20+
- Python 3.12+
- `uv` (Python package installer) - optional but recommended

#### Install uv (Recommended)

First, install `uv` which is a fast Python package installer:

```bash
# On Linux/macOS
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or using pip
pip install uv

# After installation, you may need to restart your terminal or run:
source ~/.bashrc  # or ~/.zshrc depending on your shell
```

#### Install Project Dependencies

```bash
pnpm install
```

This will install both the Node.js and Python dependencies.

#### Update Next.js (Security Fix)

To address a security vulnerability, update Next.js to a patched version:

```bash
pnpm add next@16.1.0
```

Or manually update the version in `package.json` to `16.1.0` or later, then run `pnpm install`.

## Step 4: Maintain Package Lock File Consistency

### Understanding Package Lock Files

The project uses two important files for dependency management:

- **`package.json`**: Defines the dependencies your project needs
- **`package-lock.json`**: Records the exact versions of all installed dependencies and their sub-dependencies

### Why Lock File Consistency Matters

Keeping these files synchronized is crucial because:

1. **Reproducible builds**: Ensures that every deployment installs exactly the same dependency versions
2. **Docker builds**: The Docker build process uses `npm ci` which requires perfect lock file synchronization
3. **Deployment reliability**: Prevents deployment failures due to dependency version mismatches
4. **Team collaboration**: Ensures all team members and environments use identical dependency trees

### Maintaining Lock File Consistency

#### When to Update the Lock File

You **must** update `package-lock.json` after any of these operations:

```bash
# After adding a new dependency
pnpm add <package-name>

# After removing a dependency  
pnpm remove <package-name>

# After updating a dependency
pnpm update <package-name>

# After manually editing package.json
npm install
```

#### Correct Workflow

1. Make changes to `package.json` (add/remove/update dependencies)
2. Run `npm install` to update `package-lock.json`
3. Commit **both** files to version control together
4. Deploy or build

#### What NOT to Do

- ❌ Don't manually edit `package-lock.json`
- ❌ Don't commit `package.json` without updating `package-lock.json`
- ❌ Don't commit `package-lock.json` without the corresponding `package.json` changes
- ❌ Don't use `--no-save` flags unless you intentionally want to ignore lock file updates

### Handling Synchronization Issues

#### Detection During Deployment

The deployment script automatically validates lock file consistency before building Docker images. If synchronization issues are found:

```bash
ERROR: package.json and package-lock.json are out of sync

RECOVERY INSTRUCTIONS:
1. To fix this issue, run: npm install
2. This will update package-lock.json to match package.json  
3. Commit the updated package-lock.json to your repository
4. Then run the deployment again

To bypass this check (not recommended), use: ./deploy.sh --skip-deps-check
```

#### Fixing Out-of-Sync Lock Files

If you encounter synchronization issues:

```bash
# Fix the synchronization
npm install

# Verify the fix (optional)
npm ci --dry-run

# Commit both files
git add package.json package-lock.json
git commit -m "Update dependencies and synchronize lock file"
```

### Emergency Bypass (Not Recommended)

In emergency situations, you can bypass the lock file validation:

```bash
./deploy.sh --skip-deps-check
```

**⚠️ Warning**: Use this only in emergencies. Bypassing validation can lead to:
- Unpredictable builds
- Different dependency versions across environments
- Deployment failures
- Security vulnerabilities from unintended version updates

### Best Practices

1. **Always run `npm install` after changing `package.json`**
2. **Commit both files together** - never commit just one
3. **Test locally** with `npm ci --dry-run` before deployment
4. **Communicate dependency changes** with your team
5. **Review lock file changes** to understand what dependencies were updated

### Troubleshooting Common Issues

#### "npm ci" fails with lock file errors

```bash
# This means your lock file is out of sync
npm install  # Fix the synchronization
npm ci       # Verify it works
```

#### Git shows conflicts in package-lock.json

```bash
# Resolve conflicts by accepting the current version
npm install
git add package-lock.json
```

#### Deployment fails with lock file errors

Follow the recovery instructions shown in the error message, or run:

```bash
npm install
git add package.json package-lock.json
git commit -m "Fix lock file synchronization"
./deploy.sh
```

### Docker Build Fallback Mechanism

The project includes a **Docker build fallback mechanism** to handle lock file synchronization issues during the build process. This ensures that deployments can continue even when there are minor synchronization problems between `package.json` and `package-lock.json`.

#### What is the Fallback Mechanism?

The Dockerfile includes a two-stage dependency installation process:

1. **Primary path**: Uses `npm ci` for clean, reproducible builds when lock files are synchronized
2. **Fallback path**: Automatically switches to `npm install` if `npm ci` fails due to sync issues

This allows the build to continue while providing clear warnings about the synchronization issue.

#### When the Fallback Triggers

The fallback mechanism activates when:

- `package.json` and `package-lock.json` are out of sync
- Missing dependencies in the lock file
- Version conflicts between package.json and lock file
- Corrupted or incomplete lock file

#### What Happens When Fallback Triggers

When the fallback is triggered, you'll see these messages in the Docker build logs:

```
=== DOCKER BUILD FALLBACK MECHANISM TRIGGERED ===
ERROR: npm ci failed due to lock file synchronization issues
FALLBACK: Switching to npm install to continue build
ACTION REQUIRED: Run 'npm install' to update package-lock.json
===============================================
=== FALLBACK COMPLETED: Build continuing with npm install ===
WARNING: package.json and package-lock.json are out of sync
```

#### Implications of Using Fallback

| Scenario | Result | Action Required |
|----------|---------|-----------------|
| **Fallback NOT used** | ✅ Reproducible build with `npm ci` | None - ideal state |
| **Fallback USED** | ⚠️ Build continues but less reproducible | Fix lock file sync immediately |
| **Fallback fails** | ❌ Build completely fails | Fix lock file then retry |

#### What to Do When Fallback Triggers

Even though the build succeeds when the fallback triggers, **you must fix the underlying issue**:

1. **Immediately after deployment**, fix the lock file synchronization:
   ```bash
   npm install
   git add package.json package-lock.json
   git commit -m "Fix lock file synchronization (fallback was triggered)"
   ```

2. **Verify the fix**:
   ```bash
   npm ci --dry-run
   ```

3. **Rebuild to ensure clean build** without fallback:
   ```bash
   docker build -t my-ag-ui-app:latest .
   ```

#### Why This Matters

- **Build Reproducibility**: Fallback builds may install different dependency versions across environments
- **Security**: May install unintended versions with security vulnerabilities
- **Deployment Consistency**: Different environments might have different dependency versions
- **Debugging**: Issues become harder to trace if dependencies are inconsistent

#### Monitoring Fallback Usage

Watch for these fallback messages in your Docker build logs:
- `"DOCKER BUILD FALLBACK MECHANISM TRIGGERED"`
- `"WARNING: package.json and package-lock.json are out of sync"`

If you see these messages frequently, investigate your team's dependency management practices to prevent synchronization issues.

## Step 5: Run the Application

After setting up your environment variables and installing dependencies, run:

```bash
pnpm dev
```

This will start both the UI (on http://localhost:3000) and the agent (on http://localhost:8000) servers.

## Available Models

DeepSeek offers several models. You can change the `OPENAI_MODEL` variable to use different models:

- `deepseek-chat` - General purpose chat model (recommended)
- `deepseek-coder` - Specialized for coding tasks
- `deepseek-reasoner` - Advanced reasoning capabilities

## Troubleshooting

### Error: "The api_key client option must be set"

This error occurs when the `OPENAI_API_KEY` environment variable is not set. Make sure you've:

1. Created the `.env` file with your API key
2. Or set the environment variables in your shell
3. Restarted your terminal or IDE after setting environment variables

### Checking if environment variables are set

You can verify your environment variables are set by running:

```bash
echo $OPENAI_API_KEY
echo $OPENAI_BASE_URL
echo $OPENAI_MODEL
```

Each should display the configured value.

### Additional Troubleshooting

If you still encounter issues:

1. **Port conflicts**: Make sure ports 3000 and 8000 are not in use
2. **Python version**: Ensure you have Python 3.12+ installed
3. **Node.js version**: Ensure you have Node.js 20+ installed
4. **Missing dependencies**: Make sure `concurrently` is installed (included with `pnpm install`)
5. **uv not found**: If you don't want to install uv, you can use pip instead (see SETUP-FIX.md for alternative scripts)

## Security Notes

- Never commit your `.env` file to version control
- The `.env` file is already included in `.gitignore`
- Keep your API keys secure and don't share them publicly
- Rotate your API keys periodically for better security
