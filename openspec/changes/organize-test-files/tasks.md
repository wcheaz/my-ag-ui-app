## 1. Preparation

- [x] 1.1 Verify the list of files to be moved by running glob patterns: `ls test*.py`, `ls debug*.py`, `ls check*.py`, `ls measure*.py`, `ls performance*.py`, `ls verify*.py`, `ls validate*.py`
- [x] 1.2 Search for references to development files in scripts, Makefiles, and CI/CD configurations using `grep -r "test_.*\.py\|debug_.*\.py\|check_.*\.py\|measure_.*\.py\|performance_.*\.py\|verify_.*\.py\|validate_.*\.py" --include="*.sh" --include="*.yml" --include="*.yaml" --include="Makefile" --include="*.json"`
- [x] 1.3 Create the `test/` directory if it doesn't exist: `mkdir -p test/`
- [x] 1.4 Verify the `test/` directory is empty or ready to receive files: `ls test/`

## 2. File Relocation

- [x] 2.1 Move all test*.py files to test/ directory using git mv: `git mv test*.py test/`
- [x] 2.2 Move all debug*.py files to test/ directory using git mv: `git mv debug*.py test/`
- [x] 2.3 Move all check*.py files to test/ directory using git mv: `git mv check*.py test/`
- [x] 2.4 Move all measure*.py files to test/ directory using git mv: `git mv measure*.py test/`
- [ ] 2.5 Move all performance*.py files to test/ directory using git mv: `git mv performance*.py test/` and `git mv env_performance*.py test/`
- [ ] 2.6 Move all verify*.py files to test/ directory using git mv: `git mv verify*.py test/`
- [ ] 2.7 Move all validate*.py files to test/ directory using git mv: `git mv validate*.py test/`
- [ ] 2.8 Verify all files were moved successfully by checking the test/ directory: `ls test/ | wc -l` (should show 70+ files)
- [ ] 2.9 Verify project root no longer contains development files: `ls test*.py debug*.py check*.py measure*.py performance*.py verify*.py validate*.py 2>&1 | grep "No such file"`

## 3. Documentation Update

- [ ] 3.1 Update the `Testing Strategy` section in `openspec/project.md` to specify `test/` directory instead of `tests/`
- [ ] 3.2 Verify the documentation update is clear and accurate: review the updated section in `openspec/project.md`

## 4. Cleanup

- [ ] 4.1 Remove the empty `tests/` directory if it exists: `rmdir tests/` (only if empty)
- [ ] 4.2 Verify the empty `tests/` directory has been removed: `ls tests/ 2>&1 | grep "No such file or directory"`

## 5. Validation

- [ ] 5.1 Run a sample of test files to verify they work correctly: `cd test/ && python test_complete_workflow_simple.py`
- [ ] 5.2 Run a sample of debug files to verify they work correctly: `cd test/ && python debug_parsing.py`
- [ ] 5.3 Run a sample of verify files to verify they work correctly: `cd test/ && python verify_datetime_fix.py`
- [ ] 5.4 Check for any import errors or path issues in the executed files
- [ ] 5.5 If import errors are found, identify the pattern and add `test/` to PYTHONPATH in relevant scripts or update problematic imports
- [ ] 5.6 Update any script references found in step 1.2 to use the new path (e.g., update `./test_file.py` to `./test/test_file.py`)
- [ ] 5.7 Verify all updated script references work correctly

## 6. Final Verification

- [ ] 6.1 Verify Git status shows all moved files: `git status`
- [ ] 6.2 Verify the project root is cleaner and easier to navigate: `ls` (should show significantly fewer files)
- [ ] 6.3 Verify the `test/` directory contains all expected files: `ls test/`
- [ ] 6.4 Verify the documentation in `openspec/project.md` correctly specifies the `test/` directory convention
- [ ] 6.5 Commit the changes with an appropriate commit message describing the file reorganization
