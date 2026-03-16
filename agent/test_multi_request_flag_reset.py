#!/usr/bin/env python3
"""
Test script to verify multi-request scenario: read and save in first request,
verify flag resets for second request.

This tests that the rules_loaded_this_turn flag properly resets when new
requests are made (new state instances are created).
"""

import sys
import os
import asyncio

# We need to run this from the agent directory to access dependencies
# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(os.getcwd(), "src"))

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


async def test_multi_request_scenario():
    """Test multi-request scenario: flag resets between requests."""

    print("=== Testing multi-request scenario: flag resets between requests ===")

    # === FIRST REQUEST ===
    print("\n--- Simulating First Request ---")

    # Create first request context
    ctx1 = create_test_context()

    # Verify initial state for first request
    assert ctx1.deps.state.rules_loaded_this_turn == False, (
        f"Expected initial flag to be False in first request, got {ctx1.deps.state.rules_loaded_this_turn}"
    )
    print("✓ First request: flag is initially False")

    # Step 1: Read the code generation file in first request
    print("\n1. Reading code generation file in first request...")
    try:
        content = read_code_generation_file(ctx1)
        print(f"✓ Successfully read CODE_GENERATION.md in first request")

        # Verify flag is now True
        assert ctx1.deps.state.rules_loaded_this_turn == True, (
            f"Expected flag to be True after reading file in first request, got {ctx1.deps.state.rules_loaded_this_turn}"
        )
        print("✓ rules_loaded_this_turn flag is now True in first request")

    except Exception as e:
        print(f"✗ Failed to read CODE_GENERATION.md in first request: {e}")
        return False

    # Step 2: Save a code in first request
    print("\n2. Saving procurement code in first request...")
    try:
        result = await save_procurement_code(
            ctx1, "CFR01067261", "Steel I-beam for office building construction"
        )

        # Verify that save succeeded
        assert isinstance(result, StateSnapshotEvent), (
            f"Expected StateSnapshotEvent in first request, got {type(result)}: {result}"
        )
        print("✓ Successfully saved code in first request")

        # Verify flag is still True after saving
        assert ctx1.deps.state.rules_loaded_this_turn == True, (
            f"Expected flag to remain True after saving in first request, got {ctx1.deps.state.rules_loaded_this_turn}"
        )
        print(
            "✓ rules_loaded_this_turn flag remains True after saving in first request"
        )

    except Exception as e:
        print(f"✗ Failed to save code in first request: {e}")
        return False

    # === SECOND REQUEST ===
    print("\n--- Simulating Second Request (New Context) ---")

    # Create second request context (simulating a new request)
    ctx2 = create_test_context()

    # Verify that flag is reset to False for new request
    assert ctx2.deps.state.rules_loaded_this_turn == False, (
        f"Expected flag to be reset to False in second request, got {ctx2.deps.state.rules_loaded_this_turn}"
    )
    print("✓ Second request: flag is reset to False (new request)")

    # Step 3: Try to save a code in second request WITHOUT reading file first
    print("\n3. Attempting to save code in second request WITHOUT reading file...")
    try:
        result = await save_procurement_code(
            ctx2, "CFR02067262", "Concrete blocks for foundation work"
        )

        # This should fail with an error message
        assert isinstance(result, str), (
            f"Expected error string in second request, got {type(result)}: {result}"
        )
        assert (
            "ERROR: You must call read_code_generation_file before saving a code."
            in result
        ), f"Expected specific error message, got: {result}"
        print(f"✓ Correctly rejected save attempt in second request: {result}")

    except Exception as e:
        print(f"✗ Unexpected exception in second request: {e}")
        return False

    # Step 4: Verify first request context is unchanged
    print("\n4. Verifying first request context is unchanged...")
    assert ctx1.deps.state.rules_loaded_this_turn == True, (
        f"Expected first request flag to still be True, got {ctx1.deps.state.rules_loaded_this_turn}"
    )
    assert len(ctx1.deps.state.procurement_codes) == 1, (
        f"Expected first request to still have 1 code, got {len(ctx1.deps.state.procurement_codes)}"
    )
    print("✓ First request context remains unchanged")

    # Step 5: Verify second request context is unchanged (no code saved)
    print("\n5. Verifying second request context is unchanged...")
    assert ctx2.deps.state.rules_loaded_this_turn == False, (
        f"Expected second request flag to still be False, got {ctx2.deps.state.rules_loaded_this_turn}"
    )
    assert len(ctx2.deps.state.procurement_codes) == 0, (
        f"Expected second request to have 0 codes (save rejected), got {len(ctx2.deps.state.procurement_codes)}"
    )
    print("✓ Second request context unchanged (no code saved)")

    print("\n=== Multi-request scenario test passed! ===")
    print("Key findings:")
    print("- First request: read file → save code works correctly")
    print("- Second request: flag is automatically reset to False")
    print("- Second request: save without read is properly blocked")
    print("- Each request maintains its own isolated state")
    return True


if __name__ == "__main__":
    success = asyncio.run(test_multi_request_scenario())
    sys.exit(0 if success else 1)
