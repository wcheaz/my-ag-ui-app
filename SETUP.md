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

## Step 4: Run the Application

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
