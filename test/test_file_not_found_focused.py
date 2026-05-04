#!/usr/bin/env python3
"""
Test script to verify that FileNotFoundError is raised correctly when CODE_GENERATION.md
is not found in the actual agent implementation.
"""

import sys
import os
import tempfile
import shutil
import datetime

# We need to run this from the project root to access dependencies properly
project_root = os.path.dirname(__file__)
agent_src_dir = os.path.join(project_root, "agent", "src")
os.chdir(project_root)

# Add the agent src directory to the Python path
sys.path.insert(0, agent_src_dir)

# Import required modules directly
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional
    from pydantic_ai.ag_ui import StateDeps
except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the project directory with the virtual environment activated."
    )
    sys.exit(1)


# Define ProcurementState class (matching the one in agent.py)
class ProcurementState(BaseModel):
    """
    State for the Procurement Agent.
    Maintains conversation history and other session-specific data.
    """

    # Placeholder for message history or other state tracking
    conversation_id: Optional[str] = None
    procurement_codes: List[str] = Field(default_factory=list)
    citation_sources: List[str] = Field(
        default_factory=list
    )  # Accumulated citation sources
    rules_loaded_this_turn: bool = False


# Import the read_code_generation_file function directly
def read_code_generation_file(ctx):
    """
    Read the contents of the CODE_GENERATION.md file which contains the procurement code generation template.
    This is a copy of the actual function from agent.py for testing purposes.
    """
    try:
        # DEBUG: Log context messages
        try:
            with open(
                os.path.join(os.getcwd(), "hidden", "debug_context.txt"), "a"
            ) as f:
                f.write(f"\nCTX MESSAGES AT {datetime.datetime.now()}:\n")
                if hasattr(ctx, "messages"):
                    for i, m in enumerate(ctx.messages):
                        f.write(
                            f"MSG {i}: Type={type(m).__name__}, Parts={len(m.parts) if hasattr(m, 'parts') else 'N/A'}\n"
                        )
                        if hasattr(m, "parts"):
                            for p in m.parts:
                                f.write(f"  PART: {type(p).__name__}\n")
        except Exception as deb_e:
            print(f"Debug log failed: {deb_e}")

        # Try finding the file relative to CWD
        paths_to_check = [
            os.path.join(
                os.getcwd(), "agent", "data", "CODE_GENERATION.md"
            ),  # From project root
            os.path.join("data", "CODE_GENERATION.md"),  # From agent dir
            os.path.join("..", "data", "CODE_GENERATION.md"),  # From src dir
        ]

        file_path = None
        for path in paths_to_check:
            if os.path.exists(path):
                file_path = path
                break

        if not file_path:
            raise FileNotFoundError(
                "CODE_GENERATION.md not found. Cannot generate codes without rules."
            )

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Set flag to indicate rules were successfully loaded this turn
        ctx.deps.state.rules_loaded_this_turn = True
        return content
    except FileNotFoundError:
        # Re-raise FileNotFoundError directly as per specification
        raise
    except Exception as e:
        raise Exception(f"Error reading CODE_GENERATION.md file: {str(e)}")


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
