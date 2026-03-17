#!/usr/bin/env python3
"""
Integration test for single ambiguous component scenario.

This test verifies the disambiguation workflow when the user provides
a description that results in exactly one component being ambiguous,
requiring clarification before code generation can proceed.
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
        read_code_generation_file,
        clarify_components,
        save_procurement_code,
        ProcurementState,
        AmbiguityInfo,
    )
    from pydantic_ai import RunContext
    from pydantic_ai.ag_ui import StateDeps
    from ag_ui.core import EventType, StateSnapshotEvent


class TestSingleAmbiguousComponentScenario(unittest.TestCase):
    """Integration test for single ambiguous component scenario."""

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock ProcurementState
        self.state = ProcurementState()

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

    async def test_single_ambiguous_component_scenario(self):
        """Test the disambiguation workflow with a single ambiguous component."""

        # User description that should result in exactly one ambiguous component
        # "manufactured component" is ambiguous (could be Machining or Casting)
        ambiguous_user_description = (
            "I need a stainless steel manufactured angular bracket for aerospace applications. "
            "It should be medium-sized and meet aerospace quality standards."
        )

        print("=== Testing Single Ambiguous Component Scenario ===")
        print(f"User description: {ambiguous_user_description}")

        # Step 1: Read the code generation file
        print("\n--- Step 1: Reading code generation file ---")
        try:
            # Mock the file reading to return our test content
            with patch("builtins.open", create=True) as mock_open:
                mock_open.return_value.__enter__.return_value.read.return_value = (
                    self.complete_code_generation_content
                )

                # Call read_code_generation_file
                content = read_code_generation_file(self.mock_ctx)

                # Verify rules were loaded
                self.assertTrue(
                    self.state.rules_loaded_this_turn,
                    "rules_loaded_this_turn should be True after reading file",
                )
                print("✓ Successfully read code generation file")
                print("✓ rules_loaded_this_turn flag is set to True")

        except Exception as e:
            self.fail(f"Step 1 failed: Could not read code generation file: {e}")

        # Step 2: Call clarify_components to identify component ambiguity
        print("\n--- Step 2: Calling clarify_components ---")
        try:
            # Call clarify_components
            result = clarify_components(self.mock_ctx, ambiguous_user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)
            print("✓ clarify_components returned valid JSON structure")

            # With this description, we should have exactly one ambiguous component (Manufacturing Method)
            ambiguous_components = result_data["ambiguous_components"]
            unambiguous_components = result_data["unambiguous_components"]

            self.assertEqual(
                len(ambiguous_components),
                1,
                f"Expected exactly 1 ambiguous component, got {len(ambiguous_components)}",
            )

            # Verify the ambiguous component is Manufacturing Method
            ambiguous_component = ambiguous_components[0]
            self.assertEqual(
                ambiguous_component["component_name"],
                "Manufacturing Method",
                f"Expected ambiguous component to be 'Manufacturing Method', got '{ambiguous_component['component_name']}'",
            )

            # Verify it has multiple options
            self.assertGreater(
                len(ambiguous_component["options"]),
                1,
                "Ambiguous component should have multiple options",
            )

            print(
                f"✓ Found exactly 1 ambiguous component: {ambiguous_component['component_name']}"
            )
            print(f"✓ Found {len(unambiguous_components)} unambiguous components")

            # Store the ambiguous component info for later use
            self.ambiguous_component_info = ambiguous_component

        except Exception as e:
            self.fail(f"Step 2 failed: Could not clarify components: {e}")

        # Step 3: Simulate user selecting an option to resolve the ambiguity
        print("\n--- Step 3: Simulating user clarification ---")
        try:
            # Simulate user selecting "Machining" (M) as the manufacturing method
            selected_option = "M"

            # Update the component ambiguity status in the state
            component_name = self.ambiguous_component_info["component_name"]

            # Create AmbiguityInfo for the now-unambiguous component
            ambiguity_info = AmbiguityInfo(
                status="unambiguous",
                options=self.ambiguous_component_info["options"],
                selected_value=selected_option,
            )

            # Update the state
            self.state.component_ambiguity_status[component_name] = ambiguity_info

            print(f"✓ User selected option '{selected_option}' for {component_name}")
            print(f"✓ Component marked as unambiguous in state")

        except Exception as e:
            self.fail(f"Step 3 failed: Could not simulate user clarification: {e}")

        # Step 4: Attempt to save the procurement code (should succeed now)
        print("\n--- Step 4: Saving procurement code after disambiguation ---")
        try:
            # Based on the resolved description, we expect:
            # - Major: M (Metal products)
            # - Manufacturing: M (Machining) - now resolved
            # - Shape: A (Angular)
            # - Material: 01 (Steel)
            # - Quality: 04 (Aerospace)
            # - Size: 2 (Medium)
            # - Year: 26 (current year)
            # - Sequence: 1 (first code)

            generated_code = "MMA014261"
            code_description = "Stainless steel machined angular bracket for aerospace applications, medium size"

            # Call save_procurement_code
            result = await save_procurement_code(
                self.mock_ctx, generated_code, code_description
            )

            # Verify that a StateSnapshotEvent was returned (not an error string)
            self.assertIsInstance(
                result,
                StateSnapshotEvent,
                f"Expected StateSnapshotEvent, got {type(result)}: {result}",
            )
            print("✓ save_procurement_code returned StateSnapshotEvent (success)")

            # Verify that the code was saved to the state
            self.assertEqual(
                len(self.state.procurement_codes),
                1,
                f"Expected 1 code in state, got {len(self.state.procurement_codes)}",
            )

            saved_code = self.state.procurement_codes[0]
            self.assertEqual(
                saved_code.code,
                generated_code,
                f"Expected code '{generated_code}', got '{saved_code.code}'",
            )
            self.assertEqual(
                saved_code.description,
                code_description,
                f"Expected description '{code_description}', got '{saved_code.description}'",
            )
            print("✓ Code was successfully saved to state")

        except Exception as e:
            self.fail(f"Step 4 failed: Could not save procurement code: {e}")

        print("\n=== Single ambiguous component scenario test passed! ===")
        print("The workflow with single ambiguous component works correctly:")
        print("- Step 1: ✓ Code generation file read successfully")
        print("- Step 2: ✓ Exactly one ambiguous component identified")
        print("- Step 3: ✓ User clarification resolved the ambiguity")
        print("- Step 4: ✓ Code saved successfully after disambiguation")

        return True

    async def test_save_blocked_before_disambiguation(self):
        """Test that save is blocked when there's an ambiguous component."""

        # Set up the scenario with an ambiguous component
        await self.test_single_ambiguous_component_scenario()

        # Reset the state to test the blocked scenario
        self.state.rules_loaded_this_turn = False
        self.state.component_ambiguity_status.clear()
        self.state.procurement_codes.clear()

        # Read the file again
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )
            read_code_generation_file(self.mock_ctx)

        # Get the ambiguous component information
        ambiguous_user_description = (
            "I need a stainless steel manufactured angular bracket for aerospace applications. "
            "It should be medium-sized and meet aerospace quality standards."
        )

        result = clarify_components(self.mock_ctx, ambiguous_user_description)
        result_data = json.loads(result)

        # Verify we have an ambiguous component
        self.assertEqual(
            len(result_data["ambiguous_components"]),
            1,
            "Should have exactly 1 ambiguous component",
        )

        # Try to save without resolving the ambiguity
        generated_code = "MMA014261"
        code_description = "Stainless steel machined angular bracket for aerospace applications, medium size"

        print("\n--- Testing Save Blocked Before Disambiguation ---")

        # Call save_procurement_code
        result = await save_procurement_code(
            self.mock_ctx, generated_code, code_description
        )

        # Verify that an error string was returned (not a StateSnapshotEvent)
        self.assertIsInstance(
            result,
            str,
            f"Expected error string, got {type(result)}: {result}",
        )

        # Verify the error message mentions the ambiguous component
        self.assertIn(
            "ambiguous",
            result.lower(),
            f"Error message should mention 'ambiguous', got: {result}",
        )

        self.assertIn(
            "manufacturing method",
            result.lower(),
            f"Error message should mention 'manufacturing method', got: {result}",
        )

        # Verify that no code was saved to the state
        self.assertEqual(
            len(self.state.procurement_codes),
            0,
            "No code should be saved when there are ambiguous components",
        )

        print("✓ Save correctly blocked when component is ambiguous")
        print("✓ Error message correctly identifies the ambiguous component")

    async def test_ambiguous_component_options_structure(self):
        """Test that the ambiguous component options have the correct structure."""

        # Set up the scenario with an ambiguous component
        await self.test_single_ambiguous_component_scenario()

        # Reset to test the options structure
        self.state.rules_loaded_this_turn = False
        self.state.component_ambiguity_status.clear()

        # Read the file and get component analysis
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )
            read_code_generation_file(self.mock_ctx)

        ambiguous_user_description = (
            "I need a stainless steel manufactured angular bracket for aerospace applications. "
            "It should be medium-sized and meet aerospace quality standards."
        )

        result = clarify_components(self.mock_ctx, ambiguous_user_description)
        result_data = json.loads(result)

        # Get the ambiguous component
        ambiguous_component = result_data["ambiguous_components"][0]

        # Verify the component structure
        self.assertIn("component_name", ambiguous_component)
        self.assertIn("options", ambiguous_component)
        self.assertIsInstance(ambiguous_component["options"], list)
        self.assertGreater(len(ambiguous_component["options"]), 1)

        # Verify each option has the required fields
        for option in ambiguous_component["options"]:
            self.assertIn("value", option)
            self.assertIn("description", option)
            self.assertIsInstance(option["value"], str)
            self.assertIsInstance(option["description"], str)
            self.assertTrue(len(option["value"]) > 0)
            self.assertTrue(len(option["description"]) > 0)

        print("\n--- Testing Ambiguous Component Options Structure ---")
        print(f"✓ Component name: {ambiguous_component['component_name']}")
        print(f"✓ Number of options: {len(ambiguous_component['options'])}")
        print("✓ All options have required 'value' and 'description' fields")

        # Verify we have the expected manufacturing method options
        option_values = [opt["value"] for opt in ambiguous_component["options"]]
        expected_manufacturing_options = ["M", "C"]  # Machining and Casting

        for expected_opt in expected_manufacturing_options:
            self.assertIn(
                expected_opt,
                option_values,
                f"Expected manufacturing option '{expected_opt}' not found in {option_values}",
            )

        print("✓ Expected manufacturing method options found")


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
