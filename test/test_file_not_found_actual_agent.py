#!/usr/bin/env python3
"""
Test script to verify that FileNotFoundError is raised correctly when CODE_GENERATION.md
is not found in the actual agent implementation.
"""

import sys
import os
import tempfile
import shutil

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(__file__), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional
    from pydantic_ai import RunContext
    from pydantic_ai.ag_ui import StateDeps
    from agent import read_code_generation_file, ProcurementState
except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the project directory with the virtual environment activated."
    )
    sys.exit(1)


def create_test_context():
    """Create a test RunContext with ProcurementState for testing."""
    # Create a test state
    state = ProcurementState()

    # Create StateDeps wrapper
    deps = StateDeps(state=state)

    # Create a minimal RunContext-like object for testing
    # Since RunContext requires framework setup, we'll mock the essential parts
    class MockRunContext:
        def __init__(self, deps):
            self.deps = deps

    return MockRunContext(deps)


def test_file_not_found_exception():
    """Test that FileNotFoundError is raised correctly when CODE_GENERATION.md is not found."""

    print("=== Testing FileNotFoundError when file is not found ===")

    # Create a temporary directory without CODE_GENERATION.md
    temp_dir = tempfile.mkdtemp()
    try:
        print(f"✓ Created temporary directory: {temp_dir}")

        # Change to the temp directory so file resolution works
        original_cwd = os.getcwd()
        os.chdir(temp_dir)

        try:
            # Create test context
            ctx = create_test_context()

            # Verify flag starts as False
            assert ctx.deps.state.rules_loaded_this_turn == False, (
                f"Expected initial flag to be False, got {ctx.deps.state.rules_loaded_this_turn}"
            )
            print("✓ Initial rules_loaded_this_turn flag is False")

            # Call read_code_generation_file and expect FileNotFoundError
            try:
                result = read_code_generation_file(ctx)
                # If we reach here, the function didn't raise an exception - this is a failure
                assert False, "Function should have raised FileNotFoundError but didn't"
            except FileNotFoundError as e:
                # This is the expected behavior
                expected_message = (
                    "CODE_GENERATION.md not found. Cannot generate codes without rules."
                )
                assert str(e) == expected_message, (
                    f"Expected error message: '{expected_message}', got: '{str(e)}'"
                )
                print(f"✓ Correct FileNotFoundError raised with message: '{str(e)}'")
                print(f"✓ Exception type: {type(e).__name__}")

            except Exception as e:
                # This is NOT the expected behavior - we should get FileNotFoundError directly
                assert False, (
                    f"Expected FileNotFoundError but got {type(e).__name__}: {str(e)}"
                )

            # Verify flag is still False (should not have been set)
            assert ctx.deps.state.rules_loaded_this_turn == False, (
                f"Expected flag to remain False after failed read, got {ctx.deps.state.rules_loaded_this_turn}"
            )
            print("✓ rules_loaded_this_turn flag remains False after failed read")

            print("\n=== All tests passed! ===")
            print(
                "The FileNotFoundError is correctly raised when CODE_GENERATION.md is not found."
            )
            return True

        finally:
            # Restore original working directory
            os.chdir(original_cwd)

    finally:
        # Clean up temp directory
        shutil.rmtree(temp_dir)
        print("✓ Cleaned up temporary directory")


if __name__ == "__main__":
    success = test_file_not_found_exception()
    sys.exit(0 if success else 1)
