#!/usr/bin/env python3
"""
Integration tests for the clarify_components tool with various input scenarios.

These tests verify the end-to-end functionality of the disambiguation workflow,
including component extraction, ambiguity detection, and structured JSON response
generation across different types of user inputs.
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
        ProcurementState,
        AmbiguityInfo,
    )
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps


class TestClarifyComponentsIntegration(unittest.TestCase):
    """Integration test cases for the clarify_components tool with various input scenarios."""

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock ProcurementState
        self.state = ProcurementState(
            rules_loaded_this_turn=True  # Set to True to bypass validation
        )

        # Create a mock RunContext
        self.mock_ctx = Mock(spec=RunContext)
        self.mock_ctx.deps = StateDeps(state=self.state)

        # Complete CODE_GENERATION.md content for realistic testing
        self.complete_code_generation_content = """
### First Letter - Major Categories
| Code | Industry Focus | Description |
|------|----------------|-------------|
| A | Agricultural products | Products derived from agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| F | Food and beverage | Food items and beverages |
| M | Metal products | Metal-based products and components |
| T | Textile products | Textiles and clothing items |

### Second Letter - Manufacturing Method
| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| A | Additive manufacturing | 3D printing and additive processes |
| B | Blow molding | Plastic molding processes |
| C | Casting | Metal casting processes |
| F | Forging | Metal forging processes |
| M | Machining | CNC and traditional machining |
| W | Welding | Welding and joining processes |

### Third Letter - Object Shape/Form
| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| A | Angular | Sharp-cornered shapes |
| B | Barrel/cylindrical | Rounded cylindrical shapes |
| C | Cubic | Cube or box-like shapes |
| F | Flat/sheet | Flat or sheet-like objects |
| R | Round/spherical | Spherical or rounded objects |
| T | Tubular | Hollow tube-like shapes |

### Material Type
| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel, stainless steel |
| 02 | Aluminum | Aluminum alloys, pure aluminum |
| 03 | Plastic | Various plastic polymers |
| 04 | Wood | Natural wood, engineered wood |
| 05 | Glass | Glass materials, fiberglass |
| 06 | Composite | Composite materials, carbon fiber |
| 07 | Ceramic | Ceramic materials, porcelain |

### Quality Grade
| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | High-quality commercial |
| 03 | Industrial | Heavy-duty industrial use |
| 04 | Aerospace | Aerospace-grade quality |
| 05 | Medical | Medical-grade quality |

### Size Category
| Code | Size Category | Description |
|------|--------------|-------------|
| 1 | Small | Small items under 10cm |
| 2 | Medium | Medium items 10-50cm |
| 3 | Large | Large items 50-100cm |
| 4 | Extra Large | Extra large items over 100cm |
"""

    def test_scenario_1_clear_unambiguous_input(self):
        """Test Scenario 1: Clear, unambiguous input with all components specified."""
        user_description = "I need a steel additive manufactured angular bracket for industrial use, medium size"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # With this clear description, we should have few or no ambiguous components
            # Most components should be identified correctly
            self.assertIsInstance(result_data["unambiguous_components"], list)
            self.assertIsInstance(result_data["ambiguous_components"], list)

            # Verify that component_details contains all expected components
            expected_components = [
                "major_category",
                "manufacturing_method",
                "object_shape",
                "material_type",
                "quality_grade",
                "size_category",
            ]
            for component in expected_components:
                self.assertIn(component, result_data["component_details"])

    def test_scenario_2_highly_ambiguous_input(self):
        """Test Scenario 2: Highly ambiguous input with vague descriptions."""
        user_description = "I need some kind of product made of material for something"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # With this vague description, most components should be ambiguous
            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            # Should have several ambiguous components due to vague description
            self.assertGreater(
                ambiguous_count,
                2,
                "Vague description should result in multiple ambiguous components",
            )

            # Verify ambiguous components structure
            for ambiguous_component in result_data["ambiguous_components"]:
                self.assertIn("component_name", ambiguous_component)
                self.assertIn("component_key", ambiguous_component)
                self.assertIn("options", ambiguous_component)
                self.assertIn("match_count", ambiguous_component)

                # Should have multiple options for each ambiguous component
                self.assertGreater(ambiguous_component["match_count"], 1)
                self.assertGreater(len(ambiguous_component["options"]), 1)

    def test_scenario_3_mixed_ambiguous_and_unambiguous(self):
        """Test Scenario 3: Mixed ambiguous and unambiguous components."""
        user_description = "I need a metal product that's manufactured, but I'm not sure about the shape"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Should have both ambiguous and unambiguous components
            self.assertIsInstance(result_data["ambiguous_components"], list)
            self.assertIsInstance(result_data["unambiguous_components"], list)

            # Should have at least one ambiguous component
            ambiguous_count = len(result_data["ambiguous_components"])
            self.assertGreater(
                ambiguous_count, 0, "Should have at least one ambiguous component"
            )

            # Should have at least one unambiguous component (metal product)
            unambiguous_count = len(result_data["unambiguous_components"])
            self.assertGreater(
                unambiguous_count, 0, "Should have at least one unambiguous component"
            )

    def test_scenario_4_real_world_complex_description(self):
        """Test Scenario 4: Real-world complex description with multiple aspects."""
        user_description = "I need a stainless steel CNC-machined bracket for aerospace applications. It should be medium-sized, have an angular design, and meet aerospace quality standards. The bracket will be used in aircraft assembly and needs to be precision-engineered."

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # With this detailed description, most components should be unambiguous
            # Material: stainless steel -> should match steel (01)
            # Manufacturing: CNC-machined -> should match machining (M)
            # Quality: aerospace quality -> should match aerospace (04)
            # Size: medium-sized -> should match medium (2)
            # Shape: angular design -> should match angular (A)
            unambiguous_count = len(result_data["unambiguous_components"])
            self.assertGreaterEqual(
                unambiguous_count,
                3,
                "Detailed description should result in multiple unambiguous components",
            )

    def test_scenario_5_multiple_material_mentions(self):
        """Test Scenario 5: Description with multiple material mentions."""
        user_description = "I need a part that could be made of steel, aluminum, or possibly plastic. It should be manufactured using casting or forging methods."

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Should have ambiguous components due to multiple material mentions
            material_component = None
            for component in result_data["ambiguous_components"]:
                if component["component_key"] == "material_type":
                    material_component = component
                    break

            self.assertIsNotNone(
                material_component,
                "Material type should be ambiguous with multiple material mentions",
            )

            # Should have multiple material options
            self.assertGreater(
                material_component["match_count"],
                2,
                "Should have multiple material matches",
            )

    def test_scenario_6_shape_specific_ambiguous_others(self):
        """Test Scenario 6: Shape-specific description but ambiguous other components."""
        user_description = "I need a cylindrical object, but I'm not sure about the material or manufacturing method"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Shape should be unambiguous (cylindrical -> barrel/cylindrical -> B)
            # But material and manufacturing method should be ambiguous

            # Check if shape is in unambiguous components
            shape_unambiguous = False
            for component in result_data["unambiguous_components"]:
                if component["component_key"] == "object_shape":
                    shape_unambiguous = True
                    break

            self.assertTrue(
                shape_unambiguous,
                "Shape should be unambiguous with 'cylindrical' description",
            )

            # Should have ambiguous components
            ambiguous_count = len(result_data["ambiguous_components"])
            self.assertGreater(ambiguous_count, 0, "Should have ambiguous components")

    def test_scenario_7_industry_specific_terminology(self):
        """Test Scenario 7: Industry-specific terminology."""
        user_description = "I need a carbon fiber composite additive manufactured spherical component for medical device applications"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Should match:
            # Material: carbon fiber composite -> composite (06)
            # Manufacturing: additive manufactured -> additive manufacturing (A)
            # Shape: spherical -> round/spherical (R)
            # Quality: medical device -> medical (05)

            # Should have several unambiguous components due to specific terminology
            unambiguous_count = len(result_data["unambiguous_components"])
            self.assertGreaterEqual(
                unambiguous_count,
                3,
                "Industry-specific terminology should result in multiple unambiguous components",
            )

    def test_scenario_8_no_matches_scenario(self):
        """Test Scenario 8: Description with no valid matches for some components."""
        user_description = (
            "I need a product made of unobtanium using teleportation manufacturing"
        )

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Should have components with no matches
            # Check component details for "no_match" status
            no_match_components = []
            for component_key, detail in result_data["component_details"].items():
                if detail["status"] == "no_match":
                    no_match_components.append(component_key)

            self.assertGreater(
                len(no_match_components),
                0,
                "Should have components with no matches for fictional materials/methods",
            )

    def test_scenario_9_minimal_description(self):
        """Test Scenario 9: Minimal, very short description."""
        user_description = "steel part"

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # With minimal description, should have some unambiguous components (steel)
            # but many ambiguous components due to lack of detail

            # Steel should be unambiguous
            steel_unambiguous = False
            for component in result_data["unambiguous_components"]:
                if component["component_key"] == "material_type":
                    steel_unambiguous = True
                    break

            self.assertTrue(
                steel_unambiguous,
                "Steel should be unambiguous even with minimal description",
            )

            # Should have several ambiguous components
            ambiguous_count = len(result_data["ambiguous_components"])
            self.assertGreater(
                ambiguous_count,
                2,
                "Minimal description should result in multiple ambiguous components",
            )

    def test_scenario_10_edge_case_empty_description(self):
        """Test Scenario 10: Edge case with empty description."""
        user_description = ""

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # With empty description, all components should be ambiguous or no-match
            # Should return a valid JSON structure even with empty input

            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # All components should have status "ambiguous" or "no_match"
            for component_key, detail in result_data["component_details"].items():
                self.assertIn(detail["status"], ["ambiguous", "no_match"])

    def test_scenario_11_unicode_and_special_characters(self):
        """Test Scenario 11: Description with unicode and special characters."""
        user_description = (
            "I need a steel pièce made with CNC® machining™ for médical applications"
        )

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Should handle unicode gracefully
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # Should still identify key components despite special characters
            # Steel -> material_type
            # CNC machining -> manufacturing_method
            # Medical -> quality_grade

            found_key_components = 0
            for component in result_data["unambiguous_components"]:
                if component["component_key"] in [
                    "material_type",
                    "manufacturing_method",
                    "quality_grade",
                ]:
                    found_key_components += 1

            self.assertGreaterEqual(
                found_key_components,
                1,
                "Should identify key components despite unicode characters",
            )

    def test_scenario_12_semantic_similarity_test(self):
        """Test Scenario 12: Test semantic similarity with related terms."""
        user_description = (
            "I need a metallic component created by milling for aircraft usage"
        )

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            # Call clarify_components
            result = clarify_components(self.mock_ctx, user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Should use semantic similarity:
            # "metallic" should match "metal products" (M)
            # "milling" should match "machining" (M)
            # "aircraft" should match "aerospace" (04)

            # Check for semantic matches
            unambiguous_components = result_data["unambiguous_components"]
            component_keys = [comp["component_key"] for comp in unambiguous_components]

            # Should have at least some semantic matches
            self.assertGreater(
                len(unambiguous_components),
                0,
                "Should have semantic matches for related terms",
            )

    def test_all_scenarios_json_validity(self):
        """Test that all scenarios return valid JSON."""
        test_scenarios = [
            "I need a steel additive manufactured angular bracket",
            "I need some kind of product made of material",
            "I need a metal product that's manufactured",
            "",
            "steel part",
            "I need a steel pièce made with CNC® machining™ for médical applications",
        ]

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            for i, user_description in enumerate(test_scenarios):
                with self.subTest(scenario=i):
                    # Call clarify_components
                    result = clarify_components(self.mock_ctx, user_description)

                    # Verify the result is valid JSON
                    try:
                        result_data = json.loads(result)
                        # Verify basic structure
                        self.assertIn("ambiguous_components", result_data)
                        self.assertIn("unambiguous_components", result_data)
                        self.assertIn("component_details", result_data)
                    except json.JSONDecodeError:
                        self.fail(f"Scenario {i} did not return valid JSON: {result}")

    def test_all_scenarios_state_consistency(self):
        """Test that all scenarios maintain state consistency."""
        test_scenarios = [
            "I need a steel additive manufactured angular bracket",
            "I need some kind of product made of material",
            "I need a metal product that's manufactured",
        ]

        # Mock the read_code_generation_file function
        with patch("agent.read_code_generation_file") as mock_read:
            mock_read.return_value = self.complete_code_generation_content

            for i, user_description in enumerate(test_scenarios):
                with self.subTest(scenario=i):
                    # Reset state
                    self.state.component_ambiguity_status.clear()

                    # Call clarify_components
                    result = clarify_components(self.mock_ctx, user_description)

                    # Parse the JSON result
                    result_data = json.loads(result)

                    # Verify that state was updated
                    self.assertGreater(
                        len(self.state.component_ambiguity_status),
                        0,
                        f"State should be updated for scenario {i}",
                    )

                    # Verify that state has valid AmbiguityInfo objects
                    for (
                        component_name,
                        ambiguity_info,
                    ) in self.state.component_ambiguity_status.items():
                        self.assertIsInstance(ambiguity_info, AmbiguityInfo)
                        self.assertIn(
                            ambiguity_info.status, ["ambiguous", "unambiguous"]
                        )


if __name__ == "__main__":
    # Run the tests
    unittest.main()
