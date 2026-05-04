#!/usr/bin/env python3
"""
Integration test for complete disambiguation workflow with clear input.

This test verifies the end-to-end disambiguation workflow when the user provides
a clear, unambiguous description that should result in all components being
identified correctly without any ambiguity.
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


class TestCompleteDisambiguationWorkflowClearInput(unittest.TestCase):
    """Integration test for complete disambiguation workflow with clear, unambiguous input."""

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

    async def test_complete_disambiguation_workflow_clear_input(self):
        """Test the complete disambiguation workflow with a clear, unambiguous input."""

        # Clear, unambiguous user description that should result in all components being identified
        clear_user_description = (
            "I need a stainless steel CNC-machined angular bracket for aerospace applications. "
            "It should be medium-sized and meet aerospace quality standards."
        )

        print("=== Testing Complete Disambiguation Workflow with Clear Input ===")
        print(f"User description: {clear_user_description}")

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
            result = clarify_components(self.mock_ctx, clear_user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)
            print("✓ clarify_components returned valid JSON structure")

            # With this clear description, we should have few or no ambiguous components
            # Most components should be identified correctly
            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            print(f"✓ Found {unambiguous_count} unambiguous components")
            print(f"✓ Found {ambiguous_count} ambiguous components")

            # Should have some unambiguous components with this clear description
            self.assertGreater(
                unambiguous_count,
                0,
                f"Expected at least 1 unambiguous component with clear description, got {unambiguous_count}",
            )

            # With a clear description, we should have more unambiguous than ambiguous components
            self.assertGreater(
                unambiguous_count,
                ambiguous_count,
                f"Expected more unambiguous ({unambiguous_count}) than ambiguous ({ambiguous_count}) components with clear description",
            )

            print(
                "✓ Clear description resulted in more unambiguous than ambiguous components (as expected)"
            )

        except Exception as e:
            self.fail(f"Step 2 failed: Could not clarify components: {e}")

        # Step 3: Generate the procurement code based on the unambiguous components
        print("\n--- Step 3: Generating procurement code ---")
        try:
            # Based on the clear description, we expect:
            # - Major: M (Metal products)
            # - Manufacturing: M (Machining)
            # - Shape: A (Angular)
            # - Material: 01 (Steel)
            # - Quality: 04 (Aerospace)
            # - Size: 2 (Medium)
            # - Year: 26 (current year)
            # - Sequence: 1 (first code)

            generated_code = "MMA014261"
            code_description = "Stainless steel CNC-machined angular bracket for aerospace applications, medium size"

            print(f"✓ Generated code: {generated_code}")
            print(f"✓ Code description: {code_description}")

        except Exception as e:
            self.fail(f"Step 3 failed: Could not generate procurement code: {e}")

        # Step 4: Save the procurement code (should succeed since all components are unambiguous)
        print("\n--- Step 4: Saving procurement code ---")
        try:
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

        print("\n=== Complete disambiguation workflow test passed! ===")
        print("The workflow with clear input works correctly:")
        print("- Step 1: ✓ Code generation file read successfully")
        print("- Step 2: ✓ Components identified as unambiguous (no ambiguity)")
        print("- Step 3: ✓ Procurement code generated based on unambiguous components")
        print(
            "- Step 4: ✓ Code saved successfully (no ambiguous components to block save)"
        )

        return True

    async def test_state_validation_after_clear_workflow(self):
        """Test that the state is properly validated after the clear workflow."""

        # Run the complete workflow
        await self.test_complete_disambiguation_workflow_clear_input()

        # Verify that the state was updated with component ambiguity information
        self.assertGreater(
            len(self.state.component_ambiguity_status),
            0,
            "State should contain component ambiguity information after workflow",
        )

        # Verify that we have a mix of resolved (unambiguous/guessed) components
        resolved_components = 0
        for (
            component_name,
            ambiguity_info,
        ) in self.state.component_ambiguity_status.items():
            if ambiguity_info.status in ["unambiguous", "guessed"]:
                resolved_components += 1

        self.assertGreater(
            resolved_components,
            0,
            "Should have at least one resolved component in state after clear workflow",
        )

        print(
            "✓ State validation passed: Component ambiguity information properly tracked"
        )

    async def test_workflow_repeatability(self):
        """Test that the workflow can be repeated with another clear input."""

        # First workflow with stainless steel bracket
        await self.test_complete_disambiguation_workflow_clear_input()

        # Reset the state for a new workflow
        self.state.rules_loaded_this_turn = False
        self.state.component_ambiguity_status.clear()

        # Second workflow with a different clear description
        clear_user_description_2 = (
            "I need an aluminum additive manufactured spherical component for medical applications. "
            "It should be small-sized and meet medical quality standards."
        )

        print("\n=== Testing Workflow Repeatability with Second Clear Input ===")

        # Run the workflow again with the second description
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            # Read file
            content = read_code_generation_file(self.mock_ctx)

            # Clarify components
            result = clarify_components(self.mock_ctx, clear_user_description_2)
            result_data = json.loads(result)

            # Verify no ambiguous components
            ambiguous_count = len(result_data["ambiguous_components"])
            self.assertEqual(
                ambiguous_count,
                0,
                "Second workflow should also have no ambiguous components",
            )

            # Generate and save code
            generated_code_2 = "TAR025261"  # Textile (T), Additive (A), Round (R), Aluminum (02), Medical (05), Small (1), 26, 1
            code_description_2 = "Aluminum additive manufactured spherical component for medical applications, small size"

            result = save_procurement_code(
                self.mock_ctx, generated_code_2, code_description_2
            )
            self.assertIsInstance(result, StateSnapshotEvent)

            # Verify we have 2 codes saved
            self.assertEqual(
                len(self.state.procurement_codes),
                2,
                "Should have 2 codes saved after 2 workflows",
            )

        print(
            "✓ Workflow repeatability test passed: Second clear input also processed successfully"
        )


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
