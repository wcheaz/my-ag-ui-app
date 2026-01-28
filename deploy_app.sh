#!/bin/bash

# Kill any process running on port 8000 (just in case)
fuser -k 8000/tcp || true

# Build the frontend
echo "Building the frontend..."
npm run build

# Run the full stack (Frontend + Backend) in production
echo "Starting application in production mode..."
npx concurrently "scripts/run-agent-prod.sh" "npm run start" --names agent,ui --prefix-colors green,blue --kill-others
