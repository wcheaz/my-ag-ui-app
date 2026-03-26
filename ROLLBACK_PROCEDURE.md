# Rollback Procedure for Deployment Scripts

This document provides the rollback procedure for restoring the original monolithic `deploy.sh` script if issues arise with the new modular deployment system.

## When to Consider Rollback

Consider rolling back to the original `deploy.sh` in these scenarios:

1. **Critical Deployment Failures**: When the modular scripts consistently fail and you need a working deployment solution
2. **CI/CD Pipeline Breakage**: When existing workflows cannot be easily updated to use the new modular system
3. **Development Workflow Disruption**: When the new system significantly impacts team productivity
4. **Debugging Complexities**: When isolating issues across multiple scripts becomes more difficult than using the monolithic approach

## Quick Rollback Procedure

### Step 1: Backup Current State (Optional but Recommended)

```bash
# Create a backup of the current modular system
cp -r deploy_scripts deploy_scripts_backup_$(date +%Y%m%d_%H%M%S)
cp deploy-all.sh deploy-all.sh_backup_$(date +%Y%m%d_%H%M%S)
```

### Step 2: Restore Original deploy.sh

```bash
# Copy the archived original deploy.sh to project root
cp archive/deploy.sh.original deploy.sh

# Make it executable
chmod +x deploy.sh
```

### Step 3: Remove Modular System (Optional)

```bash
# Remove the orchestrator script
rm deploy-all.sh

# Remove the modular scripts directory (only if you're sure they won't be needed)
rm -rf deploy_scripts
```

### Step 4: Test Restored System

```bash
# Test the restored monolithic deployment script
./deploy.sh
```

## Detailed Rollback with Preservation

If you want to rollback but preserve the modular system for future use:

### Step 1: Archive Modular System

```bash
# Create a comprehensive archive of the modular system
tar -czf deployment_modular_system_backup_$(date +%Y%m%d_%H%M%S).tar.gz \
    deploy_all.sh \
    deploy_scripts/ \
    README.md
```

### Step 2: Restore Original deploy.sh

```bash
# Copy the archived original to project root
cp archive/deploy.sh.original deploy.sh
chmod +x deploy.sh
```

### Step 3: Update Documentation

```bash
# Create a rollback note in your project documentation
cat >> ROLLBACK_NOTE.md << EOF
# Deployment System Rollback Notice

Date: $(date)
Reason: [Add reason for rollback here]

The deployment system was rolled back from modular scripts to the original monolithic deploy.sh.

The modular system has been archived as: deployment_modular_system_backup_$(date +%Y%m%d_%H%M%S).tar.gz

To restore the modular system in the future:
1. Extract the backup archive
2. Copy deploy-all.sh to project root
3. Copy deploy_scripts/ directory to project root
4. Update README.md and workflows
EOF
```

## Reverting the Rollback

After fixing the issues that caused the rollback, you can restore the modular system:

### Step 1: Restore Modular Scripts

```bash
# Extract the backup (if you created one)
tar -xzf deployment_modular_system_backup_YYYYMMDD_HHMMSS.tar.gz

# Or recreate from scratch if needed
```

### Step 2: Restore Orchestrator

```bash
# Ensure deploy-all.sh is in project root and executable
chmod +x deploy-all.sh
```

### Step 3: Archive Original Again

```bash
# Move the current deploy.sh to archive
mkdir -p archive
mv deploy.sh archive/deploy.sh.rollback_$(date +%Y%m%d_%H%M%S)
cp archive/deploy.sh.original archive/deploy.sh  # Ensure original is preserved
```

### Step 4: Update Workflows and Documentation

```bash
# Update any CI/CD pipelines, scripts, or documentation that reference deploy.sh
# to use deploy-all.sh instead
```

## Emergency Rollback (Quick Fix)

For emergency situations when you need immediate deployment capability:

```bash
# Emergency restore - directly from archive
cp archive/deploy.sh.original deploy.sh && chmod +x deploy.sh

# Run deployment
./deploy.sh
```

## Troubleshooting Rollback Issues

### Issue: deploy.sh.original Missing

If the original script is not in the archive directory:

1. **Check if it was moved elsewhere**:
   ```bash
   find . -name "deploy.sh.original" -type f
   ```

2. **Check git history**:
   ```bash
   git log --oneline --follow deploy.sh
   git show <commit-hash>:deploy.sh > deploy.sh.restored
   ```

3. **Recreate from documentation** (last resort):
   - Use the deployment documentation in README.md
   - Reconstruct the script based on the modular scripts

### Issue: Permissions Problems

After rollback, ensure proper permissions:

```bash
chmod +x deploy.sh
ls -la deploy.sh  # Should show -rwxr-xr-x
```

### Issue: Environment Variables

The original `deploy.sh` might expect different environment variables. Check:

```bash
# Compare environment variable requirements
grep -n "export\|\$" deploy.sh | head -20
```

## Best Practices for Rollback

1. **Document Everything**: Keep a record of why the rollback was performed and what issues were encountered

2. **Test Before Full Rollback**: Test the restored deploy.sh in a staging environment if possible

3. **Communicate Changes**: Inform all team members about the rollback and any workflow changes

4. **Plan for Re-migration**: Use the rollback period to fix the issues with the modular system

5. **Preserve Debug Information**: Keep logs and error reports from the modular system failures

## Prevention: Avoiding Future Rollbacks

To minimize the need for future rollbacks:

1. **Gradual Migration**: Consider running both systems in parallel during transition

2. **Feature Flags**: Implement feature flags in the deployment system to enable/disable modular components

3. **Extensive Testing**: Test the modular system thoroughly in non-production environments

4. **Monitoring**: Add monitoring and health checks to detect issues early

5. **Documentation**: Keep detailed documentation of all deployment system changes

## Support

If you encounter issues during rollback or need assistance:

1. **Review git history**: Check previous commits for deployment script changes
2. **Consult team**: Discuss with team members who worked on the modular system
3. **Create issue**: Open a GitHub issue detailing the rollback problems

---

**Note**: This rollback procedure is designed to be safe and reversible. Always test in a non-production environment when possible.