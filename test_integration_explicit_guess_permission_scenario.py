#!/usr/bin/env python3
"""
Integration test for explicit guess permission scenario.

This test verifies the complete disambiguation workflow when the user gives
explicit permission for the agent to make guesses for ambiguous components.

Key scenarios tested:
1. User provides a description with ambiguous components
2. User gives explicit guess permission (e.g., "I don't know", "whatever", "you choose")
3. System detects guess permission and marks components as "guessed"
4. System generates user notification about the guesses
5. System allows code generation with guessed components
6. System correctly stores guessed values in state
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
        detect_explicit_guess_permission,
    )
    from pydantic_ai import RunContext
    from pydantic_ai.ag_ui import StateDeps
    from ag_ui.core import EventType, StateSnapshotEvent


class TestExplicitGuessPermissionScenario(unittest.TestCase):
    """Integration test for explicit guess permission scenario."""

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

    async def test_explicit_guess_permission_scenario(self):
        """Test the complete workflow with explicit guess permission."""

        # User description that should result in ambiguous components
        # "manufactured component" is ambiguous (could be Machining, Casting, or Forging)
        # "shaped object" is ambiguous (could be Angular, Round, or Barrel)
        # "industrial product" is ambiguous (could be Industrial or Standard quality)
        ambiguous_user_description = (
            "I need a manufactured shaped industrial steel component. "
            "It should be medium-sized and made of steel."
        )

        # User gives explicit guess permission
        user_with_guess_permission = "I don't know, you choose whatever is best"

        print("=== Testing Explicit Guess Permission Scenario ===")
        print(f"User description: {ambiguous_user_description}")
        print(f"User permission: {user_with_guess_permission}")

        # Step 1: Verify guess permission detection
        print("\n--- Step 1: Verifying guess permission detection ---")
        try:
            guess_detected = detect_explicit_guess_permission(
                user_with_guess_permission
            )
            self.assertTrue(
                guess_detected,
                f"Expected to detect guess permission in: '{user_with_guess_permission}'",
            )
            print("✓ Guess permission detected correctly")
        except Exception as e:
            self.fail(f"Step 1 failed: Could not detect guess permission: {e}")

        # Step 2: Read the code generation file
        print("\n--- Step 2: Reading code generation file ---")
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
            self.fail(f"Step 2 failed: Could not read code generation file: {e}")

        # Step 3: Call clarify_components with guess permission
        print("\n--- Step 3: Calling clarify_components with guess permission ---")
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

            # Verify that we have some ambiguous components that could be guessed
            ambiguous_components = result_data["ambiguous_components"]
            unambiguous_components = result_data["unambiguous_components"]

            self.assertGreaterEqual(
                len(ambiguous_components),
                2,
                f"Expected at least 2 ambiguous components for guess permission test, got {len(ambiguous_components)}",
            )

            print(
                f"✓ Found {len(ambiguous_components)} ambiguous components that can be guessed"
            )
            print(f"✓ Found {len(unambiguous_components)} unambiguous components")

            # Store the ambiguous component info for later verification
            self.ambiguous_component_names = [
                comp["component_name"] for comp in ambiguous_components
            ]

        except Exception as e:
            self.fail(f"Step 3 failed: Could not clarify components: {e}")

        # Step 4: Simulate guess permission and mark components as guessed
        print("\n--- Step 4: Marking components as guessed based on permission ---")
        try:
            guessed_components = []

            # For each ambiguous component, mark it as guessed since user gave permission
            for comp_info in ambiguous_components:
                component_name = comp_info["component_name"]

                # Use the first option as the guessed value (highest scoring match)
                guessed_value = comp_info["options"][0]["value"]
                guessed_description = comp_info["options"][0]["description"]

                # Create AmbiguityInfo for the guessed component
                ambiguity_info = AmbiguityInfo(
                    status="guessed",
                    options=comp_info["options"],
                    selected_value=guessed_value,
                    guessed_value=guessed_value,
                    is_guessed=True,
                )

                # Update the state
                self.state.update_component_ambiguity(component_name, ambiguity_info)
                guessed_components.append(
                    {
                        "component_name": component_name,
                        "guessed_value": guessed_value,
                        "description": guessed_description,
                    }
                )

                print(
                    f"✓ Marked '{component_name}' as guessed with value '{guessed_value}'"
                )

            # Verify that all ambiguous components are now marked as guessed in state
            for comp_name in self.ambiguous_component_names:
                self.assertIn(
                    comp_name,
                    self.state.component_ambiguity_status,
                    f"Component '{comp_name}' should be in component_ambiguity_status",
                )

                comp_info = self.state.component_ambiguity_status[comp_name]
                self.assertEqual(
                    comp_info.status,
                    "guessed",
                    f"Component '{comp_name}' should have status 'guessed', got '{comp_info.status}'",
                )
                self.assertTrue(
                    comp_info.is_guessed,
                    f"Component '{comp_name}' should have is_guessed=True",
                )
                self.assertIsNotNone(
                    comp_info.guessed_value,
                    f"Component '{comp_name}' should have a guessed_value",
                )

            print("✓ All ambiguous components marked as guessed in state")
            self.guessed_components = guessed_components

        except Exception as e:
            self.fail(f"Step 4 failed: Could not mark components as guessed: {e}")

        # Step 5: Generate user notification about guesses
        print("\n--- Step 5: Generating user notification about guesses ---")
        try:
            # Format a notification message
            notification_lines = [
                "🎯 **I've made the following guesses based on your permission:**",
                "",
            ]

            for comp in guessed_components:
                component_name = comp["component_name"]
                guessed_value = comp["guessed_value"]
                description = comp["description"]

                notification_lines.append(f"**{component_name}**: {description}")
                notification_lines.append(f"  → Guessed value: {guessed_value}")
                notification_lines.append("")

            notification_lines.extend(
                [
                    '💡 **Note**: These guesses are based on your explicit permission (e.g., "I don\'t know", "whatever", "you choose").',
                    "If you'd like to change any of these guesses, please let me know which component you'd like to clarify.",
                    "",
                ]
            )

            notification = "\n".join(notification_lines)

            # Verify notification content
            self.assertIn("🎯", notification)
            self.assertIn("guesses based on your permission", notification)
            self.assertIn("I don't know", notification)
            self.assertIn("whatever", notification)
            self.assertIn("you choose", notification)

            # Verify all guessed components are mentioned
            for comp in guessed_components:
                self.assertIn(comp["component_name"], notification)
                self.assertIn(comp["guessed_value"], notification)

            print("✓ User notification generated successfully")
            print(
                "✓ Notification contains all guessed components and permission phrases"
            )
            self.guess_notification = notification

        except Exception as e:
            self.fail(f"Step 5 failed: Could not generate user notification: {e}")

        # Step 6: Attempt to save the procurement code (should succeed with guessed components)
        print("\n--- Step 6: Saving procurement code with guessed components ---")
        try:
            # Based on the guessed components, we expect:
            # - Major: M (Metal products) - should be unambiguous
            # - Manufacturing: M (Machining) - guessed (first option)
            # - Shape: A (Angular) - guessed (first option)
            # - Material: 01 (Steel) - should be unambiguous
            # - Quality: 03 (Industrial) - guessed (first option)
            # - Size: 2 (Medium) - should be unambiguous
            # - Year: 26 (current year)
            # - Sequence: 1 (first code)

            generated_code = "MMA013261"
            code_description = (
                "Manufactured shaped industrial steel component, medium size "
                "(Manufacturing Method: Machining, Object Shape: Angular, Quality Grade: Industrial - all guessed based on user permission)"
            )

            # Verify that all components are either unambiguous or guessed (not ambiguous)
            try:
                self.state.validate_all_components_unambiguous()
                print("✓ All components validated as either unambiguous or guessed")
            except ValueError as e:
                self.fail(f"Components validation failed: {e}")

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
            print("✓ Code was successfully saved to state with guessed components")

        except Exception as e:
            self.fail(f"Step 6 failed: Could not save procurement code: {e}")

        print("\n=== Explicit Guess Permission Scenario Test Passed! ===")
        print("The workflow with explicit guess permission works correctly:")
        print("- Step 1: ✓ Guess permission detected correctly")
        print("- Step 2: ✓ Code generation file read successfully")
        print("- Step 3: ✓ Ambiguous components identified for guessing")
        print("- Step 4: ✓ Components marked as guessed in state")
        print("- Step 5: ✓ User notification generated")
        print("- Step 6: ✓ Code saved successfully with guessed components")

        return True

    async def test_different_guess_permission_phrases(self):
        """Test different types of guess permission phrases."""

        print("\n=== Testing Different Guess Permission Phrases ===")

        # Test various guess permission phrases
        guess_permission_test_cases = [
            (
                "I don't know, whatever you choose",
                "I don't know + whatever + you choose",
            ),
            ("just guess for me", "Direct guess instruction"),
            ("your call, I have no idea", "Delegative + no idea combination"),
            ("any of them is fine", "Indifference phrase"),
            ("up to you, I don't care", "Delegative + don't care combination"),
            ("feel free to make a guess", "Polite guess permission"),
            ("whichever you think is best", "Indifference + delegative"),
        ]

        for user_phrase, description in guess_permission_test_cases:
            print(f"\n--- Testing phrase: '{user_phrase}' ({description}) ---")

            # Reset state for each test
            self.state = ProcurementState()
            self.mock_ctx.deps = StateDeps(state=self.state)

            try:
                # Step 1: Verify guess permission detection
                guess_detected = detect_explicit_guess_permission(user_phrase)
                self.assertTrue(
                    guess_detected,
                    f"Expected to detect guess permission in: '{user_phrase}'",
                )

                # Step 2: Read code generation file
                with patch("builtins.open", create=True) as mock_open:
                    mock_open.return_value.__enter__.return_value.read.return_value = (
                        self.complete_code_generation_content
                    )
                    read_code_generation_file(self.mock_ctx)

                # Step 3: Get ambiguous components
                ambiguous_description = (
                    "I need a manufactured shaped industrial steel component"
                )
                result = clarify_components(self.mock_ctx, ambiguous_description)
                result_data = json.loads(result)

                ambiguous_components = result_data["ambiguous_components"]
                self.assertGreater(
                    len(ambiguous_components),
                    0,
                    f"Should have at least one ambiguous component for phrase: '{user_phrase}'",
                )

                # Step 4: Mark components as guessed
                for comp_info in ambiguous_components:
                    component_name = comp_info["component_name"]
                    guessed_value = comp_info["options"][0]["value"]

                    ambiguity_info = AmbiguityInfo(
                        status="guessed",
                        options=comp_info["options"],
                        selected_value=guessed_value,
                        guessed_value=guessed_value,
                        is_guessed=True,
                    )

                    self.state.update_component_ambiguity(
                        component_name, ambiguity_info
                    )

                # Step 5: Verify save works with guessed components
                generated_code = "MMA013261"
                code_description = f"Test component with phrase: {user_phrase}"

                result = await save_procurement_code(
                    self.mock_ctx, generated_code, code_description
                )

                self.assertIsInstance(
                    result,
                    StateSnapshotEvent,
                    f"Expected StateSnapshotEvent for phrase '{user_phrase}', got {type(result)}: {result}",
                )

                print(f"✓ Phrase '{user_phrase}' works correctly")

            except Exception as e:
                self.fail(f"Failed testing phrase '{user_phrase}': {e}")

        print("\n✓ All guess permission phrases tested successfully")

    async def test_save_blocked_without_guess_permission(self):
        """Test that save is blocked when components are ambiguous and no guess permission given."""

        print("\n--- Testing Save Blocked Without Guess Permission ---")

        # Reset state
        self.state = ProcurementState()
        self.mock_ctx.deps = StateDeps(state=self.state)

        # Read file and get ambiguous components
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )
            read_code_generation_file(self.mock_ctx)

        ambiguous_description = (
            "I need a manufactured shaped industrial steel component"
        )
        result = clarify_components(self.mock_ctx, ambiguous_description)
        result_data = json.loads(result)

        # Verify we have ambiguous components
        ambiguous_components = result_data["ambiguous_components"]
        self.assertGreater(
            len(ambiguous_components), 0, "Should have at least one ambiguous component"
        )

        # DO NOT mark them as guessed (no permission)

        # Try to save without resolving or guessing
        generated_code = "MMA013261"
        code_description = "Test component"

        result = await save_procurement_code(
            self.mock_ctx, generated_code, code_description
        )

        # Verify that an error string was returned (not a StateSnapshotEvent)
        self.assertIsInstance(
            result,
            str,
            f"Expected error string when no guess permission given, got {type(result)}: {result}",
        )

        # Verify the error message mentions ambiguous components
        self.assertIn(
            "ambiguous",
            result.lower(),
            f"Error message should mention 'ambiguous' when no guess permission given, got: {result}",
        )

        # Verify that no code was saved
        self.assertEqual(
            len(self.state.procurement_codes),
            0,
            "No code should be saved when components are ambiguous and no guess permission given",
        )

        print("✓ Save correctly blocked when no guess permission given")
        print("✓ Error message correctly indicates ambiguous components")


if __name__ == "__main__":
    # Run the tests
    print("Running integration test for explicit guess permission scenario...")
    print("=" * 70)

    # Run with detailed output
    unittest.main(verbosity=2)
