#!/usr/bin/env python3
"""
Unit test for task 6.6: Write unit tests for save success with all unambiguous components.

This test verifies that the save_procurement_code function successfully saves
procurement codes when all components are unambiguous.
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
        """
        Data class to track component ambiguity status during disambiguation workflow.
        """

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

    # Import the actual save_procurement_code function from agent.py
    from agent import save_procurement_code

except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)


async def test_save_success_with_all_unambiguous_components():
    """Test that save_procurement_code succeeds when all components are unambiguous."""

    print(
        "=== Testing save_procurement_code success with all unambiguous components ==="
    )

    # Create test context with rules loaded and all unambiguous components
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add all unambiguous components with selected values
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "C", "description": "Chemical products"}],
            selected_value="C",
        ),
        "Manufacturing Method": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "CF", "description": "Cold formed"}],
            selected_value="CF",
        ),
        "Object Shape": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "R", "description": "Round"}],
            selected_value="R",
        ),
        "Material Type": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "01", "description": "Steel"}],
            selected_value="01",
        ),
        "Quality Grade": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "01", "description": "Standard quality"}],
            selected_value="01",
        ),
        "Size Category": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "1", "description": "Large"}],
            selected_value="1",
        ),
    }

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and all components are unambiguous
    assert ctx.deps.state.rules_loaded_this_turn == True, "Rules should be loaded"
    print("✓ Rules loaded flag is True")

    unambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "unambiguous"
    )
    assert unambiguous_count == 6, (
        f"Expected 6 unambiguous components, got {unambiguous_count}"
    )
    print("✓ Found 6 unambiguous components")

    ambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "ambiguous"
    )
    assert ambiguous_count == 0, (
        f"Expected 0 ambiguous components, got {ambiguous_count}"
    )
    print("✓ Found 0 ambiguous components")

    # Try to save a code with all unambiguous components
    result = await save_procurement_code(
        ctx, "CFR01067261", "Cold formed steel round bar"
    )

    # Verify that StateSnapshotEvent was returned (successful save)
    assert not isinstance(result, str), (
        f"Expected StateSnapshotEvent, got error string: {result}"
    )
    print("✓ Function returned StateSnapshotEvent (successful save)")

    # Verify that the code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 1, (
        f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    assert ctx.deps.state.procurement_codes[0].code == "CFR01067261", (
        "Code should match"
    )
    assert (
        ctx.deps.state.procurement_codes[0].description == "Cold formed steel round bar"
    ), "Description should match"
    print("✓ Code was saved successfully to state")

    print("\n=== Test passed! ===")
    print("save_procurement_code correctly saves when all components are unambiguous.")
    return True


async def test_save_success_with_mixed_unambiguous_and_guessed_components():
    """Test that save_procurement_code succeeds when components are either unambiguous or guessed."""

    print(
        "\n=== Testing save_procurement_code success with mixed unambiguous and guessed components ==="
    )

    # Create test context with rules loaded and mixed unambiguous/guessed components
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add mix of unambiguous and guessed components
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "C", "description": "Chemical products"}],
            selected_value="C",
        ),
        "Manufacturing Method": AmbiguityInfo(
            status="guessed",
            options=[{"value": "CF", "description": "Cold formed"}],
            selected_value="CF",
            guessed_value="CF",
            is_guessed=True,
        ),
        "Object Shape": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "R", "description": "Round"}],
            selected_value="R",
        ),
        "Material Type": AmbiguityInfo(
            status="guessed",
            options=[{"value": "01", "description": "Steel"}],
            selected_value="01",
            guessed_value="01",
            is_guessed=True,
        ),
        "Quality Grade": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "01", "description": "Standard quality"}],
            selected_value="01",
        ),
        "Size Category": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "1", "description": "Large"}],
            selected_value="1",
        ),
    }

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and we have no ambiguous components
    assert ctx.deps.state.rules_loaded_this_turn == True, "Rules should be loaded"
    print("✓ Rules loaded flag is True")

    unambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "unambiguous"
    )
    guessed_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "guessed"
    )
    ambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "ambiguous"
    )

    assert unambiguous_count == 4, (
        f"Expected 4 unambiguous components, got {unambiguous_count}"
    )
    assert guessed_count == 2, f"Expected 2 guessed components, got {guessed_count}"
    assert ambiguous_count == 0, (
        f"Expected 0 ambiguous components, got {ambiguous_count}"
    )
    print("✓ Found 4 unambiguous and 2 guessed components (0 ambiguous)")

    # Try to save a code with mixed unambiguous and guessed components
    result = await save_procurement_code(
        ctx, "CFR01067262", "Cold formed steel round bar with guessed components"
    )

    # Verify that StateSnapshotEvent was returned (successful save)
    assert not isinstance(result, str), (
        f"Expected StateSnapshotEvent, got error string: {result}"
    )
    print("✓ Function returned StateSnapshotEvent (successful save)")

    # Verify that the code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 1, (
        f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    assert ctx.deps.state.procurement_codes[0].code == "CFR01067262", (
        "Code should match"
    )
    assert (
        ctx.deps.state.procurement_codes[0].description
        == "Cold formed steel round bar with guessed components"
    ), "Description should match"
    print("✓ Code was saved successfully to state")

    print("\n=== Test passed! ===")
    print(
        "save_procurement_code correctly saves when components are either unambiguous or guessed."
    )
    return True


async def test_save_success_with_all_guessed_components():
    """Test that save_procurement_code succeeds when all components are guessed."""

    print("\n=== Testing save_procurement_code success with all guessed components ===")

    # Create test context with rules loaded and all guessed components
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add all guessed components
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="guessed",
            options=[{"value": "C", "description": "Chemical products"}],
            selected_value="C",
            guessed_value="C",
            is_guessed=True,
        ),
        "Manufacturing Method": AmbiguityInfo(
            status="guessed",
            options=[{"value": "CF", "description": "Cold formed"}],
            selected_value="CF",
            guessed_value="CF",
            is_guessed=True,
        ),
        "Object Shape": AmbiguityInfo(
            status="guessed",
            options=[{"value": "R", "description": "Round"}],
            selected_value="R",
            guessed_value="R",
            is_guessed=True,
        ),
        "Material Type": AmbiguityInfo(
            status="guessed",
            options=[{"value": "01", "description": "Steel"}],
            selected_value="01",
            guessed_value="01",
            is_guessed=True,
        ),
        "Quality Grade": AmbiguityInfo(
            status="guessed",
            options=[{"value": "01", "description": "Standard quality"}],
            selected_value="01",
            guessed_value="01",
            is_guessed=True,
        ),
        "Size Category": AmbiguityInfo(
            status="guessed",
            options=[{"value": "1", "description": "Large"}],
            selected_value="1",
            guessed_value="1",
            is_guessed=True,
        ),
    }

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and we have all guessed components
    assert ctx.deps.state.rules_loaded_this_turn == True, "Rules should be loaded"
    print("✓ Rules loaded flag is True")

    guessed_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "guessed"
    )
    ambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "ambiguous"
    )

    assert guessed_count == 6, f"Expected 6 guessed components, got {guessed_count}"
    assert ambiguous_count == 0, (
        f"Expected 0 ambiguous components, got {ambiguous_count}"
    )
    print("✓ Found 6 guessed components (0 ambiguous)")

    # Try to save a code with all guessed components
    result = await save_procurement_code(
        ctx, "CFR01067263", "Cold formed steel round bar - all components guessed"
    )

    # Verify that StateSnapshotEvent was returned (successful save)
    assert not isinstance(result, str), (
        f"Expected StateSnapshotEvent, got error string: {result}"
    )
    print("✓ Function returned StateSnapshotEvent (successful save)")

    # Verify that the code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 1, (
        f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    assert ctx.deps.state.procurement_codes[0].code == "CFR01067263", (
        "Code should match"
    )
    assert (
        ctx.deps.state.procurement_codes[0].description
        == "Cold formed steel round bar - all components guessed"
    ), "Description should match"
    print("✓ Code was saved successfully to state")

    print("\n=== Test passed! ===")
    print("save_procurement_code correctly saves when all components are guessed.")
    return True


async def test_save_success_with_single_component():
    """Test that save_procurement_code succeeds with only one unambiguous component."""

    print(
        "\n=== Testing save_procurement_code success with single unambiguous component ==="
    )

    # Create test context with rules loaded and single unambiguous component
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add single unambiguous component
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "C", "description": "Chemical products"}],
            selected_value="C",
        ),
    }

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and we have single unambiguous component
    assert ctx.deps.state.rules_loaded_this_turn == True, "Rules should be loaded"
    print("✓ Rules loaded flag is True")

    unambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "unambiguous"
    )
    ambiguous_count = sum(
        1
        for info in ctx.deps.state.component_ambiguity_status.values()
        if info.status == "ambiguous"
    )

    assert unambiguous_count == 1, (
        f"Expected 1 unambiguous component, got {unambiguous_count}"
    )
    assert ambiguous_count == 0, (
        f"Expected 0 ambiguous components, got {ambiguous_count}"
    )
    print("✓ Found 1 unambiguous component (0 ambiguous)")

    # Try to save a code with single unambiguous component
    result = await save_procurement_code(ctx, "SINGLE001", "Single component test")

    # Verify that StateSnapshotEvent was returned (successful save)
    assert not isinstance(result, str), (
        f"Expected StateSnapshotEvent, got error string: {result}"
    )
    print("✓ Function returned StateSnapshotEvent (successful save)")

    # Verify that the code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 1, (
        f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    assert ctx.deps.state.procurement_codes[0].code == "SINGLE001", "Code should match"
    assert ctx.deps.state.procurement_codes[0].description == "Single component test", (
        "Description should match"
    )
    print("✓ Code was saved successfully to state")

    print("\n=== Test passed! ===")
    print("save_procurement_code correctly saves with single unambiguous component.")
    return True


async def main():
    """Run all save success tests with unambiguous components."""
    print("=== Testing save_procurement_code success with unambiguous components ===")

    success1 = await test_save_success_with_all_unambiguous_components()
    success2 = await test_save_success_with_mixed_unambiguous_and_guessed_components()
    success3 = await test_save_success_with_all_guessed_components()
    success4 = await test_save_success_with_single_component()

    if success1 and success2 and success3 and success4:
        print("\n" + "=" * 60)
        print("=== All save success tests with unambiguous components passed! ===")
        print(
            "The save_procurement_code function correctly allows saves when all components are resolved (unambiguous or guessed)."
        )
        return True
    else:
        print("\n=== Some tests failed! ===")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
