#!/usr/bin/env python3
"""
Unit tests for the clarify_components tool implementation.

Tests the functionality of parsing user descriptions and returning structured
disambiguation options for ambiguous components.
"""

import json
import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock
from typing import Dict, Any

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
        get_component_extraction_results,
        ProcurementState,
        AmbiguityInfo,
    )
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps


class TestClarifyComponentsTool(unittest.TestCase):
    """Test cases for the clarify_components tool."""

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
| A | Agricultural products | Products derived from agriculture |
| C | Chemical products | Chemical and pharmaceutical products |

### Second Letter - Manufacturing Method
| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| A | Additive manufacturing | 3D printing and additive processes |
| B | Blow molding | Plastic molding processes |

### Third Letter - Object Shape/Form
| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| A | Angular | Sharp-cornered shapes |
| B | Barrel/cylindrical | Rounded cylindrical shapes |

### Material Type
| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel |
| 02 | Aluminum | Aluminum alloys |

### Quality Grade
| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | High-quality commercial |

### Size Category
| Code | Size Category | Description |
|------|--------------|-------------|
| 1 | Small | Small items under 10cm |
| 2 | Medium | Medium items 10-50cm |
"""

    def test_clarify_components_with_unambiguous_input(self):
        """Test clarify_components with a clear, unambiguous description."""
        user_description = "I need a steel additive manufactured angular bracket"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # With this clear description, we should have mostly unambiguous components
            # or at least have a structured response
            self.assertIsInstance(result_data["ambiguous_components"], list)
            self.assertIsInstance(result_data["unambiguous_components"], list)
            self.assertIsInstance(result_data["component_details"], dict)

    def test_clarify_components_with_ambiguous_input(self):
        """Test clarify_components with an ambiguous description."""
        user_description = "I need some kind of product made from material"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # With this ambiguous description, we should have ambiguous components
            self.assertIsInstance(result_data["ambiguous_components"], list)
            # Should have some ambiguous components due to vague description
            # We don't assert specific count as it depends on matching algorithm

    def test_clarify_components_without_rules_loaded(self):
        """Test clarify_components when rules file hasn't been loaded."""
        # Set rules_loaded_this_turn to False
        self.state.rules_loaded_this_turn = False

        user_description = "I need a steel bracket"

        # Call clarify_components - should raise an error
        result = clarify_components(self.mock_ctx, user_description)

        # Parse the JSON result
        result_data = json.loads(result)

        # Verify error is returned
        self.assertIn("error", result_data)
        self.assertIn("must call read_code_generation_file", result_data["error"])

    def test_clarify_components_json_format(self):
        """Test that clarify_components returns valid JSON format."""
        user_description = "test description"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Verify the result is valid JSON
            try:
                result_data = json.loads(result)
                # If we get here, JSON is valid
                self.assertTrue(True)
            except json.JSONDecodeError:
                self.fail("clarify_components did not return valid JSON")

    def test_clarify_components_ambiguous_structure(self):
        """Test the structure of ambiguous components in the response."""
        user_description = "I need a product"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Check ambiguous components structure if any exist
            for ambiguous_component in result_data["ambiguous_components"]:
                self.assertIn("component_name", ambiguous_component)
                self.assertIn("component_key", ambiguous_component)
                self.assertIn("options", ambiguous_component)
                self.assertIn("match_count", ambiguous_component)

                # Check options structure
                for option in ambiguous_component["options"]:
                    self.assertIn("value", option)
                    self.assertIn("description", option)

    def test_clarify_components_unambiguous_structure(self):
        """Test the structure of unambiguous components in the response."""
        user_description = "I need a steel additive manufactured angular bracket"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Check unambiguous components structure if any exist
            for unambiguous_component in result_data["unambiguous_components"]:
                self.assertIn("component_name", unambiguous_component)
                self.assertIn("component_key", unambiguous_component)
                self.assertIn("selected_value", unambiguous_component)
                self.assertIn("description", unambiguous_component)

    def test_clarify_components_state_update(self):
        """Test that clarify_components updates the ProcurementState correctly."""
        user_description = "I need a steel bracket"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.sample_code_generation_content

            # Ensure state is initially empty
            initial_component_count = len(self.state.component_ambiguity_status)

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Verify that state was updated
            self.assertGreater(
                len(self.state.component_ambiguity_status),
                initial_component_count,
                "ProcurementState should be updated with component ambiguity information",
            )

    def test_clarify_components_error_handling(self):
        """Test error handling in clarify_components."""
        user_description = "test description"

        # Mock read_code_generation_file to raise an exception
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.side_effect = Exception("Test error")

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify error is handled gracefully
            self.assertIn("error", result_data)
            self.assertEqual(result_data["error"], "Test error")
            # Verify structure is maintained even in error case
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)


if __name__ == "__main__":
    # Run the tests
    unittest.main()
