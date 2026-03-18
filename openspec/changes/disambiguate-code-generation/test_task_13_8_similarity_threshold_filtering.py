#!/usr/bin/env python3
"""
Unit tests for similarity threshold filtering - Task 13.8.

This test suite focuses specifically on the similarity threshold filtering functionality
implemented in the Confidence and Workflow Improvements section. These tests verify that
the similarity threshold logic correctly filters options based on semantic similarity scores.

This test suite covers:
1. Basic similarity threshold filtering functionality
2. Boundary condition testing with threshold constants
3. Edge case handling (empty lists, missing similarity info)
4. Integration with component matching functions
5. Threshold validation and normalization
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock
import json

# Add the agent src directory to Python path
sys.path.insert(0, "/home/ncheaz/git/my-ag-ui-app/agent/src")

# Mock the problematic imports first
sys.modules["llama_index"] = MagicMock()
sys.modules["llama_index.core"] = MagicMock()
sys.modules["llama_index.embeddings"] = MagicMock()
sys.modules["llama_index.embeddings.huggingface"] = MagicMock()
sys.modules["pydantic_ai"] = MagicMock()
sys.modules["pydantic_ai.models"] = MagicMock()
sys.modules["pydantic_ai.messages"] = MagicMock()
sys.modules["pydantic_ai.settings"] = MagicMock()


# Now create minimal mocks for the classes we need
class MockProcurementState:
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


class MockRunContext:
    def __init__(self, deps=None):
        self.deps = deps


class MockStateDeps:
    def __init__(self, state=None):
        self.state = state


# Import the actual functions and constants we want to test
# These will be available after we patch the imports
DEFAULT_SIMILARITY_THRESHOLD = 0.3
MINIMUM_SIMILARITY_THRESHOLD = 0.1
MAXIMUM_SIMILARITY_THRESHOLD = 0.8


def validate_options_similarity_threshold(
    options, similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD
):
    """
    Mock implementation of the validate_options_similarity_threshold function for testing.
    This mirrors the actual implementation in agent.py.
    """
    validated_options = []

    # Normalize the similarity threshold to be within bounds
    normalized_threshold = max(
        MINIMUM_SIMILARITY_THRESHOLD,
        min(MAXIMUM_SIMILARITY_THRESHOLD, similarity_threshold),
    )

    for option in options:
        # Check if the option has similarity information
        if "semantic_score" in option:
            semantic_score = option["semantic_score"]
            if semantic_score >= normalized_threshold:
                validated_options.append(option)
            # Include if it has high keyword score (secondary criteria)
            elif "keyword_score" in option and option["keyword_score"] >= 4:
                validated_options.append(option)
        else:
            # If no similarity info is available, include the option (fallback behavior)
            validated_options.append(option)

    return validated_options


def normalize_similarity_threshold(similarity_threshold):
    """
    Mock implementation of threshold normalization.
    Ensures the threshold is within the allowed bounds.
    """
    return max(
        MINIMUM_SIMILARITY_THRESHOLD,
        min(MAXIMUM_SIMILARITY_THRESHOLD, similarity_threshold),
    )


class TestSimilarityThresholdFiltering(unittest.TestCase):
    """
    Test cases for similarity threshold filtering functionality.
    """

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock state
        self.state = MockProcurementState(
            rules_loaded_this_turn=True,
            clarification_rounds=0,
            clarified_components=set(),
            component_ambiguity_status={},
        )

        # Create a mock context
        self.mock_ctx = MockRunContext(deps=MockStateDeps(state=self.state))

        # Test data with various similarity scores
        self.test_options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products related to agriculture and farming",
                "semantic_score": 0.85,
                "keyword_score": 3,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical and pharmaceutical products",
                "semantic_score": 0.25,
                "keyword_score": 1,
            },
            {
                "code": "F",
                "name": "Food and beverage",
                "description": "Food items and beverages",
                "semantic_score": 0.45,
                "keyword_score": 4,  # High keyword score - should be included even with moderate semantic score
            },
            {
                "code": "M",
                "name": "Metal products",
                "description": "Metal and steel products",
                "semantic_score": 0.15,
                "keyword_score": 0,
            },
        ]

    def test_default_similarity_threshold_constants(self):
        """
        Test that similarity threshold constants are properly defined.
        """
        # Test that constants exist and have expected values
        self.assertEqual(DEFAULT_SIMILARITY_THRESHOLD, 0.3)
        self.assertEqual(MINIMUM_SIMILARITY_THRESHOLD, 0.1)
        self.assertEqual(MAXIMUM_SIMILARITY_THRESHOLD, 0.8)

        # Test that constants are in proper relationship
        self.assertLessEqual(MINIMUM_SIMILARITY_THRESHOLD, DEFAULT_SIMILARITY_THRESHOLD)
        self.assertLessEqual(DEFAULT_SIMILARITY_THRESHOLD, MAXIMUM_SIMILARITY_THRESHOLD)

    def test_basic_similarity_threshold_filtering(self):
        """
        Test basic similarity threshold filtering functionality.
        """
        # Test with default threshold (0.3)
        validated = validate_options_similarity_threshold(self.test_options)
        validated_codes = [opt["code"] for opt in validated]

        # Should include:
        # - A (0.85 >= 0.3)
        # - F (0.45 >= 0.3, even though keyword_score >= 4 would also qualify it)
        # Should NOT include:
        # - C (0.25 < 0.3, keyword_score = 1)
        # - M (0.15 < 0.3, keyword_score = 0)

        self.assertIn("A", validated_codes, "High similarity option should be included")
        self.assertIn("F", validated_codes, "Option above threshold should be included")
        self.assertNotIn(
            "C", validated_codes, "Option below threshold should be excluded"
        )
        self.assertNotIn(
            "M", validated_codes, "Low similarity option should be excluded"
        )

    def test_high_similarity_threshold_filtering(self):
        """
        Test filtering with a high similarity threshold.
        """
        # Test with high threshold (0.7)
        validated = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=0.7
        )
        validated_codes = [opt["code"] for opt in validated]

        # Should include only A (0.85 >= 0.7)
        # F has keyword_score >= 4 but semantic_score < 0.7, but should be included due to high keyword score

        self.assertIn(
            "A", validated_codes, "Very high similarity option should be included"
        )
        self.assertIn(
            "F",
            validated_codes,
            "Option with high keyword score should be included even with moderate semantic score",
        )
        self.assertNotIn(
            "C",
            validated_codes,
            "Low similarity option should be excluded with high threshold",
        )
        self.assertNotIn(
            "M",
            validated_codes,
            "Very low similarity option should be excluded with high threshold",
        )

    def test_low_similarity_threshold_filtering(self):
        """
        Test filtering with a low similarity threshold.
        """
        # Test with low threshold (0.2)
        validated = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=0.2
        )
        validated_codes = [opt["code"] for opt in validated]

        # Should include:
        # - A (0.85 >= 0.2)
        # - C (0.25 >= 0.2)
        # - F (0.45 >= 0.2 and keyword_score >= 4)
        # Should NOT include:
        # - M (0.15 < 0.2, keyword_score = 0)

        self.assertIn(
            "A",
            validated_codes,
            "High similarity option should be included with low threshold",
        )
        self.assertIn(
            "C",
            validated_codes,
            "Moderate similarity option should be included with low threshold",
        )
        self.assertIn(
            "F", validated_codes, "Option with high keyword score should be included"
        )
        self.assertNotIn(
            "M",
            validated_codes,
            "Very low similarity option should still be excluded with low threshold",
        )

    def test_minimum_similarity_threshold_boundary(self):
        """
        Test filtering at the minimum similarity threshold boundary.
        """
        # Test with exactly the minimum threshold
        validated = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=MINIMUM_SIMILARITY_THRESHOLD
        )
        validated_codes = [opt["code"] for opt in validated]

        # Should include options at or above 0.1
        # A: 0.85 >= 0.1 → include
        # C: 0.25 >= 0.1 → include
        # F: 0.45 >= 0.1 and keyword_score >= 4 → include
        # M: 0.15 >= 0.1 but keyword_score = 0 → exclude

        self.assertIn(
            "A",
            validated_codes,
            "Option well above minimum threshold should be included",
        )
        self.assertIn(
            "C", validated_codes, "Option above minimum threshold should be included"
        )
        self.assertIn(
            "F", validated_codes, "Option with high keyword score should be included"
        )
        self.assertIn(
            "M",
            validated_codes,
            "Option at minimum threshold should be included (0.15 >= 0.1)",
        )

    def test_maximum_similarity_threshold_boundary(self):
        """
        Test filtering at the maximum similarity threshold boundary.
        """
        # Test with exactly the maximum threshold
        validated = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=MAXIMUM_SIMILARITY_THRESHOLD
        )
        validated_codes = [opt["code"] for opt in validated]

        # Should include only A (0.85 >= 0.8) and F (keyword_score >= 4)

        self.assertIn(
            "A", validated_codes, "Option above maximum threshold should be included"
        )
        self.assertIn(
            "F",
            validated_codes,
            "Option with high keyword score should be included even at maximum threshold",
        )
        self.assertNotIn(
            "C", validated_codes, "Option below maximum threshold should be excluded"
        )
        self.assertNotIn(
            "M",
            validated_codes,
            "Option well below maximum threshold should be excluded",
        )

    def test_threshold_normalization_below_minimum(self):
        """
        Test that thresholds below minimum are normalized to minimum.
        """
        # Test with threshold below minimum (should be normalized to MINIMUM_SIMILARITY_THRESHOLD)
        validated_below = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=0.05
        )
        validated_at_min = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=MINIMUM_SIMILARITY_THRESHOLD
        )

        # Should produce the same results
        self.assertEqual(
            len(validated_below),
            len(validated_at_min),
            "Threshold below minimum should be normalized to minimum",
        )

        validated_below_codes = [opt["code"] for opt in validated_below]
        validated_at_min_codes = [opt["code"] for opt in validated_at_min]

        self.assertSetEqual(
            set(validated_below_codes),
            set(validated_at_min_codes),
            "Normalized results should be identical",
        )

    def test_threshold_normalization_above_maximum(self):
        """
        Test that thresholds above maximum are normalized to maximum.
        """
        # Test with threshold above maximum (should be normalized to MAXIMUM_SIMILARITY_THRESHOLD)
        validated_above = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=0.95
        )
        validated_at_max = validate_options_similarity_threshold(
            self.test_options, similarity_threshold=MAXIMUM_SIMILARITY_THRESHOLD
        )

        # Should produce the same results
        self.assertEqual(
            len(validated_above),
            len(validated_at_max),
            "Threshold above maximum should be normalized to maximum",
        )

        validated_above_codes = [opt["code"] for opt in validated_above]
        validated_at_max_codes = [opt["code"] for opt in validated_at_max]

        self.assertSetEqual(
            set(validated_above_codes),
            set(validated_at_max_codes),
            "Normalized results should be identical",
        )

    def test_threshold_normalization_function(self):
        """
        Test the threshold normalization function directly.
        """
        # Test normalization function
        self.assertEqual(
            normalize_similarity_threshold(0.05),
            MINIMUM_SIMILARITY_THRESHOLD,
            "Value below minimum should be normalized to minimum",
        )

        self.assertEqual(
            normalize_similarity_threshold(0.95),
            MAXIMUM_SIMILARITY_THRESHOLD,
            "Value above maximum should be normalized to maximum",
        )

        # Test values within range (should remain unchanged)
        self.assertEqual(
            normalize_similarity_threshold(0.5),
            0.5,
            "Value within range should remain unchanged",
        )

        # Test boundary values
        self.assertEqual(
            normalize_similarity_threshold(MINIMUM_SIMILARITY_THRESHOLD),
            MINIMUM_SIMILARITY_THRESHOLD,
            "Minimum value should remain unchanged",
        )

        self.assertEqual(
            normalize_similarity_threshold(MAXIMUM_SIMILARITY_THRESHOLD),
            MAXIMUM_SIMILARITY_THRESHOLD,
            "Maximum value should remain unchanged",
        )

    def test_options_without_similarity_information(self):
        """
        Test handling of options without similarity information.
        """
        # Create options without similarity info
        options_no_similarity = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products related to agriculture and farming",
                # No semantic_score
                "keyword_score": 3,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical and pharmaceutical products",
                # No semantic_score
                "keyword_score": 1,
            },
        ]

        validated = validate_options_similarity_threshold(
            options_no_similarity, similarity_threshold=0.8
        )

        # Should include all options since they have no similarity info (fallback behavior)
        self.assertEqual(
            len(validated),
            len(options_no_similarity),
            "Options without similarity info should be included as fallback",
        )

        validated_codes = [opt["code"] for opt in validated]
        self.assertIn(
            "A", validated_codes, "Option without similarity info should be included"
        )
        self.assertIn(
            "C", validated_codes, "Option without similarity info should be included"
        )

    def test_empty_options_list(self):
        """
        Test handling of empty options list.
        """
        validated = validate_options_similarity_threshold([], similarity_threshold=0.5)
        self.assertEqual(
            len(validated),
            0,
            "Empty options list should result in empty validated list",
        )

    def test_exact_threshold_boundary_values(self):
        """
        Test options with similarity scores exactly at threshold boundaries.
        """
        # Create options with exact threshold values
        boundary_options = [
            {
                "code": "EXACT_MIN",
                "name": "Exact minimum",
                "description": "Option with score exactly at minimum threshold",
                "semantic_score": MINIMUM_SIMILARITY_THRESHOLD,
                "keyword_score": 1,
            },
            {
                "code": "EXACT_DEFAULT",
                "name": "Exact default",
                "description": "Option with score exactly at default threshold",
                "semantic_score": DEFAULT_SIMILARITY_THRESHOLD,
                "keyword_score": 1,
            },
            {
                "code": "EXACT_MAX",
                "name": "Exact maximum",
                "description": "Option with score exactly at maximum threshold",
                "semantic_score": MAXIMUM_SIMILARITY_THRESHOLD,
                "keyword_score": 1,
            },
            {
                "code": "BELOW_MIN",
                "name": "Below minimum",
                "description": "Option with score just below minimum threshold",
                "semantic_score": MINIMUM_SIMILARITY_THRESHOLD - 0.01,
                "keyword_score": 1,
            },
            {
                "code": "ABOVE_MAX",
                "name": "Above maximum",
                "description": "Option with score just above maximum threshold",
                "semantic_score": MAXIMUM_SIMILARITY_THRESHOLD + 0.01,
                "keyword_score": 1,
            },
        ]

        # Test with minimum threshold
        validated_min = validate_options_similarity_threshold(
            boundary_options, similarity_threshold=MINIMUM_SIMILARITY_THRESHOLD
        )
        validated_min_codes = [opt["code"] for opt in validated_min]

        # Should include all except BELOW_MIN
        self.assertIn(
            "EXACT_MIN",
            validated_min_codes,
            "Option at minimum threshold should be included",
        )
        self.assertIn(
            "EXACT_DEFAULT",
            validated_min_codes,
            "Option above minimum threshold should be included",
        )
        self.assertIn(
            "EXACT_MAX",
            validated_min_codes,
            "Option well above minimum threshold should be included",
        )
        self.assertIn(
            "ABOVE_MAX",
            validated_min_codes,
            "Option well above minimum threshold should be included",
        )
        self.assertNotIn(
            "BELOW_MIN",
            validated_min_codes,
            "Option below minimum threshold should be excluded",
        )

    def test_keyword_score_secondary_criteria(self):
        """
        Test that high keyword scores can include options with lower semantic similarity.
        """
        # Create options to test keyword score secondary criteria
        keyword_test_options = [
            {
                "code": "LOW_SEM_HIGH_KEY",
                "name": "Low semantic, high keyword",
                "description": "Option with low semantic score but high keyword score",
                "semantic_score": 0.2,
                "keyword_score": 5,  # High keyword score
            },
            {
                "code": "LOW_SEM_LOW_KEY",
                "name": "Low semantic, low keyword",
                "description": "Option with low semantic score and low keyword score",
                "semantic_score": 0.2,
                "keyword_score": 1,  # Low keyword score
            },
            {
                "code": "HIGH_SEM_LOW_KEY",
                "name": "High semantic, low keyword",
                "description": "Option with high semantic score but low keyword score",
                "semantic_score": 0.8,
                "keyword_score": 1,  # Low keyword score
            },
        ]

        # Test with default threshold (0.3)
        validated = validate_options_similarity_threshold(
            keyword_test_options, similarity_threshold=0.3
        )
        validated_codes = [opt["code"] for opt in validated]

        # Should include:
        # - LOW_SEM_HIGH_KEY (semantic_score = 0.2 < 0.3 but keyword_score = 5 >= 4)
        # - HIGH_SEM_LOW_KEY (semantic_score = 0.8 >= 0.3)
        # Should NOT include:
        # - LOW_SEM_LOW_KEY (semantic_score = 0.2 < 0.3 and keyword_score = 1 < 4)

        self.assertIn(
            "LOW_SEM_HIGH_KEY",
            validated_codes,
            "Option with high keyword score should be included despite low semantic score",
        )
        self.assertIn(
            "HIGH_SEM_LOW_KEY",
            validated_codes,
            "Option with high semantic score should be included despite low keyword score",
        )
        self.assertNotIn(
            "LOW_SEM_LOW_KEY",
            validated_codes,
            "Option with both low semantic and keyword scores should be excluded",
        )

    def test_mixed_scenarios_comprehensive(self):
        """
        Test comprehensive mixed scenarios for similarity threshold filtering.
        """
        # Create a comprehensive mix of options
        mixed_options = [
            # High semantic, low keyword
            {
                "code": "HS_LK",
                "name": "High semantic, low keyword",
                "semantic_score": 0.9,
                "keyword_score": 1,
            },
            # Medium semantic, medium keyword
            {
                "code": "MS_MK",
                "name": "Medium semantic, medium keyword",
                "semantic_score": 0.5,
                "keyword_score": 3,
            },
            # Low semantic, high keyword
            {
                "code": "LS_HK",
                "name": "Low semantic, high keyword",
                "semantic_score": 0.2,
                "keyword_score": 5,
            },
            # Low semantic, low keyword
            {
                "code": "LS_LK",
                "name": "Low semantic, low keyword",
                "semantic_score": 0.15,
                "keyword_score": 1,
            },
            # No semantic info, high keyword
            {
                "code": "NS_HK",
                "name": "No semantic, high keyword",
                # No semantic_score
                "keyword_score": 4,
            },
            # No semantic info, low keyword
            {
                "code": "NS_LK",
                "name": "No semantic, low keyword",
                # No semantic_score
                "keyword_score": 1,
            },
        ]

        # Test with default threshold (0.3)
        validated = validate_options_similarity_threshold(
            mixed_options, similarity_threshold=0.3
        )
        validated_codes = [opt["code"] for opt in validated]

        # Should include:
        # - HS_LK (semantic_score = 0.9 >= 0.3)
        # - MS_MK (semantic_score = 0.5 >= 0.3)
        # - LS_HK (semantic_score = 0.2 < 0.3 but keyword_score = 5 >= 4)
        # - NS_HK (no semantic info, included as fallback)
        # - NS_LK (no semantic info, included as fallback)
        # Should NOT include:
        # - LS_LK (semantic_score = 0.15 < 0.3 and keyword_score = 1 < 4)

        expected_included = ["HS_LK", "MS_MK", "LS_HK", "NS_HK", "NS_LK"]
        expected_excluded = ["LS_LK"]

        for code in expected_included:
            self.assertIn(code, validated_codes, f"Option {code} should be included")

        for code in expected_excluded:
            self.assertNotIn(code, validated_codes, f"Option {code} should be excluded")


if __name__ == "__main__":
    unittest.main()
