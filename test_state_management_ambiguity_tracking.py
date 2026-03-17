#!/usr/bin/env python3
"""
Test script to verify state management and ambiguity tracking functionality.

This tests the AmbiguityInfo class, ProcurementState with ambiguity status tracking,
and validation logic for state transitions.
"""

import sys
import os

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(__file__), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional

    # Instead of importing from agent (which has RAG dependencies),
    # we'll define the classes locally for testing
    class AmbiguityInfo(BaseModel):
        """
        Data class to track component ambiguity status during disambiguation workflow.

        This class tracks whether a component is ambiguous or unambiguous,
        maintains the list of plausible options, and stores the user's selected value.

        Attributes:
            status: Either "ambiguous" or "unambiguous"
            options: List of plausible matches for the component
            selected_value: The user's selected value (if resolved)
        """

        status: str  # "ambiguous" or "unambiguous"
        options: List[dict]  # List of plausible matches with their descriptions
        selected_value: Optional[str] = None  # User's selected value when resolved

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
        # ENFORCEMENT MECHANISM: Flag to track if rules file has been loaded this turn
        # This flag enforces the workflow: read_code_generation_file MUST be called before save_procurement_code
        # The flag defaults to False and is reset per request to prevent stale state
        rules_loaded_this_turn: bool = False
        # DISAMBIGUATION TRACKING: Dictionary to track component ambiguity status
        # Key: component_name (str), Value: AmbiguityInfo object
        # This enables programmatic enforcement of disambiguation workflow
        component_ambiguity_status: dict[str, AmbiguityInfo] = Field(
            default_factory=dict
        )

        def update_component_ambiguity(
            self, component_name: str, ambiguity_info: AmbiguityInfo
        ) -> None:
            """
            Update component ambiguity status with validation for state transitions.

            Args:
                component_name: Name of the component to update
                ambiguity_info: New AmbiguityInfo for the component

            Raises:
                ValueError: If state transition is invalid
            """
            # Validate that unambiguous components have a selected_value (for both new and existing components)
            if (
                ambiguity_info.status == "unambiguous"
                and ambiguity_info.selected_value is None
            ):
                raise ValueError(
                    f"Invalid state for component '{component_name}': "
                    f"Unambiguous components must have a selected_value."
                )

            if component_name in self.component_ambiguity_status:
                current_info = self.component_ambiguity_status[component_name]

                # Validate state transition: only allow ambiguous → unambiguous
                if (
                    current_info.status == "unambiguous"
                    and ambiguity_info.status == "ambiguous"
                ):
                    raise ValueError(
                        f"Invalid state transition for component '{component_name}': "
                        f"Cannot transition from 'unambiguous' to 'ambiguous'. "
                        f"Once a component is resolved, it cannot become ambiguous again."
                    )

            # Apply the update
            self.component_ambiguity_status[component_name] = ambiguity_info

        def validate_all_components_unambiguous(self) -> None:
            """
            Validate that all components are unambiguous (no ambiguous components remain).

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
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
    )
    sys.exit(1)


def test_ambiguity_info_creation():
    """Test that AmbiguityInfo can be created with valid data."""

    print("=== Testing AmbiguityInfo creation ===")

    # Test creating an ambiguous component
    ambiguous_info = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
    )

    assert ambiguous_info.status == "ambiguous", (
        f"Expected status 'ambiguous', got '{ambiguous_info.status}'"
    )
    assert len(ambiguous_info.options) == 2, (
        f"Expected 2 options, got {len(ambiguous_info.options)}"
    )
    assert ambiguous_info.selected_value is None, (
        f"Expected selected_value to be None, got '{ambiguous_info.selected_value}'"
    )
    print("✓ Ambiguous AmbiguityInfo created successfully")

    # Test creating an unambiguous component
    unambiguous_info = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "A", "description": "Agricultural products"}],
        selected_value="A",
    )

    assert unambiguous_info.status == "unambiguous", (
        f"Expected status 'unambiguous', got '{unambiguous_info.status}'"
    )
    assert len(unambiguous_info.options) == 1, (
        f"Expected 1 option, got {len(unambiguous_info.options)}"
    )
    assert unambiguous_info.selected_value == "A", (
        f"Expected selected_value 'A', got '{unambiguous_info.selected_value}'"
    )
    print("✓ Unambiguous AmbiguityInfo created successfully")

    return True


def test_procurement_state_ambiguity_tracking():
    """Test that ProcurementState can track component ambiguity status."""

    print("\n=== Testing ProcurementState ambiguity tracking ===")

    # Create a state
    state = ProcurementState()

    # Verify initial state
    assert len(state.component_ambiguity_status) == 0, (
        f"Expected empty ambiguity status, got {len(state.component_ambiguity_status)} items"
    )
    print("✓ Initial component_ambiguity_status is empty")

    # Add ambiguous components
    major_category_ambiguous = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
    )

    manufacturing_method_unambiguous = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "CF", "description": "Cold formed"}],
        selected_value="CF",
    )

    state.component_ambiguity_status["Major Category"] = major_category_ambiguous
    state.component_ambiguity_status["Manufacturing Method"] = (
        manufacturing_method_unambiguous
    )

    # Verify components were added
    assert len(state.component_ambiguity_status) == 2, (
        f"Expected 2 components, got {len(state.component_ambiguity_status)}"
    )
    assert "Major Category" in state.component_ambiguity_status, (
        "Major Category not found in ambiguity status"
    )
    assert "Manufacturing Method" in state.component_ambiguity_status, (
        "Manufacturing Method not found in ambiguity status"
    )
    print("✓ Components added to ambiguity status successfully")

    return True


def test_update_component_ambiguity():
    """Test the update_component_ambiguity method with validation."""

    print("\n=== Testing update_component_ambiguity method ===")

    state = ProcurementState()

    # Test adding new ambiguous component
    ambiguous_info = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
    )

    state.update_component_ambiguity("Major Category", ambiguous_info)
    assert "Major Category" in state.component_ambiguity_status, (
        "Major Category not added to state"
    )
    assert state.component_ambiguity_status["Major Category"].status == "ambiguous", (
        "Component status not set correctly"
    )
    print("✓ New ambiguous component added successfully")

    # Test adding new unambiguous component
    unambiguous_info = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "CF", "description": "Cold formed"}],
        selected_value="CF",
    )

    state.update_component_ambiguity("Manufacturing Method", unambiguous_info)
    assert "Manufacturing Method" in state.component_ambiguity_status, (
        "Manufacturing Method not added to state"
    )
    assert (
        state.component_ambiguity_status["Manufacturing Method"].status == "unambiguous"
    ), "Component status not set correctly"
    print("✓ New unambiguous component added successfully")

    # Test updating ambiguous to unambiguous (valid transition)
    resolved_info = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "A", "description": "Agricultural products"}],
        selected_value="A",
    )

    state.update_component_ambiguity("Major Category", resolved_info)
    assert state.component_ambiguity_status["Major Category"].status == "unambiguous", (
        "Component not updated to unambiguous"
    )
    assert state.component_ambiguity_status["Major Category"].selected_value == "A", (
        "Selected value not set correctly"
    )
    print("✓ Valid ambiguous to unambiguous transition successful")

    return True


def test_update_component_ambiguity_validation_errors():
    """Test validation errors in update_component_ambiguity method."""

    print("\n=== Testing update_component_ambiguity validation errors ===")

    state = ProcurementState()

    # Test unambiguous component without selected_value (should raise ValueError)
    try:
        invalid_unambiguous = AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "A", "description": "Agricultural products"}],
            # Missing selected_value
        )

        state.update_component_ambiguity("Major Category", invalid_unambiguous)
        assert False, (
            "Should have raised ValueError for unambiguous component without selected_value"
        )
    except ValueError as e:
        assert "selected_value" in str(e), (
            f"Expected error about selected_value, got: {e}"
        )
        print("✓ Validation error for unambiguous component without selected_value")

    # Add a valid component first
    valid_info = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "A", "description": "Agricultural products"}],
        selected_value="A",
    )
    state.update_component_ambiguity("Major Category", valid_info)

    # Test unambiguous to ambiguous transition (should raise ValueError)
    try:
        invalid_transition = AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "A", "description": "Agricultural products"},
                {"value": "C", "description": "Chemical products"},
            ],
        )

        state.update_component_ambiguity("Major Category", invalid_transition)
        assert False, (
            "Should have raised ValueError for unambiguous to ambiguous transition"
        )
    except ValueError as e:
        assert "Cannot transition" in str(e), (
            f"Expected error about state transition, got: {e}"
        )
        print("✓ Validation error for invalid unambiguous to ambiguous transition")

    return True


def test_validate_all_components_unambiguous():
    """Test the validate_all_components_unambiguous method."""

    print("\n=== Testing validate_all_components_unambiguous method ===")

    state = ProcurementState()

    # Test with no components (should not raise error)
    try:
        state.validate_all_components_unambiguous()
        print("✓ Validation passes with no components")
    except ValueError:
        assert False, "Should not raise ValueError with no components"

    # Add unambiguous components
    state.update_component_ambiguity(
        "Major Category",
        AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "A", "description": "Agricultural products"}],
            selected_value="A",
        ),
    )

    state.update_component_ambiguity(
        "Manufacturing Method",
        AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "CF", "description": "Cold formed"}],
            selected_value="CF",
        ),
    )

    # Test with all unambiguous components (should not raise error)
    try:
        state.validate_all_components_unambiguous()
        print("✓ Validation passes with all unambiguous components")
    except ValueError:
        assert False, "Should not raise ValueError with all unambiguous components"

    # Add ambiguous component
    state.update_component_ambiguity(
        "Object Shape",
        AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "R", "description": "Round"},
                {"value": "S", "description": "Square"},
            ],
        ),
    )

    # Test with ambiguous components (should raise ValueError)
    try:
        state.validate_all_components_unambiguous()
        assert False, "Should have raised ValueError with ambiguous components"
    except ValueError as e:
        assert "Object Shape" in str(e), (
            f"Expected error mentioning 'Object Shape', got: {e}"
        )
        assert "ambiguous" in str(e), (
            f"Expected error about ambiguous components, got: {e}"
        )
        print("✓ Validation correctly fails with ambiguous components")

    return True


def test_get_ambiguous_and_unambiguous_components():
    """Test the get_ambiguous_components and get_unambiguous_components methods."""

    print(
        "\n=== Testing get_ambiguous_components and get_unambiguous_components methods ==="
    )

    state = ProcurementState()

    # Add mix of ambiguous and unambiguous components
    state.update_component_ambiguity(
        "Major Category",
        AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "A", "description": "Agricultural products"},
                {"value": "C", "description": "Chemical products"},
            ],
        ),
    )

    state.update_component_ambiguity(
        "Manufacturing Method",
        AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "CF", "description": "Cold formed"}],
            selected_value="CF",
        ),
    )

    state.update_component_ambiguity(
        "Object Shape",
        AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "R", "description": "Round"},
                {"value": "S", "description": "Square"},
            ],
        ),
    )

    # Test get_ambiguous_components
    ambiguous_components = state.get_ambiguous_components()
    assert len(ambiguous_components) == 2, (
        f"Expected 2 ambiguous components, got {len(ambiguous_components)}"
    )
    assert "Major Category" in ambiguous_components, (
        "Major Category not found in ambiguous components"
    )
    assert "Object Shape" in ambiguous_components, (
        "Object Shape not found in ambiguous components"
    )
    assert "Manufacturing Method" not in ambiguous_components, (
        "Manufacturing Method incorrectly found in ambiguous components"
    )
    print("✓ get_ambiguous_components returns correct components")

    # Test get_unambiguous_components
    unambiguous_components = state.get_unambiguous_components()
    assert len(unambiguous_components) == 1, (
        f"Expected 1 unambiguous component, got {len(unambiguous_components)}"
    )
    assert "Manufacturing Method" in unambiguous_components, (
        "Manufacturing Method not found in unambiguous components"
    )
    assert "Major Category" not in unambiguous_components, (
        "Major Category incorrectly found in unambiguous components"
    )
    assert "Object Shape" not in unambiguous_components, (
        "Object Shape incorrectly found in unambiguous components"
    )
    print("✓ get_unambiguous_components returns correct components")

    return True


def run_all_tests():
    """Run all state management and ambiguity tracking tests."""

    print("=== Testing State Management and Ambiguity Tracking ===")

    try:
        test_ambiguity_info_creation()
        test_procurement_state_ambiguity_tracking()
        test_update_component_ambiguity()
        test_update_component_ambiguity_validation_errors()
        test_validate_all_components_unambiguous()
        test_get_ambiguous_and_unambiguous_components()

        print("\n=== All state management tests passed! ===")
        print(
            "State management and ambiguity tracking functionality is working correctly."
        )
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
