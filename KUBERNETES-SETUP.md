# Kubernetes Setup Guide (Multipass & MicroK8s)

This guide provides step-by-step instructions for creating a local Kubernetes cluster using **Multipass** and **MicroK8s**, configuring it, and deploying the Procurement Code Generator application.

---

## Prerequisites

Before starting, ensure your host machine has:
- **Multipass** installed: [multipass.run](https://multipass.run/)
- **Docker** installed: [docs.docker.com/get-docker/](https://docs.docker.com/get-docker/) (used to build the local container image)
- **Sufficient System Resources**: At least **4 CPUs**, **8 GB RAM**, and **20 GB free disk space**.

---

## Cluster Provisioning Step-by-Step

### 1. Launch the Multipass VM

Create a new Ubuntu VM named `my-ag-ui-app-k8s` with the necessary specifications to run Kubernetes:

```bash
multipass launch --cpus 4 --memory 7.7G --disk 19.3G --name my-ag-ui-app-k8s
```

*Note: You can verify the VM has launched correctly by running `multipass list`.*

### 2. Install MicroK8s inside the VM

Execute the package installer command inside the newly created VM:

```bash
multipass exec my-ag-ui-app-k8s -- sudo snap install microk8s --classic
```

### 3. Enable Required MicroK8s Add-ons

MicroK8s uses modular add-ons. Enable DNS, local storage storage-class, and the ingress controller:

```bash
multipass exec my-ag-ui-app-k8s -- microk8s enable dns storage ingress
```

- **dns**: Provides service discovery inside the cluster.
- **storage**: Provisions local persistent volumes.
- **ingress**: Standard NGINX ingress controller to route external traffic to your service.

---

## Deploying the Application

Once the cluster is running, follow these steps from your host machine's terminal:

### 1. Configure Secrets

Before deploying, you must set up the Kubernetes secrets using your local configurations:

```bash
./deploy_scripts/setup-k8s-secrets.sh
```

This will read your `.env` file (containing your `OPENAI_API_KEY`, model configs, etc.) and generate a secure `k8s/secrets.yaml` file, applying it directly into the VM's Kubernetes namespace.

### 2. Run the Deployment Pipeline

Execute the main orchestrator script:

```bash
./deploy-all.sh
```

This script will run:
- Pre-deployment checks.
- Build of the application Docker image locally.
- Configuration of the MicroK8s local container registry (port `32000`).
- Push of the built image to the VM registry.
- Application of Kubernetes deployment manifests (`k8s/deployment.yaml`, `k8s/service.yaml`, `k8s/ingress.yaml`).

---

## Testing & Verification

### Check Cluster Status
Verify that MicroK8s is running:
```bash
multipass exec my-ag-ui-app-k8s -- microk8s status
```

### Verify Application Pods
```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods
```
Expected output: Pod named `my-ag-ui-app-...` showing a `Running` status.

### Access the Application
1. **Find the VM's IP address**:
   ```bash
   multipass info my-ag-ui-app-k8s | grep IPv4
   ```
2. **Access directly**:
   Open your browser and navigate to `http://<VM_IP>`.
3. **Setup custom hostname (Optional)**:
   Add the following line to your host's `/etc/hosts` file (macOS/Linux):
   ```text
   <VM_IP>    my-ag-ui-app.local
   ```
   Then navigate to `http://my-ag-ui-app.local` in your browser.

---

## VM Management Reference

Use these commands to manage the lifecycle of your local VM:

- **Check VM Details**: `multipass info my-ag-ui-app-k8s`
- **Stop Cluster VM**: `multipass stop my-ag-ui-app-k8s` (saves system resources when not developing)
- **Start Cluster VM**: `multipass start my-ag-ui-app-k8s`
- **SSH Shell access**: `multipass shell my-ag-ui-app-k8s`
- **Tear Down / Delete VM**:
  ```bash
  multipass delete my-ag-ui-app-k8s
  multipass purge
  ```

---

## Troubleshooting

### VM Creation Fails
If launching the VM fails, check that virtualisation is enabled in your BIOS/system, and verify resources:
```bash
multipass --version
free -h
nproc
```

### Ingress not routing / Connection Refused
If the ingress controller is still initializing, wait 2–3 minutes. You can also view the ingress controller status:
```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get ingress
```

### Viewing Logs
To stream application logs for debugging:
```bash
multipass exec my-ag-ui-app-k8s -- microk8s kubectl logs -f -l app=my-ag-ui-app
```
