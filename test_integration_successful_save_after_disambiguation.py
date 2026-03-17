#!/usr/bin/env python3
"""
Integration test for successful save after disambiguation.

This test verifies the end-to-end workflow when the user provides an ambiguous
description that goes through the disambiguation process, and then successfully
saves the procurement code after all components become unambiguous.
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


class TestSuccessfulSaveAfterDisambiguation(unittest.TestCase):
    """Integration test for successful save after disambiguation."""

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

    async def test_successful_save_after_disambiguation_workflow(self):
        """Test the complete disambiguation workflow leading to successful save."""

        # Initially ambiguous user description that becomes unambiguous after clarification
        ambiguous_user_description = (
            "I need some kind of metal product made using some method. "
            "It should have a specific shape and be made from some material. "
            "I need it for industrial use and it should be a certain size."
        )

        print("=== Testing Successful Save After Disambiguation Workflow ===")
        print(f"Initial ambiguous user description: {ambiguous_user_description}")

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

        # Step 2: Call clarify_components to identify initial component ambiguity
        print("\n--- Step 2: Initial clarification (identifying ambiguity) ---")
        try:
            # Call clarify_components with ambiguous description
            result = clarify_components(self.mock_ctx, ambiguous_user_description)

            # Parse the JSON result
            result_data = json.loads(result)

            # Verify the structure
            self.assertIn("ambiguous_components", result_data)
            self.assertIn("unambiguous_components", result_data)
            self.assertIn("component_details", result_data)
            print("✓ clarify_components returned valid JSON structure")

            # With this ambiguous description, we should have multiple ambiguous components
            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            print(f"✓ Found {unambiguous_count} unambiguous components initially")
            print(f"✓ Found {ambiguous_count} ambiguous components initially")

            # Should have some ambiguous components with this vague description
            self.assertGreater(
                ambiguous_count,
                0,
                f"Expected at least 1 ambiguous component with vague description, got {ambiguous_count}",
            )

            print("✓ Initial ambiguity detected (as expected)")

        except Exception as e:
            self.fail(f"Step 2 failed: Could not identify initial ambiguity: {e}")

        # Step 3: Simulate user clarification - update state with unambiguous components
        print("\n--- Step 3: Simulating user clarification process ---")
        try:
            # Update the state to simulate user providing clarifications
            # This represents the user selecting specific options for ambiguous components
            self.state.component_ambiguity_status = {
                "Major Category": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "M", "description": "Metal products"}],
                    selected_value="M",
                ),
                "Manufacturing Method": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "M", "description": "Machining"}],
                    selected_value="M",
                ),
                "Object Shape": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "A", "description": "Angular"}],
                    selected_value="A",
                ),
                "Material Type": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "01", "description": "Steel"}],
                    selected_value="01",
                ),
                "Quality Grade": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "03", "description": "Industrial"}],
                    selected_value="03",
                ),
                "Size Category": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "3", "description": "Large"}],
                    selected_value="3",
                ),
            }

            # Verify all components are now unambiguous
            ambiguous_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "ambiguous"
            )
            unambiguous_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "unambiguous"
            )

            self.assertEqual(
                ambiguous_count,
                0,
                f"Expected 0 ambiguous components after clarification, got {ambiguous_count}",
            )
            self.assertGreater(
                unambiguous_count,
                0,
                f"Expected at least 1 unambiguous component after clarification, got {unambiguous_count}",
            )

            print(
                f"✓ All components clarified: {unambiguous_count} unambiguous, {ambiguous_count} ambiguous"
            )

        except Exception as e:
            self.fail(f"Step 3 failed: Could not simulate user clarification: {e}")

        # Step 4: Attempt to save the procurement code (should succeed now)
        print("\n--- Step 4: Saving procurement code after disambiguation ---")
        try:
            # Generate the code based on the clarified components
            # M (Metal) + M (Machining) + A (Angular) + 01 (Steel) + 03 (Industrial) + 3 (Large) + 26 (Year) + 1 (Sequence)
            test_code = "MMA013261"
            code_description = (
                "Metal machined angular steel component, industrial quality, large size"
            )

            # Call save_procurement_code
            result = await save_procurement_code(
                self.mock_ctx, test_code, code_description
            )

            # Verify that a StateSnapshotEvent was returned (success)
            self.assertIsInstance(
                result,
                StateSnapshotEvent,
                f"Expected StateSnapshotEvent for successful save, got {type(result)}: {result}",
            )
            print("✓ save_procurement_code returned StateSnapshotEvent (success)")

            # Verify that the code was saved to the state
            self.assertEqual(
                len(self.state.procurement_codes),
                1,
                f"Expected 1 code in state after successful save, got {len(self.state.procurement_codes)}",
            )

            saved_code = self.state.procurement_codes[0]
            self.assertEqual(
                saved_code.code,
                test_code,
                f"Expected saved code '{test_code}', got '{saved_code.code}'",
            )
            self.assertEqual(
                saved_code.description,
                code_description,
                f"Expected saved description '{code_description}', got '{saved_code.description}'",
            )
            print("✓ Code successfully saved to state")

            # Verify the state reflects the successful disambiguation workflow
            self.assertTrue(
                self.state.rules_loaded_this_turn,
                "rules_loaded_this_turn should remain True after successful save",
            )
            print("✓ State correctly reflects successful disambiguation workflow")

        except Exception as e:
            self.fail(
                f"Step 4 failed: Could not save procurement code after disambiguation: {e}"
            )

        print("\n=== Successful save after disambiguation test passed! ===")
        print("The complete disambiguation workflow works correctly:")
        print("- Step 1: ✓ Code generation file read successfully")
        print("- Step 2: ✓ Initial ambiguity identified")
        print(
            "- Step 3: ✓ User clarification process completed (all components unambiguous)"
        )
        print("- Step 4: ✓ Code saved successfully after disambiguation")
        print("- Step 5: ✓ State correctly reflects successful workflow")

        return True

    async def test_successful_save_after_partial_disambiguation_with_guesses(self):
        """Test successful save after some components are resolved through guessing."""

        print(
            "\n=== Testing Successful Save After Partial Disambiguation with Guesses ==="
        )

        # Step 1: Read the code generation file
        try:
            with patch("builtins.open", create=True) as mock_open:
                mock_open.return_value.__enter__.return_value.read.return_value = (
                    self.complete_code_generation_content
                )

                content = read_code_generation_file(self.mock_ctx)
                self.assertTrue(self.state.rules_loaded_this_turn)
                print("✓ Successfully read code generation file")

        except Exception as e:
            self.fail(f"Could not read code generation file: {e}")

        # Step 2: Set up state with mix of unambiguous and guessed components
        print("\n--- Step 2: Setting up mixed unambiguous and guessed components ---")
        try:
            self.state.component_ambiguity_status = {
                "Major Category": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "T", "description": "Textile products"}],
                    selected_value="T",
                ),
                "Manufacturing Method": AmbiguityInfo(
                    status="guessed",
                    options=[{"value": "A", "description": "Additive manufacturing"}],
                    selected_value="A",
                    guessed_value="A",
                    is_guessed=True,
                ),
                "Object Shape": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "R", "description": "Round/spherical"}],
                    selected_value="R",
                ),
                "Material Type": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "02", "description": "Aluminum"}],
                    selected_value="02",
                ),
                "Quality Grade": AmbiguityInfo(
                    status="guessed",
                    options=[{"value": "05", "description": "Medical"}],
                    selected_value="05",
                    guessed_value="05",
                    is_guessed=True,
                ),
                "Size Category": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "1", "description": "Small"}],
                    selected_value="1",
                ),
            }

            # Verify we have a mix of unambiguous and guessed components (no ambiguous)
            unambiguous_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "unambiguous"
            )
            guessed_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "guessed"
            )
            ambiguous_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "ambiguous"
            )

            self.assertGreater(
                unambiguous_count, 0, "Should have at least 1 unambiguous component"
            )
            self.assertGreater(
                guessed_count, 0, "Should have at least 1 guessed component"
            )
            self.assertEqual(ambiguous_count, 0, "Should have 0 ambiguous components")

            print(
                f"✓ Set up mixed components: {unambiguous_count} unambiguous, {guessed_count} guessed, {ambiguous_count} ambiguous"
            )

        except Exception as e:
            self.fail(f"Could not set up mixed components: {e}")

        # Step 3: Save the code successfully
        print(
            "\n--- Step 3: Saving code with mixed unambiguous and guessed components ---"
        )
        try:
            test_code = "TAR025261"
            code_description = "Textile additive manufactured round aluminum component, medical quality, small size"

            result = await save_procurement_code(
                self.mock_ctx, test_code, code_description
            )

            # Verify success
            self.assertIsInstance(result, StateSnapshotEvent)
            print("✓ Save succeeded with mixed unambiguous and guessed components")

            # Verify code was saved
            self.assertEqual(len(self.state.procurement_codes), 1)
            saved_code = self.state.procurement_codes[0]
            self.assertEqual(saved_code.code, test_code)
            self.assertEqual(saved_code.description, code_description)
            print("✓ Code correctly saved to state")

        except Exception as e:
            self.fail(f"Could not save code with mixed components: {e}")

        print("\n=== Partial disambiguation with guesses test passed! ===")
        return True

    async def test_successful_save_after_iterative_disambiguation(self):
        """Test successful save after multiple rounds of iterative disambiguation."""

        print("\n=== Testing Successful Save After Iterative Disambiguation ===")

        # Step 1: Read file
        try:
            with patch("builtins.open", create=True) as mock_open:
                mock_open.return_value.__enter__.return_value.read.return_value = (
                    self.complete_code_generation_content
                )

                content = read_code_generation_file(self.mock_ctx)
                self.assertTrue(self.state.rules_loaded_this_turn)
                print("✓ Successfully read code generation file")

        except Exception as e:
            self.fail(f"Could not read code generation file: {e}")

        # Step 2: Simulate iterative disambiguation process
        print("\n--- Step 2: Simulating iterative disambiguation rounds ---")

        # Round 1: Some components still ambiguous
        self.state.component_ambiguity_status = {
            "Major Category": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "C", "description": "Chemical products"}],
                selected_value="C",
            ),
            "Manufacturing Method": AmbiguityInfo(
                status="ambiguous",
                options=[
                    {"value": "C", "description": "Casting"},
                    {"value": "F", "description": "Forging"},
                ],
            ),
            "Object Shape": AmbiguityInfo(
                status="ambiguous",
                options=[
                    {"value": "B", "description": "Barrel/cylindrical"},
                    {"value": "T", "description": "Tubular"},
                ],
            ),
        }

        print("✓ Round 1: 1 unambiguous, 2 ambiguous components")

        # Round 2: Some resolved, some still ambiguous
        self.state.component_ambiguity_status["Manufacturing Method"] = AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "F", "description": "Forging"}],
            selected_value="F",
        )
        print("✓ Round 2: Manufacturing Method resolved, 1 remaining ambiguous")

        # Round 3: All resolved
        self.state.component_ambiguity_status["Object Shape"] = AmbiguityInfo(
            status="unambiguous",
            options=[{"value": "T", "description": "Tubular"}],
            selected_value="T",
        )

        # Add remaining unambiguous components
        self.state.component_ambiguity_status.update(
            {
                "Material Type": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "04", "description": "Wood"}],
                    selected_value="04",
                ),
                "Quality Grade": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "02", "description": "Premium"}],
                    selected_value="02",
                ),
                "Size Category": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "2", "description": "Medium"}],
                    selected_value="2",
                ),
            }
        )

        # Verify all components are now unambiguous
        ambiguous_count = sum(
            1
            for info in self.state.component_ambiguity_status.values()
            if info.status == "ambiguous"
        )
        self.assertEqual(
            ambiguous_count,
            0,
            "All components should be unambiguous after iterative disambiguation",
        )
        print("✓ All components resolved after iterative disambiguation")

        # Step 3: Save successfully
        print("\n--- Step 3: Saving after iterative disambiguation ---")
        try:
            test_code = "CFT042261"
            code_description = (
                "Chemical forged tubular wood component, premium quality, medium size"
            )

            result = await save_procurement_code(
                self.mock_ctx, test_code, code_description
            )

            # Verify success
            self.assertIsInstance(result, StateSnapshotEvent)
            print("✓ Save succeeded after iterative disambiguation")

            # Verify code was saved
            self.assertEqual(len(self.state.procurement_codes), 1)
            saved_code = self.state.procurement_codes[0]
            self.assertEqual(saved_code.code, test_code)
            self.assertEqual(saved_code.description, code_description)
            print("✓ Code correctly saved to state")

        except Exception as e:
            self.fail(f"Could not save code after iterative disambiguation: {e}")

        print("\n=== Iterative disambiguation test passed! ===")
        return True


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
