#!/usr/bin/env python3
"""
Simple test to verify that save_procurement_code blocks save when components are ambiguous.
This test focuses only on the ambiguity validation logic.
"""

import sys
import os
import asyncio

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

try:
    from pydantic import BaseModel, Field
    from typing import List, Optional, Dict

    # Import the classes we need for testing
    class ProcurementCode(BaseModel):
        code: str
        description: str

    class AmbiguityInfo(BaseModel):
        status: str  # "ambiguous", "unambiguous", or "guessed"
        options: List[dict]  # List of plausible matches
        selected_value: Optional[str] = None
        guessed_value: Optional[str] = None
        is_guessed: bool = False

    class ProcurementState(BaseModel):
        """
        State for the Procurement Agent.
        """

        conversation_id: Optional[str] = None
        procurement_codes: List[ProcurementCode] = Field(default_factory=list)
        citation_sources: List[str] = Field(default_factory=list)
        rules_loaded_this_turn: bool = False
        component_ambiguity_status: Dict[str, AmbiguityInfo] = Field(
            default_factory=dict
        )

    class MockDeps:
        def __init__(self, state):
            self.state = state

    class MockRunContext:
        def __init__(self, deps):
            self.deps = deps

    # Import the actual save_procurement_code function
    from agent import save_procurement_code

except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)


async def test_save_blocked_with_ambiguous_components():
    """Test that save_procurement_code returns error when components are ambiguous."""

    print("=== Testing save_procurement_code blocked with ambiguous components ===")

    # Create test context with rules loaded but ambiguous components
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add some ambiguous components
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "A", "description": "Agricultural products"},
                {"value": "C", "description": "Chemical products"},
            ],
        ),
        "Material Type": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "S", "description": "Steel"}],
            selected_value="S",
        ),
    }

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and we have ambiguous components
    assert ctx.deps.state.rules_loaded_this_turn == True, "Rules should be loaded"
    print("✓ Rules loaded flag is True")

    ambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "ambiguous"
    )
    assert ambiguous_count == 1, (
        f"Expected 1 ambiguous component, got {ambiguous_count}"
    )
    print("✓ Found 1 ambiguous component (Major Category)")

    # Try to save a code with ambiguous components
    result = await save_procurement(ctx, "TEST001", "Test code description")

    # Verify that an error message was returned
    assert isinstance(result, str), f"Expected string error message, got {type(result)}"
    assert "Cannot save code with ambiguous components" in result, (
        f"Expected ambiguity error, got: {result}"
    )
    assert "Major Category" in result, (
        f"Expected Major Category in error message, got: {result}"
    )
    print("✓ Function returned expected error message for ambiguous components")

    # Verify that no code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 0, (
        f"Expected 0 codes in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    print("✓ No code was saved when components are ambiguous")

    print("\n=== Test passed! ===")
    print("save_procurement_code correctly blocks save when components are ambiguous.")


async def test_save_allowed_with_all_unambiguous():
    """Test that save_procurement_code allows save when all components are unambiguous."""

    print(
        "=== Testing save_procurement_code allowed with all unambiguous components ==="
    )

    # Create test context with rules loaded and all components unambiguous
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add unambiguous components
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "A", "description": "Agricultural products"}],
            selected_value="A",
        ),
        "Material Type": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "S", "description": "Steel"}],
            selected_value="S",
        ),
    }

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and all components are unambiguous
    assert ctx.deps.state.rules_loaded_this_turn == True, "Rules should be loaded"
    print("✓ Rules loaded flag is True")

    ambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "ambiguous"
    )
    assert ambiguous_count == 0, (
        f"Expected 0 ambiguous components, got {ambiguous_count}"
    )
    print("✓ Found 0 ambiguous components (all unambiguous)")

    # Try to save a code with all unambiguous components
    result = await save_procurement_code(ctx, "TEST001", "Test code description")

    # Note: This may return a StateSnapshotEvent object, not a string
    print(f"✓ Function returned success (type: {type(result).__name__})")

    # Verify that the code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 1, (
        f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    assert ctx.deps.state.procurement_codes[0].code == "TEST001", "Code should match"
    print("✓ Code was saved successfully when all components are unambiguous")

    print("\n=== Test passed! ===")
    print(
        "save_procurement_code correctly allows save when all components are unambiguous."
    )


async def main():
    """Run all tests."""
    print("Testing save_procurement_code ambiguity validation...\n")

    await test_save_blocked_with_ambiguous_components()
    print("\n" + "=" * 60 + "\n")
    await test_save_allowed_with_all_unambiguous()

    print("\n" + "=" * 60)
    print("All tests passed! Ambiguity validation is working correctly.")


if __name__ == "__main__":
    asyncio.run(main())
