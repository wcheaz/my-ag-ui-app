#!/usr/bin/env python3
"""
Integration test for save rejection with ambiguous components.

This test verifies the end-to-end workflow when the user provides a description
that results in ambiguous components, and the save_procurement_code function
correctly rejects the save with a clear error message.
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


class TestSaveRejectionWithAmbiguousComponents(unittest.TestCase):
    """Integration test for save rejection when components are ambiguous."""

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

    async def test_save_rejection_with_ambiguous_components(self):
        """Test that save_procurement_code rejects save when components are ambiguous."""

        # Ambiguous user description that should result in multiple ambiguous components
        ambiguous_user_description = (
            "I need some kind of product made from materials. "
            "It should have some quality and size. I need it for something."
        )

        print("=== Testing Save Rejection with Ambiguous Components ===")
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

            # With this ambiguous description, we should have multiple ambiguous components
            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            print(f"✓ Found {unambiguous_count} unambiguous components")
            print(f"✓ Found {ambiguous_count} ambiguous components")

            # Should have some ambiguous components with this vague description
            self.assertGreater(
                ambiguous_count,
                0,
                f"Expected at least 1 ambiguous component with vague description, got {ambiguous_count}",
            )

            print("✓ Vague description resulted in ambiguous components (as expected)")

        except Exception as e:
            self.fail(f"Step 2 failed: Could not clarify components: {e}")

        # Step 3: Attempt to save the procurement code (should be rejected)
        print(
            "\n--- Step 3: Attempting to save procurement code (should be rejected) ---"
        )
        try:
            # Generate a test code (this would normally be based on unambiguous components)
            test_code = "TEST001"
            code_description = "Test code for ambiguous components scenario"

            # Call save_procurement_code
            result = await save_procurement_code(
                self.mock_ctx, test_code, code_description
            )

            # Verify that an error string was returned (not a StateSnapshotEvent)
            self.assertIsInstance(
                result,
                str,
                f"Expected error string, got {type(result)}: {result}",
            )
            print(
                "✓ save_procurement_code returned error string (as expected for ambiguous components)"
            )

            # Verify the error message contains the expected text
            self.assertIn(
                "Cannot save code with ambiguous components",
                result,
                f"Expected ambiguity error message, got: {result}",
            )
            print("✓ Error message contains expected ambiguity rejection text")

            # Verify that the error message mentions specific ambiguous components
            # The exact components will depend on the clarify_components logic
            self.assertIn(
                "Please clarify the following components:",
                result,
                f"Expected component clarification list in error message, got: {result}",
            )
            print("✓ Error message includes list of components to clarify")

            # Verify that no code was saved to the state
            self.assertEqual(
                len(self.state.procurement_codes),
                0,
                f"Expected 0 codes in state, got {len(self.state.procurement_codes)}",
            )
            print("✓ No code was saved to state (as expected for ambiguous components)")

        except Exception as e:
            self.fail(f"Step 3 failed: Could not test save rejection: {e}")

        print("\n=== Save rejection with ambiguous components test passed! ===")
        print("The workflow correctly rejects saves when components are ambiguous:")
        print("- Step 1: ✓ Code generation file read successfully")
        print("- Step 2: ✓ Components identified as ambiguous")
        print("- Step 3: ✓ Save rejected with clear error message")
        print("- Step 4: ✓ No code saved to state (save blocked)")

        return True

    async def test_save_rejection_with_specific_ambiguous_components(self):
        """Test save rejection with manually set ambiguous components for precise testing."""

        print("\n=== Testing Save Rejection with Specific Ambiguous Components ===")

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

        # Step 2: Manually set specific ambiguous components in state
        print("\n--- Step 2: Setting specific ambiguous components in state ---")
        try:
            # Set up specific ambiguous components
            self.state.component_ambiguity_status = {
                "Major Category": AmbiguityInfo(
                    status="ambiguous",
                    options=[
                        {"value": "A", "description": "Agricultural products"},
                        {"value": "C", "description": "Chemical products"},
                    ],
                ),
                "Manufacturing Method": AmbiguityInfo(
                    status="ambiguous",
                    options=[
                        {"value": "M", "description": "Machining"},
                        {"value": "F", "description": "Forging"},
                    ],
                ),
                "Material Type": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "01", "description": "Steel"}],
                    selected_value="01",
                ),
            }

            # Verify we have the expected number of ambiguous components
            ambiguous_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "ambiguous"
            )
            self.assertEqual(
                ambiguous_count, 2, "Expected exactly 2 ambiguous components"
            )
            print(
                "✓ Set exactly 2 ambiguous components (Major Category, Manufacturing Method)"
            )

        except Exception as e:
            self.fail(f"Could not set ambiguous components in state: {e}")

        # Step 3: Attempt to save and verify rejection
        print("\n--- Step 3: Attempting to save (should be rejected) ---")
        try:
            test_code = "TEST002"
            code_description = "Test code with specific ambiguous components"

            result = await save_procurement_code(
                self.mock_ctx, test_code, code_description
            )

            # Verify error response
            self.assertIsInstance(result, str)
            self.assertIn("Cannot save code with ambiguous components", result)
            print("✓ Save rejected with error message")

            # Verify specific components are mentioned in error
            self.assertIn("Major Category", result)
            self.assertIn("Manufacturing Method", result)
            print("✓ Error message mentions specific ambiguous components")

            # Verify no code was saved
            self.assertEqual(len(self.state.procurement_codes), 0)
            print("✓ No code saved to state")

        except Exception as e:
            self.fail(f"Save rejection test failed: {e}")

        print("\n=== Specific ambiguous components test passed! ===")
        return True

    async def test_save_success_after_resolving_ambiguity(self):
        """Test that save succeeds after all components are resolved (unambiguous)."""

        print("\n=== Testing Save Success After Resolving Ambiguity ===")

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

        # Step 2: Set up state with all unambiguous components
        print("\n--- Step 2: Setting all components as unambiguous ---")
        try:
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
                    options=[{"value": "04", "description": "Aerospace"}],
                    selected_value="04",
                ),
                "Size Category": AmbiguityInfo(
                    status="unambiguous",
                    options=[{"value": "2", "description": "Medium"}],
                    selected_value="2",
                ),
            }

            # Verify all components are unambiguous
            ambiguous_count = sum(
                1
                for info in self.state.component_ambiguity_status.values()
                if info.status == "ambiguous"
            )
            self.assertEqual(ambiguous_count, 0, "Expected 0 ambiguous components")
            print("✓ All components set as unambiguous")

        except Exception as e:
            self.fail(f"Could not set unambiguous components in state: {e}")

        # Step 3: Attempt to save and verify success
        print("\n--- Step 3: Attempting to save (should succeed) ---")
        try:
            test_code = "MMA014261"  # Based on the unambiguous components
            code_description = (
                "Metal machined angular steel component, aerospace quality, medium size"
            )

            result = await save_procurement_code(
                self.mock_ctx, test_code, code_description
            )

            # Verify success response (StateSnapshotEvent)
            self.assertIsInstance(
                result,
                StateSnapshotEvent,
                f"Expected StateSnapshotEvent for successful save, got {type(result)}",
            )
            print("✓ Save succeeded, returned StateSnapshotEvent")

            # Verify code was saved to state
            self.assertEqual(len(self.state.procurement_codes), 1)
            saved_code = self.state.procurement_codes[0]
            self.assertEqual(saved_code.code, test_code)
            self.assertEqual(saved_code.description, code_description)
            print("✓ Code correctly saved to state")

        except Exception as e:
            self.fail(f"Save success test failed: {e}")

        print("\n=== Save success after resolving ambiguity test passed! ===")
        return True


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
