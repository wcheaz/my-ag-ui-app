#!/usr/bin/env python3
"""
Unit tests for selective option filtering in clarify_components tool.

Tests the actual filtering behavior within the clarify_components tool,
ensuring that options are properly filtered based on similarity threshold
before being presented to users. This tests the integration of the filtering
logic within the tool, not just the helper functions in isolation.
"""

import json
import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock

# Mock the dependencies at system level before any imports
sys.modules["llama_index"] = MagicMock()
sys.modules["llama_index.core"] = MagicMock()
sys.modules["llama_index.embeddings"] = MagicMock()
sys.modules["llama_index.embeddings.huggingface"] = MagicMock()
sys.modules["src"] = MagicMock()
sys.modules["src.rag"] = MagicMock()
sys.modules["src.rag.index"] = MagicMock()
sys.modules["src.rag.settings"] = MagicMock()
sys.modules["src.rag.citation"] = MagicMock()
sys.modules["src.rag.query"] = MagicMock()

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

# Now import the agent modules
from agent import (
    clarify_components,
    ProcurementState,
    AmbiguityInfo,
)

# Import these outside the mock context
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps


class TestSelectiveOptionFilteringInClarifyComponents(unittest.TestCase):
    """Test cases for selective option filtering within the clarify_components tool."""

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock ProcurementState
        self.state = ProcurementState(
            rules_loaded_this_turn=True  # Set to True to bypass validation
        )

        # Create a mock RunContext
        self.mock_ctx = Mock(spec=RunContext)
        self.mock_ctx.deps = StateDeps(state=self.state)

        # Sample CODE_GENERATION.md content for testing
        self.sample_code_generation_content = """
### First Letter - Major Categories
| Code | Industry Focus | Description |
|------|----------------|-------------|
| A | Agricultural products | Products derived from agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| T | Textile products | Clothing and textile materials |
| M | Mechanical products | Machinery and mechanical equipment |

### Second Letter - Manufacturing Method
| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| A | Additive manufacturing | 3D printing and additive processes |
| B | Blow molding | Plastic molding processes |
| C | Casting | Metal and plastic casting |
| F | Forging | Metal forging processes |

### Third Letter - Object Shape/Form
| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| A | Angular | Sharp-cornered shapes |
| B | Barrel/cylindrical | Rounded cylindrical shapes |
| C | Cubic | Box-like shapes |
| R | Rounded | Curved shapes |

### Material Type
| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel |
| 02 | Aluminum | Aluminum alloys |
| 03 | Plastic | Various plastic materials |

### Quality Grade
| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | High-quality commercial |
| 03 | Industrial | Industrial grade materials |

### Size Category
| Code | Size Category | Description |
|------|--------------|-------------|
| 1 | Small | Small items under 10cm |
| 2 | Medium | Medium items 10-50cm |
| 3 | Large | Large items over 50cm |
"""

    def test_selective_option_filtering_with_high_threshold(self):
        """Test that clarify_components filters out options below high similarity threshold."""
        user_description = (
            "I need an agricultural product"  # Should match "A" but not others
        )

        # Mock semantic similarity calculation to return specific values
        with patch("agent.calculate_semantic_similarity") as mock_similarity:
            # Set up similarity scores to test filtering
            def mock_similarity_func(text1, text2):
                # Return specific scores based on content
                if "Agricultural products" in text2:
                    return 0.8  # High similarity - should be included
                elif "Chemical products" in text2:
                    return 0.2  # Low similarity - should be filtered out with high threshold
                elif "Textile products" in text2:
                    return 0.1  # Very low similarity - should be filtered out
                elif "Mechanical products" in text2:
                    return (
                        0.3  # Medium similarity - might be filtered with high threshold
                    )
                else:
                    return 0.0  # Default low similarity

            mock_similarity.side_effect = mock_similarity_func

            # Mock the read_code_generation_file function
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components with high threshold (0.5)
                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.5
                )

                # Parse the JSON result
                result_data = json.loads(result)

                # Verify similarity threshold info is present
                self.assertIn("similarity_threshold_info", result_data)
                self.assertEqual(
                    result_data["similarity_threshold_info"]["threshold_used"], 0.5
                )
                self.assertTrue(
                    result_data["similarity_threshold_info"]["filtering_applied"]
                )

                # Check that ambiguous components have filtered options
                for component in result_data["ambiguous_components"]:
                    if component["component_name"] == "Major Category":
                        # Should only include options that meet the threshold
                        options = component["options"]
                        option_codes = [opt["value"] for opt in options]

                        # "A" should be included (0.8 >= 0.5)
                        self.assertIn("A", option_codes)

                        # "C", "T", "M" should NOT be included (below threshold)
                        self.assertNotIn("C", option_codes)  # 0.2 < 0.5
                        self.assertNotIn("T", option_codes)  # 0.1 < 0.5
                        self.assertNotIn("M", option_codes)  # 0.3 < 0.5

                        # Verify that included options have similarity info
                        for option in options:
                            if "similarity_info" in option:
                                self.assertGreaterEqual(
                                    option["similarity_info"]["semantic_score"], 0.5
                                )

    def test_selective_option_filtering_with_low_threshold(self):
        """Test that clarify_components includes more options with low similarity threshold."""
        user_description = "I need an agricultural product"

        # Mock semantic similarity calculation to return specific values
        with patch("agent.calculate_semantic_similarity") as mock_similarity:

            def mock_similarity_func(text1, text2):
                if "Agricultural products" in text2:
                    return 0.8
                elif "Chemical products" in text2:
                    return 0.2
                elif "Textile products" in text2:
                    return 0.1
                elif "Mechanical products" in text2:
                    return 0.3
                else:
                    return 0.0

            mock_similarity.side_effect = mock_similarity_func

            # Mock the read_code_generation_file function
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components with low threshold (0.15)
                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.15
                )

                # Parse the JSON result
                result_data = json.loads(result)

                # Verify similarity threshold info is present
                self.assertIn("similarity_threshold_info", result_data)
                self.assertEqual(
                    result_data["similarity_threshold_info"]["threshold_used"], 0.15
                )

                # Check that ambiguous components include more options
                for component in result_data["ambiguous_components"]:
                    if component["component_name"] == "Major Category":
                        options = component["options"]
                        option_codes = [opt["value"] for opt in options]

                        # With low threshold, more options should be included
                        # "A" should be included (0.8 >= 0.15)
                        # "C" should be included (0.2 >= 0.15)
                        # "M" should be included (0.3 >= 0.15)
                        # "T" should NOT be included (0.1 < 0.15)
                        self.assertIn("A", option_codes)
                        self.assertIn("C", option_codes)
                        self.assertIn("M", option_codes)
                        self.assertNotIn("T", option_codes)

    def test_selective_option_filtering_with_keyword_fallback(self):
        """Test that strong keyword matches are included even with low semantic similarity."""
        user_description = (
            "steel steel steel steel steel steel"  # Strong keyword match for "Steel"
        )

        # Mock semantic similarity calculation to return low values
        with patch("agent.calculate_semantic_similarity") as mock_similarity:
            mock_similarity.return_value = 0.1  # Low semantic similarity for all

            # Mock the read_code_generation_file function
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components with high threshold (0.5)
                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.5
                )

                # Parse the JSON result
                result_data = json.loads(result)

                # Find material type component
                for component in result_data["ambiguous_components"]:
                    if component["component_name"] == "Material Type":
                        options = component["options"]
                        option_codes = [opt["value"] for opt in options]

                        # "01" (Steel) should be included due to strong keyword matches
                        # even though semantic similarity is low (0.1 < 0.5)
                        self.assertIn("01", option_codes)

                        # Check if it was included due to keyword matches
                        steel_option = None
                        for option in options:
                            if option["value"] == "01":
                                steel_option = option
                                break

                        if steel_option and "similarity_info" in steel_option:
                            # The filter reason should indicate strong keyword matches
                            self.assertIn(
                                "keyword",
                                steel_option["similarity_info"].get(
                                    "filter_reason", ""
                                ),
                            )

    def test_selective_option_filtering_unambiguous_components(self):
        """Test that selective option filtering also applies to unambiguous components."""
        user_description = "I need a steel additive manufactured angular bracket"

        # Mock semantic similarity calculation
        with patch("agent.calculate_semantic_similarity") as mock_similarity:

            def mock_similarity_func(text1, text2):
                # Return high similarity for the first match (unambiguous)
                # and low similarity for others (should be filtered)
                if "steel" in text2.lower():
                    return 0.9  # High similarity
                elif "aluminum" in text2.lower():
                    return 0.2  # Low similarity - should be filtered
                elif "plastic" in text2.lower():
                    return 0.1  # Very low similarity - should be filtered
                else:
                    return 0.0

            mock_similarity.side_effect = mock_similarity_func

            # Mock the read_code_generation_file function
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components with threshold (0.5)
                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.5
                )

                # Parse the JSON result
                result_data = json.loads(result)

                # Check unambiguous components
                for component in result_data["unambiguous_components"]:
                    if component["component_name"] == "Material Type":
                        # Should have selected_value for steel
                        self.assertEqual(component["selected_value"], "01")

                        # Should have similarity info
                        self.assertIn("similarity_info", component)

                        # Semantic score should be above threshold
                        self.assertGreaterEqual(
                            component["similarity_info"]["semantic_score"], 0.5
                        )

    def test_selective_option_filtering_similarity_threshold_info(self):
        """Test that similarity threshold information is properly included in response."""
        user_description = "I need a product"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Call clarify_components
            result = clarify_components(
                self.mock_ctx, user_description, similarity_threshold=0.4
            )

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify similarity_threshold_info structure
            self.assertIn("similarity_threshold_info", result_data)
            threshold_info = result_data["similarity_threshold_info"]

            # Check required fields
            required_fields = ["threshold_used", "filtering_applied", "description"]
            for field in required_fields:
                self.assertIn(field, threshold_info)

            # Check values
            self.assertEqual(threshold_info["threshold_used"], 0.4)
            self.assertTrue(threshold_info["filtering_applied"])
            self.assertIn("similarity", threshold_info["description"].lower())

            # Should have counts information
            self.assertIn("total_options_filtered", threshold_info)
            self.assertIn("options_presented", threshold_info)

    def test_selective_option_filtering_with_zero_threshold(self):
        """Test selective option filtering with zero threshold (should include all options)."""
        user_description = "I need an agricultural product"

        # Mock semantic similarity calculation
        with patch("agent.calculate_semantic_similarity") as mock_similarity:

            def mock_similarity_func(text1, text2):
                if "Agricultural products" in text2:
                    return 0.8
                elif "Chemical products" in text2:
                    return 0.2
                elif "Textile products" in text2:
                    return 0.1
                elif "Mechanical products" in text2:
                    return 0.3
                else:
                    return 0.0

            mock_similarity.side_effect = mock_similarity_func

            # Mock the read_code_generation_file function
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call clarify_components with zero threshold
                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.0
                )

                # Parse the JSON result
                result_data = json.loads(result)

                # With zero threshold, all options should be included
                for component in result_data["ambiguous_components"]:
                    if component["component_name"] == "Major Category":
                        options = component["options"]
                        option_codes = [opt["value"] for opt in options]

                        # All options should be included with zero threshold
                        self.assertIn("A", option_codes)
                        self.assertIn("C", option_codes)
                        self.assertIn("T", option_codes)
                        self.assertIn("M", option_codes)

    def test_selective_option_filtering_edge_cases(self):
        """Test edge cases for selective option filtering."""
        user_description = "I need a product"

        # Mock semantic similarity to return edge case values
        with patch("agent.calculate_semantic_similarity") as mock_similarity:

            def mock_similarity_func(text1, text2):
                # Return boundary values
                if "Agricultural products" in text2:
                    return 1.0  # Maximum similarity
                elif "Chemical products" in text2:
                    return 0.0  # Minimum similarity
                elif "Textile products" in text2:
                    return 0.5  # Exactly at threshold
                else:
                    return 0.1

            mock_similarity.side_effect = mock_similarity_func

            # Mock the read_code_generation_file function
            with patch("agent.read_code_generation_file") as mock_read:
                mock_read.return_value = self.sample_code_generation_content

                # Call with threshold of 0.5
                result = clarify_components(
                    self.mock_ctx, user_description, similarity_threshold=0.5
                )

                # Parse the JSON result
                result_data = json.loads(result)

                # Check boundary filtering
                for component in result_data["ambiguous_components"]:
                    if component["component_name"] == "Major Category":
                        options = component["options"]
                        option_codes = [opt["value"] for opt in options]

                        # Should include A (1.0 >= 0.5) and T (0.5 >= 0.5)
                        # Should NOT include C (0.0 < 0.5)
                        self.assertIn("A", option_codes)
                        self.assertIn("T", option_codes)
                        self.assertNotIn("C", option_codes)


if __name__ == "__main__":
    # Run the tests
    unittest.main()
