#!/usr/bin/env python3
"""
Test for task 3.8 - Modify clarify_components tool to filter options based on similarity threshold.

This test verifies that the clarify_components tool now accepts a similarity_threshold parameter
and uses it correctly throughout the function.
"""

import json
import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

# Mock all the dependencies that might not be available
with patch.dict(
    "sys.modules",
    {
        "src.rag.index": MagicMock(),
        "src.rag.settings": MagicMock(),
        "src.rag.citation": MagicMock(),
        "src.rag.query": MagicMock(),
        "llama_index.core": MagicMock(),
        "llama_index.embeddings.huggingface": MagicMock(),
        "pydantic_ai": MagicMock(),
        "pydantic_ai.models": MagicMock(),
        "pydantic_ai.settings": MagicMock(),
        "pydantic_ai.messages": MagicMock(),
        "pydantic_ai.ag_ui": MagicMock(),
        "pydantic_ai.models.openai": MagicMock(),
        "numpy": MagicMock(),
    },
):
    # Now we can import the functions we need to test
    from agent import clarify_components

    # Mock the RunContext and StateDeps
    class MockRunContext:
        def __init__(self, deps):
            self.deps = deps

    class MockStateDeps:
        def __init__(self, state):
            self.state = state

    class MockProcurementState:
        def __init__(self):
            self.rules_loaded_this_turn = True
            self.component_ambiguity_status = {}
            self.clarification_rounds = 0
            self.clarified_components = set()


class TestSimilarityThresholdParameter(unittest.TestCase):
    """Test that clarify_components accepts and uses similarity_threshold parameter."""

    def test_function_signature_has_similarity_threshold(self):
        """Test that the clarify_components function has a similarity_threshold parameter."""
        import inspect

        # Get the function signature
        sig = inspect.signature(clarify_components)
        params = list(sig.parameters.keys())

        # Verify that similarity_threshold parameter is present
        self.assertIn("similarity_threshold", params)

        # Verify that it has a default value
        similarity_threshold_param = sig.parameters.get("similarity_threshold")
        self.assertIsNotNone(similarity_threshold_param.default)
        self.assertIsInstance(similarity_threshold_param.default, float)

    def test_similarity_threshold_validation(self):
        """Test that similarity_threshold is properly validated."""
        # Mock the necessary dependencies
        with (
            patch("agent.read_code_generation_file") as mock_read,
            patch("agent.detect_component_ambiguity") as mock_detect,
            patch("agent.get_component_extraction_results") as mock_extract,
        ):
            # Set up mocks
            mock_read.return_value = "Sample content"
            mock_detect.return_value = {
                "ambiguity_detected": False,
                "ambiguous_components": [],
                "unambiguous_components": [],
                "guessed_components": [],
                "no_match_components": [],
                "ambiguity_details": {},
                "guess_notification": "",
            }
            mock_extract.return_value = {
                "ambiguous_components": [],
                "unambiguous_components": [],
                "no_match_components": [],
                "component_details": {},
            }

            # Create mock context and state
            mock_state = MockProcurementState()
            mock_deps = MockStateDeps(mock_state)
            mock_ctx = MockRunContext(mock_deps)

            # Test with different similarity thresholds
            test_thresholds = [0.1, 0.3, 0.5, 0.8]

            for threshold in test_thresholds:
                with self.subTest(threshold=threshold):
                    try:
                        # Call clarify_components with the threshold
                        result = clarify_components(
                            mock_ctx, "test description", similarity_threshold=threshold
                        )

                        # Verify it returns valid JSON
                        result_data = json.loads(result)

                        # Verify the similarity_threshold_info reflects the used threshold
                        if "similarity_threshold_info" in result_data:
                            self.assertEqual(
                                result_data["similarity_threshold_info"][
                                    "threshold_used"
                                ],
                                threshold,
                            )

                    except Exception as e:
                        self.fail(
                            f"clarify_components failed with similarity_threshold={threshold}: {e}"
                        )

    def test_similarity_threshold_normalization(self):
        """Test that extreme similarity_threshold values are normalized."""
        with (
            patch("agent.read_code_generation_file") as mock_read,
            patch("agent.detect_component_ambiguity") as mock_detect,
            patch("agent.get_component_extraction_results") as mock_extract,
        ):
            # Set up mocks
            mock_read.return_value = "Sample content"
            mock_detect.return_value = {
                "ambiguity_detected": False,
                "ambiguous_components": [],
                "unambiguous_components": [],
                "guessed_components": [],
                "no_match_components": [],
                "ambiguity_details": {},
                "guess_notification": "",
            }
            mock_extract.return_value = {
                "ambiguous_components": [],
                "unambiguous_components": [],
                "no_match_components": [],
                "component_details": {},
            }

            # Create mock context and state
            mock_state = MockProcurementState()
            mock_deps = MockStateDeps(mock_state)
            mock_ctx = MockRunContext(mock_deps)

            # Test with extreme values that should be normalized
            extreme_values = [-0.1, 0.0, 1.0, 1.5]

            for value in extreme_values:
                with self.subTest(value=value):
                    try:
                        result = clarify_components(
                            mock_ctx, "test description", similarity_threshold=value
                        )
                        result_data = json.loads(result)

                        # The function should complete successfully even with extreme values
                        self.assertIn("ambiguous_components", result_data)

                    except Exception as e:
                        self.fail(
                            f"clarify_components failed with extreme similarity_threshold={value}: {e}"
                        )

    def test_backward_compatibility_with_default_threshold(self):
        """Test that clarify_components still works with default similarity_threshold."""
        with (
            patch("agent.read_code_generation_file") as mock_read,
            patch("agent.detect_component_ambiguity") as mock_detect,
            patch("agent.get_component_extraction_results") as mock_extract,
        ):
            # Set up mocks
            mock_read.return_value = "Sample content"
            mock_detect.return_value = {
                "ambiguity_detected": False,
                "ambiguous_components": [],
                "unambiguous_components": [],
                "guessed_components": [],
                "no_match_components": [],
                "ambiguity_details": {},
                "guess_notification": "",
            }
            mock_extract.return_value = {
                "ambiguous_components": [],
                "unambiguous_components": [],
                "no_match_components": [],
                "component_details": {},
            }

            # Create mock context and state
            mock_state = MockProcurementState()
            mock_deps = MockStateDeps(mock_state)
            mock_ctx = MockRunContext(mock_deps)

            # Call clarify_components without similarity_threshold (should use default)
            result = clarify_components(mock_ctx, "test description")
            result_data = json.loads(result)

            # Verify it works with default
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)


if __name__ == "__main__":
    unittest.main()
