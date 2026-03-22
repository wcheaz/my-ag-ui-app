# Dependency Management Guide

This document provides comprehensive guidance for managing dependencies in the my-ag-ui-app project. Proper dependency management is crucial for application stability, security, and deployment reliability.

## ⚠️ Critical: Lock File Synchronization

**This project requires strict synchronization between `package.json` and `package-lock.json`.** Docker builds will fail if these files are out of sync. This guide includes specific procedures for maintaining lock file consistency and handling synchronization issues.

## Table of Contents

1. [Dependency Files Overview](#dependency-files-overview)
2. [Package Management Tools](#package-management-tools)
3. [Dependency Types](#dependency-types)
4. [Adding Dependencies](#adding-dependencies)
5. [Updating Dependencies](#updating-dependencies)
6. [Removing Dependencies](#removing-dependencies)
7. [Lock File Management](#lock-file-management)
8. [Deployment Considerations](#deployment-considerations)
9. [Security Best Practices](#security-best-practices)
10. [Troubleshooting](#troubleshooting)
11. [Common Scenarios](#common-scenarios)

## Dependency Files Overview

### Primary Files

| File | Purpose | When to Edit | Commit to Git |
|------|---------|--------------|---------------|
| `package.json` | Defines project dependencies and scripts | When adding/removing/updating deps | ✅ Always |
| `package-lock.json` | Locks exact versions of all dependencies | Never manually edit | ✅ With package.json |
| `.npmrc` | npm configuration settings | Rarely | ⚠️ Only if necessary |

### Understanding package.json Structure

```json
{
  "name": "my-ag-ui-app",
  "version": "0.1.0",
  "dependencies": {
    "next": "^16.1.0",           // Production dependencies
    "react": "^19.2.1",
    "react-dom": "^19.2.1"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",   // Development-only dependencies
    "typescript": "^5.0.0",
    "eslint": "^8.0.0"
  },
  "scripts": {
    "dev": "next dev",           // npm run scripts
    "build": "next build",
    "start": "next start"
  }
}
```

## Package Management Tools

### Available Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `npm` | Node.js package manager | Default, for CI/CD and scripts |
| `pnpm` | Fast, disk-space efficient alternative | Development, local installs |
| `npx` | Execute packages without installing | One-off commands, project init |

### Tool Selection Guidelines

- **Development**: Use `pnpm` for faster installs and better disk usage
- **CI/CD**: Use `npm` for maximum compatibility and reproducibility
- **Scripts**: Use `npm run` in package.json for cross-platform compatibility

### Basic Commands

```bash
# Install all dependencies (from lock file)
npm ci

# Install all dependencies (may update lock file)
npm install

# Add a production dependency
npm add <package-name>
# or
pnpm add <package-name>

# Add a development dependency
npm add <package-name> --save-dev
# or  
pnpm add <package-name> -D

# Remove a dependency
npm remove <package-name>
# or
pnpm remove <package-name>

# Update dependencies
npm update
# or
pnpm update
```

## Dependency Types

### Production Dependencies

Dependencies required for the application to run in production:

```bash
# Add production dependency
npm add express
npm add lodash
```

### Development Dependencies

Dependencies only needed during development:

```bash
# Add development dependency
npm add typescript --save-dev
npm add eslint --save-dev
npm add @types/node --save-dev
```

### Peer Dependencies

Dependencies that your package expects to be provided by the consumer:

```bash
# Usually installed automatically, but sometimes need explicit installation
npm add react@peer-version
```

### Optional Dependencies

Dependencies that aren't required for core functionality:

```bash
# Add optional dependency
npm add fsevents --save-optional
```

## Adding Dependencies

### Best Practices for Adding Dependencies

1. **Check if you really need it**: Can you implement it yourself?
2. **Research alternatives**: Compare similar packages
3. **Check package health**: Downloads, maintenance, security
4. **Consider bundle size**: Impact on application size
5. **Test in isolation**: Verify it works as expected

### Adding Production Dependencies

```bash
# Recommended workflow
npm add <package-name>  # Add to package.json and install
# Test the functionality
# Commit both package.json and package-lock.json
```

### Adding Development Dependencies

```bash
# Development dependencies
npm add <package-name> --save-dev

# Example: TypeScript types
npm add @types/express --save-dev
npm add @types/react --save-dev
```

### Adding Specific Versions

```bash
# Exact version
npm add package@1.2.3

# Major version (compatible updates)
npm add package@^1.2.3

# Minor version (patch updates only)
npm add package@~1.2.3

# Latest version
npm add package@latest
```

## Updating Dependencies

### Update Strategies

| Strategy | Command | Use Case |
|----------|---------|----------|
| Update all | `npm update` | Regular maintenance |
| Update single | `npm update package-name` | Specific bug fixes |
| Interactive updates | `npm outdated` then manual | Careful updates |
| Major version updates | Manual in package.json | Breaking changes |

### Safe Update Workflow

```bash
# 1. Check what's outdated
npm outdated

# 2. Update one package at a time
npm update package-name

# 3. Test the application
npm test
npm run build

# 4. Commit if everything works
git add package.json package-lock.json
git commit -m "Update package-name to version"
```

### Major Version Updates

```bash
# For major updates that may have breaking changes
npm uninstall package-name
npm add package-name@latest

# Or update manually in package.json then
npm install
```

## Removing Dependencies

### Removal Workflow

```bash
# 1. Remove the dependency
npm remove package-name

# 2. Check for any remaining references
grep -r "package-name" src/

# 3. Test the application
npm test
npm run build

# 4. Commit the removal
git add package.json package-lock.json
git commit -m "Remove unused package-name"
```

### Cleanup Unused Dependencies

```bash
# Check for potentially unused dependencies
npm audit

# Manually review and remove
# Consider tools like depcheck for larger projects
```

## Lock File Management

### Purpose of package-lock.json

The `package-lock.json` file serves several critical purposes:

1. **Reproducible builds**: Ensures identical installs across environments
2. **Dependency tree integrity**: Locks the exact versions of all dependencies
3. **Security**: Enables vulnerability auditing and patching
4. **Bandwidth efficiency**: Avoids unnecessary re-downloads

### 🔴 Critical: Lock File Synchronization Requirements

**This project has strict requirements for lock file synchronization due to the Docker build process.**

#### Why Synchronization is Critical

The Docker build process uses `npm ci` which **requires exact synchronization** between `package.json` and `package-lock.json`. When these files are out of sync:

- Docker builds fail during the `RUN npm ci --ignore-scripts` step
- Deployments are blocked, creating critical bottlenecks
- Team productivity is impacted

#### Pre-Build Validation

The deployment script (`deploy.sh`) automatically validates lock file consistency before attempting Docker builds:

```bash
# This runs automatically in deploy.sh before Docker build
npm ci --dry-run
```

**If validation fails:**
- Deployment stops immediately with clear error messages
- You must fix the synchronization issue before proceeding
- Use `--skip-deps-check` flag only in emergencies (see below)

#### Docker Build Fallback Mechanism

The Dockerfile includes a **fallback mechanism** to handle lock file synchronization issues during builds:

```dockerfile
# Primary path: Use npm ci for reproducible builds
RUN npm ci --ignore-scripts && npm cache clean --force || \
    # Fallback: Use npm install if npm ci fails due to sync issues
    (echo "=== DOCKER BUILD FALLBACK MECHANISM TRIGGERED ===" && \
     echo "ERROR: npm ci failed due to lock file synchronization issues" && \
     echo "FALLBACK: Switching to npm install to continue build" && \
     echo "ACTION REQUIRED: Run 'npm install' to update package-lock.json" && \
     echo "===============================================" && \
     npm install --ignore-scripts && npm cache clean --force && \
     echo "=== FALLBACK COMPLETED: Build continuing with npm install ===" && \
     echo "WARNING: package.json and package-lock.json are out of sync")
```

#### When Fallback Triggers

The fallback mechanism activates when:
- `package.json` and `package-lock.json` are out of sync
- Missing dependencies in lock file
- Version conflicts between package.json and lock file
- Corrupted or incomplete lock file

#### Fallback Implications

| Scenario | Result | Action Required |
|----------|---------|-----------------|
| **Fallback NOT used** | ✅ Reproducible build with `npm ci` | None - ideal state |
| **Fallback USED** | ⚠️ Build continues but less reproducible | Fix lock file sync immediately |
| **Fallback fails** | ❌ Build completely fails | Fix lock file then retry |

#### Emergency Bypass: --skip-deps-check Flag

The `--skip-deps-check` flag provides an emergency bypass for pre-build validation:

```bash
# EMERGENCY USE ONLY
./deploy.sh --skip-deps-check
```

**⚠️ Critical Warnings:**
- Use ONLY in production outages or security emergencies
- Does NOT guarantee successful build (may still fail in Docker)
- Creates non-reproducible builds
- Security and stability risks
- MUST document usage and fix root cause afterward

**When NOT to use:**
- Regular development deployments
- Convenience to avoid proper fix
- Non-critical feature deployments
- When you have time to fix properly

**Post-bypass procedures:**
```bash
# 1. Fix the root cause immediately
npm install

# 2. Verify the fix
npm ci --dry-run

# 3. Commit the corrected files
git add package.json package-lock.json
git commit -m "Emergency fix: Restore lock file synchronization"

# 4. Document the incident
echo "$(date): Emergency deployment with --skip-deps-check used" >> deployment-emergency.log
```

### Lock File Best Practices

```bash
# ✅ Do: Always commit lock file with package.json
git add package.json package-lock.json
git commit -m "Update dependencies"

# ✅ Do: Update lock file when dependencies change
npm install

# ✅ Do: Use npm ci for CI/CD and deployments
npm ci

# ❌ Don't: Manually edit package-lock.json
# ❌ Don't: Commit package.json without package-lock.json
# ❌ Don't: Use --no-save unless intentional
```

### Fixing Lock File Issues

```bash
# When package.json and package-lock.json are out of sync
npm install

# Verify the fix
npm ci --dry-run

# If issues persist, regenerate lock file
rm package-lock.json
npm install
```

## Deployment Considerations

### CI/CD Pipeline

```bash
# Use npm ci for clean, reproducible installs
npm ci

# Only install production dependencies in CI
npm ci --production

# Run security audit
npm audit
```

### Docker Builds

The project's Docker build process requires lock file synchronization:

```dockerfile
# This will fail if package.json and package-lock.json are out of sync
RUN npm ci --ignore-scripts
```

### Pre-deployment Validation

The deployment script automatically validates lock file consistency before initiating any Docker build operations. This pre-build validation process is a critical safeguard that prevents deployment failures and provides immediate feedback when dependency issues are detected.

#### What is Pre-Build Validation?

Pre-build validation is an automated check that runs in the `deploy.sh` script before any Docker build operations begin. It uses npm's built-in validation logic to detect lock file synchronization issues that would cause `npm ci` to fail during the Docker build process.

#### How the Validation Process Works

The validation process is implemented in the `validate_lock_files()` function in `deploy.sh` and follows these steps:

1. **File Existence Check**: Verifies that both `package.json` and `package-lock.json` exist in the current directory
2. **Consistency Validation**: Runs `npm ci --dry-run` to check if the lock file is synchronized with package.json
3. **Result Handling**: 
   - If validation passes: Proceeds with Docker build
   - If validation fails: Halts deployment with detailed error messages and recovery instructions

#### Technical Implementation

The validation logic in `deploy.sh`:

```bash
validate_lock_files() {
    log "Starting lock file validation..."
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log "ERROR: package.json not found in current directory"
        return 1
    fi
    
    # Check if package-lock.json exists
    if [ ! -f "package-lock.json" ]; then
        log "ERROR: package-lock.json not found in current directory"
        return 1
    fi
    
    log "Validating npm lock file consistency using npm ci --dry-run..."
    
    # Run npm ci --dry-run to validate lock file consistency
    if ! npm ci --dry-run; then
        log "ERROR: package.json and package-lock.json are out of sync"
        log ""
        log "RECOVERY INSTRUCTIONS:"
        log "1. To fix this issue, run: npm install"
        log "2. This will update package-lock.json to match package.json"
        log "3. Commit the updated package-lock.json to your repository"
        log "4. Then run the deployment again"
        log ""
        log "To bypass this check (not recommended), use: $0 --skip-deps-check"
        log ""
        return 1
    fi
    
    log "✓ Lock file validation successful - package.json and package-lock.json are synchronized"
    return 0
}
```

#### When Validation Runs

The pre-build validation runs automatically in these scenarios:

1. **Normal Deployment**: Every time `./deploy.sh` is executed
2. **CI/CD Pipeline**: When the deployment script is used in automated pipelines
3. **Manual Deployments**: Any manual execution of the deployment script

The validation can be bypassed using the `--skip-deps-check` flag, but this should only be used in emergencies and with full understanding of the risks.

#### Integration with Deployment Workflow

The pre-build validation is seamlessly integrated into the deployment workflow:

```bash
# This runs automatically in deploy.sh before Docker build
if [ "$SKIP_DEPS_CHECK" = false ]; then
    if ! validate_lock_files; then
        handle_secrets_error 200 "Lock file validation failed" \
            "package.json and package-lock.json are out of sync. Run 'npm install' to synchronize them."
    fi
else
    log "SKIPPED: Lock file validation bypassed by --skip-deps-check flag"
fi
```

#### Validation Output

##### Success Output
When validation passes, you'll see:

```
[timestamp] Starting lock file validation...
[timestamp] Validating npm lock file consistency using npm ci --dry-run...
[timestamp] ✓ Lock file validation successful - package.json and package-lock.json are synchronized
```

##### Failure Output
When validation fails, you'll see detailed error messages:

```
[timestamp] Starting lock file validation...
[timestamp] Validating npm lock file consistency using npm ci --dry-run...
npm ERR! Invalid: lock file's express@1.0.0 does not satisfy ^2.0.0
[timestamp] ERROR: package.json and package-lock.json are out of sync

RECOVERY INSTRUCTIONS:
1. To fix this issue, run: npm install
2. This will update package-lock.json to match package.json
3. Commit the updated package-lock.json to your repository
4. Then run the deployment again

To bypass this check (not recommended), use: ./deploy.sh --skip-deps-check
```

#### Common Validation Failure Scenarios

##### Scenario 1: Missing Dependencies in Lock File
**Error**: `npm ERR! Invalid: missing dependency: package-name@version`

**Cause**: A dependency was added to `package.json` but `npm install` was not run afterward

**Fix**: `npm install`

##### Scenario 2: Version Mismatch
**Error**: `npm ERR! Invalid: lock file's package@1.0.0 does not satisfy ^2.0.0`

**Cause**: `package.json` was updated to require a different version than what's in the lock file

**Fix**: `npm install`

##### Scenario 3: Missing Lock File
**Error**: `ERROR: package-lock.json not found in current directory`

**Cause**: The lock file was deleted or never created

**Fix**: `npm install`

##### Scenario 4: Corrupted Lock File
**Error**: JSON parsing errors or unexpected npm behavior

**Cause**: Lock file is corrupted or malformed

**Fix**: `rm package-lock.json && npm install`

#### Benefits of Pre-Build Validation

1. **Fast Failure**: Detects issues immediately, saving time that would be wasted on Docker builds that would fail
2. **Clear Error Messages**: Provides specific, actionable error messages with recovery instructions
3. **Consistency Enforcement**: Ensures all deployments use consistent, reproducible dependency installations
4. **Development Feedback**: Helps developers identify and fix lock file issues early in the development process
5. **Deployment Reliability**: Reduces deployment failures due to dependency synchronization issues

#### Performance Impact

The pre-build validation typically adds 2-5 seconds to the deployment process, but this is minimal compared to the time saved by preventing Docker build failures (which can take several minutes to fail).

### Docker Build Fallback Mechanism

The Docker build process includes a fallback mechanism to handle lock file synchronization issues during builds.

#### How the Fallback Works

The Dockerfile implements a two-stage dependency installation:

```dockerfile
# First attempt: Use npm ci for reproducible builds
RUN npm ci --ignore-scripts && npm cache clean --force || \
    # Fallback: Use npm install if npm ci fails
    (echo "=== DOCKER BUILD FALLBACK MECHANISM TRIGGERED ===" && \
     echo "ERROR: npm ci failed due to lock file synchronization issues" && \
     echo "FALLBACK: Switching to npm install to continue build" && \
     echo "ACTION REQUIRED: Run 'npm install' to update package-lock.json" && \
     echo "===============================================" && \
     npm install --ignore-scripts && npm cache clean --force && \
     echo "=== FALLBACK COMPLETED: Build continuing with npm install ===" && \
     echo "WARNING: package.json and package-lock.json are out of sync")
```

#### When the Fallback Triggers

The fallback mechanism triggers when:

1. **Lock files are out of sync**: `package.json` and `package-lock.json` don't match
2. **Missing dependencies**: Dependencies in `package.json` are missing from lock file
3. **Version conflicts**: Dependency versions in lock file don't satisfy package.json requirements
4. **Corrupted lock file**: The lock file is malformed or incomplete

#### Fallback Behavior

| Scenario | Primary Path | Fallback Path | Result |
|----------|--------------|---------------|---------|
| Lock files in sync | `npm ci` succeeds | Not used | ✅ Reproducible build |
| Lock files out of sync | `npm ci` fails | `npm install` used | ⚠️ Build succeeds but less reproducible |
| Severe sync issues | `npm ci` fails | `npm install` may fail | ❌ Build fails |

#### Fallback Logging

When the fallback triggers, Docker build logs show:

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

**Build Continues But:**
- ⚠️ **Less reproducible**: Dependencies may not match exactly across environments
- ⚠️ **Security risk**: May install unintended versions with vulnerabilities
- ⚠️ **Deployment inconsistency**: Different environments may have different versions
- ⚠️ **Masked root cause**: The real issue (out-of-sync lock files) still needs fixing

#### Recommended Actions When Fallback Triggers

1. **Immediate**: Note that fallback was used in build logs
2. **Short-term**: Fix lock file synchronization:
   ```bash
   npm install
   git add package.json package-lock.json
   git commit -m "Fix lock file synchronization"
   ```
3. **Long-term**: Ensure all dependency updates follow proper workflow:
   - Always run `npm install` after changing `package.json`
   - Commit both files together
   - Use pre-build validation to catch issues early

#### Monitoring Fallback Usage

**In Build Logs:**
- Watch for "DOCKER BUILD FALLBACK MECHANISM TRIGGERED" messages
- Monitor frequency of fallback usage
- Alert if fallback is used in production builds

**In CI/CD:**
- Consider failing builds if fallback is used (strict mode)
- Log fallback occurrences for tracking
- Create alerts for repeated fallback usage

#### Best Practices

1. **Prevent fallback usage**: Maintain lock file consistency
2. **Monitor builds**: Check for fallback messages in logs
3. **Fix root causes**: Don't rely on fallback as a solution
4. **Document occurrences**: Track when and why fallback was used
5. **Review regularly**: Audit build logs for fallback patterns

## Monitoring and Alerting for Fallback Usage

Effective monitoring of the fallback mechanism is crucial for maintaining deployment reliability and identifying systemic issues early. This section provides comprehensive guidance for monitoring fallback usage and setting up appropriate alerts.

### What to Monitor

#### Primary Metrics

| Metric | Description | Importance | Threshold |
|--------|-------------|-----------|-----------|
| **Fallback Trigger Count** | Number of times fallback mechanism activates | Critical | > 0 in production |
| **Fallback Frequency** | Rate of fallback usage per time period | High | > 2 per week |
| **Fallback by Environment** | Breakdown by dev/staging/prod | High | Any in production |
| **Build Success Rate** | Overall build success with/without fallback | Medium | < 95% success |

#### Secondary Metrics

| Metric | Description | Importance | Threshold |
|--------|-------------|-----------|-----------|
| **Lock File Validation Failures** | Pre-build validation failures in deploy.sh | High | Any in production |
| **Emergency Bypass Usage** | --skip-deps-check flag usage | Critical | > 0 in production |
| **Build Duration Increase** | Additional time when fallback is used | Medium | > 10% increase |
| **Post-Fallback Issues** | Application issues after fallback deployments | High | Any correlation |

### Alert Thresholds and Escalation

#### Critical Alerts (Immediate Action Required)

**Alert Condition:**
- Fallback mechanism triggered in **production** environment
- Emergency bypass flag (`--skip-deps-check`) used in any environment

**Response Time:** Immediate (within 15 minutes)

**Escalation Path:**
1. **On-call engineer** investigates immediately
2. **DevOps lead** notified within 30 minutes
3. **Engineering manager** notified if production impacted

**Actions Required:**
1. Verify deployment completed successfully
2. Check application functionality
3. Document incident in incident tracking system
4. Schedule root cause analysis within 24 hours
5. Plan fix deployment within 48 hours

#### Warning Alerts (Within 24 Hours)

**Alert Condition:**
- Fallback mechanism triggered more than **2 times per week** in any environment
- Lock file validation failure rate > **10%** in any environment

**Response Time:** Within 24 hours

**Escalation Path:**
1. **Team lead** reviews pattern
2. **DevOps engineer** investigates systemic issues
3. **Development team** notified of process issues

**Actions Required:**
1. Review recent dependency management practices
2. Identify root causes of frequent fallback usage
3. Provide additional training if needed
4. Consider process improvements

#### Informational Alerts (Weekly Review)

**Alert Condition:**
- Any fallback usage in development environments
- Build duration trends increasing

**Response Time:** Weekly team review

**Actions Required:**
1. Review patterns in team standup
2. Identify opportunities for improvement
3. Update documentation if needed
4. Consider process refinements

### Implementation Strategies

#### Log-Based Monitoring

**Docker Build Log Monitoring:**

```bash
# Monitor Docker build logs for fallback triggers
docker build --progress=plain . 2>&1 | grep -E "(FALLBACK|npm ci failed)"

# Sample log patterns to monitor:
# "=== DOCKER BUILD FALLBACK MECHANISM TRIGGERED ==="
# "ERROR: npm ci failed due to lock file synchronization issues"
# "=== FALLBACK COMPLETED: Build continuing with npm install ==="
```

**Deploy.sh Log Monitoring:**

```bash
# Monitor deploy.sh logs for validation failures
./deploy.sh 2>&1 | grep -E "(Lock file validation failed|SKIPPED: Lock file validation)"

# Sample log patterns to monitor:
# "ERROR: Lock file validation failed"
# "SKIPPED: Lock file validation bypassed by --skip-deps-check flag"
```

#### Structured Logging Implementation

For better monitoring, consider implementing structured logging:

```bash
# Enhanced logging in deploy.sh for monitoring
log_fallback_usage() {
    local environment=$1
    local trigger_reason=$2
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "{\"timestamp\":\"$timestamp\",\"event\":\"fallback_triggered\",\"environment\":\"$environment\",\"reason\":\"$trigger_reason\"}" >&2
}

# Usage in Dockerfile fallback:
RUN npm ci --ignore-scripts && npm cache clean --force || \
    (log_fallback_usage "production" "npm ci failure" && \
     npm install --ignore-scripts && npm cache clean --force)
```

#### Integration with Monitoring Systems

**Prometheus/Grafana Integration:**

```yaml
# prometheus.yml example
scrape_configs:
  - job_name: 'docker-builds'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
    scrape_interval: 5m

# Example metrics to expose:
# docker_build_fallback_count{environment="production"}
# docker_build_validation_failures{environment="staging"}
```

**DataDog/New Relic Integration:**

```javascript
// Example DataDog metric submission
const datadog = require('datadog-metrics');

datadog.init({
  apiKey: process.env.DATADOG_API_KEY,
  host: 'my-ag-ui-app-builder',
  prefix: 'docker_build.'
});

// When fallback is triggered:
datadog.increment('fallback.count', 1, {
  environment: process.env.DEPLOY_ENV,
  trigger_reason: 'npm_ci_failure'
});
```

### Dashboard Recommendations

#### Primary Dashboard: Build Health

**Widgets to Include:**
1. **Fallback Usage Count** (Last 7 days) - Bar chart
2. **Build Success Rate** by environment - Pie chart
3. **Average Build Duration** with/without fallback - Line chart
4. **Recent Fallback Incidents** - Table with details
5. **Lock File Validation Failures** - Trend line

**Layout Example:**
```
┌─────────────────────────┬─────────────────────────┐
│   Fallback Usage (7d)   │   Build Success Rate    │
│     [Bar Chart]         │    [Pie Chart]          │
├─────────────────────────┼─────────────────────────┤
│ Build Duration Trend    │ Recent Incidents        │
│     [Line Chart]        │      [Table]            │
├─────────────────────────┼─────────────────────────┤
│ Validation Failures     │ Environment Breakdown   │
│     [Line Chart]        │    [Bar Chart]          │
└─────────────────────────┴─────────────────────────┘
```

#### Secondary Dashboard: Incident Response

**Widgets to Include:**
1. **Active Alerts** - Status list
2. **Mean Time to Resolution** - Trend
3. **Root Cause Categories** - Pie chart
4. **Team Response Times** - Metrics
5. **Follow-up Actions** - Task list

### Automated Response Procedures

#### When Fallback is Detected

**Immediate Actions:**
1. **Log to structured monitoring system**
2. **Send alert to appropriate channel**
3. **Create incident ticket**
4. **Notify on-call engineer**

**Automation Script Example:**

```bash
#!/bin/bash
# fallback-alert.sh - Triggered when fallback is detected

ENVIRONMENT=${1:-"unknown"}
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_ID=${BUILD_ID:-"manual"}

# Log to monitoring system
curl -X POST "https://api.monitoring-service.com/metrics" \
  -H "Content-Type: application/json" \
  -d '{
    "metric": "docker_build_fallback",
    "value": 1,
    "tags": {
      "environment": "'$ENVIRONMENT'",
      "build_id": "'$BUILD_ID'",
      "timestamp": "'$TIMESTAMP'"
    }
  }'

# Send alert
curl -X POST "https://api.alert-service.com/webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "alert_type": "warning",
    "title": "Docker Build Fallback Triggered",
    "message": "Fallback mechanism activated in '$ENVIRONMENT' environment",
    "priority": "high",
    "timestamp": "'$TIMESTAMP'"
  }'

# Create incident ticket
curl -X POST "https://api.ticket-system.com/incidents" \
  -H "Authorization: Bearer $TICKET_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker Build Fallback - '$ENVIRONMENT'",
    "description": "Fallback mechanism was triggered during build process",
    "priority": "high",
    "environment": "'$ENVIRONMENT'",
    "build_id": "'$BUILD_ID'",
    "requires_followup": true
  }'
```

### Incident Response Playbook

#### Phase 1: Immediate Response (First 30 Minutes)

**Incident Commander Actions:**
1. **Verify impact scope**
   - Which environment was affected?
   - Is this impacting production traffic?
   - Are there active user impacts?

2. **Assess current state**
   - Did the deployment complete successfully?
   - Is the application functioning normally?
   - Are there immediate stability concerns?

3. **Initial communication**
   - Notify stakeholders of potential impact
   - Set up incident communication channel
   - Document initial assessment

#### Phase 2: Investigation (First 2 Hours)

**Technical Investigation:**
1. **Gather diagnostic information**
   ```bash
   # Collect build logs
   docker logs <container_id> > build-fallback-incident.log
   
   # Check lock file status
   npm ci --dry-run > validation-check.log 2>&1
   
   # Document current state
   git status > git-status.log
   npm ls --depth=0 > dependency-list.log
   ```

2. **Identify root cause**
   - When were package.json/lock.json last modified?
   - Who made the changes?
   - Were proper procedures followed?
   - Are there merge conflicts or manual edits?

3. **Determine impact assessment**
   - Are dependencies actually different?
   - Could this cause runtime issues?
   - Is immediate rollback needed?

#### Phase 3: Resolution and Recovery (First 24 Hours)

**Immediate Fix:**
```bash
# Fix lock file synchronization
npm install
git add package.json package-lock.json
git commit -m "Fix lock file synchronization - incident $INCIDENT_ID"

# Verify fix
npm ci --dry-run
docker build -t fixed-build .
```

**Post-Incident Actions:**
1. **Documentation update**
   - Create incident report
   - Update monitoring thresholds if needed
   - Add to team knowledge base

2. **Process improvement**
   - Review if existing procedures were followed
   - Identify gaps in training or documentation
   - Implement preventive measures

3. **Follow-up monitoring**
   - Increased monitoring for 72 hours
   - Check for any delayed issues
   - Verify application stability

### Long-term Trend Analysis

#### Weekly Reporting

**Metrics to Track:**
1. **Fallback frequency trend** (week over week)
2. **Common root causes** (categorized)
3. **Team performance** (time to fix, recurrence rate)
4. **Process effectiveness** (trending improvements)

**Sample Report Structure:**

```markdown
# Weekly Build Health Report

## Summary Period: YYYY-MM-DD to YYYY-MM-DD

## Key Metrics
- Total builds: 45
- Fallback incidents: 2 (↓ 50% from last week)
- Emergency bypass usage: 0
- Average time to fix: 1.2 hours

## Incidents by Category
- Manual lock file edits: 1
- Missing npm install after package.json changes: 1
- Merge conflict resolution errors: 0

## Team Performance
- Fastest fix time: 30 minutes
- Slowest fix time: 2 hours
- Recurrence rate: 0%

## Action Items
1. [ ] Update team training on dependency management
2. [ ] Consider pre-commit hook implementation
3. [ ] Review merge conflict resolution procedures

## Trend Analysis
Fallback usage is decreasing, indicating improved team practices. Continue current training approach.
```

### Configuration Files

#### Alert Configuration Example

```yaml
# alerts.yaml
alerts:
  - name: "Fallback Mechanism Triggered - Production"
    condition: "docker_build_fallback_count > 0 AND environment == 'production'"
    severity: "critical"
    notification_channels:
      - "pagerduty:production-oncall"
      - "slack:deployment-alerts"
    
  - name: "High Fallback Frequency"
    condition: "docker_build_fallback_count > 2 AND time_range == '7d'"
    severity: "warning"
    notification_channels:
      - "slack:build-team"
      - "email:devops-team"
    
  - name: "Emergency Bypass Usage"
    condition: "emergency_bypass_count > 0"
    severity: "critical"
    notification_channels:
      - "pagerduty:engineering-manager"
      - "slack:incident-response"
```

#### Dashboard Configuration Example

```json
// dashboard-config.json
{
  "title": "Docker Build Health",
  "panels": [
    {
      "title": "Fallback Usage",
      "type": "stat",
      "targets": [
        {
          "query": "sum(docker_build_fallback_count)"
        }
      ]
    },
    {
      "title": "Build Success Rate",
      "type": "gauge",
      "targets": [
        {
          "query": "(builds_success_count / builds_total_count) * 100"
        }
      ]
    }
  ]
}
```

### Emergency Bypass: --skip-deps-check Flag

The `--skip-deps-check` flag provides an emergency bypass for the lock file validation step in the deployment script. This should only be used in exceptional circumstances.

#### When to Use --skip-deps-check

**Appropriate Use Cases:**
1. **Production Outage**: When you need to deploy a critical fix immediately and cannot wait for proper lock file synchronization
2. **Emergency Security Patch**: Deploying a critical security vulnerability fix where time is of the essence
3. **Last Resort**: When all other troubleshooting methods have failed and you understand the risks

**Inappropriate Use Cases:**
- ❌ Regular development deployments
- ❌ Convenience to avoid fixing the root cause
- ❌ When you have time to properly fix lock file synchronization
- ❌ In CI/CD automated pipelines
- ❌ When working on non-critical features

#### How to Use the Flag

```bash
# Emergency bypass - use with extreme caution
./deploy.sh --skip-deps-check

# The flag bypasses this validation step:
# if ! validate_lock_files; then
#     handle_secrets_error 200 "Lock file validation failed" ...
# fi
```

#### Risks and Warnings

**⚠️ Critical Risks:**

1. **Build Failures**: The Docker build may still fail if lock files are severely out of sync
2. **Non-Reproducible Builds**: Dependencies installed may not match across environments
3. **Security Vulnerabilities**: May install unintended versions with known vulnerabilities
4. **Deployment Inconsistency**: Different environments may have different dependency versions
5. **Debugging Difficulty**: Issues become harder to trace if dependencies are inconsistent

**⚠️ Operational Warnings:**

1. **Temporary Measure**: This is not a permanent solution - you MUST fix the lock file afterward
2. **Documentation Required**: You must document when and why this flag was used
3. **Team Notification**: Inform your team that an emergency bypass was used
4. **Monitoring**: Increased monitoring of the deployed application is recommended

#### Post-Bypass Procedures

**Immediate Actions (After Successful Deployment):**

```bash
# 1. Fix the root cause immediately
npm install

# 2. Verify the fix
npm ci --dry-run

# 3. Commit the corrected lock file
git add package.json package-lock.json
git commit -m "Emergency fix: Restore lock file synchronization"

# 4. Document the bypass incident
echo "$(date): Emergency deployment with --skip-deps-check used by $(whoami)" >> deployment-emergency.log
echo "Reason: [brief explanation of emergency]" >> deployment-emergency.log
```

**Follow-up Actions:**

```bash
# 1. Verify deployed application functionality
# Test critical functionality thoroughly

# 2. Check for any issues caused by inconsistent dependencies
# Monitor application logs for dependency-related errors

# 3. Plan a hotfix deployment with proper lock file validation
# Prepare to redeploy with correct lock files as soon as possible
```

#### Incident Documentation Template

When using `--skip-deps-check`, document the incident:

```markdown
## Emergency Deployment Incident

**Date:** YYYY-MM-DD HH:MM:SS
**Environment:** [production/staging/development]
**Initiator:** [name/team]
**Reason:** [detailed explanation of emergency]
**Flag Used:** --skip-deps-check

### Impact Assessment
- **What was at risk:** [description of what would happen if not deployed immediately]
- **Business impact:** [description of business impact]
- **Technical impact:** [description of technical impact]

### Actions Taken
1. Used `--skip-deps-check` flag to bypass lock file validation
2. Deployed changes: [description of changes deployed]
3. Immediate post-deployment fixes: [what was done after deployment]

### Root Cause
- **Why lock files were out of sync:** [explanation]
- **Why normal fix couldn't be applied:** [explanation]

### Resolution
- **Lock file fixed:** [yes/no] - If yes, when and how
- **Normal deployment restored:** [yes/no] - If yes, when
- **Prevention measures:** [what will prevent this in future]

### Lessons Learned
- [what could be done differently to avoid this in future]
- [process improvements needed]
```

#### Team Guidelines

**Pre-approval (if possible):**
- For production environments, get approval from at least one other senior developer
- Document the approval in your team's communication channel (Slack, Teams, etc.)

**Communication:**
- Notify your team before using the flag if time permits
- Announce when the emergency deployment is complete
- Share the incident documentation with the team

**Follow-up:**
- Schedule a team review to discuss why the emergency bypass was needed
- Implement process improvements to prevent future emergencies
- Consider adding the root cause to your team's troubleshooting guide

#### Technical Details

**What the Flag Bypasses:**

The `--skip-deps-check` flag specifically bypasses this validation in `deploy.sh`:

```bash
if [ "$SKIP_DEPS_CHECK" = false ]; then
    if ! validate_lock_files; then
        handle_secrets_error 200 "Lock file validation failed" \
            "package.json and package-lock.json are out of sync. Run 'npm install' to synchronize them."
    fi
else
    log "SKIPPED: Lock file validation bypassed by --skip-deps-check flag"
fi
```

**What It Does NOT Bypass:**

- Docker build dependency installation steps
- npm ci or npm install commands in the Dockerfile
- Any other validation or error checking in the deployment process
- Kubernetes deployment validations

**Best Practice Alternative:**

Instead of using the bypass flag, consider these alternatives:

```bash
# Quick fix (preferred):
npm install
./deploy.sh

# If that fails, complete lock file regeneration:
rm package-lock.json
npm install
./deploy.sh

# Only use --skip-deps-check as absolute last resort
```

## Security Best Practices

### Regular Security Audits

```bash
# Check for known vulnerabilities
npm audit

# Fix vulnerabilities automatically (when possible)
npm audit fix

# Review security updates
npm audit fix --dry-run
```

### Dependency Vetting

Before adding any dependency:

1. **Check the package website** and documentation
2. **Review the GitHub repository** activity
3. **Check npm page** for downloads and maintenance status
4. **Look for security issues** in the repository
5. **Consider the license** compatibility

### Secure Development Practices

```bash
# Use npm audit in your development workflow
npm audit

# Check for outdated dependencies with known vulnerabilities
npm outdated

# Regular updates
npm update
```

## Troubleshooting

### Lock File Synchronization Issues (Project-Specific)

Lock file synchronization is the **most common cause of deployment failures** in this project. Below are detailed troubleshooting steps for lock file sync issues.

#### 🔴 Critical Issue: Pre-deployment Validation Failure

**Symptoms:**
- Deployment stops immediately with: `"Lock file validation failed"`
- Error message: `"package.json and package-lock.json are out of sync"`
- Error code 200 from deployment script
- Build fails before Docker build starts

**Root Causes:**
1. `package.json` was modified without running `npm install`
2. `package-lock.json` was manually edited
3. Merge conflicts in lock file were not resolved properly
4. Different npm versions used by team members

**Diagnosis:**
```bash
# Check if files are out of sync (same check deploy.sh uses)
npm ci --dry-run

# This will show exactly which dependencies are problematic
# Example error: "npm ERR! Invalid: lock file's express@1.0.0 does not satisfy ^2.0.0"
```

**Quick Fix (95% success rate):**
```bash
# Step 1: Update lock file to match package.json
npm install

# Step 2: Verify the fix
npm ci --dry-run

# Step 3: If verification passes, commit the fix
git add package.json package-lock.json
git commit -m "Fix lock file synchronization"

# Step 4: Retry deployment
./deploy.sh
```

#### 🔴 Critical Issue: Docker Build Fallback Triggered

**Symptoms:**
- Docker build succeeds but shows warning: `"DOCKER BUILD FALLBACK MECHANISM TRIGGERED"`
- Build logs contain: `"ERROR: npm ci failed due to lock file synchronization issues"`
- Build completes but with reproducibility warnings

**Root Cause:**
Lock files are out of sync, but not severely enough to completely break the build.

**Immediate Action Required:**
```bash
# Even though build "succeeded", the issue must be fixed
npm install
git add package.json package-lock.json
git commit -m "Fix lock file synchronization (fallback was triggered)"

# Rebuild to ensure clean build without fallback
docker build -t my-ag-ui-app:latest .
```

#### 🔴 Critical Issue: Complete Docker Build Failure

**Symptoms:**
- Docker build fails during "RUN npm ci --ignore-scripts" step
- Error: `"npm ERR! cipm can only install packages when your package.json and package-lock.json are in sync"`
- Deployment completely blocked

**Solutions (in order of preference):**

**Option 1: Fix Lock File (Recommended)**
```bash
# Fix the synchronization issue
npm install

# Verify with Docker build
docker build -t test .

# If successful, commit and deploy
git add package.json package-lock.json
git commit -m "Fix lock file synchronization for Docker build"
./deploy.sh
```

**Option 2: Complete Lock File Regeneration**
```bash
# Last resort if Option 1 fails
rm package-lock.json
npm install

# Test locally
npm ci --dry-run
docker build -t test .

# Commit and deploy if successful
git add package.json package-lock.json
git commit -m "Regenerate package-lock.json"
./deploy.sh
```

**Option 3: Emergency Bypass (Use with extreme caution)**
```bash
# ONLY for production emergencies when time is critical
./deploy.sh --skip-deps-check

# NOTE: This may still fail in Docker build step
# If it fails, you must use Option 1 or 2 anyway
```

#### Issue: Docker build fails with npm ci error

**Symptoms:**
- Docker build fails during "RUN npm ci" step
- Build logs show "npm ERR! cipm can only find packages" or similar
- Deployment stops at Docker build stage

**Root Causes:**
1. Lock file out of sync (most common)
2. Missing dependencies in lock file
3. Corrupted lock file
4. npm version mismatch between build and development environments

**Diagnosis:**
```bash
# Test locally with same conditions as Docker
npm ci

# Check lock file integrity
npm install --dry-run
```

**Solutions:**
```bash
# Fix lock file synchronization
npm install

# Verify with Docker build test
docker build -t test .

# If still failing, check Docker build logs for specific errors
docker build --progress=plain .
```

#### Issue: Docker build fallback mechanism triggers

**Symptoms:**
- Docker build succeeds but shows "DOCKER BUILD FALLBACK MECHANISM TRIGGERED"
- Build logs show warning about lock files being out of sync
- Build completes but with warnings about reproducibility

**Root Causes:**
1. Same as above, but fallback mechanism handled the failure
2. Lock files are out of sync but not severely enough to completely break `npm install`

**Diagnosis:**
```bash
# Check build logs for fallback message
docker build --progress=plain . 2>&1 | grep "FALLBACK"

# Verify lock file status
npm ci --dry-run
```

**Solutions:**
```bash
# Even though build succeeded, fix the root cause
npm install
git add package.json package-lock.json
git commit -m "Fix lock file synchronization"

# Rebuild to ensure no fallback is used
docker build -t my-ag-ui-app:latest .
```

#### Issue: Lock file conflicts during team development

**Symptoms:**
- Git merge conflicts in package-lock.json
- Team members report different dependency versions
- CI builds pass but local builds fail or vice versa

**Root Causes:**
1. Multiple team members updating dependencies simultaneously
2. Inconsistent npm versions across development environments
3. Improper merge conflict resolution
4. Not committing lock file with package.json changes

**Solutions:**
```bash
# For merge conflicts, always prefer the version that matches package.json
# After resolving conflicts, run:
npm install

# Ensure all team members use same npm version (or compatible)
npm --version

# Standardize on npm ci for installs after git pull
git pull
npm ci
```

#### Issue: Reproducible build failures across environments

**Symptoms:**
- Build works on one machine but fails on another
- CI build works but local build fails
- Different dependency versions installed

**Root Causes:**
1. Different npm versions
2. Different Node.js versions
3. Platform-specific dependencies
4. Lock file not committed to repository

**Solutions:**
```bash
# Ensure lock file is committed
git add package-lock.json
git commit -m "Add package-lock.json for reproducible builds"

# Use npm ci everywhere (not npm install) for consistency
npm ci

# Standardize Node.js and npm versions across team
# Use .nvmrc or similar for Node version management
```

### Advanced Lock File Debugging

#### Analyzing Lock File Structure

```bash
# View lock file structure
cat package-lock.json | jq '.dependencies' | less

# Check specific dependency
cat package-lock.json | jq '.dependencies.react'

# Compare package.json dependencies with lock file
node -e "
const pkg = require('./package.json');
const lock = require('./package-lock.json');
Object.keys(pkg.dependencies || {}).forEach(dep => {
  if (!lock.dependencies || !lock.dependencies[dep]) {
    console.log('Missing in lock file:', dep);
  } else {
    const pkgVer = pkg.dependencies[dep];
    const lockVer = lock.dependencies[dep].version;
    if (!lockVer.match(pkgVer.replace(/^[\^~]/, '').split(' ')[0])) {
      console.log('Version mismatch:', dep, 'pkg:', pkgVer, 'lock:', lockVer);
    }
  }
});
"
```

#### Identifying Corrupted Lock Files

```bash
# Validate JSON structure
cat package-lock.json | jq . > /dev/null

# Check for required top-level fields
cat package-lock.json | jq 'has("name") and has("version") and has("lockfileVersion")'

# Check lock file version compatibility
cat package-lock.json | jq '.lockfileVersion'
```

#### Recovery Procedures

**Complete Lock File Regeneration:**
```bash
# Last resort - complete regeneration
rm package-lock.json node_modules
npm install
npm ci --dry-run  # Verify
```

**Partial Lock File Fix:**
```bash
# When only specific dependencies are problematic
npm install <problematic-package>
npm ci --dry-run
```

### Prevention Strategies

#### Pre-commit Hooks

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/sh
# Prevent commit if package.json and package-lock.json are out of sync
if [ -f "package.json" ] && [ -f "package-lock.json" ]; then
  if ! npm ci --dry-run >/dev/null 2>&1; then
    echo "ERROR: package.json and package-lock.json are out of sync"
    echo "Run 'npm install' to fix before committing"
    exit 1
  fi
fi
```

#### CI/CD Pipeline Validation

Add to your CI pipeline:
```yaml
- name: Validate lock file synchronization
  run: npm ci --dry-run
  
- name: Fail if lock file validation fails
  if: failure()
  run: |
    echo "Lock file validation failed. Fix with: npm install"
    exit 1
```

### Common Issues and Solutions

#### Issue: "Cannot resolve dependency" errors

```bash
# Cause: Missing or incorrect dependency versions
npm install
# or
rm -rf node_modules package-lock.json
npm install
```

#### Issue: Deployment fails with dependency errors

```bash
# Cause: Lock file out of sync in deployment
npm install
git add package.json package-lock.json
git commit -m "Fix lock file synchronization"
./deploy.sh
```

#### Issue: Peer dependency conflicts

```bash
# Cause: Incompatible peer dependency versions
npm install --legacy-peer-deps  # Temporary fix
# Then update packages to resolve conflicts
```

### Debugging Commands

```bash
# Check dependency tree
npm ls

# Check for global packages that might interfere
npm list -g

# Clear npm cache
npm cache clean --force

# Check npm configuration
npm config list
```

## Common Scenarios

### Scenario 1: Adding a New Feature

1. Research and select required dependencies
2. Add dependencies: `npm add package-name`
3. Test functionality: `npm run dev`
4. Run build: `npm run build`
5. Commit changes: `git add package.json package-lock.json`
6. Deploy: `./deploy.sh`

### Scenario 2: Security Vulnerability

1. Run audit: `npm audit`
2. Review issues: `npm audit --json`
3. Fix automatically: `npm audit fix`
4. Test thoroughly: `npm test`
5. Commit updates: `git add package.json package-lock.json`
6. Deploy: `./deploy.sh`

### Scenario 3: Production Deployment (Project-Specific)

**For this project, follow this exact sequence:**

1. **Ensure clean working directory**
   ```bash
   git status
   # Should be clean or have only intended changes
   ```

2. **Run lock file validation** (same as deploy.sh pre-check)
   ```bash
   npm ci --dry-run
   # This MUST pass before proceeding
   ```

3. **Fix any sync issues immediately** (if validation fails)
   ```bash
   npm install
   git add package.json package-lock.json
   git commit -m "Fix lock file synchronization before deployment"
   ```

4. **Final validation check**
   ```bash
   npm ci --dry-run
   # Verify this passes
   ```

5. **Deploy**
   ```bash
   ./deploy.sh
   # This will run the same validation again
   ```

**⚠️ Important:** If step 2 fails, do NOT proceed to deployment. The deploy.sh will catch the same issue and fail, wasting time. Fix lock file synchronization first.

**Emergency deployment procedure:**
```bash
# ONLY use if production is down and you understand the risks
./deploy.sh --skip-deps-check

# Then immediately after successful deployment:
npm install
git add package.json package-lock.json
git commit -m "Emergency deployment: Fix lock file synchronization"
```

### Scenario 4: Team Development

1. Pull latest changes
2. Install dependencies: `npm ci`
3. Work on feature
4. Update dependencies if needed
5. Commit both files together
6. Push changes

## Additional Resources

- [npm Documentation](https://docs.npmjs.com/)
- [package.json Documentation](https://docs.npmjs.com/cli/v7/configuring-npm/package-json)
- [Semantic Versioning](https://semver.org/)
- [Node.js Security Best Practices](https://nodejs.org/en/guides/security/)

---

**Remember**: Consistent dependency management practices prevent deployment failures, security vulnerabilities, and team collaboration issues. When in doubt, test locally with `npm ci --dry-run` before deploying.