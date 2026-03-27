#!/bin/bash

# Simple HTTP server for testing health check endpoint
# Responds with HTTP 200 on /api/health

# Function to handle HTTP requests
handle_request() {
    while read -r line; do
        # Read until empty line (end of headers)
        if [[ "$line" == $'\r' ]]; then
            break
        fi
    done
    
    # Check if the request is for /api/health
    if [[ "$REQUEST_URI" == "/api/health" ]]; then
        # Send HTTP 200 response
        echo -e "HTTP/1.1 200 OK\r"
        echo -e "Content-Type: application/json\r"
        echo -e "Connection: close\r"
        echo -e "\r"
        echo -e '{"status": "healthy", "timestamp": "'$(date -Iseconds)'"}'
    else
        # Send 404 for other paths
        echo -e "HTTP/1.1 404 Not Found\r"
        echo -e "Connection: close\r"
        echo -e "\r"
    fi
}

# Create a simple HTTP server using netcat
echo "Starting health check test server on port 3000..."
echo "Health endpoint: http://localhost:3000/api/health"

# Export the function for use with bash
export -f handle_request

# Start the server
while true; do
    # Read the first line to get the request method and URI
    read -r method request_uri http_version
    
    # Extract the URI (remove query string if present)
    export REQUEST_URI="${request_uri%%\?*}"
    
    # Handle the request
    handle_request
done | nc -l -p 3000 -q 1