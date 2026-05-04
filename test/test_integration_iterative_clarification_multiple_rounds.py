#!/usr/bin/env python3
"""
Integration test for iterative clarification (multiple rounds).

This test verifies the complete disambiguation workflow when the user provides
a description that results in multiple ambiguous components, requiring multiple
rounds of clarification before code generation can proceed.

Key scenarios tested:
1. Initial identification of multiple ambiguous components
2. First round of clarification - user resolves some components
3. Second round of clarification - user resolves remaining components
4. Context preservation across rounds
5. Successful code generation after all ambiguities resolved
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


class TestIterativeClarificationMultipleRounds(unittest.TestCase):
    """Integration test for iterative clarification with multiple rounds."""

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

    async def test_iterative_clarification_multiple_rounds(self):
        """Test the complete disambiguation workflow with multiple clarification rounds."""

        # User description that should result in multiple ambiguous components
        # "industrial component" could be Industrial quality or Standard quality
        # "shaped object" could be Angular, Round, or Barrel shapes
        # "manufactured item" could be Machining, Casting, or Forging
        ambiguous_user_description = (
            "I need an industrial shaped manufactured metal component. "
            "It should be medium-sized and made of steel."
        )

        print("=== Testing Iterative Clarification (Multiple Rounds) ===")
        print(f"User description: {ambiguous_user_description}")

        # === ROUND 0: Initial Setup ===
        print("\n--- Round 0: Initial Setup ---")
        try:
            # Mock the file reading to return our test content
            with patch("builtins.open", create=True) as mock_open:
                mock_open.return_value.__enter__.return_value.read.return_value = (
                    self.complete_code_generation_content
                )

                # Call read_code_generation_file
                content = read_code_generation_file(self.mock_ctx)

                # Verify rules were loaded and initial state
                self.assertTrue(
                    self.state.rules_loaded_this_turn,
                    "rules_loaded_this_turn should be True after reading file",
                )
                self.assertEqual(
                    self.state.clarification_rounds,
                    0,
                    "Initial clarification_rounds should be 0",
                )
                self.assertEqual(
                    len(self.state.clarified_components),
                    0,
                    "Initial clarified_components should be empty",
                )
                print("✓ Successfully read code generation file")
                print("✓ Initial state verified (rounds=0, no clarified components)")

        except Exception as e:
            self.fail(f"Round 0 failed: Could not read code generation file: {e}")

        # === ROUND 1: Initial Clarification ===
        print("\n--- Round 1: Initial Clarification ---")
        try:
            # Call clarify_components to identify component ambiguity
            result = clarify_components(self.mock_ctx, ambiguous_user_description)
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)

            # We should have multiple ambiguous components
            ambiguous_components = result_data["ambiguous_components"]
            unambiguous_components = result_data["unambiguous_components"]

            # Verify we have at least 2 ambiguous components
            self.assertGreaterEqual(
                len(ambiguous_components),
                2,
                f"Expected at least 2 ambiguous components, got {len(ambiguous_components)}",
            )

            # Store ambiguous component names for later use
            self.ambiguous_component_names = [
                comp["component_name"] for comp in ambiguous_components
            ]

            print(f"✓ Found {len(ambiguous_components)} ambiguous components")
            print(f"✓ Found {len(unambiguous_components)} unambiguous components")
            print(
                f"✓ Ambiguous components: {', '.join(self.ambiguous_component_names)}"
            )

            # Simulate user resolving first 1-2 components
            components_to_resolve = self.ambiguous_component_names[
                :2
            ]  # Resolve first 2

            for comp_name in components_to_resolve:
                # Find the component info
                comp_info = None
                for comp in ambiguous_components:
                    if comp["component_name"] == comp_name:
                        comp_info = comp
                        break

                if comp_info:
                    # User selects the first option for each component
                    selected_option = comp_info["options"][0]["value"]

                    # Create AmbiguityInfo for the now-unambiguous component
                    ambiguity_info = AmbiguityInfo(
                        status="unambiguous",
                        options=comp_info["options"],
                        selected_value=selected_option,
                    )

                    # Update the state
                    self.state.update_component_ambiguity(comp_name, ambiguity_info)
                    self.state.clarified_components.add(comp_name)

                    print(f"✓ User resolved {comp_name} as '{selected_option}'")

            # Update clarification rounds counter
            self.state.clarification_rounds = 1

            # Verify state after round 1
            self.assertEqual(
                self.state.clarification_rounds,
                1,
                "clarification_rounds should be 1 after first round",
            )
            self.assertEqual(
                len(self.state.clarified_components),
                len(components_to_resolve),
                f"Should have {len(components_to_resolve)} clarified components",
            )

            print(
                f"✓ Round 1 completed: {len(components_to_resolve)} components clarified"
            )

        except Exception as e:
            self.fail(f"Round 1 failed: {e}")

        # === ROUND 2: Second Clarification ===
        print("\n--- Round 2: Second Clarification ---")
        try:
            # Call clarify_components again to check remaining ambiguous components
            # Note: In a real scenario, this would be called with updated user input
            # For this test, we'll simulate that user provided more specific information
            updated_user_description = (
                "I need an industrial angular machined metal component. "
                "It should be medium-sized and made of steel."
            )

            result = clarify_components(self.mock_ctx, updated_user_description)
            result_data = json.loads(result)

            # Get remaining ambiguous components
            ambiguous_components = result_data["ambiguous_components"]
            unambiguous_components = result_data["unambiguous_components"]

            # Should have fewer ambiguous components now
            remaining_ambiguous_names = [
                comp["component_name"] for comp in ambiguous_components
            ]

            # The components we resolved in round 1 should not be in the ambiguous list
            for comp_name in components_to_resolve:
                self.assertNotIn(
                    comp_name,
                    remaining_ambiguous_names,
                    f"Component '{comp_name}' should not be ambiguous after round 1",
                )

            print(f"✓ Remaining ambiguous components: {remaining_ambiguous_names}")
            print(f"✓ Total unambiguous components: {len(unambiguous_components)}")

            # Resolve remaining ambiguous components
            for comp_info in ambiguous_components:
                comp_name = comp_info["component_name"]
                selected_option = comp_info["options"][0]["value"]

                # Create AmbiguityInfo for the now-unambiguous component
                ambiguity_info = AmbiguityInfo(
                    status="unambiguous",
                    options=comp_info["options"],
                    selected_value=selected_option,
                )

                # Update the state
                self.state.update_component_ambiguity(comp_name, ambiguity_info)
                self.state.clarified_components.add(comp_name)

                print(f"✓ User resolved {comp_name} as '{selected_option}'")

            # Update clarification rounds counter
            self.state.clarification_rounds = 2

            # Verify state after round 2
            self.assertEqual(
                self.state.clarification_rounds,
                2,
                "clarification_rounds should be 2 after second round",
            )

            # Verify all initially ambiguous components are now clarified
            for comp_name in self.ambiguous_component_names:
                self.assertIn(
                    comp_name,
                    self.state.clarified_components,
                    f"Component '{comp_name}' should be in clarified_components",
                )

            print(f"✓ Round 2 completed: All components now clarified")

        except Exception as e:
            self.fail(f"Round 2 failed: {e}")

        # === ROUND 3: Verification and Save ===
        print("\n--- Round 3: Verification and Code Generation ---")
        try:
            # Verify that all components are now unambiguous
            try:
                self.state.validate_all_components_unambiguous()
                print("✓ All components validated as unambiguous")
            except ValueError as e:
                self.fail(f"Components validation failed: {e}")

            # Attempt to save the procurement code
            # Based on the resolved description, we expect:
            # - Major: M (Metal products)
            # - Manufacturing: M (Machining)
            # - Shape: A (Angular)
            # - Material: 01 (Steel)
            # - Quality: 03 (Industrial)
            # - Size: 2 (Medium)
            # - Year: 26 (current year)
            # - Sequence: 1 (first code)

            generated_code = "MMA013261"
            code_description = (
                "Industrial angular machined metal component, medium size, steel"
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
            self.fail(f"Round 3 failed: {e}")

        print("\n=== Iterative Clarification Multiple Rounds Test Passed! ===")
        print("The workflow with multiple clarification rounds works correctly:")
        print("- Round 0: ✓ Initial setup with rules file read")
        print("- Round 1: ✓ Initial clarification with multiple ambiguous components")
        print("- Round 2: ✓ Second clarification with remaining ambiguous components")
        print("- Round 3: ✓ Verification and successful code generation")
        print(f"- Total clarification rounds: {self.state.clarification_rounds}")
        print(f"- Total clarified components: {len(self.state.clarified_components)}")

        return True

    async def test_context_preservation_across_rounds(self):
        """Test that context is preserved across multiple clarification rounds."""

        print("\n=== Testing Context Preservation Across Rounds ===")

        # Set up the initial scenario
        await self.test_iterative_clarification_multiple_rounds()

        # Verify that previously clarified components remain clarified
        self.assertGreater(
            len(self.state.clarified_components), 0, "Should have clarified components"
        )

        # Verify that all components are still unambiguous
        try:
            self.state.validate_all_components_unambiguous()
            print("✓ All components remain unambiguous after multiple rounds")
        except ValueError as e:
            self.fail(f"Context preservation failed: {e}")

        # Verify clarification rounds counter
        self.assertEqual(
            self.state.clarification_rounds,
            2,
            "Should have completed 2 clarification rounds",
        )

        # Verify that clarified components set contains expected components
        for comp_name in self.ambiguous_component_names:
            self.assertIn(
                comp_name,
                self.state.clarified_components,
                f"Component '{comp_name}' should be in clarified_components",
            )

        print("✓ Context preservation verified across rounds")

    async def test_save_blocked_during_clarification(self):
        """Test that save is blocked while components are still ambiguous."""

        print("\n--- Testing Save Blocked During Clarification ---")

        # Reset state to test blocked scenario
        self.state = ProcurementState()
        self.mock_ctx.deps = StateDeps(state=self.state)

        # Read the file
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )
            read_code_generation_file(self.mock_ctx)

        # Get ambiguous components
        ambiguous_user_description = (
            "I need an industrial shaped manufactured metal component. "
            "It should be medium-sized and made of steel."
        )

        result = clarify_components(self.mock_ctx, ambiguous_user_description)
        result_data = json.loads(result)

        # Verify we have ambiguous components
        ambiguous_components = result_data["ambiguous_components"]
        self.assertGreater(
            len(ambiguous_components), 0, "Should have at least one ambiguous component"
        )

        # Try to save without resolving ambiguities
        generated_code = "MMA013261"
        code_description = "Test component"

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

        print("✓ Save correctly blocked during clarification")
        print("✓ Error message correctly indicates ambiguous components")


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
