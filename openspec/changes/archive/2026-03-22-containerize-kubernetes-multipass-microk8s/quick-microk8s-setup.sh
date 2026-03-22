#!/bin/bash

# Quick setup script for microk8s in the existing VM
# This script sets up microk8s and applies the Kubernetes manifests for ingress testing

set -e

# Configuration
VM_NAME="microk8s"
LOG_FILE="quick-microk8s-setup.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Start setup
log "Starting quick microk8s setup for ingress testing..."

# Check if VM exists
log "Checking if VM $VM_NAME exists..."
if ! multipass list | grep -q "$VM_NAME"; then
    error_exit "VM $VM_NAME does not exist"
fi

log "VM $VM_NAME found. Installing microk8s..."

# Step 1: Install microk8s
log "Step 1: Installing microk8s in VM..."
if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
    log "microk8s is already installed"
    MICROK8S_VERSION=$(multipass exec "$VM_NAME" -- microk8s version 2>/dev/null | head -1 | cut -d' ' -f2 || echo "unknown")
    log "Existing microk8s version: $MICROK8S_VERSION"
else
    log "Installing microk8s using snap..."
    if ! multipass exec "$VM_NAME" -- sudo snap install microk8s --classic; then
        error_exit "Failed to install microk8s"
    fi
    log "microk8s installed successfully"
fi

# Step 2: Wait for microk8s to be ready
log "Step 2: Waiting for microk8s to be ready..."
if ! multipass exec "$VM_NAME" -- sudo microk8s status --wait-ready; then
    error_exit "microk8s is not ready"
fi
log "microk8s is ready"

# Step 3: Enable required add-ons
log "Step 3: Enabling required add-ons..."

# Enable DNS add-on
log "Enabling DNS add-on..."
if ! multipass exec "$VM_NAME" -- sudo microk8s enable dns; then
    log "WARNING: Failed to enable DNS add-on (may already be enabled)"
fi
log "DNS add-on enabled"

# Enable storage add-on
log "Enabling storage add-on..."
if ! multipass exec "$VM_NAME" -- sudo microk8s enable storage; then
    log "WARNING: Failed to enable storage add-on (may already be enabled)"
fi
log "Storage add-on enabled"

# Enable ingress add-on
log "Enabling ingress add-on..."
if ! multipass exec "$VM_NAME" -- sudo microk8s enable ingress; then
    log "WARNING: Failed to enable ingress add-on (may already be enabled)"
fi
log "Ingress add-on enabled"

# Wait for add-ons to be ready
log "Waiting for add-ons to be ready..."
sleep 10

# Step 4: Create a simple test deployment and service
log "Step 4: Creating test application deployment..."

# Create a simple nginx deployment for testing
cat > /tmp/test-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-ag-ui-app
  labels:
    app: my-ag-ui-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-ag-ui-app
  template:
    metadata:
      labels:
        app: my-ag-ui-app
    spec:
      containers:
      - name: my-ag-ui-app
        image: nginx:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

# Create a service for the deployment
cat > /tmp/test-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: my-ag-ui-app-service
  labels:
    app: my-ag-ui-app
spec:
  selector:
    app: my-ag-ui-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create ingress
cat > /tmp/test-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ag-ui-app-ingress
  labels:
    app: my-ag-ui-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: localhost
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-ag-ui-app-service
            port:
              number: 80
  - host: 127.0.0.1
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-ag-ui-app-service
            port:
              number: 80
EOF

# Copy the manifests to the VM
log "Copying manifests to VM..."
multipass exec "$VM_NAME" -- bash -c "cat > /tmp/test-deployment.yaml" < /tmp/test-deployment.yaml
multipass exec "$VM_NAME" -- bash -c "cat > /tmp/test-service.yaml" < /tmp/test-service.yaml
multipass exec "$VM_NAME" -- bash -c "cat > /tmp/test-ingress.yaml" < /tmp/test-ingress.yaml

# Apply the manifests
log "Applying Kubernetes manifests..."

# Apply deployment
log "Creating deployment..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl apply -f /tmp/test-deployment.yaml; then
    error_exit "Failed to create deployment"
fi
log "Deployment created"

# Apply service
log "Creating service..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl apply -f /tmp/test-service.yaml; then
    error_exit "Failed to create service"
fi
log "Service created"

# Apply ingress
log "Creating ingress..."
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl apply -f /tmp/test-ingress.yaml; then
    error_exit "Failed to create ingress"
fi
log "Ingress created"

# Wait for pods to be ready
log "Waiting for pods to be ready..."
sleep 10
if ! multipass exec "$VM_NAME" -- sudo microk8s kubectl wait --for=condition=ready pod -l app=my-ag-ui-app --timeout=60s; then
    log "WARNING: Pods are not ready yet, continuing with test"
fi

# Clean up temporary files
rm -f /tmp/test-deployment.yaml /tmp/test-service.yaml /tmp/test-ingress.yaml

log "Quick microk8s setup completed successfully!"
log "Now you can run the ingress routing test"