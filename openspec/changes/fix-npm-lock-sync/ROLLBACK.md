# Rollback Plan

## Purpose

This document provides a comprehensive rollback plan for the npm lock file synchronization fixes. The rollback process allows reverting all changes related to dependency validation, fallback mechanisms, and documentation updates if issues arise in production or if the new functionality causes unexpected problems.

## Rollback Triggers

Rollback should be initiated in the following scenarios:

### Critical Triggers (Immediate Action Required)
1. **Deployment failures** - The new validation or fallback mechanism causes deployment failures that cannot be resolved quickly
2. **Production issues** - Applications deployed with the fallback mechanism experience runtime errors or dependency conflicts
3. **Security vulnerabilities** - Security issues discovered in the fallback path (npm install) that weren't present in the original npm ci-only approach

### Performance Triggers
4. **Unacceptable performance impact** - The pre-build validation step adds significant delay to deployments beyond acceptable thresholds
5. **Fallback overuse** - The fallback mechanism is triggered frequently, indicating systemic lock file management issues that need to be addressed separately

### Process Triggers
6. **Validation false positives** - The validation step incorrectly flags valid lock files as out of sync
7. **Team workflow disruption** - The new processes significantly hinder development workflow without providing adequate benefit

## Rollback Procedures

### Phase 1: Immediate Actions (First 30 minutes)

#### 1.1 Assess Current State
```bash
# Check current deployment status
./deploy.sh status

# Review recent deployment logs
tail -50 deploy.log

# Check if fallback mechanism was recently used
grep -i "fallback" deploy.log | tail -10
```

#### 1.2 Make Decision
- Consult with stakeholders (DevOps, Development leads)
- Document the reason for rollback
- Create rollback ticket in issue tracking system

### Phase 2: System Revert

#### 2.1 Restore Backup Files
```bash
# Navigate to project root
cd /home/ncheaz/git/my-ag-ui-app

# Restore original Dockerfile from backup
cp openspec/changes/fix-npm-lock-sync/backups/Dockerfile.backup Dockerfile

# Restore original deploy.sh from backup
cp openspec/changes/fix-npm-lock-sync/backups/deploy.sh.backup deploy.sh
chmod +x deploy.sh
```

#### 2.2 Manual Revert (If backups not available)

**Revert Dockerfile:**
```bash
# Edit Dockerfile and remove fallback logic
# Replace the fallback npm install section with:
# RUN npm ci --ignore-scripts
```

**Revert deploy.sh:**
```bash
# Edit deploy.sh and remove the following:
# - validate_lock_files function
# - Call to validate_lock_files before docker build
# - --skip-deps-check flag parsing and handling
```

#### 2.3 Verify Revert
```bash
# Test that validation step is removed
./deploy.sh --help 2>&1 | grep -q "skip-deps-check" || echo "Validation step removed"

# Check Dockerfile for npm ci only
grep -c "npm ci" Dockerfile  # Should be 1
grep -c "npm install" Dockerfile  # Should be 0 (or only in dev dependencies)
```

### Phase 3: Testing

#### 3.1 Test Basic Functionality
```bash
# Test deployment with in-sync lock files
./deploy.sh build

# Verify build uses npm ci only
docker build . 2>&1 | grep -q "npm ci" && echo "Using npm ci only"
```

#### 3.2 Test Deployment Process
```bash
# Full deployment test in staging environment
./deploy.sh staging

# Verify application starts correctly
kubectl get pods -n staging
kubectl logs deployment/my-ag-ui-app -n staging
```

#### 3.3 Validation of Rollback
```bash
# Confirm no validation step exists
./deploy.sh build 2>&1 | grep -q "validate" || echo "No validation step found"

# Confirm no fallback mechanism
docker build . 2>&1 | grep -q "fallback" || echo "No fallback mechanism found"
```

### Phase 4: Documentation Update

#### 4.1 Remove New Documentation
```bash
# Remove DEPENDENCIES.md if it was created
rm -f DEPENDENCIES.md

# Revert SETUP.md changes if they exist
git checkout HEAD -- SETUP.md 2>/dev/null || echo "SETUP.md not modified or not in git"
```

#### 4.2 Update Documentation
```markdown
# Add to CHANGELOG.md
## [Rollback] YYYY-MM-DD

- Rolled back npm lock file synchronization fixes
- Reverted Dockerfile to original npm ci-only approach
- Removed pre-build validation from deploy.sh
- Removed fallback mechanism for lock file sync issues
- Reason: [Enter specific reason for rollback]
```

#### 4.3 Update Team Documentation
- Update development guides to reflect original process
- Remove any references to new validation steps
- Communicate rollback to development team

### Phase 5: Communication

#### 5.1 Internal Communication
```markdown
# Email/Slack Template
Subject: Rollback Completed: npm Lock File Synchronization Fixes

Team,

We have completed the rollback of the npm lock file synchronization fixes due to:
[Reason for rollback]

Changes reverted:
- Dockerfile: Restored to npm ci-only approach
- deploy.sh: Removed pre-build validation step
- Documentation: Reverted to original guides

Impact:
- Builds will no longer have lock file validation
- npm ci failures will cause build failures (no fallback)
- Original deployment process restored

Next steps:
- Investigation into root cause of issues
- Potential alternative solutions to be evaluated

Contact: [Your name/team] for questions
```

#### 5.2 External Communication (If needed)
```markdown
# For production incidents
Title: Deployment Process Update - npm Lock File Handling

The deployment process has been updated to address [issue description]. 
All systems are operational with the previous deployment configuration.

No action required from end users.
```

## Rollback Verification Checklist

### Pre-Rollback
- [ ] Reason for rollback documented
- [ ] Stakeholders notified of planned rollback
- [ ] Backup files verified to exist
- [ ] Maintenance window scheduled (if production)

### During Rollback
- [ ] Original Dockerfile restored
- [ ] Original deploy.sh restored
- [ ] File permissions set correctly
- [ ] Documentation reverted

### Post-Rollback
- [ ] Build process tested with in-sync lock files
- [ ] Build process tested with out-of-sync lock files (should fail gracefully)
- [ ] Deployment to staging successful
- [ ] Application functionality verified
- [ ] Monitoring systems confirmed operational
- [ ] Team communication sent
- [ ] Documentation updated

## Risk Assessment

### Low Risk
- **Documentation-only changes**: Reverting documentation updates has minimal impact
- **Local development**: Changes primarily affect deployment, not local development
- **Data integrity**: No data changes are part of this feature

### Medium Risk
- **Build process**: Changes to build process could affect deployment reliability
- **Team workflow**: Reverting may temporarily disrupt team if they adapted to new process

### High Risk
- **Production deployments**: If rollback is performed during production deployment window
- **Dependency management**: Reverting might expose underlying lock file management issues

## Contingencies

### If Backup Files Are Missing
1. Check git history for original versions:
   ```bash
   git log --oneline -n 10
   git show HEAD~1:Dockerfile > Dockerfile.backup
   git show HEAD~1:deploy.sh > deploy.sh.backup
   ```

2. Reconstruct from memory:
   - Dockerfile should contain single `RUN npm ci --ignore-scripts` command
   - deploy.sh should have no `validate_lock_files` function

### If Rollback Causes Issues
1. **Immediate revert**: Re-apply the changes temporarily
2. **Staged rollback**: Roll back components individually
   - Start with deploy.sh validation (least impact)
   - Then Dockerfile fallback (moderate impact)
   - Finally documentation (lowest impact)

3. **Parallel testing**: Test rollback in non-production environment first

## Timeline Estimates

| Task | Estimated Time | Actual Time | Status |
|------|---------------|-------------|---------|
| Assessment | 15-30 minutes | | |
| System Revert | 30-60 minutes | | |
| Testing | 60-120 minutes | | |
| Documentation | 15-30 minutes | | |
| Communication | 15-30 minutes | | |
| **Total** | **2.5-4 hours** | | |

## Post-Rollback Activities

1. **Root Cause Analysis**: Investigate why the rollback was necessary
2. **Lessons Learned**: Document what worked and what didn't
3. **Alternative Solutions**: Evaluate different approaches to the original problem
4. **Monitoring**: Increased monitoring of deployment success rates
5. **Follow-up**: Schedule review to determine if feature can be re-implemented with fixes

## Contacts

- **Primary Rollback Lead**: [Name]
- **DevOps Contact**: [Name]
- **Development Lead**: [Name]
- **Stakeholders**: [List of stakeholders]

---

*Document Version: 1.0*
*Last Updated: 2026-03-22*