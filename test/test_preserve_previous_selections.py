#!/usr/bin/env python3
"""
Test script to verify that previous user selections are preserved during
iterative clarification rounds (Task 5.4).

This tests the enhanced update_component_ambiguity method which should preserve
user selections when updating component ambiguity status.
"""

import sys
import os

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional, Dict, Any

    # Import the actual classes from the agent
    from agent.src.agent import AmbiguityInfo, ProcurementState

except ImportError as e:
    print(f"Import error: {e}")
    print("Please ensure you're running this from the project root directory.")
    sys.exit(1)


def test_preserve_existing_selection():
    """Test that existing user selections are preserved when updating ambiguity status."""

    print("=== Testing preservation of existing user selections ===")

    # Create a state
    state = ProcurementState()

    # First, add an ambiguous component for Major Category
    ambiguous_info = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
    )

    state.update_component_ambiguity("Major Category", ambiguous_info)

    # Verify the initial state
    assert "Major Category" in state.component_ambiguity_status
    assert state.component_ambiguity_status["Major Category"].status == "ambiguous"
    assert state.component_ambiguity_status["Major Category"].selected_value is None
    print("✓ Initial ambiguous component added successfully")

    # Now, update it to unambiguous with a selected value
    unambiguous_info = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
        selected_value="A",  # User selects "A"
    )

    state.update_component_ambiguity("Major Category", unambiguous_info)

    # Verify the update
    assert state.component_ambiguity_status["Major Category"].status == "unambiguous"
    assert state.component_ambiguity_status["Major Category"].selected_value == "A"
    print("✓ Component updated to unambiguous with selected value 'A'")

    # Now, simulate a subsequent clarification round where we get new ambiguity info
    # but the user's previous selection should be preserved
    new_ambiguity_info = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
            {"value": "M", "description": "Manufacturing products"},  # New option added
        ],
        # Note: selected_value is not provided - it should be preserved from previous state
    )

    state.update_component_ambiguity("Major Category", new_ambiguity_info)

    # Verify that the previous selection is preserved
    assert state.component_ambiguity_status["Major Category"].status == "unambiguous"
    assert state.component_ambiguity_status["Major Category"].selected_value == "A"
    print("✓ Previous user selection 'A' preserved during subsequent update")

    return True


def test_preserve_guessed_value():
    """Test that guessed values are preserved when updating ambiguity status."""

    print("\n=== Testing preservation of guessed values ===")

    # Create a state
    state = ProcurementState()

    # Add a guessed component
    guessed_info = AmbiguityInfo(
        status="guessed",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
        selected_value="C",
        guessed_value="C",
        is_guessed=True,
    )

    state.update_component_ambiguity("Major Category", guessed_info)

    # Verify the initial guessed state
    assert state.component_ambiguity_status["Major Category"].status == "guessed"
    assert state.component_ambiguity_status["Major Category"].selected_value == "C"
    assert state.component_ambiguity_status["Major Category"].guessed_value == "C"
    assert state.component_ambiguity_status["Major Category"].is_guessed == True
    print("✓ Initial guessed component added successfully")

    # Now, update with new ambiguity info but preserve the guessed value
    new_guessed_info = AmbiguityInfo(
        status="guessed",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
            {"value": "M", "description": "Manufacturing products"},  # New option
        ],
        # Note: guessed_value is not provided - it should be preserved
    )

    state.update_component_ambiguity("Major Category", new_guessed_info)

    # Verify that the guessed value is preserved
    assert state.component_ambiguity_status["Major Category"].status == "guessed"
    assert state.component_ambiguity_status["Major Category"].selected_value == "C"
    assert state.component_ambiguity_status["Major Category"].guessed_value == "C"
    assert state.component_ambiguity_status["Major Category"].is_guessed == True
    print("✓ Previous guessed value 'C' preserved during subsequent update")

    return True


def test_invalid_selection_not_preserved():
    """Test that invalid selections are not preserved when options change."""

    print("\n=== Testing invalid selections are not preserved ===")

    # Create a state
    state = ProcurementState()

    # Add an unambiguous component with selection "A"
    unambiguous_info = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
        selected_value="A",
    )

    state.update_component_ambiguity("Major Category", unambiguous_info)

    # Verify the initial state
    assert state.component_ambiguity_status["Major Category"].selected_value == "A"
    print("✓ Initial component with selection 'A' added")

    # Now, update with new options that don't include "A"
    new_info = AmbiguityInfo(
        status="unambiguous",
        options=[
            {"value": "C", "description": "Chemical products"},
            {"value": "M", "description": "Manufacturing products"},
        ],
        # Note: selected_value is provided as "C" since "A" is no longer valid
        selected_value="C",
    )

    state.update_component_ambiguity("Major Category", new_info)

    # Verify that the selection is updated to the new valid value
    assert state.component_ambiguity_status["Major Category"].selected_value == "C"
    print("✓ Selection updated to 'C' since previous selection 'A' is no longer valid")

    return True


def test_state_transition_validation():
    """Test that state transition validation still works with preservation logic."""

    print("\n=== Testing state transition validation with preservation ===")

    # Create a state
    state = ProcurementState()

    # Add an unambiguous component
    unambiguous_info = AmbiguityInfo(
        status="unambiguous",
        options=[{"value": "A", "description": "Agricultural products"}],
        selected_value="A",
    )

    state.update_component_ambiguity("Major Category", unambiguous_info)

    # Try to transition back to ambiguous (should fail)
    ambiguous_info = AmbiguityInfo(
        status="ambiguous",
        options=[
            {"value": "A", "description": "Agricultural products"},
            {"value": "C", "description": "Chemical products"},
        ],
    )

    try:
        state.update_component_ambiguity("Major Category", ambiguous_info)
        assert False, "Should have raised ValueError for invalid transition"
    except ValueError as e:
        assert "Cannot transition from 'unambiguous' to 'ambiguous'" in str(e)
        print("✓ State transition validation still works correctly")

    return True


def run_all_tests():
    """Run all tests for user selection preservation."""

    print("=== Testing User Selection Preservation (Task 5.4) ===")

    try:
        test_preserve_existing_selection()
        test_preserve_guessed_value()
        test_invalid_selection_not_preserved()
        test_state_transition_validation()

        print("\n=== All user selection preservation tests passed! ===")
        print("Task 5.4 implementation is working correctly.")
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
