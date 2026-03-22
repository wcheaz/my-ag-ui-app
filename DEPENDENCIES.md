# Dependency Management Guide

This document provides comprehensive guidance for managing dependencies in the my-ag-ui-app project. Proper dependency management is crucial for application stability, security, and deployment reliability.

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

The deployment script automatically validates lock file consistency:

```bash
# Before building Docker images, the script runs:
npm ci --dry-run

# If validation fails, it shows clear recovery instructions
```

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

### Lock File Synchronization Issues

Lock file synchronization is one of the most common causes of deployment failures in this project. Below are detailed troubleshooting steps for lock file sync issues.

#### Issue: "npm ci --dry-run" fails during pre-deployment validation

**Symptoms:**
- Deployment script stops with "package.json and package-lock.json are out of sync"
- Error code 200 from deployment script
- Build fails before Docker build starts

**Root Causes:**
1. `package.json` was modified without running `npm install`
2. `package-lock.json` was manually edited
3. Merge conflicts in lock file were not resolved properly
4. Different npm versions used by team members

**Diagnosis:**
```bash
# Check if files are out of sync
npm ci --dry-run

# If this fails, files are definitely out of sync
# The error will show which dependencies are problematic
```

**Solutions:**
```bash
# Primary fix: Update lock file to match package.json
npm install

# Verify the fix
npm ci --dry-run

# If issues persist, regenerate lock file completely
rm package-lock.json
npm install

# Test deployment validation
./deploy.sh
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

### Scenario 3: Production Deployment

1. Ensure clean working directory
2. Run validation: `npm ci --dry-run`
3. Fix any sync issues: `npm install`
4. Deploy: `./deploy.sh`

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