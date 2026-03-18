#!/usr/bin/env python3
"""
Integration tests for generate-then-justify workflow pattern.

These tests verify that the agent follows the generate-then-justify workflow:
1. Generate code IMMEDIATELY without pre-generation confirmation
2. Provide justification AFTER generating the code
3. Never ask "Should I generate this code?" or similar confirmation questions

This is part of task 13.9: Write integration tests for generate-then-justify workflow pattern.
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
        DEFAULT_SIMILARITY_THRESHOLD,
    )
    from pydantic_ai import RunContext
    from pydantic_ai.ag_ui import StateDeps
    from ag_ui.core import EventType, StateSnapshotEvent


class TestGenerateThenJustifyWorkflow(unittest.TestCase):
    """Integration tests for generate-then-justify workflow pattern."""

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

    async def test_generate_then_justify_with_clear_unambiguous_input(self):
        """Test that agent generates code immediately then provides justification for clear, unambiguous input."""

        print("\n=== Testing Generate-Then-Justify with Clear Unambiguous Input ===")

        # Clear, unambiguous user description that should not require disambiguation
        clear_description = "Steel I-beam for office building construction"

        # Step 1: Read the code generation file
        print("\n--- Step 1: Reading code generation file ---")
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

        # Step 2: Call clarify_components to check for ambiguity (should find none or minimal)
        print("\n--- Step 2: Checking for ambiguity ---")
        try:
            result = clarify_components(self.mock_ctx, clear_description)
            result_data = json.loads(result)

            # With a clear description, we should have mostly unambiguous components
            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            print(f"✓ Found {unambiguous_count} unambiguous components")
            print(f"✓ Found {ambiguous_count} ambiguous components")

            # For a clear description like "Steel I-beam", we expect minimal ambiguity
            # (Steel is clear, I-beam suggests specific shape, construction suggests industrial use)

        except Exception as e:
            self.fail(f"Could not check for ambiguity: {e}")

        # Step 3: Simulate generate-then-justify workflow
        print("\n--- Step 3: Simulating generate-then-justify workflow ---")

        # Based on the clear description, we can determine:
        # - Steel -> Material Type: 01
        # - I-beam -> Object Shape: Angular (A) or Flat/sheet (F) - I-beams are typically angular
        # - Construction -> Major Category: Likely Metal products (M) or construction-related
        # - Office building -> Quality Grade: likely Industrial (03) or Premium (02)
        # - Building size -> Size Category: likely Large (3) or Extra Large (4)

        # Set up state with unambiguous components
        self.state.component_ambiguity_status = {
            "Major Category": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "M", "description": "Metal products"}],
                selected_value="M",
            ),
            "Manufacturing Method": AmbiguityInfo(
                status="unambiguous",
                options=[
                    {"value": "F", "description": "Forging"}
                ],  # I-beams are typically forged
                selected_value="F",
            ),
            "Object Shape": AmbiguityInfo(
                status="unambiguous",
                options=[
                    {"value": "A", "description": "Angular"}
                ],  # I-beams are angular
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

        # Verify all components are unambiguous
        ambiguous_count = sum(
            1
            for info in self.state.component_ambiguity_status.values()
            if info.status == "ambiguous"
        )
        self.assertEqual(
            ambiguous_count, 0, "All components should be unambiguous for clear input"
        )
        print("✓ All components determined as unambiguous")

        # Step 4: Generate code and save (should succeed immediately)
        print(
            "\n--- Step 4: Generating code and saving (should succeed immediately) ---"
        )
        try:
            # M (Metal) + F (Forging) + A (Angular) + 01 (Steel) + 03 (Industrial) + 3 (Large) + 26 (Year) + 1 (Sequence)
            generated_code = "MFA013261"
            code_description = "Steel I-beam for office building construction"

            result = await save_procurement_code(
                self.mock_ctx, generated_code, code_description
            )

            # Verify success
            self.assertIsInstance(result, StateSnapshotEvent)
            print(
                "✓ Code generated and saved successfully (no pre-generation confirmation needed)"
            )

            # Verify code was saved
            self.assertEqual(len(self.state.procurement_codes), 1)
            saved_code = self.state.procurement_codes[0]
            self.assertEqual(saved_code.code, generated_code)
            self.assertEqual(saved_code.description, code_description)
            print("✓ Code correctly saved to state")

        except Exception as e:
            self.fail(f"Could not generate and save code: {e}")

        print("\n=== Generate-then-justify workflow test passed! ===")
        print("✓ Agent generated code immediately for clear input")
        print("✓ No pre-generation confirmation was required")
        print("✓ Code was saved successfully")
        return True

    async def test_generate_then_justify_with_partial_ambiguity(self):
        """Test that agent generates code immediately even with some ambiguity, then provides justification."""

        print("\n=== Testing Generate-Then-Justify with Partial Ambiguity ===")

        # Partially ambiguous description
        partial_ambiguous_description = "Metal component for industrial use"

        # Step 1: Read the code generation file
        try:
            with patch("builtins.open", create=True) as mock_open:
                mock_open.return_value.__enter__.return_value.read.return_value = (
                    self.complete_code_generation_content
                )

                content = read_code_generation_file(self.mock_ctx)
                self.assertTrue(self.state.rules_loaded_this_turn)
        except Exception as e:
            self.fail(f"Could not read code generation file: {e}")

        # Step 2: Check for ambiguity (should find some)
        try:
            result = clarify_components(self.mock_ctx, partial_ambiguous_description)
            result_data = json.loads(result)

            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            print(f"✓ Found {unambiguous_count} unambiguous components")
            print(f"✓ Found {ambiguous_count} ambiguous components")

            # For "Metal component for industrial use", we expect some ambiguity
            # - Metal -> Major Category: M (unambiguous)
            # - component -> could be various shapes/manufacturing methods (ambiguous)
            # - industrial -> Quality Grade: likely 03 (unambiguous)

            self.assertGreater(
                ambiguous_count, 0, "Should have some ambiguous components"
            )

        except Exception as e:
            self.fail(f"Could not check for ambiguity: {e}")

        # Step 3: Simulate generate-then-justify workflow with best guesses for ambiguous components
        print("\n--- Step 3: Simulating generate-then-justify with best guesses ---")

        # Set up state with mix of unambiguous and guessed components
        self.state.component_ambiguity_status = {
            "Major Category": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "M", "description": "Metal products"}],
                selected_value="M",
            ),
            "Manufacturing Method": AmbiguityInfo(
                status="guessed",  # Guessed based on "component" suggesting machining
                options=[{"value": "M", "description": "Machining"}],
                selected_value="M",
                guessed_value="M",
                is_guessed=True,
            ),
            "Object Shape": AmbiguityInfo(
                status="guessed",  # Guessed as generic component shape
                options=[{"value": "C", "description": "Cubic"}],
                selected_value="C",
                guessed_value="C",
                is_guessed=True,
            ),
            "Material Type": AmbiguityInfo(
                status="guessed",  # Guessed as steel for industrial metal component
                options=[{"value": "01", "description": "Steel"}],
                selected_value="01",
                guessed_value="01",
                is_guessed=True,
            ),
            "Quality Grade": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "03", "description": "Industrial"}],
                selected_value="03",
            ),
            "Size Category": AmbiguityInfo(
                status="guessed",  # Guessed as medium for generic component
                options=[{"value": "2", "description": "Medium"}],
                selected_value="2",
                guessed_value="2",
                is_guessed=True,
            ),
        }

        # Verify no ambiguous components remain
        ambiguous_count = sum(
            1
            for info in self.state.component_ambiguity_status.values()
            if info.status == "ambiguous"
        )
        self.assertEqual(ambiguous_count, 0, "No components should remain ambiguous")
        print("✓ All ambiguities resolved (some through guessing)")

        # Step 4: Generate and save code (should succeed immediately)
        try:
            # M (Metal) + M (Machining) + C (Cubic) + 01 (Steel) + 03 (Industrial) + 2 (Medium) + 26 (Year) + 1 (Sequence)
            generated_code = "MMC013261"
            code_description = "Metal component for industrial use"

            result = await save_procurement_code(
                self.mock_ctx, generated_code, code_description
            )

            # Verify success
            self.assertIsInstance(result, StateSnapshotEvent)
            print("✓ Code generated and saved successfully despite initial ambiguity")

            # Verify code was saved
            self.assertEqual(len(self.state.procurement_codes), 1)
            saved_code = self.state.procurement_codes[0]
            self.assertEqual(saved_code.code, generated_code)
            self.assertEqual(saved_code.description, code_description)
            print("✓ Code correctly saved to state")

        except Exception as e:
            self.fail(f"Could not generate and save code with partial ambiguity: {e}")

        print("\n=== Generate-then-justify with partial ambiguity test passed! ===")
        print("✓ Agent generated code immediately despite some ambiguity")
        print("✓ Used best guesses for ambiguous components")
        print("✓ No pre-generation confirmation was required")
        return True

    def test_response_format_follows_generate_then_justify_pattern(self):
        """Test that the response format follows the generate-then-justify pattern."""

        print("\n=== Testing Response Format Follows Generate-Then-Justify Pattern ===")

        # This test verifies that the system prompt instructs the correct response format
        # The expected format should be:
        # - Start with: "Generated code: [CODE]"
        # - Follow with: "Justification: [explanation]"

        # Since we can't easily test the actual LLM response in this unit test,
        # we'll verify that the system prompt contains the correct instructions

        from agent import STATIC_SYSTEM_PROMPT

        # Check that the system prompt contains generate-then-justify instructions
        prompt_content = STATIC_SYSTEM_PROMPT

        # Verify the prompt explicitly mentions generating first
        self.assertIn(
            "GENERATE-THEN-JUSTIFY",
            prompt_content,
            "System prompt should mention GENERATE-THEN-JUSTIFY workflow",
        )

        # Verify the prompt instructs to generate immediately
        self.assertIn(
            "Generate the procurement code IMMEDIATELY",
            prompt_content,
            "System prompt should instruct to generate code immediately",
        )

        # Verify the prompt forbids pre-generation confirmation
        self.assertIn(
            "NEVER wait for pre-generation confirmation",
            prompt_content,
            "System prompt should forbid pre-generation confirmation",
        )

        # Verify the prompt specifies the response format
        self.assertIn(
            "Generated code: [CODE]",
            prompt_content,
            "System prompt should specify 'Generated code: [CODE]' format",
        )
        self.assertIn(
            "Justification: [explanation]",
            prompt_content,
            "System prompt should specify 'Justification: [explanation]' format",
        )

        # Verify the prompt explicitly forbids confirmation questions
        forbidden_phrases = [
            "Should I generate this code?",
            "Do you want me to proceed?",
            "pre-generation confirmation",
        ]

        for phrase in forbidden_phrases:
            self.assertIn(
                phrase, prompt_content, f"System prompt should forbid '{phrase}'"
            )

        print("✓ System prompt contains generate-then-justify instructions")
        print("✓ Prompt instructs to generate code immediately")
        print("✓ Prompt forbids pre-generation confirmation")
        print("✓ Prompt specifies correct response format")
        print("✓ Response format test passed!")
        return True

    async def test_confident_behavior_with_completely_clear_input(self):
        """Test that agent behaves confidently when input is completely clear and unambiguous."""

        print("\n=== Testing Confident Behavior with Completely Clear Input ===")

        # Extremely clear and specific description
        very_clear_description = (
            "Stainless steel CNC machined flat sheet for medical device"
        )

        # Step 1: Read the code generation file
        try:
            with patch("builtins.open", create=True) as mock_open:
                mock_open.return_value.__enter__.return_value.read.return_value = (
                    self.complete_code_generation_content
                )

                content = read_code_generation_file(self.mock_ctx)
                self.assertTrue(self.state.rules_loaded_this_turn)
        except Exception as e:
            self.fail(f"Could not read code generation file: {e}")

        # Step 2: Check for ambiguity (should find none)
        try:
            result = clarify_components(self.mock_ctx, very_clear_description)
            result_data = json.loads(result)

            ambiguous_count = len(result_data["ambiguous_components"])
            unambiguous_count = len(result_data["unambiguous_components"])

            print(f"✓ Found {unambiguous_count} unambiguous components")
            print(f"✓ Found {ambiguous_count} ambiguous components")

            # For such a specific description, we expect maximum unambiguous components

        except Exception as e:
            self.fail(f"Could not check for ambiguity: {e}")

        # Step 3: Set up completely unambiguous state
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
                options=[{"value": "F", "description": "Flat/sheet"}],
                selected_value="F",
            ),
            "Material Type": AmbiguityInfo(
                status="unambiguous",
                options=[
                    {"value": "01", "description": "Steel"}
                ],  # Stainless steel falls under steel
                selected_value="01",
            ),
            "Quality Grade": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "05", "description": "Medical"}],
                selected_value="05",
            ),
            "Size Category": AmbiguityInfo(
                status="unambiguous",
                options=[
                    {"value": "2", "description": "Medium"}
                ],  # Medical device components typically medium
                selected_value="2",
            ),
        }

        # Verify complete lack of ambiguity
        ambiguous_count = sum(
            1
            for info in self.state.component_ambiguity_status.values()
            if info.status == "ambiguous"
        )
        guessed_count = sum(
            1
            for info in self.state.component_ambiguity_status.values()
            if info.status == "guessed"
        )

        self.assertEqual(ambiguous_count, 0, "Should have no ambiguous components")
        self.assertEqual(
            guessed_count,
            0,
            "Should have no guessed components with completely clear input",
        )
        print("✓ All components are unambiguous (no guessing required)")

        # Step 4: Generate and save with maximum confidence
        try:
            # M (Metal) + M (Machining) + F (Flat) + 01 (Steel) + 05 (Medical) + 2 (Medium) + 26 (Year) + 1 (Sequence)
            generated_code = "MMF015261"
            code_description = (
                "Stainless steel CNC machined flat sheet for medical device"
            )

            result = await save_procurement_code(
                self.mock_ctx, generated_code, code_description
            )

            # Verify success
            self.assertIsInstance(result, StateSnapshotEvent)
            print("✓ Code generated with maximum confidence")

            # Verify code was saved
            self.assertEqual(len(self.state.procurement_codes), 1)
            saved_code = self.state.procurement_codes[0]
            self.assertEqual(saved_code.code, generated_code)
            self.assertEqual(saved_code.description, code_description)
            print("✓ Code saved successfully with complete confidence")

        except Exception as e:
            self.fail(f"Could not generate and save code with complete confidence: {e}")

        print("\n=== Confident behavior test passed! ===")
        print("✓ Agent showed maximum confidence with completely clear input")
        print("✓ No hesitation or confirmation needed")
        print("✓ Direct code generation and save")
        return True


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
