# Rollback Plan: npm Lock File Synchronization Fix

## Overview

This document outlines the rollback procedure for the npm lock file synchronization fixes implemented to address Docker build failures when `package.json` and `package-lock.json` are out of sync.

## Changes Implemented

1. **Dockerfile Updates**: Added fallback logic to use `npm install` when `npm ci` fails due to lock file sync issues
2. **deploy.sh Validation**: Added pre-build validation using `npm ci --dry-run` to detect lock file sync issues
3. **Documentation**: Created dependency management guidelines and troubleshooting documentation
4. **Emergency Bypass**: Added `--skip-deps-check` flag for emergency deployment scenarios

## Rollback Triggers

Consider rollback if any of the following conditions occur:

- **Production Issues**: Fallback mechanism causes unexpected behavior in production environments
- **Build Failures**: Validation step incorrectly blocks valid deployments
- **Performance Impact**: Additional validation step causes unacceptable deployment delays
- **Security Concerns**: Security vulnerabilities discovered in the fallback path
- **Team Workflow Disruption**: Changes significantly disrupt existing development workflows

## Rollback Procedures

### Immediate Rollback (Emergency)

1. **Revert Dockerfile**
   ```bash
   # Replace with backup from /home/ncheaz/git/my-ag-ui-app/Dockerfile.backup
   cp /home/ncheaz/git/my-ag-ui-app/Dockerfile.backup /home/ncheaz/git/my-ag-ui-app/Dockerfile
   ```

2. **Revert deploy.sh**
   ```bash
   # Replace with backup from /home/ncheaz/git/my-ag-ui-app/deploy.sh.backup
   cp /home/ncheaz/git/my-ag-ui-app/deploy.sh.backup /home/ncheaz/git/my-ag-ui-app/deploy.sh
   chmod +x /home/ncheaz/git/my-ag-ui-app/deploy.sh
   ```

3. **Verify Functionality**
   ```bash
   # Test deployment with original files
   ./deploy.sh
   ```

### Gradual Rollback (Controlled)

1. **Disable Validation First**
   ```bash
   # Temporarily disable validation while keeping fallback mechanism
   ./deploy.sh --skip-deps-check
   ```

2. **Monitor Results**
   - Check if deployments succeed without validation
   - Verify fallback mechanism still works if needed
   - Document any issues encountered

3. **Remove Fallback Mechanism**
   ```bash
   # Edit Dockerfile to remove npm install fallback
   # Keep only: RUN npm ci --ignore-scripts
   ```

4. **Final Verification**
   - Test deployment with original npm ci only approach
   - Ensure all builds are reproducible and consistent

## Rollback Validation

After performing rollback, verify the following:

1. **Docker Build Success**: Builds complete successfully with `npm ci` only
2. **Deployment Success**: Applications deploy and function correctly
3. **Performance**: Deployment times return to pre-fix levels
4. **No Errors**: No npm lock file sync errors in build logs

## Contingency Plans

### Partial Rollback

If only specific components cause issues:

1. **Keep Validation, Remove Fallback**
   - Maintain pre-build validation in deploy.sh
   - Revert Dockerfile to use `npm ci` only
   - Let validation prevent builds with out-of-sync lock files

2. **Keep Fallback, Disable Validation**
   - Remove pre-build validation from deploy.sh
   - Keep Dockerfile fallback mechanism
   - Allow deployments to use fallback when needed

### Alternative Solutions

If rollback is necessary but original approach is problematic:

1. **Manual Lock File Management**
   - Require manual verification of lock files before commits
   - Add to code review checklist
   - Use git pre-commit hooks to prevent out-of-sync commits

2. **Automated Lock File Updates**
   - Implement CI/CD pipeline step to update lock files
   - Run `npm install` and commit changes automatically
   - Requires careful testing to prevent unwanted updates

## Communication Plan

### Before Rollback

1. **Notify Stakeholders**
   - Development team
   - DevOps team
   - Product stakeholders
   - QA team

2. **Schedule Maintenance Window**
   - Coordinate with all teams
   - Choose low-traffic period
   - Allow buffer for testing

### After Rollback

1. **Confirm Success**
   - Send confirmation email
   - Update monitoring systems
   - Document lessons learned

2. **Update Documentation**
   - Mark features as deprecated
   - Update deployment guides
   - Remove or archive rollback documentation

## Monitoring During Rollback

Watch for these indicators during and after rollback:

1. **Build Success Rate**: Should return to pre-fix baseline
2. **Deployment Time**: Should decrease as validation is removed
3. **Error Rates**: Should not increase beyond normal levels
4. **Team Feedback**: Collect feedback on deployment experience

## Post-Rollback Actions

1. **Root Cause Analysis**
   - Investigate why fixes needed rollback
   - Document lessons learned
   - Identify process improvements

2. **Long-term Solution Planning**
   - Consider alternative approaches
   - Evaluate new tools or processes
   - Plan for future improvements

## Contacts

- **Primary Contact**: DevOps team lead
- **Technical Contact**: Infrastructure engineer
- **Communication Contact**: Project manager
- **Emergency Contact**: On-call engineer

---

**Note**: This rollback plan should be tested in a staging environment before executing in production. Always have backups of all files before making changes.