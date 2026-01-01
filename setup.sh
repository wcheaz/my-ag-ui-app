#!/bin/bash

# ag-ui Application Setup Script
# This script automates the dependency installation process

set -e  # Exit on any error

echo "🚀 Starting ag-ui application setup..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 20+ and try again."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2)
REQUIRED_NODE_VERSION="20.0.0"

if [ "$(printf '%s\n' "$REQUIRED_NODE_VERSION" "$NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_NODE_VERSION" ]; then
    echo "❌ Node.js version $NODE_VERSION is too old. Please install Node.js 20+ and try again."
    exit 1
fi

echo "✅ Node.js $NODE_VERSION detected"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.12+ and try again."
    echo "   Visit: https://www.python.org/downloads/"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
REQUIRED_PYTHON_VERSION="3.12.0"

if [ "$(printf '%s\n' "$REQUIRED_PYTHON_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_PYTHON_VERSION" ]; then
    echo "❌ Python version $PYTHON_VERSION is too old. Please install Python 3.12+ and try again."
    exit 1
fi

echo "✅ Python $PYTHON_VERSION detected"

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm is not installed. Installing pnpm..."
    npm install -g pnpm
fi

echo "✅ pnpm $(pnpm --version) detected"

# Check if uv is installed, install if not
UV_INSTALLED=false
if ! command -v uv &> /dev/null; then
    echo "📦 Installing uv (Python package installer)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Determine uv installation path
    UV_PATH=""
    if [ -d "$HOME/.cargo/bin" ]; then
        UV_PATH="$HOME/.cargo/bin"
    elif [ -d "$HOME/snap/code/current/.local/bin" ]; then
        UV_PATH="$HOME/snap/code/current/.local/bin"
    elif [ -d "$HOME/snap/code/217/.local/bin" ]; then
        UV_PATH="$HOME/snap/code/217/.local/bin"
    fi
    
    # Add uv to PATH for current session
    if [ -n "$UV_PATH" ]; then
        export PATH="$UV_PATH:$PATH"
        echo "✅ Added uv to PATH for current session"
    fi
    
    # Add uv to shell profile for future sessions
    SHELL_PROFILE=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_PROFILE" ] && [ -n "$UV_PATH" ]; then
        echo "export PATH=\"$UV_PATH:\$PATH\"" >> "$SHELL_PROFILE"
        echo "✅ Added uv to PATH in $SHELL_PROFILE"
    fi
    
    UV_INSTALLED=true
else
    echo "✅ uv $(uv --version) already installed"
fi

# Update Next.js for security fix
echo "🔒 Updating Next.js for security fix..."
pnpm add next@16.1.0

# Install Python dependencies using uv
echo "🐍 Installing Python dependencies..."
cd agent
if command -v uv &> /dev/null; then
    uv sync
else
    echo "⚠️  uv not found in PATH, falling back to pip..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -e .
fi
cd ..

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
# Set PATH for subprocesses to include uv if we just installed it
if [ "$UV_INSTALLED" = true ] && [ -n "$UV_PATH" ]; then
    PATH="$UV_PATH:$PATH" pnpm install
else
    pnpm install
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure your environment variables in .env file"
echo "2. Run 'pnpm dev' to start the application"
echo ""
echo "The UI will be available at http://localhost:3000"
echo "The agent will be available at http://localhost:8000"