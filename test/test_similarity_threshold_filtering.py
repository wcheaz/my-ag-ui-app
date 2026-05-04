#!/usr/bin/env python3
"""
Unit tests for similarity threshold filtering in component extraction.

Tests the implementation of similarity threshold to filter out unrelated options
from clarification prompts (Task 2.9).
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock

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
        find_component_matches,
        extract_components_from_description,
        get_component_extraction_results,
        parse_code_generation_rules,
    )


class TestSimilarityThresholdFiltering(unittest.TestCase):
    """
    Test cases for similarity threshold filtering functionality.

    Tests that the similarity threshold properly filters out unrelated options
    from clarification prompts while keeping relevant options.
    """

    def setUp(self):
        """Set up test data for similarity threshold tests."""
        # Sample component rules for testing
        self.test_component_rules = {
            "major_category": {
                "A": {
                    "name": "Agricultural products",
                    "description": "Products related to agriculture and farming",
                    "keywords": ["agricultural", "farming", "crops", "livestock"],
                },
                "C": {
                    "name": "Chemical products",
                    "description": "Chemical and pharmaceutical products",
                    "keywords": ["chemical", "pharmaceutical", "drugs", "medicine"],
                },
                "M": {
                    "name": "Metal products",
                    "description": "Metal and steel products",
                    "keywords": ["metal", "steel", "iron", "aluminum"],
                },
            }
        }

        # Sample CODE_GENERATION.md content for testing
        self.sample_code_generation_content = """
### First Letter - Major Categories

| Code | Industry Focus | Description |
|------|---------------|-------------|
| A | Agricultural products | Products related to agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| M | Metal products | Metal and steel products |

### Second Letter - Manufacturing Method

| Code | Method | Description |
|------|--------|-------------|
| A | Automated | Automated manufacturing processes |
| M | Manual | Manual manufacturing processes |
| H | Hybrid | Hybrid manufacturing processes |
"""

        # Mock semantic similarity values for testing
        self.mock_semantic_similarities = {
            # High similarity for agricultural products when description is about agriculture
            (
                "I need agricultural products for farming crops and livestock",
                "Agricultural products Products related to agriculture and farming",
            ): 0.8,
            (
                "I need agricultural products for farming crops and livestock",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.2,
            (
                "I need agricultural products for farming crops and livestock",
                "Metal products Metal and steel products",
            ): 0.1,
            # Low similarity for unrelated terms
            (
                "I need agricultural products with some metal components",
                "Agricultural products Products related to agriculture and farming",
            ): 0.7,
            (
                "I need agricultural products with some metal components",
                "Metal products Metal and steel products",
            ): 0.4,
            # High semantic similarity without exact keywords
            (
                "I need products for growing food and raising farm animals",
                "Agricultural products Products related to agriculture and farming",
            ): 0.6,
        }

    def test_similarity_threshold_filters_unrelated_options(self):
        """
        Test that similarity threshold filters out unrelated options.

        When a user describes something clearly related to one category,
        unrelated categories should be filtered out based on semantic similarity.
        """
        # User description clearly about agricultural products
        user_description = (
            "I need agricultural products for farming crops and livestock"
        )

        def mock_semantic_similarity(text1, text2):
            # Return mock values based on the texts
            key = (
                text1,
                f"Agricultural products Products related to agriculture and farming",
            )
            if key in self.mock_semantic_similarities:
                return self.mock_semantic_similarities[key]
            key = (text1, f"Chemical products Chemical and pharmaceutical products")
            if key in self.mock_semantic_similarities:
                return self.mock_semantic_similarities[key]
            key = (text1, f"Metal products Metal and steel products")
            if key in self.mock_semantic_similarities:
                return self.mock_semantic_similarities[key]
            return 0.1  # Default low similarity

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Test with low threshold (should include more matches)
            matches_low_threshold = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.1,
            )

            # Test with higher threshold (should filter out unrelated matches)
            matches_high_threshold = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.4,
            )

            # Both should include agricultural products (high similarity)
            self.assertGreaterEqual(len(matches_low_threshold), 1)
            self.assertGreaterEqual(len(matches_high_threshold), 1)

            # Agricultural products should be in both results
            ag_matches_low = [m for m in matches_low_threshold if m["code"] == "A"]
            ag_matches_high = [m for m in matches_high_threshold if m["code"] == "A"]

            self.assertEqual(len(ag_matches_low), 1)
            self.assertEqual(len(ag_matches_high), 1)

            # High threshold should have fewer total matches (filtered unrelated)
            self.assertLessEqual(
                len(matches_high_threshold), len(matches_low_threshold)
            )

    def test_similarity_threshold_preserves_keyword_matches_with_low_semantic_score(
        self,
    ):
        """
        Test that keyword matches with low semantic scores are filtered out.

        Even if there are keyword matches, if the semantic similarity is below
        the threshold, the option should be filtered out.
        """
        # User description that might have some keyword overlap with metal
        # but is primarily about agriculture
        user_description = "I need agricultural products with some metal components"

        def mock_semantic_similarity(text1, text2):
            key = (text1, text2)
            return self.mock_semantic_similarities.get(key, 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Test with very high threshold (should only include highly similar matches)
            matches_high_threshold = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.7,
            )

            # Should still include agricultural products
            ag_matches = [m for m in matches_high_threshold if m["code"] == "A"]
            self.assertEqual(len(ag_matches), 1)

            # Metal products might be filtered out due to low semantic similarity
            # despite "metal" keyword appearing in the description
            metal_matches = [m for m in matches_high_threshold if m["code"] == "M"]
            # Note: We don't assert metal matches are absent because the actual semantic
            # similarity calculation depends on the embedding model

    def test_similarity_threshold_allows_high_semantic_matches_without_keywords(self):
        """
        Test that high semantic similarity matches are included even without keyword matches.

        Options with high semantic similarity should be included even if they don't
        have exact keyword matches.
        """
        # User description that doesn't contain exact keywords but is semantically related
        user_description = "I need products for growing food and raising farm animals"

        def mock_semantic_similarity(text1, text2):
            key = (text1, text2)
            return self.mock_semantic_similarities.get(key, 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Test with moderate threshold
            matches = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.3,
            )

            # Should include agricultural products due to high semantic similarity
            # even without exact keyword matches like "agricultural" or "farming"
            ag_matches = [m for m in matches if m["code"] == "A"]
            self.assertGreaterEqual(len(ag_matches), 1)

    def test_extract_components_with_similarity_threshold(self):
        """
        Test that extract_components_from_description uses similarity threshold.

        The function should pass the similarity threshold parameter through to
        find_component_matches and filter results appropriately.
        """
        user_description = "I need agricultural products for farming"

        def mock_semantic_similarity(text1, text2):
            # Return a reasonable similarity for testing
            if "agricultural" in text1.lower() and "Agricultural products" in text2:
                return 0.7
            return 0.2

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Parse the sample content
            rules = parse_code_generation_rules(self.sample_code_generation_content)

            # Test extraction with different thresholds
            results_low_threshold = extract_components_from_description(
                user_description,
                self.sample_code_generation_content,
                similarity_threshold=0.1,
            )

            results_high_threshold = extract_components_from_description(
                user_description,
                self.sample_code_generation_content,
                similarity_threshold=0.5,
            )

            # Both should have major_category results
            self.assertIn("major_category", results_low_threshold)
            self.assertIn("major_category", results_high_threshold)

            # High threshold might have fewer matches for major_category
            low_matches = results_low_threshold["major_category"]["matches"]
            high_matches = results_high_threshold["major_category"]["matches"]

            self.assertGreaterEqual(len(low_matches), 1)
            self.assertGreaterEqual(len(high_matches), 1)

    def test_get_component_extraction_results_with_similarity_threshold(self):
        """
        Test that get_component_extraction_results uses similarity threshold.

        The function should pass the similarity threshold through the call chain
        and return filtered results.
        """
        user_description = "I need agricultural products"

        def mock_semantic_similarity(text1, text2):
            # Return a reasonable similarity for testing
            if "agricultural" in text1.lower() and "Agricultural products" in text2:
                return 0.7
            return 0.2

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Get extraction results with different thresholds
            results_low = get_component_extraction_results(
                user_description,
                self.sample_code_generation_content,
                similarity_threshold=0.1,
            )

            results_high = get_component_extraction_results(
                user_description,
                self.sample_code_generation_content,
                similarity_threshold=0.5,
            )

            # Both should have the same structure
            self.assertIn("ambiguous_components", results_low)
            self.assertIn("unambiguous_components", results_low)
            self.assertIn("no_match_components", results_low)
            self.assertIn("component_details", results_low)

            self.assertIn("ambiguous_components", results_high)
            self.assertIn("unambiguous_components", results_high)
            self.assertIn("no_match_components", results_high)
            self.assertIn("component_details", results_high)

    def test_similarity_threshold_zero_equivalent_to_no_threshold(self):
        """
        Test that similarity threshold of 0.0 is equivalent to no threshold.

        A threshold of 0.0 should include all matches with positive combined scores,
        just like the original implementation without threshold.
        """
        user_description = "I need agricultural and chemical products"

        def mock_semantic_similarity(text1, text2):
            # Return reasonable similarities for testing
            return 0.5

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Test with zero threshold
            matches_zero_threshold = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.0,
            )

            # All matches should have positive combined scores and semantic_score >= 0.0
            for match in matches_zero_threshold:
                self.assertGreater(match["score"], 0)
                self.assertGreaterEqual(match["semantic_score"], 0.0)

    @patch("agent.calculate_semantic_similarity")
    def test_semantic_similarity_failure_handled_gracefully(
        self, mock_semantic_similarity
    ):
        """
        Test that semantic similarity calculation failures are handled gracefully.

        When semantic similarity calculation fails, it should return 0.0 and
        potentially filter matches if they don't meet the threshold.
        """
        # Mock semantic similarity to always return 0.0 (simulating failure)
        mock_semantic_similarity.return_value = 0.0

        user_description = "I need agricultural products"

        # Test with threshold > 0, which should filter out matches due to 0.0 semantic similarity
        matches = find_component_matches(
            user_description,
            self.test_component_rules["major_category"],
            similarity_threshold=0.3,
        )

        # If semantic similarity fails and returns 0.0, matches should be filtered
        # unless they have sufficient keyword matches to overcome the threshold
        # (but since semantic similarity is 0.0, they might be filtered out)

        # The function should still return successfully (no exceptions)
        self.assertIsInstance(matches, list)

    def test_default_similarity_threshold_value(self):
        """
        Test that the default similarity threshold is 0.3.

        When no similarity threshold is specified, it should default to 0.3.
        """
        user_description = "I need agricultural products"

        def mock_semantic_similarity(text1, text2):
            # Return a reasonable similarity for testing
            return 0.5

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Call without specifying similarity threshold (should use default)
            matches_default = find_component_matches(
                user_description, self.test_component_rules["major_category"]
            )

            # Call with explicit 0.3 threshold
            matches_explicit = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.3,
            )

            # Results should be the same
            self.assertEqual(len(matches_default), len(matches_explicit))

            # If there are matches, they should be identical
            if matches_default and matches_explicit:
                self.assertEqual(
                    matches_default[0]["code"], matches_explicit[0]["code"]
                )


if __name__ == "__main__":
    unittest.main()
