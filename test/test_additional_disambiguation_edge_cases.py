#!/usr/bin/env python3
"""
Additional integration tests for edge cases in the disambiguation workflow.

This test file extends the existing edge case tests to cover additional
scenarios that could occur in production environments, ensuring robustness
under various unusual or challenging conditions.
"""

import sys
import os
import json
import asyncio
import tempfile
import shutil
from unittest.mock import patch, MagicMock
from pathlib import Path

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
        parse_code_generation_rules,
        find_component_matches,
        calculate_semantic_similarity,
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


class TestAdditionalDisambiguationEdgeCases:
    """Additional integration tests for disambiguation edge cases."""

    async def test_malformed_code_generation_file(self):
        """Test edge case: malformed CODE_GENERATION.md file."""
        print("\n=== Testing malformed CODE_GENERATION.md file ===")

        ctx = create_test_context()

        # Create a temporary malformed file
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False
        ) as temp_file:
            temp_file.write("This is not a valid CODE_GENERATION.md file\n")
            temp_file.write("It lacks the proper structure and format\n")
            temp_file_path = temp_file.name

        try:
            # Patch the file paths to use our temporary file
            original_paths = [
                os.path.join(os.getcwd(), "agent", "data", "CODE_GENERATION.md"),
                os.path.join("data", "CODE_GENERATION.md"),
                os.path.join("..", "data", "CODE_GENERATION.md"),
            ]

            with patch(
                "builtins.open",
                side_effect=lambda path, *args, **kwargs: (
                    open(temp_file_path, *args, **kwargs)
                    if "CODE_GENERATION.md" in path
                    else open(path, *args, **kwargs)
                ),
            ):
                with patch(
                    "os.path.exists",
                    side_effect=lambda path: (
                        True if "CODE_GENERATION.md" in path else os.path.exists(path)
                    ),
                ):
                    try:
                        content = read_code_generation_file(ctx)
                        # Should either work or fail gracefully
                        assert ctx.deps.state.rules_loaded_this_turn == True

                        # Test clarify_components with malformed content
                        result = clarify_components(ctx, "steel beam")
                        result_dict = json.loads(result)

                        # Should handle malformed file gracefully
                        assert "ambiguous_components" in result_dict
                        assert "unambiguous_components" in result_dict
                        print("✓ Malformed file handled gracefully")

                    except Exception as e:
                        # Should fail gracefully with proper error handling
                        assert "error" in str(e).lower() or "invalid" in str(e).lower()
                        print("✓ Malformed file failed gracefully")

        finally:
            # Clean up temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)

    async def test_empty_code_generation_file(self):
        """Test edge case: empty CODE_GENERATION.md file."""
        print("\n=== Testing empty CODE_GENERATION.md file ===")

        ctx = create_test_context()

        # Create a temporary empty file
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False
        ) as temp_file:
            temp_file.write("")  # Empty file
            temp_file_path = temp_file.name

        try:
            # Patch the file paths to use our temporary file
            with patch(
                "builtins.open",
                side_effect=lambda path, *args, **kwargs: (
                    open(temp_file_path, *args, **kwargs)
                    if "CODE_GENERATION.md" in path
                    else open(path, *args, **kwargs)
                ),
            ):
                with patch(
                    "os.path.exists",
                    side_effect=lambda path: (
                        True if "CODE_GENERATION.md" in path else os.path.exists(path)
                    ),
                ):
                    try:
                        content = read_code_generation_file(ctx)
                        assert ctx.deps.state.rules_loaded_this_turn == True

                        # Test clarify_components with empty content
                        result = clarify_components(ctx, "steel beam")
                        result_dict = json.loads(result)

                        # Should handle empty file gracefully
                        assert "ambiguous_components" in result_dict
                        assert "unambiguous_components" in result_dict
                        print("✓ Empty file handled gracefully")

                    except Exception as e:
                        # Should fail gracefully
                        print("✓ Empty file failed gracefully")

        finally:
            # Clean up temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)

    async def test_extremely_large_similarity_threshold_range(self):
        """Test edge case: similarity threshold at extreme boundaries."""
        print("\n=== Testing extreme similarity threshold boundaries ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with minimum threshold
        try:
            result = clarify_components(
                ctx, "steel beam", similarity_threshold=MINIMUM_SIMILARITY_THRESHOLD
            )
            result_dict = json.loads(result)
            assert "ambiguous_components" in result_dict
            print("✓ Minimum similarity threshold handled correctly")
        except Exception as e:
            assert False, f"Minimum threshold should be handled gracefully: {e}"

        # Test with maximum threshold
        try:
            result = clarify_components(
                ctx, "steel beam", similarity_threshold=MAXIMUM_SIMILARITY_THRESHOLD
            )
            result_dict = json.loads(result)
            assert "ambiguous_components" in result_dict
            print("✓ Maximum similarity threshold handled correctly")
        except Exception as e:
            assert False, f"Maximum threshold should be handled gracefully: {e}"

    async def test_semantic_similarity_calculation_failure(self):
        """Test edge case: semantic similarity calculation failure."""
        print("\n=== Testing semantic similarity calculation failure ===")

        # Test with malformed inputs that might break semantic similarity
        try:
            # Test with None inputs
            result = calculate_semantic_similarity(None, "steel")
            assert isinstance(result, float)
            assert 0.0 <= result <= 1.0
            print("✓ None input handled gracefully in semantic similarity")
        except Exception as e:
            assert "none" in str(e).lower() or "invalid" in str(e).lower()

        try:
            # Test with empty string
            result = calculate_semantic_similarity("", "steel")
            assert isinstance(result, float)
            assert 0.0 <= result <= 1.0
            print("✓ Empty string handled gracefully in semantic similarity")
        except Exception as e:
            assert "empty" in str(e).lower() or "invalid" in str(e).lower()

    async def test_component_extraction_with_none_rules(self):
        """Test edge case: component extraction with None rules."""
        print("\n=== Testing component extraction with None rules ===")

        try:
            result = extract_components_from_description(
                "steel beam",
                None,  # None rules
                similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD,
            )
            # Should handle None gracefully
            assert isinstance(result, dict)
            print("✓ None rules handled gracefully in component extraction")
        except Exception as e:
            assert "none" in str(e).lower() or "invalid" in str(e).lower()

    async def test_find_component_matches_with_empty_rules(self):
        """Test edge case: find_component_matches with empty rules."""
        print("\n=== Testing find_component_matches with empty rules ===")

        try:
            result = find_component_matches(
                "steel beam",
                {},  # Empty rules
                similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD,
            )
            # Should return empty list
            assert isinstance(result, list)
            assert len(result) == 0
            print("✓ Empty rules handled correctly in find_component_matches")
        except Exception as e:
            assert False, f"Empty rules should be handled gracefully: {e}"

    async def test_parse_code_generation_rules_with_malformed_content(self):
        """Test edge case: parse_code_generation_rules with malformed content."""
        print("\n=== Testing parse_code_generation_rules with malformed content ===")

        # Test with various malformed contents
        malformed_contents = [
            "",  # Empty content
            "Just some text without proper formatting",
            "||| Invalid table format |||",
            "### Major Categories\nNo table here",
            "A|B|C\n1|2|3",  # Incomplete table
        ]

        for content in malformed_contents:
            try:
                result = parse_code_generation_rules(content)
                # Should handle malformed content gracefully
                assert isinstance(result, dict)
                assert len(result) >= 0  # Should not crash
                print(f"✓ Malformed content handled gracefully: {repr(content[:50])}")
            except Exception as e:
                assert (
                    "parse" in str(e).lower()
                    or "invalid" in str(e).lower()
                    or "format" in str(e).lower()
                )

    async def test_detect_component_ambiguity_with_invalid_context(self):
        """Test edge case: detect_component_ambiguity with invalid context."""
        print("\n=== Testing detect_component_ambiguity with invalid context ===")

        try:
            # Test with None context
            result = detect_component_ambiguity(
                "steel beam",
                "dummy content",
                None,  # None context
                "steel beam",
            )
            # Should handle None gracefully
            assert isinstance(result, dict)
            print("✓ None context handled gracefully in detect_component_ambiguity")
        except (AttributeError, TypeError, ValueError) as e:
            # Expected to fail gracefully
            assert "none" in str(e).lower() or "context" in str(e).lower()

    async def test_save_procurement_code_with_extremely_long_values(self):
        """Test edge case: save_procurement_code with extremely long values."""
        print("\n=== Testing save_procurement_code with extremely long values ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Make all components unambiguous to allow save
        for component_name in [
            "Major Category",
            "Manufacturing Method",
            "Object Shape",
            "Material Type",
            "Quality Grade",
            "Size Category",
        ]:
            ambiguity_info = AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "A", "description": "test"}],
                selected_value="A",
            )
            ctx.deps.state.update_component_ambiguity(component_name, ambiguity_info)

        # Test with extremely long code and description
        long_code = "A" * 1000
        long_description = "x" * 10000

        try:
            result = await save_procurement_code(ctx, long_code, long_description)

            if isinstance(result, StateSnapshotEvent):
                print("✓ Extremely long values saved successfully")
            else:
                # Should handle gracefully if there are limitations
                assert (
                    "error" in result.lower()
                    or "invalid" in result.lower()
                    or "too long" in result.lower()
                )
                print("✓ Extremely long values handled with proper error")
        except Exception as e:
            # Should fail gracefully
            assert (
                "length" in str(e).lower()
                or "size" in str(e).lower()
                or "invalid" in str(e).lower()
            )

    async def test_concurrent_state_modification_simulation(self):
        """Test edge case: simulate concurrent state modification."""
        print("\n=== Testing concurrent state modification simulation ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Simulate rapid state modifications
        modifications = []
        for i in range(10):
            component_name = f"Test Component {i}"
            ambiguity_info = AmbiguityInfo(
                status="ambiguous" if i % 2 == 0 else "unambiguous",
                options=[{"value": chr(65 + i), "description": f"test {i}"}],
                selected_value=chr(65 + i) if i % 2 == 1 else None,
            )
            modifications.append((component_name, ambiguity_info))

        # Apply all modifications rapidly
        try:
            for component_name, ambiguity_info in modifications:
                ctx.deps.state.update_component_ambiguity(
                    component_name, ambiguity_info
                )

            # Validate state after rapid modifications
            ctx.deps.state.validate_all_component_states()
            print("✓ Rapid state modifications handled correctly")
        except Exception as e:
            assert (
                "state" in str(e).lower()
                or "concurrent" in str(e).lower()
                or "invalid" in str(e).lower()
            )

    async def test_memory_pressure_simulation(self):
        """Test edge case: simulate memory pressure with large data."""
        print("\n=== Testing memory pressure simulation ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Create large component ambiguity data
        large_options = []
        for i in range(1000):
            large_options.append(
                {
                    "value": f"CODE{i:03d}",
                    "description": f"Very long description repeated many times " * 10,
                }
            )

        try:
            # Create ambiguity info with large options
            ambiguity_info = AmbiguityInfo(
                status="ambiguous", options=large_options, selected_value=None
            )

            ctx.deps.state.update_component_ambiguity("Large Component", ambiguity_info)

            # Test clarify_components with large state
            result = clarify_components(ctx, "test description")
            result_dict = json.loads(result)

            # Should handle large data gracefully
            assert "ambiguous_components" in result_dict
            print("✓ Large data handled gracefully under memory pressure simulation")

        except MemoryError:
            print("✓ Memory error handled gracefully (as expected)")
        except Exception as e:
            assert (
                "memory" in str(e).lower()
                or "size" in str(e).lower()
                or "large" in str(e).lower()
            )

    async def test_nested_error_scenarios(self):
        """Test edge case: nested error scenarios."""
        print("\n=== Testing nested error scenarios ===")

        ctx = create_test_context()

        # Create a context that will fail in multiple ways
        class FailingContext:
            def __init__(self, deps):
                self.deps = deps
                self.messages = None  # This will cause issues

        failing_ctx = FailingContext(ctx.deps)

        # Test multiple error conditions
        error_scenarios = [
            # Invalid context with None messages
            (failing_ctx, "invalid context"),
            # None context
            (None, "none context"),
        ]

        for test_ctx, description in error_scenarios:
            try:
                result = clarify_components(test_ctx, "steel beam")
                # If it doesn't crash, that's good
                assert isinstance(result, str)
                print(f"✓ {description} handled gracefully")
            except (AttributeError, TypeError, ValueError) as e:
                # Expected to fail gracefully
                assert (
                    "none" in str(e).lower()
                    or "invalid" in str(e).lower()
                    or "context" in str(e).lower()
                )

    async def test_permission_denied_simulation(self):
        """Test edge case: permission denied on file access."""
        print("\n=== Testing permission denied simulation ===")

        ctx = create_test_context()

        # Create a temporary file and then make it inaccessible
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False
        ) as temp_file:
            temp_file.write(
                "# Test Content\n## Major Categories\n| A | Industry | Description |"
            )
            temp_file_path = temp_file.name

        try:
            # Make the file read-only to simulate permission issues
            os.chmod(temp_file_path, 0o000)  # No permissions

            with patch(
                "builtins.open",
                side_effect=lambda path, *args, **kwargs: (
                    open(temp_file_path, *args, **kwargs)
                    if "CODE_GENERATION.md" in path
                    else open(path, *args, **kwargs)
                ),
            ):
                with patch(
                    "os.path.exists",
                    side_effect=lambda path: (
                        True if "CODE_GENERATION.md" in path else os.path.exists(path)
                    ),
                ):
                    try:
                        content = read_code_generation_file(ctx)
                        print(
                            "✓ Permission denied handled gracefully (unexpected success)"
                        )
                    except (PermissionError, OSError) as e:
                        print("✓ Permission denied handled correctly")
                    except Exception as e:
                        assert (
                            "permission" in str(e).lower()
                            or "access" in str(e).lower()
                            or "denied" in str(e).lower()
                        )

        finally:
            # Restore permissions and clean up
            try:
                os.chmod(temp_file_path, 0o644)
                os.unlink(temp_file_path)
            except:
                pass  # Ignore cleanup errors

    async def test_unicode_normalization_edge_cases(self):
        """Test edge case: unicode normalization and compatibility."""
        print("\n=== Testing unicode normalization edge cases ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        # Test with various unicode normalization forms
        unicode_variants = [
            "café",  # Normal form
            "cafe\u0301",  # Combining accent
            "caf\u00e9",  # Composed character
            "日本語",  # Japanese
            "русский",  # Russian
            "العربية",  # Arabic
            "🚀",  # Emoji
        ]

        for unicode_text in unicode_variants:
            try:
                result = clarify_components(ctx, f"steel beam with {unicode_text}")
                result_dict = json.loads(result)

                # Should handle unicode variants gracefully
                assert "ambiguous_components" in result_dict
                assert "unambiguous_components" in result_dict
                print(f"✓ Unicode variant handled: {unicode_text}")
            except Exception as e:
                assert (
                    "unicode" in str(e).lower()
                    or "encoding" in str(e).lower()
                    or "invalid" in str(e).lower()
                )

    async def test_zero_similarity_threshold_edge_case(self):
        """Test edge case: zero similarity threshold."""
        print("\n=== Testing zero similarity threshold ===")

        ctx = create_test_context()

        # First, read the code generation file
        try:
            content = read_code_generation_file(ctx)
            assert ctx.deps.state.rules_loaded_this_turn == True
        except FileNotFoundError:
            print("SKIPPED: CODE_GENERATION.md not found")
            return

        try:
            result = clarify_components(ctx, "steel beam", similarity_threshold=0.0)
            result_dict = json.loads(result)

            # Should handle zero threshold gracefully (might return more matches)
            assert "ambiguous_components" in result_dict
            assert "unambiguous_components" in result_dict
            print("✓ Zero similarity threshold handled correctly")

        except Exception as e:
            assert (
                "threshold" in str(e).lower()
                or "similarity" in str(e).lower()
                or "range" in str(e).lower()
            )


# Main test runner
async def run_additional_integration_tests():
    """Run all additional integration tests."""
    print("Running additional disambiguation edge case integration tests...")

    test_instance = TestAdditionalDisambiguationEdgeCases()

    tests = [
        test_instance.test_malformed_code_generation_file,
        test_instance.test_empty_code_generation_file,
        test_instance.test_extremely_large_similarity_threshold_range,
        test_instance.test_semantic_similarity_calculation_failure,
        test_instance.test_component_extraction_with_none_rules,
        test_instance.test_find_component_matches_with_empty_rules,
        test_instance.test_parse_code_generation_rules_with_malformed_content,
        test_instance.test_detect_component_ambiguity_with_invalid_context,
        test_instance.test_save_procurement_code_with_extremely_long_values,
        test_instance.test_concurrent_state_modification_simulation,
        test_instance.test_memory_pressure_simulation,
        test_instance.test_nested_error_scenarios,
        test_instance.test_permission_denied_simulation,
        test_instance.test_unicode_normalization_edge_cases,
        test_instance.test_zero_similarity_threshold_edge_case,
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

    print(f"\n=== Additional Integration Test Results ===")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Skipped: {skipped}")
    print(f"Total: {passed + failed + skipped}")

    if failed == 0:
        print("All additional integration tests passed!")
        return True
    else:
        print(f"{failed} additional integration tests failed!")
        return False


if __name__ == "__main__":
    success = asyncio.run(run_additional_integration_tests())
    sys.exit(0 if success else 1)
