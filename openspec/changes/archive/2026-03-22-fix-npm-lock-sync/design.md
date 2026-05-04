## Context

The current Docker build process fails when `package.json` and `package-lock.json` are out of sync. The error occurs during the `npm ci` step in the Dockerfile, which requires exact synchronization between these files. This creates a critical deployment bottleneck where developers must manually synchronize lock files before any Docker build can succeed.

**Current State:**
- Dockerfile uses `npm ci --ignore-scripts` for dependency installation
- No pre-build validation of lock file consistency
- No fallback mechanism when `npm ci` fails
- Error messages are cryptic and don't provide clear remediation steps
- The deploy.sh script doesn't validate dependencies before initiating Docker builds

**Constraints:**
- Must maintain reproducible builds (prefer `npm ci` over `npm install`)
- Minimal changes to existing Docker build workflow
- Must work with current multipass VM and Kubernetes deployment setup
- Should not break existing CI/CD pipelines
- Must provide clear error messages and remediation guidance

**Stakeholders:**
- Developers who need to update dependencies
- DevOps team managing deployments
- CI/CD pipeline maintainers

## Goals / Non-Goals

**Goals:**
- Detect lock file synchronization issues before Docker builds
- Provide clear error messages with remediation steps
- Implement a fallback mechanism when `npm ci` fails
- Document best practices for maintaining lock file consistency
- Ensure deployment process is more resilient to dependency sync issues

**Non-Goals:**
- Changing the fundamental Docker build architecture
- Modifying Kubernetes deployment configurations
- Implementing a full dependency management system
- Changing the multipass VM setup
- Modifying application code or dependencies

## Decisions

### Decision 1: Pre-build validation in deploy.sh
**Choice:** Add a validation step in deploy.sh before Docker build that checks if package.json and package-lock.json are synchronized.

**Rationale:**
- Fails fast before expensive Docker build operations
- Provides immediate feedback to developers
- Easier to maintain than Dockerfile changes
- Can provide more detailed error messages and remediation steps
- Doesn't require modifying the Docker build process itself

**Alternatives considered:**
- **Dockerfile validation:** Would catch issues during build but wastes build time
- **CI/CD gate:** Would catch issues but doesn't help local development
- **Git pre-commit hook:** Would prevent committing out-of-sync files but doesn't help existing issues

### Decision 2: Fallback mechanism in Dockerfile
**Choice:** Modify Dockerfile to use `npm install` as a fallback when `npm ci` fails due to lock file sync issues.

**Rationale:**
- Maintains reproducible builds when lock files are in sync (preferred path)
- Provides graceful degradation when sync issues occur
- Allows deployments to proceed even with minor sync discrepancies
- Logs when fallback is triggered for monitoring and debugging

**Alternatives considered:**
- **Always use npm install:** Loses reproducibility benefits of npm ci
- **Fail hard on sync issues:** Too strict, blocks deployments unnecessarily
- **Separate Dockerfile for development:** Adds complexity and maintenance burden

### Decision 3: Validation approach
**Choice:** Use `npm ci --dry-run` to validate lock file consistency.

**Rationale:**
- Uses npm's built-in validation logic
- Fast and reliable
- Provides detailed error messages about which dependencies are out of sync
- No external dependencies required

**Alternatives considered:**
- **Custom JSON comparison:** Would need to handle npm's resolution logic
- **npm outdated:** Doesn't check lock file sync, only version availability
- **npm audit:** Checks for security issues, not sync consistency

### Decision 4: Documentation location
**Choice:** Add lock file maintenance guidance to existing SETUP.md and create a separate DEPENDENCIES.md file.

**Rationale:**
- SETUP.md already covers environment setup, so it's a natural fit
- Separate DEPENDENCIES.md allows for more detailed dependency management documentation
- Keeps documentation organized and discoverable
- Can be referenced from multiple places (README, deploy.sh output)

**Alternatives considered:**
- **Only in README:** README is already long, might get lost
- **Only in deploy.sh comments:** Not discoverable enough
- **Inline in Dockerfile:** Hard to read and maintain

## Risks / Trade-offs

### Risk 1: Fallback mechanism masks underlying issues
**Risk:** Using `npm install` as a fallback might allow deployments with inconsistent lock files, potentially leading to different dependency versions across environments.

**Mitigation:**
- Log prominently when fallback is triggered
- Include warnings in deployment logs about lock file inconsistencies
- Provide clear instructions to fix the root cause
- Monitor fallback usage in production to identify systemic issues

### Risk 2: Pre-build validation adds deployment time
**Risk:** Additional validation step adds ~2-5 seconds to deployment time.

**Mitigation:**
- Validation is fast compared to Docker build (minutes)
- Fails fast, saving time when issues are present
- Can be skipped with a flag if needed (e.g., `--skip-deps-check`)

### Risk 3: npm ci --dry-run might have false positives
**Risk:** Some edge cases where `npm ci --dry-run` reports issues that wouldn't actually fail the build.

**Mitigation:**
- Test validation against various dependency scenarios
- Allow bypass with explicit flag if needed
- Monitor validation accuracy and adjust as needed

### Risk 4: Documentation drift
**Risk:** Documentation might become outdated as npm or project practices evolve.

**Mitigation:**
- Include documentation in code review checklist
- Add automated checks where possible
- Review documentation quarterly or after major npm version changes

### Trade-off: Reproducibility vs. Resilience
**Trade-off:** We're trading some build reproducibility (by allowing fallback) for deployment resilience.

**Balance:** The fallback is a safety net, not the primary path. We maintain reproducibility as the default and only fall back when necessary, with clear logging to encourage fixing the root cause.

## Migration Plan

### Deployment Steps

1. **Update Dockerfile**
   - Add fallback logic for npm ci failures
   - Add logging for fallback activation
   - Test with both in-sync and out-of-sync lock files

2. **Update deploy.sh**
   - Add pre-build validation function
   - Call validation before Docker build
   - Add error handling and remediation messages
   - Add `--skip-deps-check` flag for emergency bypass

3. **Create documentation**
   - Add lock file maintenance section to SETUP.md
   - Create DEPENDENCIES.md with detailed guidance
   - Add troubleshooting section for common sync issues

4. **Test deployment**
   - Deploy with in-sync lock files (verify normal path)
   - Deploy with out-of-sync lock files (verify fallback path)
   - Verify error messages are clear and actionable
   - Test with `--skip-deps-check` flag

### Rollback Strategy

1. **Revert Dockerfile** to original `npm ci` only version
2. **Revert deploy.sh** to remove validation step
3. **Remove documentation** changes (or keep as helpful reference)
4. **No data migration** needed (no data changes)

**Rollback triggers:**
- Fallback mechanism causes production issues
- Validation step blocks valid deployments
- Performance impact is unacceptable
- Security vulnerabilities discovered in fallback path

## Open Questions

1. **Should we enforce lock file consistency in CI/CD?**
   - Currently unclear if this should be a hard gate or just a warning
   - Need to understand team's tolerance for deployment delays

2. **What's the acceptable threshold for fallback usage?**
   - How often can fallback be triggered before we need to investigate?
   - Should we alert if fallback is used more than X times per week?

3. **Should we add a git pre-commit hook?**
   - Would prevent committing out-of-sync files
   - Might be too restrictive for some workflows
   - Need team input on this

4. **How should we handle transitive dependency updates?**
   - When npm updates transitive dependencies, lock file changes
   - Need clear guidance on when to commit these changes
   - May need to document expected behavior

5. **Should we add automated lock file updates to CI/CD?**
   - Could run `npm install` periodically to keep lock file fresh
   - Might create unexpected changes in production
   - Need to weigh benefits vs. risks