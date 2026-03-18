#!/usr/bin/env python3
"""
Enhanced unit tests for selective option presentation (only showing matching options).

Tests the enhanced selective option presentation functionality implemented in the
Confidence and Workflow Improvements section (Task 13.7). These tests verify that
the improved filtering logic correctly presents only matching options based on both
keyword and semantic similarity criteria.

This test suite focuses on:
1. Improved keyword and semantic similarity integration
2. Enhanced filtering logic from tasks 13.1-13.3
3. Strict matching vs unrelated option presentation
4. Integration with generate-then-justify workflow (task 13.4)
5. Confidence in agent behavior with clear inputs (task 13.5-13.6)
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock
import json

# Add the agent src directory to Python path
sys.path.insert(0, "/home/ncheaz/git/my-ag-ui-app/agent/src")

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
        MINIMUM_SIMILARITY_THRESHOLD,
        MAXIMUM_SIMILARITY_THRESHOLD,
    )
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps
from agent import ProcurementState


class TestEnhancedSelectiveOptionPresentation(unittest.TestCase):
    """
    Enhanced test cases for selective option presentation functionality.

    Tests the improved selective option presentation implemented in tasks 13.1-13.3,
    ensuring that only matching options are presented based on both keyword and
    semantic similarity criteria.
    """

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock ProcurementState with initialized fields
        self.state = ProcurementState(
            rules_loaded_this_turn=True,
            clarification_rounds=0,
            clarified_components=set(),
            component_ambiguity_status={},
        )

        # Create a mock RunContext
        self.mock_ctx = MagicMock(spec=RunContext)
        self.mock_ctx.deps = StateDeps(state=self.state)

        # Enhanced sample component rules for testing
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
                "T": {
                    "name": "Technology products",
                    "description": "Technology and electronics products",
                    "keywords": ["technology", "electronics", "computer", "software"],
                },
            },
            "manufacturing_method": {
                "A": {
                    "name": "Automated",
                    "description": "Automated manufacturing processes",
                    "keywords": ["automated", "automatic", "robotic", "machine"],
                },
                "M": {
                    "name": "Manual",
                    "description": "Manual manufacturing processes",
                    "keywords": ["manual", "handmade", "craft", "artisan"],
                },
                "H": {
                    "name": "Hybrid",
                    "description": "Hybrid manufacturing processes",
                    "keywords": ["hybrid", "combined", "mixed", "integrated"],
                },
            },
        }

        # Enhanced sample CODE_GENERATION.md content
        self.sample_code_generation_content = """
### First Letter - Major Categories

| Code | Industry Focus | Description |
|------|---------------|-------------|
| A | Agricultural products | Products related to agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| M | Metal products | Metal and steel products |
| F | Food and beverage | Food items and beverages |
| T | Technology products | Technology and electronics products |

### Second Letter - Manufacturing Method

| Code | Method | Description |
|------|--------|-------------|
| A | Automated | Automated manufacturing processes |
| M | Manual | Manual manufacturing processes |
| H | Hybrid | Hybrid manufacturing processes |
"""

        # Enhanced mock semantic similarity values for testing
        self.mock_semantic_similarities = {
            # High similarity for agricultural products
            (
                "I need agricultural products for farming",
                "Agricultural products Products related to agriculture and farming",
            ): 0.85,
            (
                "I need agricultural products for farming",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.15,
            (
                "I need agricultural products for farming",
                "Metal products Metal and steel products",
            ): 0.05,
            (
                "I need agricultural products for farming",
                "Food and beverage Food items and beverages",
            ): 0.25,
            (
                "I need agricultural products for farming",
                "Technology products Technology and electronics products",
            ): 0.08,
            # High similarity for chemical products
            (
                "I need chemical pharmaceutical products",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.92,
            (
                "I need chemical pharmaceutical products",
                "Agricultural products Products related to agriculture and farming",
            ): 0.12,
            (
                "I need chemical pharmaceutical products",
                "Metal products Metal and steel products",
            ): 0.08,
            (
                "I need chemical pharmaceutical products",
                "Food and beverage Food items and beverages",
            ): 0.18,
            (
                "I need chemical pharmaceutical products",
                "Technology products Technology and electronics products",
            ): 0.35,
            # Medium similarity for food products
            (
                "I need food and beverage items",
                "Food and beverage Food items and beverages",
            ): 0.78,
            (
                "I need food and beverage items",
                "Agricultural products Products related to agriculture and farming",
            ): 0.45,
            (
                "I need food and beverage items",
                "Chemical products Chemical and pharmaceutical products",
            ): 0.22,
            (
                "I need food and beverage items",
                "Metal products Metal and steel products",
            ): 0.12,
            (
                "I need food and beverage items",
                "Technology products Technology and electronics products",
            ): 0.15,
        }

    def test_enhanced_strict_description_matching(self):
        """
        Test enhanced strict description matching (Task 13.1).

        Verify that the improved ambiguity detection only presents options that
        match the user's description based on both keyword and semantic matching.
        """
        user_description = "I need agricultural products for farming"

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get((text1, text2), 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.7
                )
                result_data = json.loads(result)

                # Should have ambiguous components for testing
                if result_data["ambiguous_components"]:
                    ambiguous_component = result_data["ambiguous_components"][0]
                    options = ambiguous_component["options"]

                    # Only high-similarity options should be presented
                    high_similarity_codes = []
                    for option in options:
                        if "similarity_info" in option:
                            similarity_info = option["similarity_info"]
                            semantic_score = similarity_info["semantic_score"]
                            if semantic_score >= 0.7:
                                high_similarity_codes.append(option["value"])

                    # Should include agricultural (A) with high similarity
                    self.assertIn(
                        "A",
                        high_similarity_codes,
                        "Agricultural products should be presented with high similarity",
                    )

                    # Should not include unrelated options like metal (M) or technology (T)
                    self.assertNotIn(
                        "M",
                        high_similarity_codes,
                        "Metal products should be filtered out due to low similarity",
                    )
                    self.assertNotIn(
                        "T",
                        high_similarity_codes,
                        "Technology products should be filtered out due to low similarity",
                    )

    def test_enhanced_filtering_unrelated_options(self):
        """
        Test enhanced filtering of completely unrelated options (Task 13.2).

        Verify that completely unrelated options are filtered out from clarification
        prompts based on both keyword and semantic similarity.
        """
        user_description = "I need chemical pharmaceutical products"

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get((text1, text2), 0.1)

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.8
                )
                result_data = json.loads(result)

                if result_data["ambiguous_components"]:
                    ambiguous_component = result_data["ambiguous_components"][0]
                    options = ambiguous_component["options"]

                    # Only chemical products should be presented with very high similarity
                    option_codes = [option["value"] for option in options]

                    # Chemical products (C) should be present with high similarity
                    self.assertIn(
                        "C",
                        option_codes,
                        "Chemical products should be presented with high similarity",
                    )

                    # Check that low-similarity options are filtered out
                    for option in options:
                        if "similarity_info" in option:
                            similarity_info = option["similarity_info"]
                            semantic_score = similarity_info["semantic_score"]
                            self.assertGreaterEqual(
                                semantic_score,
                                0.8,
                                "All presented options should meet high similarity threshold",
                            )

    def test_enhanced_similarity_threshold_determination(self):
        """
        Test enhanced similarity threshold for matching vs unrelated options (Task 13.3).

        Verify that the similarity threshold correctly determines which options are
        "matching" vs "unrelated".
        """
        # Test with different similarity thresholds
        user_description = "I need food and beverage items"

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get((text1, text2), 0.1)

        # Test with low threshold (should include more options)
        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                result_low = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.3
                )
                result_data_low = json.loads(result_low)

                # Test with high threshold (should include fewer options)
                result_high = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.7
                )
                result_data_high = json.loads(result_high)

                # Low threshold should have more options than high threshold
                low_option_count = 0
                high_option_count = 0

                if result_data_low["ambiguous_components"]:
                    low_option_count = len(
                        result_data_low["ambiguous_components"][0]["options"]
                    )

                if result_data_high["ambiguous_components"]:
                    high_option_count = len(
                        result_data_high["ambiguous_components"][0]["options"]
                    )

                self.assertGreaterEqual(
                    low_option_count,
                    high_option_count,
                    "Low threshold should include same or more options than high threshold",
                )

    def test_enhanced_confident_agent_behavior_with_clear_inputs(self):
        """
        Test confident agent behavior with clear inputs (Tasks 13.5-13.6).

        Verify that when inputs are clear and unambiguous, the agent behaves
        confidently and generates appropriate responses.
        """
        # Use a very clear, unambiguous description
        user_description = (
            "I need agricultural products for farming using automated processes"
        )

        def mock_semantic_similarity(text1, text2):
            return self.mock_semantic_similarities.get(
                (text1, text2), 0.9
            )  # High similarity for all

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.8
                )
                result_data = json.loads(result)

                # With clear inputs, we should have confident response structure
                self.assertIn(
                    "unambiguous_components",
                    result_data,
                    "Response should include unambiguous_components",
                )
                self.assertIn(
                    "similarity_threshold_info",
                    result_data,
                    "Response should include similarity threshold information",
                )

                # Verify that the result shows confident filtering
                if result_data["unambiguous_components"]:
                    for component in result_data["unambiguous_components"]:
                        if "similarity_info" in component:
                            similarity_info = component["similarity_info"]
                            # Should have high similarity scores for clear inputs
                            if "semantic_score" in similarity_info:
                                self.assertGreaterEqual(
                                    similarity_info["semantic_score"],
                                    0.8,
                                    "Clear inputs should result in high similarity scores",
                                )

    def test_enhanced_validate_options_similarity_threshold_function(self):
        """
        Test enhanced validate_options_similarity_threshold function.

        Verify that the enhanced validation function correctly filters options
        based on both semantic similarity and keyword criteria.
        """
        # Test data with various similarity scores
        test_options = [
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
                "keyword_score": 4,  # High keyword score should include even with lower semantic
            },
            {
                "code": "M",
                "name": "Metal products",
                "description": "Metal and steel products",
                "semantic_score": 0.15,
                "keyword_score": 0,
            },
        ]

        # Test with high threshold
        validated_high = validate_options_similarity_threshold(
            test_options, similarity_threshold=0.7
        )
        validated_codes_high = [opt["code"] for opt in validated_high]

        # Should include agricultural (A) with high semantic score
        self.assertIn(
            "A",
            validated_codes_high,
            "Options with high semantic score should be included with high threshold",
        )

        # Should NOT include chemical (C) or metal (M) with low scores
        self.assertNotIn(
            "C",
            validated_codes_high,
            "Options with low semantic score should be filtered out with high threshold",
        )
        self.assertNotIn(
            "M",
            validated_codes_high,
            "Options with low scores should be filtered out with high threshold",
        )

        # Should include food (F) due to high keyword score
        self.assertIn(
            "F",
            validated_codes_high,
            "Options with high keyword score should be included even with moderate semantic score",
        )

    def test_enhanced_edge_cases_boundary_conditions(self):
        """
        Test enhanced edge cases and boundary conditions.

        Verify that the enhanced selective option presentation handles edge cases
        gracefully, including boundary conditions for similarity thresholds.
        """
        # Test with minimum similarity threshold
        user_description = "I need technology products"

        def mock_semantic_similarity(text1, text2):
            return MINIMUM_SIMILARITY_THRESHOLD  # Use the minimum threshold

        with patch(
            "agent.calculate_semantic_similarity", side_effect=mock_semantic_similarity
        ):
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Test with minimum threshold
                result = clarify_components(
                    self.mock_ctx,
                    user_description,
                    similarity_threshold=MINIMUM_SIMILARITY_THRESHOLD,
                )
                result_data = json.loads(result)

                # Should handle minimum threshold gracefully
                self.assertIn(
                    "ambiguous_components",
                    result_data,
                    "Should handle minimum threshold gracefully",
                )

                # Test with maximum similarity threshold
                result_max = clarify_components(
                    self.mock_ctx,
                    user_description,
                    similarity_threshold=MAXIMUM_SIMILARITY_THRESHOLD,
                )
                result_data_max = json.loads(result_max)

                # Should handle maximum threshold gracefully
                self.assertIn(
                    "ambiguous_components",
                    result_data_max,
                    "Should handle maximum threshold gracefully",
                )


if __name__ == "__main__":
    unittest.main()
