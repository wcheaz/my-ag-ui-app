#!/bin/bash
# Kill any process running on port 8000 (just in case)
fuser -k 8000/tcp || true

# Run the full stack (Frontend + Backend)
npm run dev
