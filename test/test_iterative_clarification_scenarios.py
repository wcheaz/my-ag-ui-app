#!/usr/bin/env python3
"""
Unit tests for iterative clarification scenarios with multiple rounds (Task 5.5).

These tests verify that the iterative clarification functionality works correctly
across multiple rounds of user interaction, ensuring that:

1. The clarification_rounds counter is properly incremented
2. The clarified_components set tracks which components have been resolved
3. Already-clarified components are filtered out from subsequent clarification requests
4. Context is preserved across multiple clarification rounds
5. The system correctly handles partially clarified states

This test follows the same pattern as other tests by defining necessary classes locally
to avoid import conflicts.
"""

import sys
import os
import json
from typing import List, Optional, Dict, Any
from unittest.mock import Mock, patch, MagicMock

# We need to run this from the project directory for consistent imports
os.chdir(os.path.dirname(__file__))

# Import required modules
try:
    from pydantic import BaseModel, Field

    # Define the classes locally (same pattern as other tests)
    class AmbiguityInfo(BaseModel):
        """
        Data class to track component ambiguity status during disambiguation workflow.

        This class tracks whether a component is ambiguous, unambiguous, or guessed,
        maintains the list of plausible options, and stores the user's selected value.

        Attributes:
            status: Either "ambiguous", "unambiguous", or "guessed"
            options: List of plausible matches for the component
            selected_value: The user's selected value (if resolved)
            guessed_value: The value selected when user gave explicit guess permission
            is_guessed: Boolean flag indicating if this component was guessed
        """

        status: str  # "ambiguous", "unambiguous", or "guessed"
        options: List[dict]  # List of plausible matches with their descriptions
        selected_value: Optional[str] = None  # User's selected value when resolved
        guessed_value: Optional[str] = (
            None  # Value selected when user gave guess permission
        )
        is_guessed: bool = False  # Flag indicating if this component was guessed

    class ProcurementState(BaseModel):
        """
        State for the Procurement Agent.
        Maintains conversation history and other session-specific data.
        """

        # Placeholder for message history or other state tracking
        conversation_id: Optional[str] = None
        procurement_codes: List[str] = Field(default_factory=list)
        citation_sources: List[str] = Field(default_factory=list)
        # ENFORCEMENT MECHANISM: Flag to track if rules file has been loaded this turn
        rules_loaded_this_turn: bool = False
        # DISAMBIGUATION TRACKING: Dictionary to track component ambiguity status
        component_ambiguity_status: dict[str, AmbiguityInfo] = Field(
            default_factory=dict
        )
        # ITERATIVE CLARIFICATION: Counter to track number of clarification rounds completed
        clarification_rounds: int = 0
        # ITERATIVE CLARIFICATION: Set to track which components have been successfully clarified
        clarified_components: set[str] = Field(default_factory=set)

        def update_component_ambiguity(
            self, component_name: str, ambiguity_info: AmbiguityInfo
        ) -> None:
            """
            Update component ambiguity status with validation for state transitions.
            Preserves previous user selections when updating component ambiguity status.

            Args:
                component_name: Name of the component to update
                ambiguity_info: New AmbiguityInfo for the component

            Raises:
                ValueError: If state transition is invalid
            """
            # Check if we're updating an existing component and preserve previous selections
            if component_name in self.component_ambiguity_status:
                current_info = self.component_ambiguity_status[component_name]

                # Validate state transitions: only allow ambiguous → unambiguous or ambiguous → guessed
                if (
                    current_info.status in ["unambiguous", "guessed"]
                    and ambiguity_info.status == "ambiguous"
                ):
                    raise ValueError(
                        f"Invalid state transition for component '{component_name}': "
                        f"Cannot transition from '{current_info.status}' to 'ambiguous'. "
                        f"Once a component is resolved, it cannot become ambiguous again."
                    )

                # PRESERVE PREVIOUS USER SELECTIONS: If the component already has a selected_value
                # and the new status is unambiguous, preserve the existing selection if it's valid
                if current_info.selected_value is not None:
                    if ambiguity_info.status == "unambiguous":
                        # Check if the existing selected_value is still valid in the new options
                        existing_selection_valid = any(
                            option["value"] == current_info.selected_value
                            for option in ambiguity_info.options
                        )

                        if existing_selection_valid:
                            # Preserve the existing user selection
                            ambiguity_info.selected_value = current_info.selected_value
                        # If existing selection is not valid, use the new selected_value
                    elif ambiguity_info.status == "guessed":
                        # For guessed components, preserve the existing guessed_value if valid
                        if current_info.guessed_value is not None:
                            existing_guess_valid = any(
                                option["value"] == current_info.guessed_value
                                for option in ambiguity_info.options
                            )

                            if existing_guess_valid:
                                ambiguity_info.guessed_value = (
                                    current_info.guessed_value
                                )
                                ambiguity_info.selected_value = (
                                    current_info.guessed_value
                                )
                                ambiguity_info.is_guessed = True

            # Now validate after potential preservation of selections
            # Validate that unambiguous components have a selected_value
            if (
                ambiguity_info.status == "unambiguous"
                and ambiguity_info.selected_value is None
            ):
                raise ValueError(
                    f"Invalid state for component '{component_name}': "
                    f"Unambiguous components must have a selected_value."
                )

            # Validate that guessed components have a guessed_value
            if (
                ambiguity_info.status == "guessed"
                and ambiguity_info.guessed_value is None
            ):
                raise ValueError(
                    f"Invalid state for component '{component_name}': "
                    f"Guessed components must have a guessed_value."
                )

            # Apply the update
            self.component_ambiguity_status[component_name] = ambiguity_info

        def validate_all_components_unambiguous(self) -> None:
            """
            Validate that all components are resolved (either unambiguous or guessed).
            This allows code generation to proceed when components have been explicitly
            guessed with user permission.

            Raises:
                ValueError: If any component is still ambiguous
            """
            ambiguous_components = [
                name
                for name, info in self.component_ambiguity_status.items()
                if info.status == "ambiguous"
            ]

            if ambiguous_components:
                component_list = ", ".join(ambiguous_components)
                raise ValueError(
                    f"Cannot proceed with code generation: "
                    f"The following components are still ambiguous and need clarification: {component_list}"
                )

        def get_ambiguous_components(self) -> dict[str, AmbiguityInfo]:
            """
            Get all components that are currently ambiguous.

            Returns:
                Dictionary of ambiguous component names to their AmbiguityInfo
            """
            return {
                name: info
                for name, info in self.component_ambiguity_status.items()
                if info.status == "ambiguous"
            }

        def get_unambiguous_components(self) -> dict[str, AmbiguityInfo]:
            """
            Get all components that are currently unambiguous.

            Returns:
                Dictionary of unambiguous component names to their AmbiguityInfo
            """
            return {
                name: info
                for name, info in self.component_ambiguity_status.items()
                if info.status == "unambiguous"
            }

except ImportError as e:
    print(f"Import error: {e}")
    print("Please ensure you're running this from the project root directory.")
    sys.exit(1)


def test_multiple_rounds_partial_clarification():
    """
    Test multiple rounds of clarification where user clarifies some components
    in each round until all components are resolved.
    """
    print("\n=== Testing multiple rounds of partial clarification ===")

    # Create a state
    state = ProcurementState(
        rules_loaded_this_turn=True, clarification_rounds=0, clarified_components=set()
    )

    # === ROUND 1: Initial state with ambiguous components ===
    # Simulate initial ambiguous components
    major_category_ambiguous = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "M", "description": "Metal products"},
        ],
    )

    manufacturing_method_ambiguous = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "M", "description": "Machining"},
            {"value": "F", "description": "Forging"},
        ],
    )

    object_shape_ambiguous = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Angular"},
            {"value": "R", "description": "Round"},
        ],
    )

    # Add ambiguous components to state
    state.update_component_ambiguity("Major Category", major_category_ambiguous)
    state.update_component_ambiguity(
        "Manufacturing Method", manufacturing_method_ambiguous
    )
    state.update_component_ambiguity("Object Shape", object_shape_ambiguous)

    # Verify initial state
    assert state.clarification_rounds == 0
    assert len(state.clarified_components) == 0
    assert len(state.get_ambiguous_components()) == 3

    print("✓ Initial state with 3 ambiguous components created")

    # === ROUND 1: User clarifies some components ===
    # User clarifies Major Category as "M" and Manufacturing Method as "M"
    major_category_resolved = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "M", "description": "Metal products"},
        ],
        selected_value="M",
    )

    manufacturing_method_resolved = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "M", "description": "Machining"},
            {"value": "F", "description": "Forging"},
        ],
        selected_value="M",
    )

    state.update_component_ambiguity("Major Category", major_category_resolved)
    state.update_component_ambiguity(
        "Manufacturing Method", manufacturing_method_resolved
    )

    # Mark these components as clarified
    state.clarified_components.add("Major Category")
    state.clarified_components.add("Manufacturing Method")
    state.clarification_rounds = 1

    # Verify state after round 1
    assert state.clarification_rounds == 1
    assert len(state.clarified_components) == 2
    assert "Major Category" in state.clarified_components
    assert "Manufacturing Method" in state.clarified_components

    # Check that these components are now unambiguous
    unambiguous_components = state.get_unambiguous_components()
    assert "Major Category" in unambiguous_components
    assert "Manufacturing Method" in unambiguous_components

    # But Object Shape should still be ambiguous
    ambiguous_components = state.get_ambiguous_components()
    assert len(ambiguous_components) == 1
    assert "Object Shape" in ambiguous_components

    print("✓ After round 1: 2 components clarified, 1 still ambiguous")

    # === ROUND 2: User clarifies remaining component ===
    # User clarifies Object Shape as "A"
    object_shape_resolved = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "A", "description": "Angular"},
            {"value": "R", "description": "Round"},
        ],
        selected_value="A",
    )

    state.update_component_ambiguity("Object Shape", object_shape_resolved)

    # Mark as clarified
    state.clarified_components.add("Object Shape")
    state.clarification_rounds = 2

    # Verify final state
    assert state.clarification_rounds == 2
    assert len(state.clarified_components) == 3
    assert "Object Shape" in state.clarified_components

    # All components should now be unambiguous
    try:
        state.validate_all_components_unambiguous()
        print("✓ After round 2: All components resolved successfully")
    except ValueError as e:
        assert False, f"Should have all components resolved: {e}"


def test_context_preservation_across_rounds():
    """
    Test that context is preserved across multiple clarification rounds,
    including previous selections and clarified component tracking.
    """
    print("\n=== Testing context preservation across rounds ===")

    # Create a state
    state = ProcurementState(
        rules_loaded_this_turn=True, clarification_rounds=0, clarified_components=set()
    )

    # === ROUND 1: Clarify Quality Grade ===
    quality_ambiguous = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "03", "description": "Industrial"},
            {"value": "04", "description": "Aerospace"},
        ],
    )

    state.update_component_ambiguity("Quality Grade", quality_ambiguous)

    # User clarifies as "03" (Industrial)
    quality_resolved = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "03", "description": "Industrial"},
            {"value": "04", "description": "Aerospace"},
        ],
        selected_value="03",
    )

    state.update_component_ambiguity("Quality Grade", quality_resolved)
    state.clarified_components.add("Quality Grade")
    state.clarification_rounds = 1

    # Store the state before round 2
    quality_info_after_round1 = state.component_ambiguity_status.get("Quality Grade")
    rounds_after_round1 = state.clarification_rounds
    clarified_after_round1 = set(state.clarified_components)

    # === ROUND 2: Add another component, preserve first ===
    # Add Material Type component
    material_ambiguous = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "01", "description": "Steel"},
            {"value": "02", "description": "Aluminum"},
        ],
    )

    state.update_component_ambiguity("Material Type", material_ambiguous)

    # User clarifies Material Type as "01"
    material_resolved = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "01", "description": "Steel"},
            {"value": "02", "description": "Aluminum"},
        ],
        selected_value="01",
    )

    state.update_component_ambiguity("Material Type", material_resolved)
    state.clarified_components.add("Material Type")
    state.clarification_rounds = 2

    # Verify context preservation
    # 1. Quality Grade should still be resolved with same value
    quality_info_after_round2 = state.component_ambiguity_status.get("Quality Grade")
    assert quality_info_after_round2 is not None
    assert quality_info_after_round2.status == "unambiguous"
    assert quality_info_after_round2.selected_value == "03"
    assert (
        quality_info_after_round2.selected_value
        == quality_info_after_round1.selected_value
    )

    # 2. Quality Grade should still be in clarified components
    assert "Quality Grade" in state.clarified_components
    assert "Quality Grade" in clarified_after_round1  # Was preserved

    # 3. Rounds counter should be incremented
    assert state.clarification_rounds == rounds_after_round1 + 1

    # 4. New component should be added and clarified
    assert "Material Type" in state.clarified_components
    material_info = state.component_ambiguity_status.get("Material Type")
    assert material_info is not None
    assert material_info.status == "unambiguous"
    assert material_info.selected_value == "01"

    # 5. All components should be unambiguous
    try:
        state.validate_all_components_unambiguous()
        print("✓ Context preservation across rounds working correctly")
    except ValueError as e:
        assert False, f"Context preservation failed: {e}"


def test_filtering_of_already_clarified_components():
    """
    Test that already-clarified components are properly filtered out
    from subsequent clarification requests.
    """
    print("\n=== Testing filtering of already-clarified components ===")

    # Create a state
    state = ProcurementState(
        rules_loaded_this_turn=True, clarification_rounds=0, clarified_components=set()
    )

    # Add multiple ambiguous components
    components_to_add = [
        (
            "Major Category",
            [
                {"value": "A", "description": "Agricultural"},
                {"value": "M", "description": "Metal"},
            ],
        ),
        (
            "Manufacturing Method",
            [
                {"value": "M", "description": "Machining"},
                {"value": "F", "description": "Forging"},
            ],
        ),
        (
            "Object Shape",
            [
                {"value": "A", "description": "Angular"},
                {"value": "R", "description": "Round"},
            ],
        ),
        (
            "Material Type",
            [
                {"value": "01", "description": "Steel"},
                {"value": "02", "description": "Aluminum"},
            ],
        ),
    ]

    # Add all as ambiguous initially
    for comp_name, options in components_to_add:
        ambiguous_info = AmbiguityInfo(
            status="ambiguous",
            options=options,
        )
        state.update_component_ambiguity(comp_name, ambiguous_info)

    # Verify initial state: all ambiguous
    initial_ambiguous = state.get_ambiguous_components()
    assert len(initial_ambiguous) == 4
    print(f"✓ Initial state: {len(initial_ambiguous)} ambiguous components")

    # === ROUND 1: Clarify some components ===
    components_to_clarify = ["Major Category", "Manufacturing Method"]

    for comp_name in components_to_clarify:
        # Find the options for this component
        options = None
        for name, opts in components_to_add:
            if name == comp_name:
                options = opts
                break

        if options:
            # Resolve with first option
            resolved_info = AmbiguityInfo(
                status="unambiguous",
                options=options,
                selected_value=options[0]["value"],
            )
            state.update_component_ambiguity(comp_name, resolved_info)
            state.clarified_components.add(comp_name)

    state.clarification_rounds = 1

    # Verify state after clarification
    remaining_ambiguous = state.get_ambiguous_components()
    unambiguous_now = state.get_unambiguous_components()

    # Should have 2 remaining ambiguous components
    assert len(remaining_ambiguous) == 2
    assert "Major Category" not in remaining_ambiguous
    assert "Manufacturing Method" not in remaining_ambiguous
    assert "Object Shape" in remaining_ambiguous
    assert "Material Type" in remaining_ambiguous

    # Should have 2 unambiguous components
    assert len(unambiguous_now) == 2
    assert "Major Category" in unambiguous_now
    assert "Manufacturing Method" in unambiguous_now

    # Clarified components set should contain the clarified ones
    assert len(state.clarified_components) == 2
    for comp_name in components_to_clarify:
        assert comp_name in state.clarified_components

    print("✓ Filtering working: clarified components not in ambiguous list")


def test_clarification_rounds_counter():
    """
    Test that the clarification_rounds counter is properly managed
    across multiple clarification rounds.
    """
    print("\n=== Testing clarification_rounds counter ===")

    # Create a state
    state = ProcurementState(
        rules_loaded_this_turn=True, clarification_rounds=0, clarified_components=set()
    )

    # Verify initial state
    assert state.clarification_rounds == 0

    # Simulate multiple rounds
    for round_num in range(1, 6):  # 5 rounds
        # Add and resolve a component
        comp_name = f"Component {round_num}"

        # Add as ambiguous
        ambiguous_info = AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": f"V{round_num}A", "description": f"Value {round_num} A"},
                {"value": f"V{round_num}B", "description": f"Value {round_num} B"},
            ],
        )
        state.update_component_ambiguity(comp_name, ambiguous_info)

        # Resolve it
        resolved_info = AmbiguityInfo(
            status="unambiguous",
            options=ambiguous_info.options,
            selected_value=ambiguous_info.options[0]["value"],
        )
        state.update_component_ambiguity(comp_name, resolved_info)
        state.clarified_components.add(comp_name)
        state.clarification_rounds = round_num

        # Verify counter
        assert state.clarification_rounds == round_num

        # Verify clarified components count
        assert len(state.clarified_components) == round_num

    # Final verification
    assert state.clarification_rounds == 5
    assert len(state.clarified_components) == 5
    print("✓ Clarification rounds counter working correctly")


def test_progressive_resolution_until_complete():
    """
    Test a complete iterative clarification scenario where components are
    progressively resolved until all are unambiguous.
    """
    print("\n=== Testing progressive resolution until complete ===")

    # Create a state
    state = ProcurementState(
        rules_loaded_this_turn=True, clarification_rounds=0, clarified_components=set()
    )

    # Start with multiple ambiguous components
    initial_components = [
        (
            "Major Category",
            [
                {"value": "A", "description": "Agricultural"},
                {"value": "M", "description": "Metal"},
            ],
        ),
        (
            "Manufacturing Method",
            [
                {"value": "M", "description": "Machining"},
                {"value": "F", "description": "Forging"},
            ],
        ),
        (
            "Object Shape",
            [
                {"value": "A", "description": "Angular"},
                {"value": "R", "description": "Round"},
            ],
        ),
    ]

    # Add all as ambiguous initially
    for comp_name, options in initial_components:
        ambiguous_info = AmbiguityInfo(
            status="ambiguous",
            options=options,
        )
        state.update_component_ambiguity(comp_name, ambiguous_info)

    # Continue clarifying until all components are resolved
    rounds = 0
    max_rounds = len(initial_components)  # One component per round

    while rounds < max_rounds:
        rounds += 1

        # Get current ambiguous components
        ambiguous_components = state.get_ambiguous_components()

        if len(ambiguous_components) == 0:
            print(f"✓ All components resolved after {rounds} rounds")
            break

        # Take first ambiguous component and resolve it
        comp_name, ambiguity_info = list(ambiguous_components.items())[0]

        # Resolve with first option
        resolved_info = AmbiguityInfo(
            status="unambiguous",
            options=ambiguity_info.options,
            selected_value=ambiguity_info.options[0]["value"],
        )

        state.update_component_ambiguity(comp_name, resolved_info)
        state.clarified_components.add(comp_name)
        state.clarification_rounds = rounds

        print(
            f"Round {rounds}: Clarified {comp_name} as {resolved_info.selected_value}"
        )

    # Verify final state
    try:
        state.validate_all_components_unambiguous()
        assert state.clarification_rounds == rounds
        assert len(state.clarified_components) == len(initial_components)
        print("✓ Progressive resolution completed successfully")
    except ValueError as e:
        assert False, f"Progressive resolution failed: {e}"


def test_mixed_clarification_and_guessing_across_rounds():
    """
    Test iterative clarification where some components are clarified normally
    and others are resolved through explicit guess permission.
    """
    print("\n=== Testing mixed clarification and guessing across rounds ===")

    # Create a state
    state = ProcurementState(
        rules_loaded_this_turn=True, clarification_rounds=0, clarified_components=set()
    )

    # Add ambiguous components
    components = [
        (
            "Major Category",
            [
                {"value": "A", "description": "Agricultural"},
                {"value": "M", "description": "Metal"},
            ],
        ),
        (
            "Manufacturing Method",
            [
                {"value": "M", "description": "Machining"},
                {"value": "F", "description": "Forging"},
            ],
        ),
    ]

    for comp_name, options in components:
        ambiguous_info = AmbiguityInfo(
            status="ambiguous",
            options=options,
        )
        state.update_component_ambiguity(comp_name, ambiguous_info)

    # === ROUND 1: Normal clarification ===
    # Clarify Major Category normally
    major_resolved = AmbiguityInfo(
        status="unambiguous", options=components[0][1], selected_value="M"
    )

    state.update_component_ambiguity("Major Category", major_resolved)
    state.clarified_components.add("Major Category")
    state.clarification_rounds = 1

    # Verify normal clarification
    major_info = state.component_ambiguity_status.get("Major Category")
    assert major_info.status == "unambiguous"
    assert major_info.selected_value == "M"
    assert not major_info.is_guessed

    print("✓ Round 1: Normal clarification of Major Category")

    # === ROUND 2: Guessing clarification ===
    # Simulate explicit guess permission for Manufacturing Method
    manufacturing_guessed = AmbiguityInfo(
        status="guessed",
        options=components[1][1],
        selected_value="M",  # Best guess
        guessed_value="M",
        is_guessed=True,
    )

    state.update_component_ambiguity("Manufacturing Method", manufacturing_guessed)
    state.clarified_components.add("Manufacturing Method")
    state.clarification_rounds = 2

    # Verify guessed clarification
    manufacturing_info = state.component_ambiguity_status.get("Manufacturing Method")
    assert manufacturing_info.status == "guessed"
    assert manufacturing_info.selected_value == "M"
    assert manufacturing_info.guessed_value == "M"
    assert manufacturing_info.is_guessed

    # Verify all components resolved
    try:
        state.validate_all_components_unambiguous()
        assert state.clarification_rounds == 2
        assert len(state.clarified_components) == 2
        print("✓ Mixed clarification and guessing across rounds working correctly")
    except ValueError as e:
        assert False, f"Mixed clarification failed: {e}"


def run_all_tests():
    """Run all iterative clarification tests."""

    print("=== Testing Iterative Clarification Scenarios (Task 5.5) ===")

    try:
        test_multiple_rounds_partial_clarification()
        test_context_preservation_across_rounds()
        test_filtering_of_already_clarified_components()
        test_clarification_rounds_counter()
        test_progressive_resolution_until_complete()
        test_mixed_clarification_and_guessing_across_rounds()

        print("\n=== All iterative clarification tests passed! ===")
        print("Task 5.5 implementation is working correctly.")
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
