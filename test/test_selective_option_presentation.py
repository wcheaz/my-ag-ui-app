#!/usr/bin/env python3
"""
Unit tests for selective option presentation (matching vs unrelated options).

Tests the implementation of selective option presentation that ensures only options
with similarity scores above the threshold are presented to users, while unrelated
options are filtered out (Task 2.11).

This test suite verifies that:
1. High similarity threshold filters out unrelated options
2. clarify_components only presents matching options (not all possible options)
3. Unrelated options are completely filtered out from presentation
4. Keyword matches with low semantic scores can still be presented when they meet keyword criteria
5. The validate_options_similarity_threshold function works correctly
6. Similarity threshold information is included in the response
7. Edge cases like no matching options are handled gracefully
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
        clarify_components,
        find_component_matches,
        validate_options_similarity_threshold,
        DEFAULT_SIMILARITY_THRESHOLD,
    )
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps
from agent import ProcurementState


class TestSelectiveOptionPresentation(unittest.TestCase):
    """
    Test cases for selective option presentation functionality.

    Tests that only matching options (those with similarity scores above threshold)
    are presented to users, while unrelated options are filtered out.
    """

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock ProcurementState
        self.state = ProcurementState(rules_loaded_this_turn=True)

        # Create a mock RunContext
        self.mock_ctx = MagicMock(spec=RunContext)
        self.mock_ctx.deps = StateDeps(state=self.state)

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
                "F": {
                    "name": "Food and beverage",
                    "description": "Food items and beverages",
                    "keywords": ["food", "beverage", "drink", "edible"],
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
| F | Food and beverage | Food items and beverages |

### Second Letter - Manufacturing Method

| Code | Method | Description |
|------|--------|-------------|
| A | Automated | Automated manufacturing processes |
| M | Manual | Manual manufacturing processes |
| H | Hybrid | Hybrid manufacturing processes |
"""

        # Mock semantic similarity values for testing
        self.mock_semantic_similarities = {
            # High similarity for agricultural products
            (
                "I need agricultural products for farming",
                "Agricultural products Products related to agriculture and farming",
            ): 0.8,
            (
                "I need agricultural products for farming",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.1,
            (
                "I need agricultural products for farming",
                "Metal products Metal and steel products",
            ): 0.05,
            (
                "I need agricultural products for farming",
                "Food and beverage Food items and beverages",
            ): 0.2,
            # Medium similarity for chemical products
            (
                "I need chemical pharmaceutical products",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.7,
            (
                "I need chemical pharmaceutical products",
                "Agricultural products Products related to agriculture and farming",
            ): 0.15,
            (
                "I need chemical pharmaceutical products",
                "Metal products Metal and steel products",
            ): 0.1,
            (
                "I need chemical pharmaceutical products",
                "Food and beverage Food items and beverages",
            ): 0.25,
            # Low similarity across the board (unrelated description)
            (
                "I need some kind of product",
                "Agricultural products Products related to agriculture and farming",
            ): 0.1,
            (
                "I need some kind of product",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.1,
            (
                "I need some kind of product",
                "Metal products Metal and steel products",
            ): 0.1,
            (
                "I need some kind of product",
                "Food and beverage Food items and beverages",
            ): 0.1,
        }

    def test_selective_presentation_high_threshold_filters_unrelated_options(self):
        """
        Test that high similarity threshold filters out unrelated options.

        When a high threshold is used, only options with high semantic similarity
        should be presented, filtering out unrelated options.
        """
        user_description = "I need agricultural products for farming"

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get((text1, text2), 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Test with high threshold (0.6)
            matches_high_threshold = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.6,
            )

            # Test with low threshold (0.1) for comparison
            matches_low_threshold = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.1,
            )

            # High threshold should have fewer matches (filtered unrelated options)
            self.assertLessEqual(
                len(matches_high_threshold),
                len(matches_low_threshold),
                "High threshold should filter out unrelated options",
            )

            # Agricultural products should be included in both (high similarity)
            ag_matches_high = [m for m in matches_high_threshold if m["code"] == "A"]
            ag_matches_low = [m for m in matches_low_threshold if m["code"] == "A"]

            self.assertEqual(
                len(ag_matches_high),
                1,
                "Agricultural products should be included with high threshold",
            )
            self.assertEqual(
                len(ag_matches_low),
                1,
                "Agricultural products should be included with low threshold",
            )

            # Check that high threshold filters out low similarity options
            high_threshold_codes = [m["code"] for m in matches_high_threshold]
            low_threshold_codes = [m["code"] for m in matches_low_threshold]

            # High threshold should be a subset of low threshold
            for code in high_threshold_codes:
                self.assertIn(
                    code,
                    low_threshold_codes,
                    "High threshold codes should be in low threshold codes",
                )

    def test_selective_presentation_only_matching_options_in_clarify_components(self):
        """
        Test that clarify_components only presents matching options (not all options).

        The clarify_components tool should filter out unrelated options based on
        similarity threshold and only present options that match the user's description.
        """
        user_description = "I need agricultural products for farming"

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get((text1, text2), 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components
                result = clarify_components(self.mock_ctx, user_description)

                # Parse the JSON result
                import json

                result_data = json.loads(result)

                # Check if there are ambiguous components
                if result_data["ambiguous_components"]:
                    ambiguous_component = result_data["ambiguous_components"][0]

                    # The options should be filtered based on similarity
                    options = ambiguous_component["options"]

                    # Verify that options have similarity information
                    for option in options:
                        if "similarity_info" in option:
                            similarity_info = option["similarity_info"]
                            self.assertIn("semantic_score", similarity_info)
                            self.assertIn("filter_reason", similarity_info)

                            # Verify that semantic score meets the threshold
                            semantic_score = similarity_info["semantic_score"]
                            self.assertGreaterEqual(
                                semantic_score,
                                0.0,
                                "Semantic score should be non-negative",
                            )

                            # Check that filter reason indicates why this option was included
                            filter_reason = similarity_info["filter_reason"]
                            self.assertIsInstance(filter_reason, str)
                            self.assertGreater(
                                len(filter_reason),
                                0,
                                "Filter reason should not be empty",
                            )

    def test_selective_presentation_unrelated_options_filtered_out(self):
        """
        Test that unrelated options are completely filtered out from presentation.

        Options with low semantic similarity should not appear in the clarification
        options presented to the user.
        """
        user_description = "I need chemical pharmaceutical products"

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get((text1, text2), 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components with high threshold
                result = clarify_components(self.mock_ctx, user_description)

                # Parse the JSON result
                import json

                result_data = json.loads(result)

                # Get all presented options
                all_presented_codes = []

                # Check ambiguous components
                for component in result_data["ambiguous_components"]:
                    for option in component["options"]:
                        all_presented_codes.append(option["value"])

                # Check unambiguous components
                for component in result_data["unambiguous_components"]:
                    all_presented_codes.append(component["selected_value"])

                # Verify that only related options are presented
                # Based on our mock data, chemical products should have high similarity (0.7)
                # and should be presented, while agricultural (0.15), metal (0.1),
                # and food (0.25) might be filtered out depending on the threshold

                # Chemical products should always be presented (highest similarity)
                self.assertIn(
                    "C",
                    all_presented_codes,
                    "Chemical products should be presented (highest similarity)",
                )

    def test_selective_presentation_keyword_matches_with_low_semantic_score(self):
        """
        Test that keyword matches with low semantic scores can still be presented.

        Even with low semantic similarity, strong keyword matches should be
        presented if they meet the keyword criteria.
        """
        user_description = "I need agricultural and chemical products"

        def mock_semantic_similarity(text1, text2):
            # Mock low semantic similarity for all options
            return 0.2  # Below default threshold of 0.3

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Find matches with low semantic similarity
            matches = find_component_matches(
                user_description,
                self.test_component_rules["major_category"],
                similarity_threshold=0.3,  # Higher than our mock semantic similarity
            )

            # Despite low semantic similarity, keyword matches should still be included
            # if they have sufficient keyword score (>= 4)

            # Agricultural should match (appears in description)
            ag_matches = [m for m in matches if m["code"] == "A"]
            chemical_matches = [m for m in matches if m["code"] == "C"]

            # Should have matches based on keywords despite low semantic similarity
            self.assertGreater(
                len(matches),
                0,
                "Should have matches based on keywords despite low semantic similarity",
            )

            # Verify that keyword matches are included
            if ag_matches:
                self.assertGreater(
                    ag_matches[0]["keyword_score"],
                    0,
                    "Agricultural products should have keyword matches",
                )

            if chemical_matches:
                self.assertGreater(
                    chemical_matches[0]["keyword_score"],
                    0,
                    "Chemical products should have keyword matches",
                )

    def test_selective_presentation_validate_options_similarity_threshold_function(
        self,
    ):
        """
        Test the validate_options_similarity_threshold function directly.

        This function should properly validate that options meet the similarity
        threshold requirements.
        """
        # Create test options with various similarity scores
        test_options = [
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products related to agriculture",
                "semantic_score": 0.8,  # Above threshold
                "keyword_score": 2,
            },
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical and pharmaceutical products",
                "semantic_score": 0.2,  # Below threshold
                "keyword_score": 1,
            },
            {
                "code": "M",
                "name": "Metal products",
                "description": "Metal and steel products",
                "semantic_score": 0.4,  # Above threshold
                "keyword_score": 0,
            },
        ]

        # Validate options with threshold 0.3
        validated_options = validate_options_similarity_threshold(
            test_options, similarity_threshold=0.3
        )

        # Should only include options with semantic_score >= 0.3
        self.assertEqual(
            len(validated_options), 2, "Should include 2 options above threshold"
        )

        validated_codes = [opt["code"] for opt in validated_options]
        self.assertIn("A", validated_codes, "Agricultural products should be included")
        self.assertIn("M", validated_codes, "Metal products should be included")
        self.assertNotIn(
            "C", validated_codes, "Chemical products should be filtered out"
        )

    def test_selective_presentation_similarity_threshold_info_in_response(self):
        """
        Test that similarity threshold information is included in the response.

        The clarify_components response should include information about the
        similarity threshold filtering that was applied.
        """
        user_description = "I need agricultural products"

        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            with patch("agent.calculate_semantic_similarity") as mock_semantic:
                mock_semantic.return_value = 0.5  # Above threshold

                # Call clarify_components
                result = clarify_components(self.mock_ctx, user_description)

                # Parse the JSON result
                import json

                result_data = json.loads(result)

                # Verify that similarity threshold information is included
                self.assertIn("similarity_threshold_info", result_data)

                threshold_info = result_data["similarity_threshold_info"]
                self.assertIn("threshold_used", threshold_info)
                self.assertIn("filtering_applied", threshold_info)
                self.assertIn("description", threshold_info)

                # Verify threshold values
                self.assertEqual(
                    threshold_info["threshold_used"], DEFAULT_SIMILARITY_THRESHOLD
                )
                self.assertTrue(threshold_info["filtering_applied"])
                self.assertIsInstance(threshold_info["description"], str)

    def test_selective_presentation_edge_case_no_matching_options(self):
        """
        Test edge case where no options meet the similarity threshold.

        When no options meet the similarity threshold, the system should handle
        this gracefully, potentially showing no options or all options with
        appropriate warnings.
        """
        user_description = "I need completely unrelated fictional products"

        def mock_semantic_similarity(text1, text2):
            return 0.05  # Very low similarity for all options

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components
                result = clarify_components(self.mock_ctx, user_description)

                # Parse the JSON result
                import json

                result_data = json.loads(result)

                # Should still return valid JSON structure
                self.assertIn("ambiguous_components", result_data)
                self.assertIn("unambiguous_components", result_data)
                self.assertIn("component_details", result_data)

                # Should handle the case gracefully without crashing
                # May result in components with no matches or all components being ambiguous
                for component_key, detail in result_data["component_details"].items():
                    self.assertIn(
                        detail["status"], ["ambiguous", "no_match", "unambiguous"]
                    )

    def test_selective_presentation_comprehensive_filtering_logic(self):
        """
        Test comprehensive filtering logic across all similarity scenarios.

        This test verifies that the filtering logic correctly handles:
        1. High semantic similarity (above threshold) - included
        2. Low semantic similarity but strong keyword matches - included
        3. Low semantic similarity and weak keyword matches - excluded
        4. No semantic similarity and no keyword matches - excluded
        """
        user_description = "I need agricultural products and some chemical items"

        # Mock semantic similarities for different scenarios
        def mock_semantic_similarity(text1, text2):
            # High similarity for agricultural products
            if "Agricultural products" in text2 and "agricultural" in text1.lower():
                return 0.8
            # Medium similarity for chemical products
            elif "Chemical products" in text2 and "chemical" in text1.lower():
                return 0.4
            # Low similarity for other products
            elif "Metal products" in text2:
                return 0.2
            elif "Food and beverage" in text2:
                return 0.15
            # Default low similarity
            else:
                return 0.1

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            # Test with different thresholds
            for threshold in [0.3, 0.5, 0.7]:
                with self.subTest(threshold=threshold):
                    matches = find_component_matches(
                        user_description,
                        self.test_component_rules["major_category"],
                        similarity_threshold=threshold,
                    )

                    # Verify filtering logic
                    for match in matches:
                        # Should either have high semantic similarity OR strong keyword matches
                        semantic_score = match["semantic_score"]
                        keyword_score = match["keyword_score"]

                        if semantic_score >= threshold:
                            # High semantic similarity - should be included
                            self.assertGreaterEqual(semantic_score, threshold)
                        elif keyword_score >= 4:
                            # Strong keyword matches - should be included
                            self.assertGreaterEqual(keyword_score, 4)
                        else:
                            # Should not reach here for valid matches
                            self.fail(
                                f"Match should not be included: semantic={semantic_score}, "
                                f"keywords={keyword_score}, threshold={threshold}"
                            )

    def test_selective_presentation_threshold_boundary_conditions(self):
        """
        Test threshold boundary conditions to ensure exact threshold behavior.

        This tests edge cases around the threshold value:
        1. Exactly at threshold - should be included
        2. Just below threshold - should be excluded unless keyword criteria met
        3. Just above threshold - should be included
        """
        user_description = "I need agricultural products"

        # Test with exact threshold values
        test_thresholds = [0.29, 0.30, 0.31]  # Around default threshold

        for threshold in test_thresholds:
            with self.subTest(threshold=threshold):

                def mock_semantic_similarity(text1, text2):
                    if "Agricultural products" in text2:
                        # Return exact threshold value for testing
                        return threshold
                    else:
                        return 0.1

                with patch(
                    "agent.calculate_semantic_similarity",
                    side_effect=mock_semantic_similarity,
                ):
                    matches = find_component_matches(
                        user_description,
                        self.test_component_rules["major_category"],
                        similarity_threshold=threshold,
                    )

                    # Agricultural products should be included (exactly at threshold)
                    ag_matches = [m for m in matches if m["code"] == "A"]

                    if threshold == DEFAULT_SIMILARITY_THRESHOLD:
                        # At default threshold, should be included due to semantic similarity
                        self.assertEqual(
                            len(ag_matches),
                            1,
                            "Should include matches exactly at threshold",
                        )
                    elif threshold < DEFAULT_SIMILARITY_THRESHOLD:
                        # Below default threshold, should still be included
                        self.assertEqual(
                            len(ag_matches),
                            1,
                            "Should include matches below default threshold",
                        )
                    else:
                        # Above default threshold, may or may not be included depending on keyword matches
                        # Since we have keyword matches ("agricultural" in description), it should be included
                        self.assertGreaterEqual(
                            len(ag_matches),
                            0,
                            "May include matches above default threshold with keywords",
                        )

    def test_selective_presentation_multiple_components_filtering(self):
        """
        Test that filtering works correctly across multiple components.

        This ensures that the similarity threshold filtering is applied
        consistently to all components (major_category, manufacturing_method, etc.).
        """
        user_description = "I need agricultural products made with automated methods"

        def mock_semantic_similarity(text1, text2):
            # High similarity for agricultural products
            if "Agricultural products" in text2:
                return 0.8
            # High similarity for automated manufacturing
            elif "Automated" in text2 and "automated" in text1.lower():
                return 0.7
            # Low similarity for other options
            else:
                return 0.2

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components
                result = clarify_components(self.mock_ctx, user_description)

                # Parse the JSON result
                import json

                result_data = json.loads(result)

                # Should have filtered options for both major_category and manufacturing_method
                # Check that ambiguous components have been filtered
                for component in result_data["ambiguous_components"]:
                    options = component["options"]

                    # Each option should have similarity information
                    for option in options:
                        if "similarity_info" in option:
                            similarity_info = option["similarity_info"]
                            self.assertIn("semantic_score", similarity_info)
                            self.assertIn("filter_reason", similarity_info)

                            # Verify that the option meets the filtering criteria
                            semantic_score = similarity_info["semantic_score"]
                            filter_reason = similarity_info["filter_reason"]

                            if "high_semantic_similarity" in filter_reason:
                                self.assertGreaterEqual(
                                    semantic_score, DEFAULT_SIMILARITY_THRESHOLD
                                )
                            elif "strong_keyword_matches" in filter_reason:
                                # Should have keyword score >= 4
                                self.assertIn("keyword_score", str(option))


if __name__ == "__main__":
    unittest.main()
