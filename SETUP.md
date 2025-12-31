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
OPENAI_BASE_URL=https://api.deepseek.com/v1
OPENAI_MODEL=deepseek-chat
```

### Option B: Set environment variables in your shell

For zsh (default on macOS):
```bash
echo 'export OPENAI_API_KEY="sk-your-actual-deepseek-api-key-here"' >> ~/.zshrc
echo 'export OPENAI_BASE_URL="https://api.deepseek.com/v1"' >> ~/.zshrc
echo 'export OPENAI_MODEL="deepseek-chat"' >> ~/.zshrc
source ~/.zshrc
```

For bash:
```bash
echo 'export OPENAI_API_KEY="sk-your-actual-deepseek-api-key-here"' >> ~/.bashrc
echo 'export OPENAI_BASE_URL="https://api.deepseek.com/v1"' >> ~/.bashrc
echo 'export OPENAI_MODEL="deepseek-chat"' >> ~/.bashrc
source ~/.bashrc
```

## Step 3: Run the Application

After setting up your environment variables, run:

```bash
pnpm dev
```

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

## Security Notes

- Never commit your `.env` file to version control
- The `.env` file is already included in `.gitignore`
- Keep your API keys secure and don't share them publicly
- Rotate your API keys periodically for better security
