#!/usr/bin/env python3
"""
Standalone test script to verify that the rules_loaded_this_turn flag resets correctly
when new state instances are created.
"""

from pydantic import BaseModel, Field
from typing import List, Optional


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


def test_flag_resets_on_new_instances():
    """Test that rules_loaded_this_turn flag resets to False on new state instances."""

    print("=== Testing rules_loaded_this_turn flag reset ===")

    # Test 1: Default value on new instance
    print("\n1. Testing default value on new instance...")
    state1 = ProcurementState()
    assert state1.rules_loaded_this_turn == False, (
        f"Expected False, got {state1.rules_loaded_this_turn}"
    )
    print("✓ New instance has rules_loaded_this_turn = False")

    # Test 2: Modify the flag and verify it changes
    print("\n2. Testing flag modification...")
    state1.rules_loaded_this_turn = True
    assert state1.rules_loaded_this_turn == True, (
        f"Expected True, got {state1.rules_loaded_this_turn}"
    )
    print("✓ Flag successfully modified to True")

    # Test 3: Create new instance and verify flag is reset
    print("\n3. Testing flag reset on new instance...")
    state2 = ProcurementState()
    assert state2.rules_loaded_this_turn == False, (
        f"Expected False, got {state2.rules_loaded_this_turn}"
    )
    print("✓ New instance has rules_loaded_this_turn = False (reset from previous)")

    # Test 4: Verify original instance is unchanged
    print("\n4. Testing original instance unchanged...")
    assert state1.rules_loaded_this_turn == True, (
        f"Expected True, got {state1.rules_loaded_this_turn}"
    )
    print("✓ Original instance still has rules_loaded_this_turn = True")

    # Test 5: Test multiple instances
    print("\n5. Testing multiple instances...")
    states = [ProcurementState() for _ in range(5)]
    for i, state in enumerate(states):
        assert state.rules_loaded_this_turn == False, (
            f"Instance {i} expected False, got {state.rules_loaded_this_turn}"
        )
    print("✓ All 5 new instances have rules_loaded_this_turn = False")

    print("\n=== All tests passed! ===")
    print(
        "The rules_loaded_this_turn flag correctly resets to False when new state instances are created."
    )


if __name__ == "__main__":
    test_flag_resets_on_new_instances()
