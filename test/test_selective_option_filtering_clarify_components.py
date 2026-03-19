#!/usr/bin/env python3
"""
Unit tests for selective option filtering in clarify_components tool.

Tests the similarity threshold filtering functionality that was implemented
in tasks 3.8 and 3.9, ensuring that only relevant options are presented to users
during clarification.
"""

import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

# We need to mock the RAG imports since they might not be available
with patch.dict(
    "sys.modules",
    {
        "src.rag.index": MagicMock(),
        "src.rag.settings": MagicMock(),
        "src.rag.citation": MagicMock(),
        "src.rag.query": MagicMock(),
        "llama_index.core": MagicMock(),
        "llama_index.embeddings.huggingface": MagicMock(),
    },
):
    from agent import (
        validate_options_similarity_threshold,
    )


class TestSelectiveOptionFiltering(unittest.TestCase):
    """Test cases for selective option filtering in clarify_components tool."""

    def test_validate_options_similarity_threshold(self):
        """Test the validate_options_similarity_threshold function."""
        # Create test options with varying similarity scores
        options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture",
                "semantic_score": 0.8,
                "keyword_score": 2,
                "score": 10.0,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical products",
                "semantic_score": 0.2,
                "keyword_score": 1,
                "score": 3.0,
            },
            {
                "code": "T",
                "name": "Textile products",
                "description": "Clothing and textile materials",
                "semantic_score": 0.5,
                "keyword_score": 3,
                "score": 8.0,
            },
            {
                "code": "M",
                "name": "Mechanical products",
                "description": "Machinery and mechanical equipment",
                "keyword_score": 5,  # High keyword score
                "score": 5.0,
                # Missing semantic_score to test fallback behavior
            },
        ]

        # Test with threshold of 0.4
        threshold = 0.4
        validated_options = validate_options_similarity_threshold(options, threshold)

        # Should include options with semantic_score >= threshold
        # and options without semantic_score (fallback behavior)
        expected_codes = [
            "A",
            "T",
            "M",
        ]  # A: 0.8 >= 0.4, T: 0.5 >= 0.4, M: no semantic_score
        validated_codes = [opt["code"] for opt in validated_options]

        for code in expected_codes:
            self.assertIn(code, validated_codes)

        # Should NOT include option with semantic_score < threshold
        validated_codes = [opt["code"] for opt in validated_options]
        self.assertNotIn("C", validated_codes)  # C: 0.2 < 0.4

    def test_validate_options_without_semantic_scores(self):
        """Test validate_options_similarity_threshold with options missing semantic scores."""
        options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture",
                "keyword_score": 3,
                "score": 5.0,
                # No semantic_score
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical products",
                "keyword_score": 1,
                "score": 2.0,
                # No semantic_score
            },
        ]

        threshold = 0.5
        validated_options = validate_options_similarity_threshold(options, threshold)

        # All options should be included when no semantic_score is present (fallback behavior)
        self.assertEqual(len(validated_options), len(options))
        validated_codes = [opt["code"] for opt in validated_options]
        self.assertIn("A", validated_codes)
        self.assertIn("C", validated_codes)

    def test_validate_options_empty_list(self):
        """Test validate_options_similarity_threshold with empty options list."""
        options = []
        threshold = 0.5
        validated_options = validate_options_similarity_threshold(options, threshold)

        self.assertEqual(validated_options, [])

    def test_validate_options_threshold_boundary_values(self):
        """Test validate_options_similarity_threshold with threshold boundary values."""
        options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture",
                "semantic_score": 0.0,
                "keyword_score": 2,
                "score": 5.0,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical products",
                "semantic_score": 1.0,
                "keyword_score": 1,
                "score": 3.0,
            },
        ]

        # Test with threshold = 0.0 (should include all with semantic_score >= 0.0)
        validated_options_zero = validate_options_similarity_threshold(options, 0.0)
        self.assertEqual(len(validated_options_zero), 2)  # Both should be included

        # Test with threshold = 1.0 (should only include those with semantic_score >= 1.0)
        validated_options_one = validate_options_similarity_threshold(options, 1.0)
        validated_codes = [opt["code"] for opt in validated_options_one]
        self.assertIn("C", validated_codes)  # Only C has semantic_score = 1.0

    def test_validate_options_mixed_scenarios(self):
        """Test validate_options_similarity_threshold with various mixed scenarios."""
        # Test scenario 1: Some options above threshold, some below
        options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture",
                "semantic_score": 0.6,
                "keyword_score": 3,
                "score": 9.0,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical products",
                "semantic_score": 0.3,
                "keyword_score": 2,
                "score": 5.0,
            },
            {
                "code": "T",
                "name": "Textile products",
                "description": "Clothing and textile materials",
                "keyword_score": 4,
                "score": 7.0,
                # No semantic_score
            },
        ]

        threshold = 0.5
        validated_options = validate_options_similarity_threshold(options, threshold)

        # Should include A (0.6 >= 0.5) and T (no semantic_score)
        # Should NOT include C (0.3 < 0.5)
        validated_codes = [opt["code"] for opt in validated_options]
        self.assertIn("A", validated_codes)
        self.assertIn("T", validated_codes)
        self.assertNotIn("C", validated_codes)

        # Test scenario 2: All options below threshold
        options_below = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture",
                "semantic_score": 0.2,
                "keyword_score": 1,
                "score": 3.0,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical products",
                "semantic_score": 0.1,
                "keyword_score": 1,
                "score": 2.0,
            },
        ]

        validated_below = validate_options_similarity_threshold(
            options_below, threshold
        )
        # Should be empty since all are below threshold and none have missing semantic_score
        self.assertEqual(len(validated_below), 0)

    def test_validate_options_preserves_original_structure(self):
        """Test that validate_options_similarity_threshold preserves the original option structure."""
        options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture",
                "semantic_score": 0.8,
                "keyword_score": 2,
                "score": 10.0,
                "extra_field": "preserved",
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical products",
                "semantic_score": 0.2,
                "keyword_score": 1,
                "score": 3.0,
                "another_field": "also_preserved",
            },
        ]

        threshold = 0.5
        validated_options = validate_options_similarity_threshold(options, threshold)

        # Should only include option A (semantic_score 0.8 >= 0.5)
        self.assertEqual(len(validated_options), 1)
        validated_option = validated_options[0]

        # Should preserve all original fields
        self.assertEqual(validated_option["code"], "A")
        self.assertEqual(validated_option["name"], "Agricultural products")
        self.assertEqual(
            validated_option["description"], "Products derived from agriculture"
        )
        self.assertEqual(validated_option["semantic_score"], 0.8)
        self.assertEqual(validated_option["keyword_score"], 2)
        self.assertEqual(validated_option["score"], 10.0)
        self.assertEqual(validated_option["extra_field"], "preserved")

    def test_validate_options_functional_integration(self):
        """Test validate_options_similarity_threshold as it would be used in clarify_components tool."""
        # This test simulates how the function would be used within the clarify_components tool
        # to filter options before presenting them to users

        # Simulate options that might come from find_component_matches
        component_options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products derived from agriculture and farming",
                "semantic_score": 0.9,
                "keyword_score": 3,
                "score": 12.0,
                "filter_reason": "high_semantic_similarity (0.90 >= 0.30)",
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical and pharmaceutical products",
                "semantic_score": 0.2,
                "keyword_score": 1,
                "score": 3.0,
                "filter_reason": "low_semantic_similarity (0.20 < 0.30)",
            },
            {
                "code": "M",
                "name": "Mechanical products",
                "description": "Machinery and mechanical equipment",
                "keyword_score": 6,
                "score": 6.0,
                # No semantic_score - this might happen in some edge cases
                "filter_reason": "strong_keyword_matches (6 >= 4)",
            },
        ]

        # Use the same default threshold as the clarify_components tool
        threshold = 0.3
        validated_options = validate_options_similarity_threshold(
            component_options, threshold
        )

        # Should include A (high semantic similarity) and M (strong keyword matches, no semantic_score)
        # Should NOT include C (low semantic similarity)
        validated_codes = [opt["code"] for opt in validated_options]
        self.assertIn("A", validated_codes)
        self.assertIn("M", validated_codes)
        self.assertNotIn("C", validated_codes)

        # Verify that the included options would be appropriate for user presentation
        for option in validated_options:
            # Options presented to users should have proper structure
            self.assertIn("code", option)
            self.assertIn("name", option)
            self.assertIn("description", option)

            # Should have either high semantic similarity or be a keyword fallback
            if "semantic_score" in option:
                self.assertGreaterEqual(option["semantic_score"], threshold)

            # All should have reasonable scores
            self.assertGreater(option["score"], 0)


if __name__ == "__main__":
    # Run the tests
    unittest.main()
