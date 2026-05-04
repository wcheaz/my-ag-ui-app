#!/usr/bin/env python3
"""
Simple test script to verify error handling improvements in clarify_components tool.
"""

import json
import os
import sys
import traceback
from unittest.mock import Mock, patch, MagicMock

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

# Mock the required modules that might not be available
sys.modules["llama_index.core"] = MagicMock()
sys.modules["llama_index.embeddings.huggingface"] = MagicMock()
sys.modules["src.rag.index"] = MagicMock()
sys.modules["src.rag.settings"] = MagicMock()
sys.modules["src.rag.citation"] = MagicMock()
sys.modules["src.rag.query"] = MagicMock()

# Mock numpy to avoid dependency issues
sys.modules["numpy"] = MagicMock()

# Now import the agent module
try:
    from agent import (
        clarify_components,
        ProcurementState,
        AmbiguityInfo,
    )

    print("✓ Successfully imported agent module")
except Exception as e:
    print(f"✗ Failed to import agent module: {e}")
    traceback.print_exc()
    sys.exit(1)

# Mock other required modules
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps


def test_error_handling():
    """Test error handling in clarify_components."""
    print("\n=== Testing Error Handling ===")

    # Create a mock ProcurementState
    state = ProcurementState(rules_loaded_this_turn=True)

    # Create a mock RunContext
    mock_ctx = Mock(spec=RunContext)
    mock_ctx.deps = StateDeps(state=state)

    tests_passed = 0
    tests_total = 0

    # Test 1: Invalid input validation
    tests_total += 1
    print("\n1. Testing invalid input validation...")
    try:
        result = clarify_components(mock_ctx, "")
        result_data = json.loads(result)

        if (
            "error" in result_data
            and "user_description must be a non-empty string" in result_data["error"]
        ):
            print("✓ Invalid input validation works correctly")
            tests_passed += 1
        else:
            print("✗ Invalid input validation failed")
            print(f"  Expected error message, got: {result_data}")
    except Exception as e:
        print(f"✗ Invalid input test failed with exception: {e}")
        traceback.print_exc()

    # Test 2: Rules not loaded validation
    tests_total += 1
    print("\n2. Testing rules not loaded validation...")
    try:
        state.rules_loaded_this_turn = False
        result = clarify_components(mock_ctx, "test description")
        result_data = json.loads(result)

        if (
            "error" in result_data
            and "must call read_code_generation_file" in result_data["error"]
        ):
            print("✓ Rules not loaded validation works correctly")
            tests_passed += 1
        else:
            print("✗ Rules not loaded validation failed")
            print(f"  Expected error message, got: {result_data}")
    except Exception as e:
        print(f"✗ Rules not loaded test failed with exception: {e}")
        traceback.print_exc()

    # Reset rules loaded for next tests
    state.rules_loaded_this_turn = True

    # Test 3: File not found error handling
    tests_total += 1
    print("\n3. Testing file not found error handling...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.side_effect = FileNotFoundError("Test file not found")

            result = clarify_components(mock_ctx, "test description")
            result_data = json.loads(result)

            if (
                "error" in result_data
                and "file_not_found" in result_data.get("error_type", "")
                and "Test file not found" in result_data["error"]
            ):
                print("✓ File not found error handling works correctly")
                tests_passed += 1
            else:
                print("✗ File not found error handling failed")
                print(f"  Expected error_type=file_not_found, got: {result_data}")
    except Exception as e:
        print(f"✗ File not found test failed with exception: {e}")
        traceback.print_exc()

    # Test 4: Runtime error handling
    tests_total += 1
    print("\n4. Testing runtime error handling...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.side_effect = RuntimeError("Test runtime error")

            result = clarify_components(mock_ctx, "test description")
            result_data = json.loads(result)

            if (
                "error" in result_data
                and "runtime_error" in result_data.get("error_type", "")
                and "Test runtime error" in result_data["error"]
            ):
                print("✓ Runtime error handling works correctly")
                tests_passed += 1
            else:
                print("✗ Runtime error handling failed")
                print(f"  Expected error_type=runtime_error, got: {result_data}")
    except Exception as e:
        print(f"✗ Runtime error test failed with exception: {e}")
        traceback.print_exc()

    # Test 5: Valid JSON format in error responses
    tests_total += 1
    print("\n5. Testing JSON format in error responses...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.side_effect = Exception("Test error")

            result = clarify_components(mock_ctx, "test description")

            # Verify result is valid JSON
            try:
                result_data = json.loads(result)
                if isinstance(result_data, dict):
                    print("✓ Error responses are valid JSON")
                    tests_passed += 1
                else:
                    print("✗ Error response is not a dictionary")
            except json.JSONDecodeError:
                print("✗ Error response is not valid JSON")
    except Exception as e:
        print(f"✗ JSON format test failed with exception: {e}")
        traceback.print_exc()

    # Test 6: Error response structure
    tests_total += 1
    print("\n6. Testing error response structure...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.side_effect = Exception("Test error")

            result = clarify_components(mock_ctx, "test description")
            result_data = json.loads(result)

            required_fields = [
                "error",
                "ambiguous_components",
                "unambiguous_components",
                "component_details",
            ]
            if all(field in result_data for field in required_fields):
                print("✓ Error response structure is correct")
                tests_passed += 1
            else:
                print("✗ Error response structure is incorrect")
                missing_fields = [
                    field for field in required_fields if field not in result_data
                ]
                print(f"  Missing fields: {missing_fields}")
    except Exception as e:
        print(f"✗ Error response structure test failed with exception: {e}")
        traceback.print_exc()

    print(f"\n=== Test Results: {tests_passed}/{tests_total} tests passed ===")

    if tests_passed == tests_total:
        print("✓ All error handling tests passed!")
        return True
    else:
        print("✗ Some error handling tests failed")
        return False


if __name__ == "__main__":
    success = test_error_handling()
    if success:
        print("\n🎉 Error handling implementation verified successfully!")
    else:
        print("\n❌ Error handling implementation has issues.")
        sys.exit(1)
