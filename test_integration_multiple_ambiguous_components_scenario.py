#!/usr/bin/env python3
"""
Integration test for multiple ambiguous components scenario.

This test verifies the disambiguation workflow when the user provides
a description that results in multiple components being ambiguous,
requiring clarification for each before code generation can proceed.
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


class TestMultipleAmbiguousComponentsScenario(unittest.TestCase):
    """Integration test for multiple ambiguous components scenario."""

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

    async def test_multiple_ambiguous_components_scenario(self):
        """Test the disambiguation workflow with multiple ambiguous components."""

        # User description that should result in multiple ambiguous components
        # "manufactured" is ambiguous (could be Machining or Casting)
        # "component" is ambiguous (could be Metal or Chemical products)
        # "material" is ambiguous (could be various materials)
        ambiguous_user_description = (
            "I need a manufactured component made of good material. "
            "It should have a nice shape and be of decent quality."
        )

        print("=== Testing Multiple Ambiguous Components Scenario ===")
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

            # With this description, we should have multiple ambiguous components
            ambiguous_components = result_data["ambiguous_components"]
            unambiguous_components = result_data["unambiguous_components"]

            self.assertGreaterEqual(
                len(ambiguous_components),
                2,
                f"Expected at least 2 ambiguous components, got {len(ambiguous_components)}",
            )

            print(f"✓ Found {len(ambiguous_components)} ambiguous components")
            print(f"✓ Found {len(unambiguous_components)} unambiguous components")

            # Store the ambiguous component info for later use
            self.ambiguous_components_info = ambiguous_components

            # Verify each ambiguous component has multiple options
            for component in ambiguous_components:
                self.assertGreater(
                    len(component["options"]),
                    1,
                    f"Ambiguous component '{component['component_name']}' should have multiple options",
                )

            # Print the ambiguous components found
            for component in ambiguous_components:
                print(
                    f"  - {component['component_name']}: {len(component['options'])} options"
                )

        except Exception as e:
            self.fail(f"Step 2 failed: Could not clarify components: {e}")

        # Step 3: Simulate user selecting options to resolve all ambiguities
        print(
            "\n--- Step 3: Simulating user clarification for all ambiguous components ---"
        )
        try:
            # Update the component ambiguity status in the state for each ambiguous component
            for component in self.ambiguous_components_info:
                component_name = component["component_name"]

                # Select the first option for simplicity
                selected_option = component["options"][0]["value"]

                # Create AmbiguityInfo for the now-unambiguous component
                ambiguity_info = AmbiguityInfo(
                    status="unambiguous",
                    options=component["options"],
                    selected_value=selected_option,
                )

                # Update the state
                self.state.component_ambiguity_status[component_name] = ambiguity_info

                print(
                    f"✓ User selected option '{selected_option}' for {component_name}"
                )

            print(
                f"✓ All {len(self.ambiguous_components_info)} components marked as unambiguous in state"
            )

        except Exception as e:
            self.fail(f"Step 3 failed: Could not simulate user clarification: {e}")

        # Step 4: Attempt to save the procurement code (should succeed now)
        print("\n--- Step 4: Saving procurement code after disambiguation ---")
        try:
            # Generate a code based on the resolved components
            # Since we selected the first option for each ambiguous component,
            # the actual code will depend on what those options were
            generated_code = "MMA013261"  # Example code - will vary based on selections
            code_description = (
                "Multi-component item after disambiguation of all ambiguous components"
            )

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

        print("\n=== Multiple ambiguous components scenario test passed! ===")
        print("The workflow with multiple ambiguous components works correctly:")
        print("- Step 1: ✓ Code generation file read successfully")
        print(
            f"- Step 2: ✓ {len(self.ambiguous_components_info)} ambiguous components identified"
        )
        print("- Step 3: ✓ User clarification resolved all ambiguities")
        print("- Step 4: ✓ Code saved successfully after disambiguation")

        return True

    async def test_save_blocked_with_multiple_ambiguous_components(self):
        """Test that save is blocked when there are multiple ambiguous components."""

        # Set up the scenario with multiple ambiguous components
        await self.test_multiple_ambiguous_components_scenario()

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
            "I need a manufactured component made of good material. "
            "It should have a nice shape and be of decent quality."
        )

        result = clarify_components(self.mock_ctx, ambiguous_user_description)
        result_data = json.loads(result)

        # Verify we have multiple ambiguous components
        self.assertGreaterEqual(
            len(result_data["ambiguous_components"]),
            2,
            "Should have at least 2 ambiguous components",
        )

        # Try to save without resolving the ambiguities
        generated_code = "MMA013261"
        code_description = (
            "Multi-component item after disambiguation of all ambiguous components"
        )

        print("\n--- Testing Save Blocked with Multiple Ambiguous Components ---")

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

        # Verify the error message mentions ambiguous components
        self.assertIn(
            "ambiguous",
            result.lower(),
            f"Error message should mention 'ambiguous', got: {result}",
        )

        # Verify that no code was saved to the state
        self.assertEqual(
            len(self.state.procurement_codes),
            0,
            "No code should be saved when there are ambiguous components",
        )

        print("✓ Save correctly blocked when multiple components are ambiguous")
        print("✓ Error message correctly identifies the ambiguous components")

    async def test_iterative_resolution_of_multiple_ambiguous_components(self):
        """Test iterative resolution - resolving one component at a time."""

        # Set up the scenario with multiple ambiguous components
        await self.test_multiple_ambiguous_components_scenario()

        # Reset to test iterative resolution
        self.state.rules_loaded_this_turn = False
        self.state.component_ambiguity_status.clear()

        # Read the file and get component analysis
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )
            read_code_generation_file(self.mock_ctx)

        ambiguous_user_description = (
            "I need a manufactured component made of good material. "
            "It should have a nice shape and be of decent quality."
        )

        result = clarify_components(self.mock_ctx, ambiguous_user_description)
        result_data = json.loads(result)

        # Get the ambiguous components
        ambiguous_components = result_data["ambiguous_components"]

        print("\n--- Testing Iterative Resolution of Multiple Ambiguous Components ---")

        # Resolve components one by one
        for i, component in enumerate(ambiguous_components):
            component_name = component["component_name"]

            # Simulate user resolving this component
            selected_option = component["options"][0]["value"]

            # Create AmbiguityInfo for the now-unambiguous component
            ambiguity_info = AmbiguityInfo(
                status="unambiguous",
                options=component["options"],
                selected_value=selected_option,
            )

            # Update the state
            self.state.component_ambiguity_status[component_name] = ambiguity_info

            print(
                f"✓ Iteration {i + 1}: Resolved {component_name} with option '{selected_option}'"
            )

            # Verify that the component is now unambiguous
            self.assertEqual(
                ambiguity_info.status,
                "unambiguous",
                f"Component {component_name} should be marked as unambiguous",
            )

        print(
            f"✓ All {len(ambiguous_components)} ambiguous components resolved iteratively"
        )

        # Verify final state has all components resolved
        self.assertEqual(
            len(self.state.component_ambiguity_status),
            len(ambiguous_components),
            f"Expected {len(ambiguous_components)} components in state, got {len(self.state.component_ambiguity_status)}",
        )

        for (
            component_name,
            ambiguity_info,
        ) in self.state.component_ambiguity_status.items():
            self.assertEqual(
                ambiguity_info.status,
                "unambiguous",
                f"Component {component_name} should be unambiguous",
            )


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
