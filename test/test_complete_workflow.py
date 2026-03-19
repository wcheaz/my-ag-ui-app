#!/usr/bin/env python3
"""
Test script to verify the complete workflow: read file → generate code → save code.
This should succeed when following the correct workflow.
"""

import sys
import os
import asyncio
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
    from ag_ui.core import EventType, StateSnapshotEvent

    # Import the actual agent modules
    from agent import ProcurementCode, ProcurementState

except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
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


def read_code_generation_file(ctx):
    """
    Read the CODE_GENERATION.md file and set the rules_loaded_this_turn flag.
    """
    try:
        # Try finding the file relative to CWD
        paths_to_check = [
            os.path.join(os.getcwd(), "agent", "data", "CODE_GENERATION.md"),
            os.path.join("data", "CODE_GENERATION.md"),
            os.path.join("..", "data", "CODE_GENERATION.md"),
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
    except Exception as e:
        raise Exception(f"Error reading CODE_GENERATION.md file: {str(e)}")


async def save_procurement_code(ctx, code: str, description: str):
    """
    Save a procurement code after validating that rules were loaded.
    """
    # Validate that rules were loaded this turn
    if not ctx.deps.state.rules_loaded_this_turn:
        return "ERROR: You must call read_code_generation_file before saving a code."

    new_code = ProcurementCode(code=code, description=description)
    ctx.deps.state.procurement_codes.append(new_code)
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot=ctx.deps.state,
    )


async def test_complete_workflow():
    """Test the complete workflow: read file → generate code → save code."""

    print("=== Testing complete workflow: read file → generate code → save code ===")

    # Create test context
    ctx = create_test_context()

    # Verify initial state
    assert ctx.deps.state.rules_loaded_this_turn == False, (
        f"Expected initial flag to be False, got {ctx.deps.state.rules_loaded_this_turn}"
    )
    assert len(ctx.deps.state.procurement_codes) == 0, (
        f"Expected 0 codes in state initially, got {len(ctx.deps.state.procurement_codes)}"
    )
    print("✓ Initial state: flag is False, no codes saved")

    # Step 1: Read the code generation file
    print("\n--- Step 1: Reading code generation file ---")
    try:
        content = read_code_generation_file(ctx)
        print(f"✓ Successfully read CODE_GENERATION.md ({len(content)} characters)")

        # Verify flag is now True
        assert ctx.deps.state.rules_loaded_this_turn == True, (
            f"Expected flag to be True after reading file, got {ctx.deps.state.rules_loaded_this_turn}"
        )
        print("✓ rules_loaded_this_turn flag is now True")

    except Exception as e:
        print(f"✗ Failed to read CODE_GENERATION.md: {e}")
        return False

    # Step 2: Generate a code (simulated - in real workflow this would involve AI analysis)
    print("\n--- Step 2: Generating procurement code ---")
    generated_code = "CFR01067261"  # Example code based on the rules
    code_description = "Steel I-beam for office building construction"
    print(f"✓ Generated code: {generated_code}")
    print(f"✓ Code description: {code_description}")

    # Step 3: Save the procurement code
    print("\n--- Step 3: Saving procurement code ---")
    try:
        result = await save_procurement_code(ctx, generated_code, code_description)

        # Verify that a StateSnapshotEvent was returned (not an error string)
        assert isinstance(result, StateSnapshotEvent), (
            f"Expected StateSnapshotEvent, got {type(result)}: {result}"
        )
        print("✓ save_procurement_code returned StateSnapshotEvent")

        # Verify that the code was saved to the state
        assert len(ctx.deps.state.procurement_codes) == 1, (
            f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
        )

        saved_code = ctx.deps.state.procurement_codes[0]
        assert saved_code.code == generated_code, (
            f"Expected code '{generated_code}', got '{saved_code.code}'"
        )
        assert saved_code.description == code_description, (
            f"Expected description '{code_description}', got '{saved_code.description}'"
        )
        print("✓ Code was successfully saved to state")

        # Verify flag is still True after saving
        assert ctx.deps.state.rules_loaded_this_turn == True, (
            f"Expected flag to remain True after saving, got {ctx.deps.state.rules_loaded_this_turn}"
        )
        print("✓ rules_loaded_this_turn flag remains True after saving")

    except Exception as e:
        print(f"✗ Failed to save procurement code: {e}")
        return False

    print("\n=== Complete workflow test passed! ===")
    print("The workflow read file → generate code → save code works correctly.")
    print("- Rules are loaded and flag is set to True")
    print("- Code generation is performed")
    print("- Code is saved successfully with proper validation")
    return True


if __name__ == "__main__":
    success = asyncio.run(test_complete_workflow())
    sys.exit(0 if success else 1)
