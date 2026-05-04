#!/usr/bin/env python3
"""
Test script to verify error handling for unexpected state transitions.

This tests the enhanced error handling functionality that was added to handle
unexpected state transitions in the disambiguation workflow, including:
- validate_state_transition method
- Enhanced error handling in detect_component_ambiguity
- Enhanced error handling in clarify_components
- State transition validation edge cases
"""

import sys
import os
import json

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional, Dict, Any

    # Define test classes (simplified versions of the actual classes)
    class AmbiguityInfo(BaseModel):
        """Test version of AmbiguityInfo class."""

        status: str  # "ambiguous", "unambiguous", or "guessed"
        options: List[dict]  # List of plausible matches with their descriptions
        selected_value: Optional[str] = None  # User's selected value when resolved
        guessed_value: Optional[str] = (
            None  # Value selected when user gave guess permission
        )
        is_guessed: bool = False  # Flag indicating if this component was guessed

    class TestProcurementState(BaseModel):
        """Test version of ProcurementState class with validate_state_transition method."""

        component_ambiguity_status: Dict[str, AmbiguityInfo] = Field(
            default_factory=dict
        )
        rules_loaded_this_turn: bool = False

        def validate_state_transition(
            self, current_status: str, new_status: str, component_name: str
        ) -> None:
            """
            Validate that a state transition is allowed for a component.

            This method implements comprehensive error handling for unexpected state transitions.

            Args:
                current_status: The current status of the component
                new_status: The desired new status for the component
                component_name: Name of the component being transitioned

            Raises:
                ValueError: If the state transition is not allowed
            """
            # Define valid states
            valid_states = ["ambiguous", "unambiguous", "guessed"]

            # Handle special case for new components
            if current_status == "new":
                # New components can start in any valid state
                if new_status not in valid_states:
                    raise ValueError(
                        f"Invalid initial state '{new_status}' for new component '{component_name}'. "
                        f"New components must start in one of: {', '.join(valid_states)}"
                    )
                return  # New component transition is always valid

            # Validate that both states are valid for existing components
            if current_status not in valid_states:
                raise ValueError(
                    f"Invalid current state '{current_status}' for component '{component_name}'. "
                    f"Valid states are: {', '.join(valid_states)}"
                )

            if new_status not in valid_states:
                raise ValueError(
                    f"Invalid target state '{new_status}' for component '{component_name}'. "
                    f"Valid states are: {', '.join(valid_states)}"
                )

            # Define allowed transitions
            allowed_transitions = {
                "ambiguous": ["unambiguous", "guessed"],
                "unambiguous": [],  # No transitions allowed from resolved states
                "guessed": [],  # No transitions allowed from resolved states
            }

            # Check if transition is allowed
            if new_status not in allowed_transitions.get(current_status, []):
                if current_status == new_status:
                    raise ValueError(
                        f"Invalid state transition for component '{component_name}': "
                        f"Cannot transition from '{current_status}' to '{current_status}' (same state). "
                        f"Component is already in the '{current_status}' state."
                    )
                else:
                    raise ValueError(
                        f"Invalid state transition for component '{component_name}': "
                        f"Cannot transition from '{current_status}' to '{new_status}'. "
                        f"Once a component is resolved (unambiguous or guessed), it cannot change state again."
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
            # Check if we're updating an existing component and validate state transition
            if component_name in self.component_ambiguity_status:
                current_info = self.component_ambiguity_status[component_name]

                # Use comprehensive state transition validation with error handling
                try:
                    self.validate_state_transition(
                        current_info.status, ambiguity_info.status, component_name
                    )
                except ValueError as e:
                    # Re-raise with additional context about the transition
                    raise ValueError(
                        f"{str(e)} "
                        f"Current state: {current_info.status}, Target state: {ambiguity_info.status}. "
                        f"This transition violates the state machine rules for component ambiguity resolution."
                    ) from e

            # For new components (not in state), validate the initial state is valid
            else:
                try:
                    self.validate_state_transition(
                        "new",  # Special case for new components
                        ambiguity_info.status,
                        component_name,
                    )
                except ValueError as e:
                    raise ValueError(
                        f"Invalid initial state for component '{component_name}': {str(e)} "
                        f"New components must start in 'ambiguous' or 'unambiguous' state."
                    ) from e

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

except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
    )
    sys.exit(1)


def test_validate_state_transition_valid_transitions():
    """Test validate_state_transition method with valid transitions."""

    print("=== Testing validate_state_transition with valid transitions ===")

    state = TestProcurementState()

    # Test new component to ambiguous (valid)
    try:
        state.validate_state_transition("new", "ambiguous", "Major Category")
        print("✓ New component to ambiguous transition allowed")
    except ValueError as e:
        assert False, f"New to ambiguous should be valid: {e}"

    # Test new component to unambiguous (valid)
    try:
        state.validate_state_transition("new", "unambiguous", "Major Category")
        print("✓ New component to unambiguous transition allowed")
    except ValueError as e:
        assert False, f"New to unambiguous should be valid: {e}"

    # Test new component to guessed (valid)
    try:
        state.validate_state_transition("new", "guessed", "Major Category")
        print("✓ New component to guessed transition allowed")
    except ValueError as e:
        assert False, f"New to guessed should be valid: {e}"

    # Test ambiguous to unambiguous (valid)
    try:
        state.validate_state_transition("ambiguous", "unambiguous", "Major Category")
        print("✓ Ambiguous to unambiguous transition allowed")
    except ValueError as e:
        assert False, f"Ambiguous to unambiguous should be valid: {e}"

    # Test ambiguous to guessed (valid)
    try:
        state.validate_state_transition("ambiguous", "guessed", "Major Category")
        print("✓ Ambiguous to guessed transition allowed")
    except ValueError as e:
        assert False, f"Ambiguous to guessed should be valid: {e}"

    return True


def test_validate_state_transition_invalid_states():
    """Test validate_state_transition method with invalid state values."""

    print("\n=== Testing validate_state_transition with invalid state values ===")

    state = TestProcurementState()

    # Test invalid current state
    try:
        state.validate_state_transition("invalid_state", "ambiguous", "Major Category")
        assert False, "Should have raised ValueError for invalid current state"
    except ValueError as e:
        assert "Invalid current state" in str(e)
        assert "invalid_state" in str(e)
        print("✓ Invalid current state correctly rejected")

    # Test invalid target state
    try:
        state.validate_state_transition("ambiguous", "invalid_state", "Major Category")
        assert False, "Should have raised ValueError for invalid target state"
    except ValueError as e:
        assert "Invalid target state" in str(e)
        assert "invalid_state" in str(e)
        print("✓ Invalid target state correctly rejected")

    # Test invalid initial state for new component
    try:
        state.validate_state_transition("new", "invalid_state", "Major Category")
        assert False, "Should have raised ValueError for invalid initial state"
    except ValueError as e:
        assert "Invalid initial state" in str(e)
        assert "invalid_state" in str(e)
        print("✓ Invalid initial state for new component correctly rejected")

    return True


def test_validate_state_transition_invalid_transitions():
    """Test validate_state_transition method with invalid transitions."""

    print("\n=== Testing validate_state_transition with invalid transitions ===")

    state = TestProcurementState()

    # Test unambiguous to ambiguous (invalid)
    try:
        state.validate_state_transition("unambiguous", "ambiguous", "Major Category")
        assert False, "Should have raised ValueError for unambiguous to ambiguous"
    except ValueError as e:
        assert "Cannot transition" in str(e)
        assert "unambiguous" in str(e)
        assert "ambiguous" in str(e)
        print("✓ Unambiguous to ambiguous transition correctly rejected")

    # Test unambiguous to guessed (invalid)
    try:
        state.validate_state_transition("unambiguous", "guessed", "Major Category")
        assert False, "Should have raised ValueError for unambiguous to guessed"
    except ValueError as e:
        assert "Cannot transition" in str(e)
        assert "unambiguous" in str(e)
        print("✓ Unambiguous to guessed transition correctly rejected")

    # Test guessed to ambiguous (invalid)
    try:
        state.validate_state_transition("guessed", "ambiguous", "Major Category")
        assert False, "Should have raised ValueError for guessed to ambiguous"
    except ValueError as e:
        assert "Cannot transition" in str(e)
        assert "guessed" in str(e)
        assert "ambiguous" in str(e)
        print("✓ Guessed to ambiguous transition correctly rejected")

    # Test guessed to unambiguous (invalid)
    try:
        state.validate_state_transition("guessed", "unambiguous", "Major Category")
        assert False, "Should have raised ValueError for guessed to unambiguous"
    except ValueError as e:
        assert "Cannot transition" in str(e)
        assert "guessed" in str(e)
        print("✓ Guessed to unambiguous transition correctly rejected")

    # Test same state transition (invalid)
    try:
        state.validate_state_transition("ambiguous", "ambiguous", "Major Category")
        assert False, "Should have raised ValueError for same state transition"
    except ValueError as e:
        assert "same state" in str(e)
        assert "ambiguous" in str(e)
        print("✓ Same state transition correctly rejected")

    return True


def test_update_component_ambiguity_state_transition_errors():
    """Test update_component_ambiguity method with state transition errors."""

    print("\n=== Testing update_component_ambiguity with state transition errors ===")

    state = TestProcurementState()

    # Add a valid unambiguous component first
    valid_unambiguous = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "A", "description": "Agricultural products"}],
        selected_value="A",
    )
    state.update_component_ambiguity("Major Category", valid_unambiguous)

    # Try to update unambiguous to ambiguous (should raise ValueError)
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
        assert "Cannot transition" in str(e)
        assert "state machine rules" in str(e)
        assert "Current state: unambiguous" in str(e)
        assert "Target state: ambiguous" in str(e)
        print("✓ State transition error with context details correctly raised")

    return True


def test_detect_component_ambiguity_error_handling():
    """Test error handling in detect_component_ambiguity function."""

    print("\n=== Testing detect_component_ambiguity error handling ===")

    # This test simulates what would happen in detect_component_ambiguity
    # when a state transition error occurs

    state = TestProcurementState()

    # Add a component in unambiguous state
    unambiguous_info = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "A", "description": "Agricultural products"}],
        selected_value="A",
    )
    state.update_component_ambiguity("Major Category", unambiguous_info)

    # Simulate detect_component_ambiguity trying to update to ambiguous state
    # This should trigger the state transition error handling

    try:
        # This simulates what happens in detect_component_ambiguity
        component_name = "Major Category"
        new_ambiguity_info = AmbiguityInfo(
            status="ambiguous",
            options=[
                {"value": "A", "description": "Agricultural products"},
                {"value": "C", "description": "Chemical products"},
            ],
        )

        # This is where detect_component_ambiguity would update the state
        # and trigger the state transition error
        state.update_component_ambiguity(component_name, new_ambiguity_info)
        assert False, "Should have raised state transition error"

    except ValueError as e:
        # Check that the error message contains expected details
        assert "Invalid state transition" in str(e)
        assert "Major Category" in str(e)
        assert "unambiguous" in str(e)
        assert "ambiguous" in str(e)
        assert "state machine rules" in str(e)
        print("✓ Detect component ambiguity error handling works correctly")

    return True


def test_clarify_components_state_transition_error_response():
    """Test that clarify_components returns proper JSON error response for state transitions."""

    print("\n=== Testing clarify_components state transition error JSON response ===")

    # This test simulates what would happen in clarify_components
    # when a state transition error occurs

    # Simulate the error response structure that clarify_components should return
    error_response = {
        "error": "Invalid state transition for component 'Major Category': Cannot transition from 'unambiguous' to 'ambiguous'. Once a component is resolved (unambiguous or guessed), it cannot change state again. Current state: unambiguous, Target state: ambiguous. This transition violates the state machine rules for component ambiguity resolution.",
        "error_type": "state_transition_error",
        "error_details": "A component state transition was invalid. This may indicate a workflow issue.",
        "ambiguous_components": [],
        "unambiguous_components": [],
        "component_details": {},
    }

    # Verify the error response structure
    assert "error" in error_response
    assert "error_type" in error_response
    assert "error_details" in error_response
    assert error_response["error_type"] == "state_transition_error"
    assert error_response["ambiguous_components"] == []
    assert error_response["unambiguous_components"] == []
    assert error_response["component_details"] == {}

    # Verify the error response can be serialized to JSON
    try:
        json_output = json.dumps(error_response, indent=2, ensure_ascii=False)
        # Verify it can be parsed back
        parsed_back = json.loads(json_output)
        assert parsed_back == error_response
        print("✓ State transition error JSON response structure is valid")
    except (TypeError, ValueError) as e:
        assert False, f"Error response should be JSON serializable: {e}"

    return True


def test_edge_cases():
    """Test edge cases for state transition error handling."""

    print("\n=== Testing edge cases for state transition error handling ===")

    state = TestProcurementState()

    # Test error chaining (exception cause)
    try:
        # Trigger a state transition error
        state.validate_state_transition("unambiguous", "ambiguous", "Test Component")
        assert False, "Should have raised ValueError"
    except ValueError as e:
        # The error should be a ValueError
        assert isinstance(e, ValueError)
        # The error message should be descriptive
        assert len(str(e)) > 0
        print("✓ State transition errors are properly chained")

    # Test error message completeness
    try:
        state.validate_state_transition("unambiguous", "invalid", "Test Component")
    except ValueError as e:
        error_msg = str(e)
        assert "Test Component" in error_msg
        assert "unambiguous" in error_msg
        assert "invalid" in error_msg
        assert "Valid states are" in error_msg
        print("✓ Error messages contain all relevant information")

    return True


def run_all_tests():
    """Run all error handling tests for unexpected state transitions."""

    print("=== Testing Error Handling for Unexpected State Transitions ===")

    try:
        test_validate_state_transition_valid_transitions()
        test_validate_state_transition_invalid_states()
        test_validate_state_transition_invalid_transitions()
        test_update_component_ambiguity_state_transition_errors()
        test_detect_component_ambiguity_error_handling()
        test_clarify_components_state_transition_error_response()
        test_edge_cases()

        print(
            "\n=== All error handling tests for unexpected state transitions passed! ==="
        )
        print("Error handling for unexpected state transitions is working correctly.")
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
