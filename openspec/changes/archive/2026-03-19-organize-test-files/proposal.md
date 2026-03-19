## Why

The project root directory currently contains numerous development and testing files (70+ files including test*.py, debug*.py, check*.py, measure*.py, performance*.py, verify*.py, and validate*.py), making it difficult to navigate and maintain. While the project.md references a "tests" directory convention, that directory exists but is empty. We need to establish a clear, consistent convention for organizing all development files and move them to the appropriate location.

## What Changes

- Move all existing development and testing files from the project root to a new `test/` directory, including:
  - All test*.py files (67 files)
  - All debug*.py files (debug_component_extraction.py, debug_parsing.py, debug_products_matches.py)
  - check*.py files (check_version.py)
  - measure*.py files (measure_startup_time.py)
  - performance*.py files (performance_test.py, env_performance_test.py)
  - verify*.py files (verify_datetime_fix.py, verify_flag_reset.py)
  - validate*.py files (validate_similarity_threshold.py)
- Update `openspec/project.md` to specify that all development and testing files should be placed in the `test/` directory (correcting the existing reference to "tests/")
- Create the `test/` directory structure if it doesn't exist
- Ensure any relative imports or references in development files continue to work after the move

## Capabilities

### New Capabilities
- `dev-file-organization`: Establishes the convention and structure for organizing all development and testing files within the project, specifying that all test, debug, check, measure, performance, verify, and validate files should reside in the `test/` directory

### Modified Capabilities
- None (this is a structural change, not a functional requirement change)

## Impact

- **Development Files**: 70+ development and testing files in the root directory will be moved to `test/`
- **Project Documentation**: `openspec/project.md` will be updated to reflect the correct development file directory convention
- **Scripts and Workflows**: Any scripts or workflows that reference development files by relative path may need updates
- **Directory Structure**: Creates a cleaner root directory with a dedicated test directory for all development files
- **No Breaking Changes**: This is a reorganization that maintains functionality while improving project structure
