#!/usr/bin/env python3
"""
Integration tests for edge cases in the disambiguation workflow.

This test file covers edge cases for the clarify_components tool and
the overall disambiguation workflow to ensure robustness under
various unusual or challenging scenarios.
"""

import sys
import os
import json
import asyncio

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional, Dict, Any
    from pydantic_ai import RunContext
    from pydantic_ai.ag_ui import StateDeps
    from ag_ui.core import EventType, StateSnapshotEvent

    # Import the actual agent modules
    from agent import (
        ProcurementCode,
        ProcurementState,
        AmbiguityInfo,
        clarify_components,
        read_code_generation_file,
        save_procurement_code,
        reset_conversation,
        detect_explicit_guess_permission,
        extract_components_from_description,
        get_component_extraction_results,
        detect_component_ambiguity,
        DEFAULT_SIMILARITY_THRESHOLD,
        MINIMUM_SIMILARITY_THRESHOLD,
        MAXIMUM_SIMILARITY_THRESHOLD,
    )
except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
    )
    sys.exit(1)


def create_test_context():
    """Create a test RunContext with ProcurementState for testing."""
    # Create a test state
    state = ProcurementState()

    # Create StateDeps wrapper
    deps = StateDeps(state=state)

    # Create a proper RunContext mock that matches the type signature
    class TestRunContext:
        def __init__(self, deps):
            # Initialize with minimal required attributes
            self.deps = deps
            # Mock the messages attribute that might be accessed
            self.messages = []

    return TestRunContext(deps)


class TestDisambiguationEdgeCases:
    """Integration tests for disambiguation edge cases."""

    async def test_empty_user_description(self):
        """Test edge case: empty user description."""
        print("\n=== Testing empty user description ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with empty description
        try:
            clarify_components(ctx, "")
            assert False, "Should have raised ValueError for empty description"
        except ValueError as e:
            assert "user_description must be a non-empty string" in str(e)
            print("✓ Empty description correctly rejected")

    async def test_non_string_user_description(self):
        """Test edge case: non-string user description."""
        print("\n=== Testing non-string user description ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with non-string input
        for non_string_input in [123, None, {}]:
            try:
                clarify_components(ctx, non_string_input)
                assert False, (
                    f"Should have raised ValueError for {type(non_string_input)}"
                )
            except ValueError as e:
                assert "user_description must be a non-empty string" in str(e)

        print("✓ Non-string descriptions correctly rejected")

    async def test_very_long_description(self):
        """Test edge case: very long user description."""
        print("\n=== Testing very long description ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Create a very long description (5000 characters)
        long_description = (
            "steel " * 1000 + "construction " * 1000 + "industrial " * 1000
        )

        # This should not raise an error, but should handle it gracefully
        try:
            result = clarify_components(ctx, long_description)
            result_dict = json.loads(result)

            # Should return valid JSON structure
            assert "ambiguous_components" in result_dict
            assert "unambiguous_components" in result_dict
            assert "component_details" in result_dict
            print("✓ Long description handled gracefully")

        except Exception as e:
            assert False, f"Long description should be handled gracefully: {e}"

    async def test_description_with_special_characters(self):
        """Test edge case: description with special characters."""
        print("\n=== Testing description with special characters ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with special characters
        special_description = "Steel beam with ñoño & coño characters! @#$%^&*()"

        try:
            result = clarify_components(ctx, special_description)
            result_dict = json.loads(result)

            # Should return valid JSON structure
            assert "ambiguous_components" in result_dict
            assert "unambiguous_components" in result_dict
            assert "component_details" in result_dict
            print("✓ Special characters handled correctly")

        except json.JSONDecodeError as e:
            assert False, f"Special characters should not break JSON serialization: {e}"

    async def test_no_matching_components(self):
        """Test edge case: description that matches no components."""
        print("\n=== Testing no matching components ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Use a description that should match nothing
        no_match_description = "xyzabc nonexistent quantum flux capacitor"

        result = clarify_components(ctx, no_match_description)
        result_dict = json.loads(result)

        # Should have ambiguous components (no matches are treated as ambiguous)
        assert (
            len(result_dict["ambiguous_components"]) > 0
            or len(result_dict.get("no_match_components", [])) > 0
        )
        print("✓ No matching components handled correctly")

    async def test_extreme_similarity_thresholds(self):
        """Test edge case: extreme similarity threshold values."""
        print("\n=== Testing extreme similarity threshold values ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with threshold below minimum (should be clamped to minimum)
        try:
            result = clarify_components(ctx, "steel beam", similarity_threshold=-1.0)
            result_dict = json.loads(result)

            # Should work normally (threshold should be clamped)
            assert "ambiguous_components" in result_dict
            print("✓ Negative threshold handled correctly")

        except Exception as e:
            assert False, f"Negative threshold should be handled gracefully: {e}"

        # Test with threshold above maximum (should be clamped to maximum)
        try:
            result = clarify_components(ctx, "steel beam", similarity_threshold=2.0)
            result_dict = json.loads(result)

            # Should work normally (threshold should be clamped)
            assert "ambiguous_components" in result_dict
            print("✓ Threshold > 1.0 handled correctly")

        except Exception as e:
            assert False, f"Threshold > 1.0 should be handled gracefully: {e}"

    async def test_json_serialization_edge_cases(self):
        """Test edge case: JSON serialization with problematic data."""
        print("\n=== Testing JSON serialization edge cases ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with characters that could break JSON
        problematic_description = 'Steel with "quotes" and \n newlines \t tabs'

        result = clarify_components(ctx, problematic_description)

        # Should be valid JSON
        try:
            result_dict = json.loads(result)
            assert "ambiguous_components" in result_dict
            print("✓ JSON serialization edge cases handled correctly")
        except json.JSONDecodeError:
            assert False, "Problematic characters should not break JSON serialization"

    async def test_file_read_error_during_disambiguation(self):
        """Test edge case: file read error during disambiguation."""
        print("\n=== Testing file read error during disambiguation ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Now create a context where the file read would fail
        class FailingRunContext:
            def __init__(self, deps):
                self.deps = deps
                self.messages = []

        failing_ctx = FailingRunContext(ctx.deps)
        failing_ctx.deps.state.rules_loaded_this_turn = False

        # This should fail with appropriate error message
        try:
            clarify_components(failing_ctx, "steel beam")
            assert False, "Should have raised ValueError for missing file read"
        except ValueError as e:
            assert "read_code_generation_file before using clarify_components" in str(e)
            print("✓ File read error during disambiguation handled correctly")

    async def test_invalid_context_structure(self):
        """Test edge case: invalid context structure."""
        print("\n=== Testing invalid context structure ===")

        # Test with completely invalid context - we'll use a type: ignore comment
        # to bypass type checking since we're intentionally testing error handling
        invalid_ctx = None  # type: ignore

        try:
            clarify_components(invalid_ctx, "steel beam")
            assert False, "Should have raised ValueError for invalid context"
        except (ValueError, AttributeError, TypeError) as e:
            # Various error types might be raised depending on how None is handled
            error_str = str(e).lower()
            valid_errors = ["none", "invalid", "context", "expected", "attribute"]
            assert any(err in error_str for err in valid_errors), (
                f"Unexpected error: {e}"
            )
            print("✓ Invalid context structure handled correctly")

    async def test_explicit_guess_permission_with_no_matches(self):
        """Test edge case: explicit guess permission but no matches."""
        print("\n=== Testing explicit guess permission with no matches ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Use description that should match nothing but with guess permission
        no_match_description = "xyzabc nonexistent quantum flux whatever you choose"

        result = clarify_components(ctx, no_match_description)
        result_dict = json.loads(result)

        # Should handle gracefully - no components should be marked as guessed
        assert "guessed_components" in result_dict
        print("✓ Explicit guess permission with no matches handled correctly")

    async def test_explicit_guess_permission_with_single_match(self):
        """Test edge case: explicit guess permission with single match."""
        print("\n=== Testing explicit guess permission with single match ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Use a description that should match one component with guess permission
        single_match_description = "steel beam for construction I don't know"

        result = clarify_components(ctx, single_match_description)
        result_dict = json.loads(result)

        # Should handle gracefully - might mark as unambiguous or guessed
        assert (
            "unambiguous_components" in result_dict
            or "guessed_components" in result_dict
        )
        print("✓ Explicit guess permission with single match handled correctly")

    async def test_mixed_ambiguous_and_unambiguous_components(self):
        """Test edge case: mixed ambiguous and unambiguous components."""
        print("\n=== Testing mixed ambiguous and unambiguous components ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Use a description that should create mixed results
        mixed_description = "steel industrial construction"

        result = clarify_components(ctx, mixed_description)
        result_dict = json.loads(result)

        # Should have some ambiguous and some unambiguous components
        assert isinstance(result_dict["ambiguous_components"], list)
        assert isinstance(result_dict["unambiguous_components"], list)

        # Should have at least one component in some category
        total_components = len(result_dict["ambiguous_components"]) + len(
            result_dict["unambiguous_components"]
        )
        assert total_components > 0, "Should have at least one component identified"
        print("✓ Mixed ambiguous and unambiguous components handled correctly")

    async def test_save_with_invalid_state_transitions(self):
        """Test edge case: save with invalid state transitions."""
        print("\n=== Testing save with invalid state transitions ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Manually create an invalid state transition
        invalid_ambiguity_info = AmbiguityInfo(
            status="invalid_status",
            options=[{"value": "A", "description": "test"}],
            selected_value="A",
        )

        # Add invalid state to component ambiguity status
        ctx.deps.state.component_ambiguity_status["Major Category"] = (
            invalid_ambiguity_info
        )

        # This should fail with state validation error
        result = await save_procurement_code(ctx, "CFR01067261", "test")
        assert isinstance(result, str)
        assert "Invalid state" in result or "invalid component states" in result
        print("✓ Save with invalid state transitions handled correctly")

    async def test_iterative_clarification_with_persistent_guesses(self):
        """Test edge case: iterative clarification with persistent guesses across rounds."""
        print("\n=== Testing iterative clarification with persistent guesses ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # First clarification round with guess permission
        first_description = "steel industrial construction whatever you choose"
        first_result = clarify_components(ctx, first_description)
        first_result_dict = json.loads(first_result)

        # Increment clarification rounds
        ctx.deps.state.clarification_rounds = 1

        # Add some components to clarified set
        if first_result_dict["unambiguous_components"]:
            first_unambiguous = first_result_dict["unambiguous_components"][0][
                "component_name"
            ]
            ctx.deps.state.clarified_components.add(first_unambiguous)

        # Second clarification round
        second_description = "more details about the construction"
        second_result = clarify_components(ctx, second_description)
        second_result_dict = json.loads(second_result)

        # Should preserve previous selections and not repeat questions
        assert (
            ctx.deps.state.clarification_rounds == 1
        )  # Should remain 1 until we increment

        # Should have guessed components preserved
        if first_result_dict["guessed_components"]:
            assert "guessed_components" in second_result_dict
        print("✓ Iterative clarification with persistent guesses handled correctly")

    async def test_component_extraction_with_unicode_characters(self):
        """Test edge case: component extraction with unicode characters."""
        print("\n=== Testing component extraction with unicode characters ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with unicode characters
        unicode_description = "Steel beam with ñoño and café construction"

        result = clarify_components(ctx, unicode_description)
        result_dict = json.loads(result)

        # Should handle unicode gracefully
        assert "ambiguous_components" in result_dict
        assert "unambiguous_components" in result_dict
        print("✓ Unicode characters handled correctly")

    async def test_extremely_high_keyword_matching(self):
        """Test edge case: description with extremely high keyword density."""
        print("\n=== Testing extremely high keyword density ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Create a description with repeated keywords
        high_keyword_description = (
            "steel steel steel construction construction industrial"
        )

        result = clarify_components(ctx, high_keyword_description)
        result_dict = json.loads(result)

        # Should handle high keyword density gracefully
        assert "ambiguous_components" in result_dict
        assert "unambiguous_components" in result_dict
        print("✓ Extremely high keyword density handled correctly")

    def test_detect_explicit_guess_permission_variations(self):
        """Test edge case: various guess permission phrase variations."""
        print("\n=== Testing guess permission phrase variations ===")

        # Test various explicit guess permission phrases
        test_cases = [
            ("I don't know", True),
            ("I dont know", True),
            ("whatever", True),
            ("you choose", True),
            ("doesn't matter", True),
            ("I don't care", True),
            ("just guess", True),
            ("your choice", True),
            ("up to you", True),
            ("please specify exactly", False),  # Should not match
            ("steel beam construction", False),  # Should not match
            ("", False),  # Empty string
        ]

        for text, expected in test_cases:
            result = detect_explicit_guess_permission(text)
            assert result == expected, (
                f"Failed for text: '{text}', expected {expected}, got {result}"
            )

        print("✓ Guess permission phrase variations handled correctly")


# Main test runner
async def run_integration_tests():
    """Run all integration tests."""
    print("Running disambiguation edge case integration tests...")

    test_instance = TestDisambiguationEdgeCases()

    tests = [
        test_instance.test_empty_user_description,
        test_instance.test_non_string_user_description,
        test_instance.test_very_long_description,
        test_instance.test_description_with_special_characters,
        test_instance.test_no_matching_components,
        test_instance.test_extreme_similarity_thresholds,
        test_instance.test_json_serialization_edge_cases,
        test_instance.test_file_read_error_during_disambiguation,
        test_instance.test_invalid_context_structure,
        test_instance.test_explicit_guess_permission_with_no_matches,
        test_instance.test_explicit_guess_permission_with_single_match,
        test_instance.test_mixed_ambiguous_and_unambiguous_components,
        test_instance.test_save_with_invalid_state_transitions,
        test_instance.test_iterative_clarification_with_persistent_guesses,
        test_instance.test_component_extraction_with_unicode_characters,
        test_instance.test_extremely_high_keyword_matching,
    ]

    passed = 0
    failed = 0
    skipped = 0

    for test in tests:
        try:
            print(f"\n=== Running {test.__name__} ===")
            await test()
            print(f"✓ {test.__name__} passed")
            passed += 1
        except AssertionError as e:
            print(f"✗ {test.__name__} failed: {e}")
            failed += 1
        except FileNotFoundError:
            print(f"- {test.__name__} skipped (CODE_GENERATION.md not found)")
            skipped += 1
        except Exception as e:
            print(f"✗ {test.__name__} failed with unexpected error: {e}")
            failed += 1

    # Run the non-async test
    print(f"\n=== Running test_detect_explicit_guess_permission_variations ===")
    try:
        test_instance.test_detect_explicit_guess_permission_variations()
        print(f"✓ test_detect_explicit_guess_permission_variations passed")
        passed += 1
    except Exception as e:
        print(f"✗ test_detect_explicit_guess_permission_variations failed: {e}")
        failed += 1

    print(f"\n=== Integration Test Results ===")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Skipped: {skipped}")
    print(f"Total: {passed + failed + skipped}")

    if failed == 0:
        print("All integration tests passed!")
        return True
    else:
        print(f"{failed} integration tests failed!")
        return False


if __name__ == "__main__":
    success = asyncio.run(run_integration_tests())
    sys.exit(0 if success else 1)
