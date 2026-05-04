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

## Deployment Environment Variables

The deployment system supports additional environment variables that control deployment behavior and logging. These variables can be set in your shell or in a `.env` file.

### HEALTH_CHECK_PATH

**Description**: Controls the health check endpoint path used in Kubernetes liveness and readiness probes.

**Default Value**: `/api/health`

**Usage**:
```bash
# Set custom health check path
export HEALTH_CHECK_PATH="/custom/health/endpoint"

# Or use in .env file
echo "HEALTH_CHECK_PATH=/custom/health/endpoint" >> .env
```

**Notes**:
- This variable is used in the Kubernetes deployment manifest
- The path must be accessible and return HTTP 200 for the health check to pass
- Changing this value requires updating the deployment configuration
- The application must implement a health check endpoint at the specified path

### VERBOSE

**Description**: Enables verbose logging mode for deployment scripts, providing detailed debugging information and environment context.

**Default Value**: `false` (verbose logging disabled)

**Usage**:
```bash
# Enable verbose logging for deployment
export VERBOSE="true"

# Or use in .env file
echo "VERBOSE=true" >> .env

# Run deployment with verbose logging
VERBOSE=true ./deploy-all.sh
```

**Verbose Mode Includes**:
- Environment context logging (Kubernetes, registry, VM status)
- Detailed command output and error messages
- Structured error information with recovery steps
- Deployment timing and duration information
- Debug information for troubleshooting

**Example Output**:
```
[2026-03-27 18:05:22] INFO: 📊 ENVIRONMENT CONTEXT:
[2026-03-27 18:05:22] INFO:   • Kubernetes: ✅ Accessible
[2026-03-27 18:05:22] INFO:   • Node Count: 1
[2026-03-27 18:05:22] INFO:   • Registry: ❌ Not accessible
[2026-03-27 18:05:22] INFO:   • VM: ✅ Running (my-ag-ui-app-k8s)
```

### VM_NAME

**Description**: Specifies the name of the Multipass VM used for Kubernetes deployment.

**Default Value**: `my-ag-ui-app-k8s`

**Usage**:
```bash
# Set custom VM name
export VM_NAME="my-custom-k8s-vm"

# Or use in .env file
echo "VM_NAME=my-custom-k8s-vm" >> .env
```

**Notes**:
- This variable is used throughout the deployment scripts to reference the correct VM
- If you change the VM name, ensure the VM exists and is running: `multipass list`
- The VM must have Microk8s installed and configured

### LOG_DIR

**Description**: Specifies the directory where deployment log files are stored.

**Default Value**: `/tmp`

**Usage**:
```bash
# Set custom log directory
export LOG_DIR="/var/log/deployments"

# Or use in .env file
echo "LOG_DIR=/var/log/deployments" >> .env
```

**Notes**:
- Log files are named with pattern: `deploy-YYYYMMDD-HHMMSS.log`
- The directory must exist and be writable by the deployment process
- Log rotation is handled automatically (100MB limit, keeps last 10 files)

## Logging and Retention Policy

### Log File Location

Deployment logs are automatically created and stored in the location specified by the `LOG_DIR` environment variable.

**Default Log Directory**: `/tmp/`

**Log File Naming Convention**:
```
deploy-YYYYMMDD-HHMMSS.log
Example: deploy-20260327-180522.log
```

**Finding Log Files**:
```bash
# List all deployment logs
ls -la /tmp/deploy-*.log

# List most recent logs first
ls -lt /tmp/deploy-*.log

# Find the latest log file
LATEST_LOG=$(ls -t /tmp/deploy-*.log | head -1)
echo "Latest log: $LATEST_LOG"

# View latest log file in real-time
tail -f /tmp/deploy-$(ls -t /tmp/deploy-*.log | head -1 | cut -d/ -f3)
```

### Log Retention Policy

The deployment system includes automatic log rotation and cleanup to prevent disk exhaustion.

**Rotation Criteria**:
- **File Size**: Log files are rotated when they exceed 100MB
- **Retention Period**: Only the most recent 10 log files are kept
- **Cleanup Process**: Automatic cleanup runs at the start of each deployment

**Rotation Process**:
1. **Large File Detection**: When a log file exceeds 100MB, it's flagged for rotation
2. **File Rotation**: The large file is renamed with a timestamp:
   ```
   deploy-20260327-180522.log → deploy-20260327-180522.log.rotated-20260327-190000
   ```
3. **Compression**: Rotated files are automatically compressed to save space:
   ```
   deploy-20260327-180522.log.rotated-20260327-190000 → deploy-20260327-180522.log.rotated-20260327-190000.gz
   ```
4. **Cleanup**: Only the 10 most recent log files (including rotated ones) are kept

**Retention Examples**:
```
# Before cleanup (15 files):
deploy-20260327-180522.log              (current)
deploy-20260327-175049.log.rotated-20260327-180015.gz
deploy-20260327-172100.log.rotated-20260327-180522.gz
... (12 more files)

# After cleanup (10 files):
deploy-20260327-180522.log              (current) - KEPT
deploy-20260327-175049.log.rotated-20260327-180015.gz - KEPT
... (8 most recent files) - KEPT
... (5 oldest files) - REMOVED
```

### Log File Management

**Manual Log Cleanup**:
```bash
# Clean up logs older than 7 days
find /tmp -name "deploy-*.log*" -mtime +7 -delete

# Clean up all deployment logs
rm -f /tmp/deploy-*.log*

# Check total log file size
du -sh /tmp/deploy-*.log*
```

**Custom Log Retention**:
If you need different retention settings, you can modify the `cleanup_old_logs()` function in `deploy_scripts/common.sh`:

```bash
# In deploy_scripts/common.sh, modify these parameters:
cleanup_old_logs() {
    local log_dir="${LOG_DIR:-/tmp}"
    local max_size_mb=100          # Change rotation size threshold
    local max_logs=10               # Change number of files to keep
    # ... rest of function
}
```

**Log File Content Structure**:
Each log file contains:
- **Timestamp**: Every log entry includes timestamp with millisecond precision
- **Log Level**: INFO, WARNING, ERROR with clear visual indicators
- **Step Progress**: Clear marking of deployment step start and completion
- **Error Details**: Structured error messages with recovery steps
- **Environment Context**: System status information in VERBOSE mode

**Example Log Excerpt**:
```
[2026-03-27 18:05:22] INFO: 🚀 STARTING DEPLOYMENT PIPELINE
[2026-03-27 18:05:22] INFO: Environment: development
[2026-03-27 18:05:22] INFO: Verbose mode: false
[2026-03-27 18:05:22] INFO: 📋 Step 1: Setting up Kubernetes secrets...
[2026-03-27 18:05:55] ERROR: ❌ STEP 1 FAILED: Failed to set up Kubernetes secrets
[2026-03-27 18:05:55] ERROR: 🔄 INITIATING ROLLBACK PROCEDURE
```

### Log File Security

**Access Control**:
- Log files are created with default umask permissions
- Log directory should have appropriate permissions (typically 755)
- Consider setting restrictive permissions for production environments

**Sensitive Information**:
- Log files may contain environment variable names and error details
- Actual secret values (API keys, tokens) are not logged
- Ensure log files are not committed to version control

**Production Considerations**:
For production environments, consider these additional logging practices:

1. **Centralized Logging**: Configure log aggregation to a central system
2. **Log Rotation Alerts**: Set up monitoring for log file sizes
3. **Backup Policy**: Implement backup procedures for important log files
4. **Access Controls**: Restrict log file access to authorized personnel
5. **Compliance**: Ensure logging practices meet regulatory requirements

### Best Practices

1. **Monitor Log Sizes**: Keep an eye on log file growth
2. **Regular Review**: Periodically review logs for recurring issues
3. **Archive Important Logs**: Save logs from critical deployments for later analysis
4. **Document Issues**: Use log excerpts when creating bug reports
5. **Clean Up Regularly**: Implement regular log cleanup in your deployment process

**Example Log Analysis**:
```bash
# Find most common errors
grep "ERROR:" /tmp/deploy-*.log | sort | uniq -c | sort -nr

# Find deployment durations
grep "DEPLOYMENT PIPELINE COMPLETED" /tmp/deploy-*.log

# Check for rollback occurrences
grep "ROLLBACK" /tmp/deploy-*.log | wc -l
```

## Image Retention Policy

### Overview

The deployment system includes an image retention policy to manage Docker image versions in the Microk8s registry. This policy helps maintain storage efficiency while ensuring rollback capability and deployment reliability.

### Current Image Management

**Image Tagging Strategy**:
- **Development**: Images are tagged as `localhost:32000/my-ag-ui-app:latest`
- **Deployments**: Each deployment creates a new image with the `latest` tag
- **Registry**: Microk8s registry stores images in `/var/snap/microk8s/common/registry/storage`

**Current Behavior**:
- Each deployment builds a new image and pushes it to the registry
- The `latest` tag is updated to point to the most recent image
- Previous image versions remain in the registry but are not directly accessible via tags
- No automatic cleanup of old image versions is currently implemented

### Retention Policy

**Policy Statement**: The system retains the last 5 versions of deployed images to ensure rollback capability while managing storage usage.

**Retention Criteria**:
- **Maximum Versions**: 5 most recent image versions
- **Cleanup Trigger**: Manual cleanup or automated script execution
- **Protected Images**: Currently deployed image (latest) is always protected
- **Rollback Images**: Images needed for rollback are protected during cleanup

### Implementation

The image retention policy can be implemented manually or through automated scripts:

**Manual Image Management**:
```bash
# List all images in Microk8s registry
multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app

# List with detailed information including creation dates
multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app --format "table {{.CreatedAt}}\t{{.ID}}\t{{.Size}}\t{{.Tag}}"

# Remove specific old images (keeping last 5)
multipass exec my-ag-ui-app-k8s -- docker rmi localhost:32000/my-ag-ui-app:<image-id>
```

**Automated Cleanup Script**:
Create a script `cleanup-images.sh`:
```bash
#!/bin/bash

# Image retention cleanup script
# Keeps last 5 versions of my-ag-ui-app images

VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
MAX_VERSIONS=5
IMAGE_NAME="localhost:32000/my-ag-ui-app"

echo "Cleaning up old image versions (keeping last $MAX_VERSIONS)..."

# Get list of images sorted by creation time (newest first)
IMAGE_LIST=$(multipass exec "$VM_NAME" -- docker images "$IMAGE_NAME" --format "{{.CreatedAt}}\t{{.ID}}" | sort -r)

# Count total images
TOTAL_IMAGES=$(echo "$IMAGE_LIST" | wc -l)

if [ "$TOTAL_IMAGES" -le "$MAX_VERSIONS" ]; then
    echo "Total images ($TOTAL_IMAGES) is within retention limit ($MAX_VERSIONS). No cleanup needed."
    exit 0
fi

# Calculate how many to remove
TO_REMOVE=$((TOTAL_IMAGES - MAX_VERSIONS))
echo "Found $TOTAL_IMAGES images, will remove $TO_REMOVE oldest versions."

# Remove oldest images (skip first MAX_VERSIONS)
echo "$IMAGE_LIST" | tail -n "+$((MAX_VERSIONS + 1))" | while read -r created image_id; do
    if [ -n "$image_id" ]; then
        echo "Removing image: $image_id (created: $created)"
        multipass exec "$VM_NAME" -- docker rmi "$IMAGE_NAME:$image_id" || echo "Failed to remove $image_id"
    fi
done

echo "Image cleanup completed."
```

### Manual Retention Management

**Checking Current Image Status**:
```bash
# Check current image count and sizes
multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app

# Check registry storage usage
multipass exec my-ag-ui-app-k8s -- du -sh /var/snap/microk8s/common/registry/storage

# List images by creation date
multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app --format "{{.CreatedAt}}\t{{.Size}}\t{{.Tag}}" | sort
```

**Safe Image Removal**:
```bash
# Always verify image is not in use before removal
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Remove images older than specific date
multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app --format "{{.CreatedAt}}\t{{.ID}}" | awk '$1 < "2026-03-20" {print $2}' | xargs -r docker rmi
```

### Automated Retention Implementation

To implement automated image retention, you can add the cleanup process to your deployment workflow:

**Option 1: Pre-Deployment Cleanup**
Add to `deploy-all.sh` before the Docker build step:
```bash
# Clean up old images before building new one
echo "🧹 Cleaning up old image versions..."
if [ -f "cleanup-images.sh" ]; then
    ./cleanup-images.sh
else
    echo "cleanup-images.sh not found, skipping image cleanup"
fi
```

**Option 2: Scheduled Cleanup**
Add to crontab or system scheduler:
```bash
# Add to crontab: Run daily at 2 AM
0 2 * * * /path/to/project/cleanup-images.sh >> /var/log/image-cleanup.log 2>&1
```

**Option 3: Git Hook Cleanup**
Add to `.git/hooks/post-commit`:
```bash
#!/bin/bash
# Clean up images after significant commits
if git log -1 --pretty=format:"%s" | grep -q "major\|release\|deploy"; then
    ./cleanup-images.sh
fi
```

### Storage Considerations

**Image Size Estimation**:
- **Typical Image Size**: 200-500MB (depends on dependencies)
- **5 Versions Storage**: ~1-2.5GB total storage required
- **Registry Storage**: Located in `/var/snap/microk8s/common/registry/storage`

**Monitoring Storage Usage**:
```bash
# Check registry storage usage
multipass exec my-ag-ui-app-k8s -- du -sh /var/snap/microk8s/common/registry/storage

# Check available disk space
multipass exec my-ag-ui-app-k8s -- df -h

# Monitor image count over time
echo "Current image count: $(multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app | wc -l)"
```

### Rollback and Version Management

**Image Versioning Strategy**:
- **Latest**: Always points to the most recent deployment
- **Previous Versions**: Retained for rollback capability
- **Version Tags**: Consider using semantic versioning for production releases

**Rollback Process with Image Retention**:
1. **Identify Target Version**: Find the image ID of the version to rollback to
2. **Verify Availability**: Ensure the image exists in the registry
3. **Update Deployment**: Modify the deployment manifest to use the specific image
4. **Apply Changes**: Deploy the previous version

**Example Rollback**:
```bash
# List available versions
multipass exec my-ag-ui-app-k8s -- docker images localhost:32000/my-ag-ui-app

# Update deployment to use specific image
multipass exec my-ag-ui-app-k8s -- microk8s kubectl set image deployment/my-ag-ui-app my-ag-ui-app=localhost:32000/my-ag-ui-app:<image-id>

# Verify rollback
multipass exec my-ag-ui-app-k8s -- microk8s kubectl rollout status deployment/my-ag-ui-app
```

### Best Practices

1. **Regular Cleanup**: Implement regular image cleanup to prevent storage issues
2. **Monitor Storage**: Keep an eye on registry storage usage
3. **Test Rollbacks**: Periodically test rollback capability with retained images
4. **Document Versions**: Maintain documentation of what each image version contains
5. **Production Consideration**: In production, consider keeping more versions (7-10) for better rollback capability

**Production Recommendations**:
- **Increase Retention**: Consider 7-10 versions for production environments
- **Automated Monitoring**: Set up alerts for storage usage
- **Regular Testing**: Monthly rollback testing with retained images
- **Documentation**: Maintain release notes for each image version

**Development vs Production**:
- **Development**: 3-5 versions (faster iteration, less storage concern)
- **Staging**: 5-7 versions (testing rollback scenarios)
- **Production**: 7-10 versions (maximum rollback capability, stability focused)

### Troubleshooting Image Retention Issues

**Common Issues**:
1. **Storage Full**: Registry storage exhausted
2. **Cleanup Failures**: Images in use cannot be removed
3. **Rollback Failures**: Target image no longer available
4. **Permission Issues**: Cannot access or remove images

**Solutions**:
```bash
# Force remove images (use with caution)
multipass exec my-ag-ui-app-k8s -- docker rmi -f localhost:32000/my-ag-ui-app:<image-id>

# Check which images are in use
multipass exec my-ag-ui-app-k8s -- microk8s kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'

# Clean up dangling images
multipass exec my-ag-ui-app-k8s -- docker image prune -f

# Restart registry service if needed
multipass exec my-ag-ui-app-k8s -- sudo systemctl restart snap.microk8s.daemon-registry.service
```

### ENVIRONMENT

**Description**: Specifies the deployment environment (used for logging and configuration).

**Default Value**: `development`

**Usage**:
```bash
# Set production environment
export ENVIRONMENT="production"

# Or use in .env file
echo "ENVIRONMENT=production" >> .env
```

**Notes**:
- This variable is primarily used for logging and environment-specific configuration
- It can be used to customize deployment behavior for different environments
- The value is included in deployment log headers for context

### Best Practices

1. **Environment Variables for Deployment**:
   ```bash
   # Create a .env.deploy file for deployment-specific variables
   cp .env .env.deploy
   echo "VERBOSE=true" >> .env.deploy
   echo "LOG_DIR=/var/log/deployments" >> .env.deploy
   
   # Use the deployment-specific env file
   export $(cat .env.deploy | xargs) && ./deploy-all.sh
   ```

2. **CI/CD Integration**:
   ```bash
   # Example GitHub Actions environment setup
   echo "ENVIRONMENT=production" >> $GITHUB_ENV
   echo "VERBOSE=true" >> $GITHUB_ENV
   echo "VM_NAME=prod-k8s-vm" >> $GITHUB_ENV
   ```

3. **Debugging with Verbose Logging**:
   ```bash
   # Always use verbose mode when debugging deployment issues
   VERBOSE=true ./deploy-all.sh 2>&1 | tee deployment-debug.log
   ```

4. **Custom Health Check Paths**:
    ```bash
    # If your application uses a non-standard health check endpoint
    export HEALTH_CHECK_PATH="/health/status"
    ./deploy-all.sh
    ```

## Deployment Configuration

### Health Check Implementation

The application includes a built-in health check endpoint at `/api/health` that is used by Kubernetes for monitoring container health and readiness.

**Endpoint Details**:
- **Path**: `/api/health` (configurable via `HEALTH_CHECK_PATH` environment variable)
- **Method**: GET
- **Response**: JSON `{"status": "healthy"}`
- **Status Code**: 200 (HTTP OK)
- **Authentication**: None required (publicly accessible)
- **Response Time**: < 1 second under normal conditions

**Health Check Configuration**:
```yaml
# Kubernetes probes configuration (in k8s/deployment.yaml)
readinessProbe:
  httpGet:
    path: /api/health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 1
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /api/health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 1
  failureThreshold: 3
```

### Docker Configuration for Production

The Docker container is configured for production deployment with the following optimizations:

**Production Environment**:
- **Node.js Environment**: `NODE_ENV=production` (set in Dockerfile)
- **Build Mode**: Next.js standalone output (`output: 'standalone'` in next.config.ts)
- **Server Command**: `npm start` (production server)

**Standalone Output Benefits**:
- Reduced container image size
- Faster startup times
- Better production performance
- Minimal dependencies in final image

**Container Lifecycle**:
- Containers run as non-root user for security
- Health checks prevent premature termination
- Proper signal handling for graceful shutdown
- No exit code 0 on startup (prevents Kubernetes restart loops)

### Kubernetes Deployment Configuration

The Kubernetes deployment is configured with health probes and resource management to ensure stable operation:

**Deployment Configuration**:
- **Image**: `localhost:32000/my-ag-ui-app:latest`
- **Replicas**: Configurable based on load requirements
- **Strategy**: Rolling updates for zero-downtime deployments
- **Health Monitoring**: Both readiness and liveness probes configured

**Probe Configuration Rationale**:
- **Readiness Probe**: 10s initial delay, checks if application is ready to receive traffic
- **Liveness Probe**: 30s initial delay, checks if application is still running and healthy
- **Timeout**: 1 second for both probes (health endpoint responds quickly)
- **Failure Threshold**: 3 consecutive failures before action is taken

### Deployment Process

The deployment process includes the following steps with built-in rollback capabilities:

1. **Build Phase**:
   ```bash
   # Build Docker image with standalone output
   docker build -t localhost:32000/my-ag-ui-app:latest .
   ```

2. **Push Phase**:
   ```bash
   # Push image to local registry
   docker push localhost:32000/my-ag-ui-app:latest
   ```

3. **Deploy Phase**:
   ```bash
   # Apply Kubernetes configuration
   kubectl apply -f k8s/deployment.yaml
   ```

4. **Health Check Phase**:
   ```bash
   # Verify deployment is healthy
   kubectl get pods -l app=my-ag-ui-app
   kubectl logs -f deployment/my-ag-ui-app
   ```

### Rollback Mechanism

The deployment includes an automated rollback mechanism that handles deployment failures:

**Rollback Triggers**:
- Pods enter CrashLoopBackOff state
- Health check failures exceed threshold
- Deployment takes too long to become ready

**Rollback Process**:
1. Detect deployment failure
2. Retrieve current resource version
3. Apply previous stable configuration
4. Verify pods return to healthy state

**Manual Rollback**:
```bash
# Rollback to previous version
kubectl rollout undo deployment/my-ag-ui-app

# Check rollback status
kubectl rollout status deployment/my-ag-ui-app
```

### Troubleshooting Deployment Issues

**Common Issues and Solutions**:

1. **CrashLoopBackOff**:
   - Check application logs: `kubectl logs <pod-name>`
   - Verify health endpoint is working: `kubectl exec <pod-name> -- curl http://localhost:3000/api/health`
   - Ensure proper environment variables are set

2. **Image Pull Issues**:
   - Verify registry is accessible: `curl http://localhost:32000/v2/_catalog`
   - Check image exists: `docker images localhost:32000/my-ag-ui-app`
   - Ensure proper image tag in deployment manifest

3. **Health Check Failures**:
   - Test health endpoint locally: `curl http://localhost:3000/api/health`
   - Check response time: `time curl http://localhost:3000/api/health`
   - Verify endpoint returns proper JSON: `{"status":"healthy"}`

4. **Deployment Timeout**:
   - Increase readiness/liveness probe timeouts if needed
   - Check resource limits in deployment manifest
   - Verify container has enough memory/CPU to start

**Debug Commands**:
```bash
# Check pod status
kubectl get pods -l app=my-ag-ui-app

# Check pod events
kubectl describe pod <pod-name>

# View application logs
kubectl logs -f deployment/my-ag-ui-app

# Test health endpoint from within cluster
kubectl exec -it <pod-name> -- curl http://localhost:3000/api/health

# Check deployment status
kubectl rollout status deployment/my-ag-ui-app
```

## Security Notes

- Never commit your `.env` file to version control
- The `.env` file is already included in `.gitignore`
- Keep your API keys secure and don't share them publicly
- Rotate your API keys periodically for better security
- Deployment environment variables can contain sensitive information - treat them like API keys
