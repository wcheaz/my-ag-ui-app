#!/usr/bin/env python3
"""
Test script to verify comprehensive JSON error handling in clarify_components tool.
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


def test_json_error_handling():
    """Test comprehensive JSON error handling in clarify_components."""
    print("\n=== Testing JSON Error Handling ===")

    # Create a mock ProcurementState
    state = ProcurementState(rules_loaded_this_turn=True)

    # Create a mock RunContext
    mock_ctx = Mock(spec=RunContext)
    mock_ctx.deps = StateDeps(state=state)

    tests_passed = 0
    tests_total = 0

    # Test 1: Valid JSON output in normal response
    tests_total += 1
    print("\n1. Testing valid JSON output in normal response...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = """
### First Letter - Major Categories
| A | Agricultural products | Products derived from agriculture or farming |
| B | Chemical products | Chemical substances and compounds |

### Second Letter - Manufacturing Method
| A | Casting | Pouring liquid material into a mold |
| B | Forging | Shaping metal using compressive forces |
"""

            result = clarify_components(mock_ctx, "agricultural casting products")

            # Verify result is valid JSON
            try:
                result_data = json.loads(result)
                if (
                    isinstance(result_data, dict)
                    and "ambiguous_components" in result_data
                ):
                    print("✓ Normal response returns valid JSON")
                    tests_passed += 1
                else:
                    print("✗ Normal response JSON structure is invalid")
            except json.JSONDecodeError:
                print("✗ Normal response is not valid JSON")
    except Exception as e:
        print(f"✗ Normal response test failed with exception: {e}")

    # Test 2: Valid JSON output in error response
    tests_total += 1
    print("\n2. Testing valid JSON output in error response...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.side_effect = RuntimeError("Test runtime error")

            result = clarify_components(mock_ctx, "test description")

            # Verify error response is valid JSON
            try:
                result_data = json.loads(result)
                if isinstance(result_data, dict) and "error" in result_data:
                    print("✓ Error response returns valid JSON")
                    tests_passed += 1
                else:
                    print("✗ Error response JSON structure is invalid")
            except json.JSONDecodeError:
                print("✗ Error response is not valid JSON")
    except Exception as e:
        print(f"✗ Error response test failed with exception: {e}")

    # Test 3: JSON serialization error handling (simulate unserializable data)
    tests_total += 1
    print("\n3. Testing JSON serialization error handling...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = "test content"

            # Mock get_component_extraction_results to return unserializable data
            with patch("agent.get_component_extraction_results") as mock_extract:
                # Create a circular reference that can't be serialized
                circular_ref = {}
                circular_ref["self"] = circular_ref
                mock_extract.return_value = {
                    "ambiguous_components": [{"circular": circular_ref}],
                    "unambiguous_components": [],
                    "no_match_components": [],
                    "component_details": {},
                }

                result = clarify_components(mock_ctx, "test description")

                # Should handle component processing errors gracefully and still return valid JSON
                try:
                    # Try to parse as JSON first
                    result_data = json.loads(result)
                    if isinstance(result_data, dict):
                        # The function should handle component processing errors gracefully
                        # and return a valid response structure, even if some components fail
                        required_keys = [
                            "ambiguous_components",
                            "unambiguous_components",
                            "component_details",
                        ]
                        if all(key in result_data for key in required_keys):
                            print(
                                "✓ JSON serialization error in component processing handled gracefully"
                            )
                            tests_passed += 1
                        else:
                            print(
                                "✗ JSON serialization error response missing required keys"
                            )
                            print(
                                f"DEBUG: Missing keys: {[k for k in required_keys if k not in result_data]}"
                            )
                    else:
                        print("✗ JSON serialization error response is not a dictionary")
                        print(f"DEBUG: Full result: {result}")
                except json.JSONDecodeError as e:
                    # If it's not JSON, it should be a plain text fallback
                    print(f"DEBUG: JSON decode error: {e}")
                    print(f"DEBUG: Raw result: {result}")
                    if "CRITICAL ERROR" in result and "JSON Error" in result:
                        print(
                            "✓ JSON serialization error handled with plain text fallback"
                        )
                        tests_passed += 1
                    else:
                        print("✗ JSON serialization error fallback is incorrect")
    except Exception as e:
        print(f"✗ JSON serialization error test failed with exception: {e}")
        traceback.print_exc()

    # Test 4: Unicode handling in JSON
    tests_total += 1
    print("\n4. Testing Unicode handling in JSON...")
    try:
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = """
### First Letter - Major Categories
| A | Agricultural products | Products derived from agriculture or farming |
| B | Chemical products | Chemical substances and compounds |
"""

            result = clarify_components(mock_ctx, "测试 unicode 字符")

            # Verify Unicode is handled correctly
            try:
                result_data = json.loads(result)
                if isinstance(result_data, dict):
                    print("✓ Unicode characters handled correctly in JSON")
                    tests_passed += 1
                else:
                    print("✗ Unicode handling failed")
            except json.JSONDecodeError:
                print("✗ Unicode handling caused JSON decode error")
    except Exception as e:
        print(f"✗ Unicode handling test failed with exception: {e}")

    print(f"\n=== JSON Error Handling Test Results ===")
    print(f"Tests passed: {tests_passed}/{tests_total}")

    if tests_passed == tests_total:
        print("✓ All JSON error handling tests passed!")
        return True
    else:
        print("✗ Some JSON error handling tests failed!")
        return False


if __name__ == "__main__":
    success = test_json_error_handling()
    sys.exit(0 if success else 1)
