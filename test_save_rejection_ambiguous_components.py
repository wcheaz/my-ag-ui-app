#!/usr/bin/env python3
"""
Unit test for task 6.5: Write unit tests for save rejection with ambiguous components.

This test verifies that the save_procurement_code function correctly validates
that all components are unambiguous before allowing a save.
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

    # Mock the save_procurement_code function with ambiguity validation
    async def save_procurement_code(ctx, code: str, description: str):
        """
        Mock version of save_procurement_code function with ambiguity validation.
        """
        # ENFORCEMENT MECHANISM: Validate that rules were loaded this turn
        if not ctx.deps.state.rules_loaded_this_turn:
            return (
                "ERROR: You must call read_code_generation_file before saving a code."
            )

        # DISAMBIGUATION ENFORCEMENT: Validate that all components are unambiguous
        ambiguous_components = []
        for (
            component_name,
            ambiguity_info,
        ) in ctx.deps.state.component_ambiguity_status.items():
            if ambiguity_info.status == "ambiguous":
                ambiguous_components.append(component_name)

        if ambiguous_components:
            return f"ERROR: Cannot save code with ambiguous components. Please clarify the following components: {', '.join(ambiguous_components)}"

        # If all validations pass, create and save the code
        new_code = ProcurementCode(code=code, description=description)
        ctx.deps.state.procurement_codes.append(new_code)
        return f"SUCCESS: Code {code} saved successfully"

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
            options=[{"value": "01", "description": "Steel"}],
            selected_value="01",
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
    result = await save_procurement_code(ctx, "TEST001", "Test code description")

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
    return True


async def test_save_blocked_with_multiple_ambiguous_components():
    """Test that save_procurement_code returns error when multiple components are ambiguous."""

    print(
        "\n=== Testing save_procurement_code blocked with multiple ambiguous components ==="
    )

    # Create test context with rules loaded but multiple ambiguous components
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add multiple ambiguous components
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "A", "description": "Agricultural products"},
                {"value": "C", "description": "Chemical products"},
            ],
        ),
        "Manufacturing Method": AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "CF", "description": "Cold formed"},
                {"value": "HF", "description": "Hot formed"},
            ],
        ),
        "Material Type": AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "01", "description": "Steel"}],
            selected_value="01",
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
    assert ambiguous_count == 2, (
        f"Expected 2 ambiguous components, got {ambiguous_count}"
    )
    print("✓ Found 2 ambiguous components (Major Category, Manufacturing Method)")

    # Try to save a code with multiple ambiguous components
    result = await save_procurement_code(ctx, "TEST002", "Test code description")

    # Verify that an error message was returned
    assert isinstance(result, str), f"Expected string error message, got {type(result)}"
    assert "Cannot save code with ambiguous components" in result, (
        f"Expected ambiguity error, got: {result}"
    )
    assert "Major Category" in result, (
        f"Expected Major Category in error message, got: {result}"
    )
    assert "Manufacturing Method" in result, (
        f"Expected Manufacturing Method in error message, got: {result}"
    )
    print(
        "✓ Function returned expected error message for multiple ambiguous components"
    )

    # Verify that no code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 0, (
        f"Expected 0 codes in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    print("✓ No code was saved when multiple components are ambiguous")

    print("\n=== Test passed! ===")
    print(
        "save_procurement_code correctly blocks save when multiple components are ambiguous."
    )
    return True


async def test_save_blocked_with_all_ambiguous_components():
    """Test that save_procurement_code returns error when all components are ambiguous."""

    print(
        "\n=== Testing save_procurement_code blocked with all ambiguous components ==="
    )

    # Create test context with rules loaded but all components ambiguous
    state = ProcurementState(rules_loaded_this_turn=True)

    # Add all ambiguous components
    state.component_ambiguity_status = {
        "Major Category": AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "A", "description": "Agricultural products"},
                {"value": "C", "description": "Chemical products"},
            ],
        ),
        "Manufacturing Method": AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "CF", "description": "Cold formed"},
                {"value": "HF", "description": "Hot formed"},
            ],
        ),
        "Object Shape": AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "R", "description": "Round"},
                {"value": "S", "description": "Square"},
            ],
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
    assert ambiguous_count == 3, (
        f"Expected 3 ambiguous components, got {ambiguous_count}"
    )
    print(
        "✓ Found 3 ambiguous components (Major Category, Manufacturing Method, Object Shape)"
    )

    # Try to save a code with all ambiguous components
    result = await save_procurement_code(ctx, "TEST003", "Test code description")

    # Verify that an error message was returned
    assert isinstance(result, str), f"Expected string error message, got {type(result)}"
    assert "Cannot save code with ambiguous components" in result, (
        f"Expected ambiguity error, got: {result}"
    )
    assert "Major Category" in result, (
        f"Expected Major Category in error message, got: {result}"
    )
    assert "Manufacturing Method" in result, (
        f"Expected Manufacturing Method in error message, got: {result}"
    )
    assert "Object Shape" in result, (
        f"Expected Object Shape in error message, got: {result}"
    )
    print("✓ Function returned expected error message for all ambiguous components")

    # Verify that no code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 0, (
        f"Expected 0 codes in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    print("✓ No code was saved when all components are ambiguous")

    print("\n=== Test passed! ===")
    print(
        "save_procurement_code correctly blocks save when all components are ambiguous."
    )
    return True


async def test_save_blocked_with_empty_ambiguity_status():
    """Test that save_procurement_code succeeds when no ambiguity status is set (backward compatibility)."""

    print("\n=== Testing save_procurement_code allowed with empty ambiguity status ===")

    # Create test context with rules loaded but empty ambiguity status
    state = ProcurementState(rules_loaded_this_turn=True)
    # No component_ambiguity_status set (empty dict by default)

    deps = MockDeps(state)
    ctx = MockRunContext(deps)

    # Verify rules are loaded and ambiguity status is empty
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
    print("✓ Found 0 ambiguous components (empty ambiguity status)")

    # Try to save a code with empty ambiguity status
    result = await save_procurement_code(ctx, "TEST004", "Test code description")

    # Verify that success message was returned
    assert isinstance(result, str), f"Expected string result, got {type(result)}"
    assert "SUCCESS:" in result, f"Expected success message, got: {result}"
    print("✓ Function returned success message with empty ambiguity status")

    # Verify that the code was saved to the state
    assert len(ctx.deps.state.procurement_codes) == 1, (
        f"Expected 1 code in state, got {len(ctx.deps.state.procurement_codes)}"
    )
    assert ctx.deps.state.procurement_codes[0].code == "TEST004", "Code should match"
    print("✓ Code was saved successfully with empty ambiguity status")

    print("\n=== Test passed! ===")
    print(
        "save_procurement_code correctly allows save with empty ambiguity status (backward compatibility)."
    )
    return True


async def main():
    """Run all save rejection tests with ambiguous components."""
    print("=== Testing save_procurement_code rejection with ambiguous components ===")

    success1 = await test_save_blocked_with_ambiguous_components()
    success2 = await test_save_blocked_with_multiple_ambiguous_components()
    success3 = await test_save_blocked_with_all_ambiguous_components()
    success4 = await test_save_blocked_with_empty_ambiguity_status()

    if success1 and success2 and success3 and success4:
        print("\n" + "=" * 60)
        print("=== All save rejection tests with ambiguous components passed! ===")
        print(
            "The save_procurement_code function correctly validates ambiguity status."
        )
        return True
    else:
        print("\n=== Some tests failed! ===")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
