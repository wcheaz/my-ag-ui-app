## Context

The project root directory currently contains 70+ development and testing files scattered across the root level, making navigation and maintenance difficult. These files include test files (test*.py), debug files (debug*.py), check files (check*.py), measure files (measure*.py), performance files (performance*.py, env_performance*.py), verify files (verify*.py), and validate files (validate*.py).

While the project documentation references a "tests" directory convention, that directory exists but is empty. The current structure lacks a clear, consistent convention for organizing development files.

**Current State:**
- 70+ development files in project root
- Empty `tests/` directory exists
- No clear convention for development file placement
- Difficult to navigate and maintain

**Constraints:**
- Must maintain functionality of all development files after relocation
- Must preserve import statements and relative path references
- Should minimize disruption to existing workflows
- Should be reversible if needed

## Goals / Non-Goals

**Goals:**
- Move all 70+ development and testing files from project root to `test/` directory
- Establish clear convention that all development files reside in `test/` directory
- Update project documentation to reflect the correct convention
- Ensure all files continue to function correctly after relocation
- Create a cleaner, more maintainable project structure

**Non-Goals:**
- Modifying the content or functionality of any development files
- Changing the naming conventions of existing files
- Reorganizing files within subdirectories of `test/` (all files go directly in `test/`)
- Modifying test runners or CI/CD pipelines (unless they reference moved files)
- Moving files from the `agent/` subdirectory (only root-level files)

## Decisions

### 1. Directory Name: `test/` instead of `tests/`

**Decision:** Use `test/` directory (singular) instead of `tests/` (plural).

**Rationale:**
- The user explicitly requested `test/` directory
- Consistency with the proposal and specs
- Avoids confusion with existing empty `tests/` directory

**Alternatives Considered:**
- `tests/`: Rejected - user specified `test/`, and existing `tests/` is empty
- `dev/`: Rejected - doesn't clearly indicate testing files
- `tests-and-dev/`: Rejected - too verbose

### 2. Flat Structure in `test/` Directory

**Decision:** Place all moved files directly in `test/` without subdirectories.

**Rationale:**
- Simpler structure, easier to navigate
- No clear categorization scheme for the different file types (test, debug, check, etc.)
- Maintains existing file organization within the new directory
- Easier to implement and maintain

**Alternatives Considered:**
- Subdirectories by type (e.g., `test/tests/`, `test/debug/`, etc.): Rejected - adds complexity without clear benefit
- Subdirectories by functionality: Rejected - would require categorizing each file, which is subjective and time-consuming

### 3. File Selection Pattern

**Decision:** Use glob patterns to identify files to move: `test*.py`, `debug*.py`, `check*.py`, `measure*.py`, `performance*.py`, `verify*.py`, `validate*.py`.

**Rationale:**
- Clear, predictable pattern matching
- Captures all relevant file types identified in the proposal
- Easy to verify and audit
- Can be executed with standard shell commands

**Alternatives Considered:**
- Manual file listing: Rejected - error-prone and not scalable
- All `*.py` files in root: Rejected - would move application code (e.g., `agent.py` if it existed in root)
- Heuristic-based selection: Rejected - too complex and unpredictable

### 4. Import Path Handling

**Decision:** Rely on Python's import resolution from `test/` directory without modifying file contents.

**Rationale:**
- Python's import system handles relative imports correctly when run from appropriate directory
- Most development files likely use absolute imports or are run with proper PYTHONPATH
- Minimizes risk of introducing bugs through file modifications
- If issues arise, they can be addressed individually

**Alternatives Considered:**
- Modify all import statements: Rejected - high risk, time-consuming, may introduce bugs
- Add `test/` to PYTHONPATH globally: Rejected - affects entire system, not just this project
- Create symlinks in root: Rejected - defeats the purpose of organization

### 5. Documentation Update Strategy

**Decision:** Update the `Testing Strategy` section in `openspec/project.md` to reference `test/` directory instead of `tests/`.

**Rationale:**
- Directly addresses the existing incorrect reference
- Establishes the convention for future development
- Minimal change required
- Aligns with the proposal and specs

**Alternatives Considered:**
- Add new section for development files: Rejected - `Testing Strategy` section already exists and is appropriate
- Update multiple documentation files: Rejected - no other files reference the test directory convention

## Risks / Trade-offs

### Risk 1: Import Errors After Relocation

**Risk:** Some development files may have import statements that assume they're in the project root, causing import errors after moving to `test/`.

**Mitigation:**
- Test a sample of files after relocation to identify common import patterns
- If issues are found, add `test/` to PYTHONPATH in relevant scripts or update problematic imports
- Document any necessary import adjustments in the tasks

### Risk 2: Broken Script References

**Risk:** Scripts or workflows that reference development files by relative path may break after relocation.

**Mitigation:**
- Search for references to moved files in scripts, Makefiles, and CI/CD configurations
- Update any found references to use the new path
- Document the need to update external references in the tasks

### Risk 3: Empty `tests/` Directory Confusion

**Risk:** The existing empty `tests/` directory may cause confusion about which directory to use for tests.

**Mitigation:**
- Remove the empty `tests/` directory after moving files to `test/`
- Update documentation to clearly specify `test/` directory
- Add a note in the tasks about removing the empty directory

### Risk 4: Git History Fragmentation

**Risk:** Moving files may fragment Git history, making it harder to track file changes across the move.

**Mitigation:**
- Use `git mv` instead of `mv` to preserve file history
- This is a standard Git operation and history will be preserved

### Trade-off: Simplicity vs. Perfect Organization

**Trade-off:** Using a flat structure in `test/` is simpler but doesn't categorize files by type.

**Rationale:** The benefit of perfect categorization doesn't justify the complexity. A flat structure is easier to navigate and maintain, and file names already indicate their type (e.g., `test_`, `debug_`, etc.).

## Migration Plan

### Phase 1: Preparation
1. Verify the list of files to be moved using glob patterns
2. Check for any hard references to these files in scripts or configuration
3. Ensure `test/` directory exists or create it

### Phase 2: File Relocation
1. Use `git mv` to move all files matching the patterns to `test/` directory
2. Verify all files were moved successfully
3. Remove the empty `tests/` directory if it exists

### Phase 3: Documentation Update
1. Update `openspec/project.md` to reference `test/` directory
2. Verify the documentation is clear and accurate

### Phase 4: Validation
1. Run a sample of development files to verify they work correctly
2. Check for any import errors or path issues
3. Address any issues found during validation

### Rollback Strategy
If issues arise that cannot be easily resolved:
1. Use `git mv` to move files back to project root
2. Revert the documentation changes
3. This is a low-risk change that can be easily undone

## Open Questions

None at this time. The design is straightforward and all decisions have been made.
