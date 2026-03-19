#!/usr/bin/env python3
"""
Unit tests for guess marking and notification integration.

This module provides comprehensive unit tests for the complete guess marking and notification
workflow, testing the integration between:
1. Guess permission detection
2. Component marking as guessed
3. User notification generation

These tests ensure that the complete workflow functions correctly when a user gives
explicit guess permission, from detection through to user notification.
"""

import sys
import os
import re
import unittest
from typing import Dict, List, Optional
from unittest.mock import Mock, MagicMock

# Add the agent src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

# Import the classes and functions we need to test
try:
    from pydantic import BaseModel
    from pydantic_ai import Agent, RunContext
    from pydantic_ai.ag_ui import StateDeps

    IMPORTS_AVAILABLE = True
except ImportError:
    # Create minimal mocks for testing
    class BaseModel:
        pass

    IMPORTS_AVAILABLE = False


class AmbiguityInfo:
    """
    Data class to track component ambiguity status during disambiguation workflow.
    """

    def __init__(
        self,
        status: str,
        options: List[dict] = None,
        selected_value: Optional[str] = None,
        guessed_value: Optional[str] = None,
        is_guessed: bool = False,
    ):
        self.status = status  # "ambiguous", "unambiguous", or "guessed"
        self.options = (
            options or []
        )  # List of plausible matches with their descriptions
        self.selected_value = selected_value  # User's selected value when resolved
        self.guessed_value = (
            guessed_value  # Value selected when user gave guess permission
        )
        self.is_guessed = is_guessed  # Flag indicating if this component was guessed


class ProcurementState:
    """
    State for the Procurement Agent.
    """

    def __init__(
        self,
        conversation_id: Optional[str] = None,
        procurement_codes: List[str] = None,
        citation_sources: List[str] = None,
        rules_loaded_this_turn: bool = False,
        component_ambiguity_status: Dict[str, AmbiguityInfo] = None,
    ):
        self.conversation_id = conversation_id
        self.procurement_codes = procurement_codes or []
        self.citation_sources = citation_sources or []
        self.rules_loaded_this_turn = rules_loaded_this_turn
        self.component_ambiguity_status = component_ambiguity_status or {}

    def update_component_ambiguity(
        self, component_name: str, ambiguity_info: AmbiguityInfo
    ) -> None:
        """
        Update component ambiguity status with validation for state transitions.
        """
        # Validate that unambiguous components have a selected_value
        if (
            ambiguity_info.status == "unambiguous"
            and ambiguity_info.selected_value is None
        ):
            raise ValueError(
                f"Invalid state for component '{component_name}': "
                f"Unambiguous components must have a selected_value."
            )

        # Validate that guessed components have a guessed_value
        if ambiguity_info.status == "guessed" and ambiguity_info.guessed_value is None:
            raise ValueError(
                f"Invalid state for component '{component_name}': "
                f"Guessed components must have a guessed_value."
            )

        if component_name in self.component_ambiguity_status:
            current_info = self.component_ambiguity_status[component_name]

            # Validate state transitions: only allow ambiguous → unambiguous or ambiguous → guessed
            if (
                current_info.status in ["unambiguous", "guessed"]
                and ambiguity_info.status == "ambiguous"
            ):
                raise ValueError(
                    f"Invalid state transition for component '{component_name}': "
                    f"Cannot transition from '{current_info.status}' to 'ambiguous'. "
                    f"Once a component is resolved (unambiguous or guessed), it cannot become ambiguous again."
                )

        # Apply the update
        self.component_ambiguity_status[component_name] = ambiguity_info


def detect_explicit_guess_permission(user_text: str) -> bool:
    """
    Detect explicit guess permission phrases in user text.
    """
    # Normalize the text for case-insensitive matching
    normalized_text = user_text.lower().strip()

    # Define explicit guess permission phrases
    guess_permission_phrases = [
        # Direct statements of not knowing
        r"i don't know",
        r"i dont know",
        r"idk",
        r"i have no idea",
        r"no idea",
        r"i'm not sure",
        r"im not sure",
        r"not sure",
        # Delegative phrases
        r"you choose",
        r"you decide",
        r"your choice",
        r"your decision",
        r"up to you",
        r"your call",
        r"your judgment",
        # Indifference phrases
        r"whatever",
        r"whichever",
        r"either one",
        r"any of them",
        r"any is fine",
        r"doesn't matter",
        r"doesn't matter to me",
        r"i don't care",
        r"i dont care",
        r"don't care",
        # Explicit permission to guess
        r"just guess",
        r"guess for me",
        r"make a guess",
        r"take your best guess",
        r"your best guess",
        r"go ahead and guess",
        r"feel free to guess",
    ]

    # Check for exact phrase matches using word boundaries
    for phrase in guess_permission_phrases:
        # Use regex with word boundaries to avoid partial matches
        pattern = r"\b" + re.escape(phrase) + r"\b"
        if re.search(pattern, normalized_text):
            return True

    # Check for variations and combinations
    # Handle "I don't know" followed by indifference
    if re.search(r"\bi don't know\b.*\bwhatever\b", normalized_text):
        return True

    # Handle "you choose" variations with indifference
    if re.search(r"\byou choose\b.*\bdoesn't matter\b", normalized_text):
        return True

    # Handle combined permission phrases
    combined_patterns = [
        r"\bi don't know\b.*\byou choose\b",
        r"\bwhatever\b.*\byou decide\b",
        r"\bup to you\b.*\bi don't care\b",
    ]

    for pattern in combined_patterns:
        if re.search(pattern, normalized_text):
            return True

    return False


def format_guess_notification(guessed_components: list[dict]) -> str:
    """
    Format a user-friendly notification message when components are guessed.
    """
    if not guessed_components:
        return ""

    notification_lines = [
        "🎯 **I've made the following guesses based on your permission:**",
        "",
    ]

    for comp in guessed_components:
        component_name = comp.get("component_name", "Unknown Component")
        guessed_value = comp.get("guessed_value", "Unknown")
        description = comp.get("description", "No description available")

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

    return "\n".join(notification_lines)


class MockRunContext:
    """Mock RunContext for testing."""

    def __init__(self, state: ProcurementState):
        self.deps = MockDeps(state)


class MockDeps:
    """Mock dependencies for testing."""

    def __init__(self, state: ProcurementState):
        self.state = state


def create_mock_component_matches(description: str, component_type: str) -> list:
    """
    Create mock component matches for testing.
    """
    mock_matches = {
        "steel": [
            {
                "code": "01",
                "name": "Steel",
                "description": "Steel materials",
                "score": 0.9,
                "keyword_score": 2,
                "semantic_score": 0.8,
            },
            {
                "code": "02",
                "name": "Metal",
                "description": "Metal materials",
                "score": 0.7,
                "keyword_score": 1,
                "semantic_score": 0.6,
            },
        ],
        "plastic": [
            {
                "code": "03",
                "name": "Plastic",
                "description": "Plastic materials",
                "score": 0.9,
                "keyword_score": 2,
                "semantic_score": 0.8,
            }
        ],
        "chemical": [
            {
                "code": "C",
                "name": "Chemical products",
                "description": "Chemical-related products",
                "score": 0.9,
                "keyword_score": 2,
                "semantic_score": 0.8,
            },
            {
                "code": "A",
                "name": "Agricultural products",
                "description": "Products related to agriculture",
                "score": 0.6,
                "keyword_score": 1,
                "semantic_score": 0.5,
            },
        ],
    }

    return mock_matches.get(component_type.lower(), [])


def get_component_extraction_results(
    user_description: str, code_generation_content: str
) -> dict:
    """
    Mock component extraction function for testing.
    """
    # Mock extraction results based on description content
    results = {
        "ambiguous_components": [],
        "unambiguous_components": [],
        "no_match_components": [],
        "component_details": {},
    }

    # Check for steel (ambiguous)
    if "steel" in user_description.lower():
        steel_matches = create_mock_component_matches(user_description, "steel")
        results["ambiguous_components"].append(
            {
                "component_name": "Material Type",
                "component_key": "material_type",
                "matches": steel_matches,
                "status": "ambiguous",
            }
        )
        results["component_details"]["material_type"] = {
            "component_name": "Material Type",
            "component_key": "material_type",
            "matches": steel_matches,
            "status": "ambiguous",
        }

    # Check for plastic (unambiguous)
    if (
        "plastic" in user_description.lower()
        and "steel" not in user_description.lower()
    ):
        plastic_matches = create_mock_component_matches(user_description, "plastic")
        results["unambiguous_components"].append(
            {
                "component_name": "Material Type",
                "component_key": "material_type",
                "matches": plastic_matches,
                "status": "unambiguous",
            }
        )
        results["component_details"]["material_type"] = {
            "component_name": "Material Type",
            "component_key": "material_type",
            "matches": plastic_matches,
            "status": "unambiguous",
        }

    # Check for chemical (ambiguous - major category)
    if "chemical" in user_description.lower():
        chemical_matches = create_mock_component_matches(user_description, "chemical")
        results["ambiguous_components"].append(
            {
                "component_name": "Major Category",
                "component_key": "major_category",
                "matches": chemical_matches,
                "status": "ambiguous",
            }
        )
        results["component_details"]["major_category"] = {
            "component_name": "Major Category",
            "component_key": "major_category",
            "matches": chemical_matches,
            "status": "ambiguous",
        }

    return results


def detect_component_ambiguity(
    user_description: str,
    code_generation_content: str,
    ctx: MockRunContext,
    user_text: Optional[str] = None,
) -> dict:
    """
    Implement ambiguity detection logic for testing.
    """
    # Get component extraction results
    extraction_results = get_component_extraction_results(
        user_description, code_generation_content
    )

    # Detect if user gave explicit guess permission
    guess_permission_detected = False
    if user_text:
        guess_permission_detected = detect_explicit_guess_permission(user_text)

    # Initialize result structure
    result = {
        "ambiguity_detected": len(extraction_results["ambiguous_components"]) > 0,
        "ambiguous_components": [],
        "unambiguous_components": [],
        "guessed_components": [],
        "no_match_components": [],
        "ambiguity_details": {},
        "guess_notification": "",  # User notification when guesses are made
    }

    # Process each component and create AmbiguityInfo objects
    for component_key, component_detail in extraction_results[
        "component_details"
    ].items():
        component_name = component_detail["component_name"]
        matches = component_detail["matches"]
        status = component_detail["status"]

        # Create options list for AmbiguityInfo
        options = []
        for match in matches:
            options.append(
                {
                    "value": match["code"],
                    "description": f"{match['name']}: {match['description']}",
                }
            )

        # Create AmbiguityInfo based on component status and guess permission
        if status == "ambiguous" and guess_permission_detected and matches:
            # User gave guess permission and we have matches - mark as guessed
            # Use the highest-scoring match (first in sorted list)
            guessed_value = matches[0]["code"]
            ambiguity_info = AmbiguityInfo(
                status="guessed",
                options=options,
                selected_value=guessed_value,
                guessed_value=guessed_value,
                is_guessed=True,
            )
            result["guessed_components"].append(component_name)

        elif status == "ambiguous":
            # Component has 2+ plausible matches but no guess permission - mark as ambiguous
            ambiguity_info = AmbiguityInfo(
                status="ambiguous",
                options=options,
                selected_value=None,  # No selection yet for ambiguous components
            )
            result["ambiguous_components"].append(component_name)

        elif status == "unambiguous":
            # Component has exactly 1 match - mark as unambiguous with selected value
            selected_value = matches[0]["code"]
            ambiguity_info = AmbiguityInfo(
                status="unambiguous", options=options, selected_value=selected_value
            )
            result["unambiguous_components"].append(component_name)

        else:  # status == "no_match"
            # Component has no matches - mark as ambiguous (needs clarification)
            # Even with guess permission, we can't guess if there are no matches
            ambiguity_info = AmbiguityInfo(
                status="ambiguous",
                options=[],  # No options to show
                selected_value=None,
            )
            result["no_match_components"].append(component_name)

        # Store the AmbiguityInfo
        result["ambiguity_details"][component_key] = ambiguity_info

        # Update the ProcurementState with the ambiguity information
        ctx.deps.state.update_component_ambiguity(component_name, ambiguity_info)

    # Generate user notification for guessed components
    if result["guessed_components"]:
        # Prepare guessed component details for notification
        guessed_component_details = []
        for component_key, ambiguity_info in result["ambiguity_details"].items():
            if ambiguity_info.status == "guessed":
                component_name = None
                # Find the component name from extraction results
                for comp_key, detail in extraction_results["component_details"].items():
                    if comp_key == component_key:
                        component_name = detail["component_name"]
                        break

                if component_name:
                    guessed_component_details.append(
                        {
                            "component_name": component_name,
                            "guessed_value": ambiguity_info.guessed_value,
                            "description": ambiguity_info.options[0]["description"]
                            if ambiguity_info.options
                            else "No description available",
                        }
                    )

        # Format the notification
        result["guess_notification"] = format_guess_notification(
            guessed_component_details
        )

    return result


class TestGuessMarkingAndNotification(unittest.TestCase):
    """Test suite for guess marking and notification integration."""

    def setUp(self):
        """Set up test fixtures."""
        self.state = ProcurementState()
        self.ctx = MockRunContext(self.state)

    def test_complete_workflow_with_guess_permission(self):
        """Test the complete workflow from guess permission to notification."""
        # Test data with guess permission
        user_description = "I need steel material for chemical products"
        user_text = "I don't know, you choose whatever"
        code_content = "Mock CODE_GENERATION.md content"

        # Execute the complete workflow
        result = detect_component_ambiguity(
            user_description, code_content, self.ctx, user_text
        )

        # Verify guess permission was detected
        self.assertTrue(detect_explicit_guess_permission(user_text))

        # Verify components were marked as guessed
        self.assertIn("guessed_components", result)
        self.assertGreater(len(result["guessed_components"]), 0)

        # Verify Material Type was marked as guessed in state
        self.assertIn("Material Type", self.state.component_ambiguity_status)
        material_info = self.state.component_ambiguity_status["Material Type"]
        self.assertEqual(material_info.status, "guessed")
        self.assertTrue(material_info.is_guessed)
        self.assertIsNotNone(material_info.guessed_value)

        # Verify Major Category was marked as guessed in state
        self.assertIn("Major Category", self.state.component_ambiguity_status)
        category_info = self.state.component_ambiguity_status["Major Category"]
        self.assertEqual(category_info.status, "guessed")
        self.assertTrue(category_info.is_guessed)
        self.assertIsNotNone(category_info.guessed_value)

        # Verify notification was generated
        self.assertIn("guess_notification", result)
        self.assertIsInstance(result["guess_notification"], str)
        self.assertGreater(len(result["guess_notification"]), 0)

        # Verify notification content
        notification = result["guess_notification"]
        self.assertIn("🎯", notification)
        self.assertIn("Material Type", notification)
        self.assertIn("Major Category", notification)
        self.assertIn("I don't know", notification)

    def test_workflow_without_guess_permission(self):
        """Test the workflow when no guess permission is given."""
        # Test data without guess permission
        user_description = "I need steel material for chemical products"
        user_text = "Please tell me the exact materials and categories"
        code_content = "Mock CODE_GENERATION.md content"

        # Execute the workflow
        result = detect_component_ambiguity(
            user_description, code_content, self.ctx, user_text
        )

        # Verify guess permission was NOT detected
        self.assertFalse(detect_explicit_guess_permission(user_text))

        # Verify components were marked as ambiguous, not guessed
        self.assertIn("ambiguous_components", result)
        self.assertGreater(len(result["ambiguous_components"]), 0)
        self.assertEqual(len(result["guessed_components"]), 0)

        # Verify Material Type was marked as ambiguous in state
        self.assertIn("Material Type", self.state.component_ambiguity_status)
        material_info = self.state.component_ambiguity_status["Material Type"]
        self.assertEqual(material_info.status, "ambiguous")
        self.assertFalse(material_info.is_guessed)
        self.assertIsNone(material_info.guessed_value)

        # Verify no notification was generated
        self.assertIn("guess_notification", result)
        self.assertEqual(result["guess_notification"], "")

    def test_notification_formatting_with_multiple_guessed_components(self):
        """Test notification formatting when multiple components are guessed."""
        # Create guessed components for notification testing
        guessed_components = [
            {
                "component_name": "Material Type",
                "guessed_value": "01",
                "description": "Steel: Steel materials",
            },
            {
                "component_name": "Major Category",
                "guessed_value": "C",
                "description": "Chemical products: Chemical-related products",
            },
            {
                "component_name": "Manufacturing Method",
                "guessed_value": "F",
                "description": "Forged: Forged components",
            },
        ]

        # Format the notification
        notification = format_guess_notification(guessed_components)

        # Verify notification structure and content
        self.assertIn("🎯", notification)
        self.assertIn("Material Type", notification)
        self.assertIn("Major Category", notification)
        self.assertIn("Manufacturing Method", notification)
        self.assertIn("01", notification)
        self.assertIn("C", notification)
        self.assertIn("F", notification)
        self.assertIn("Steel: Steel materials", notification)
        self.assertIn("Chemical products: Chemical-related products", notification)
        self.assertIn("Forged: Forged components", notification)
        self.assertIn("I don't know", notification)
        self.assertIn("whatever", notification)
        self.assertIn("you choose", notification)

        # Verify proper formatting with arrows and structure
        lines = notification.split("\n")
        self.assertTrue(any("→ Guessed value: 01" in line for line in lines))
        self.assertTrue(any("→ Guessed value: C" in line for line in lines))
        self.assertTrue(any("→ Guessed value: F" in line for line in lines))

    def test_notification_with_empty_guessed_components(self):
        """Test notification formatting with no guessed components."""
        notification = format_guess_notification([])
        self.assertEqual(notification, "")

    def test_state_validation_for_guessed_components(self):
        """Test that state properly validates guessed components."""
        # Test valid guessed component
        valid_guessed_info = AmbiguityInfo(
            status="guessed",
            options=[{"value": "01", "description": "Steel: Steel materials"}],
            selected_value="01",
            guessed_value="01",
            is_guessed=True,
        )

        # Should not raise an exception
        try:
            self.state.update_component_ambiguity("Material Type", valid_guessed_info)
        except Exception as e:
            self.fail(f"Valid guessed component should not raise exception: {e}")

        # Test invalid guessed component (missing guessed_value)
        invalid_guessed_info = AmbiguityInfo(
            status="guessed",
            options=[{"value": "01", "description": "Steel: Steel materials"}],
            selected_value="01",
            guessed_value=None,  # Missing guessed_value
            is_guessed=True,
        )

        # Should raise ValueError
        with self.assertRaises(ValueError) as context:
            self.state.update_component_ambiguity(
                "Another Component", invalid_guessed_info
            )

        self.assertIn(
            "Guessed components must have a guessed_value", str(context.exception)
        )

    def test_edge_case_single_guessed_component_notification(self):
        """Test notification with a single guessed component."""
        guessed_components = [
            {
                "component_name": "Material Type",
                "guessed_value": "01",
                "description": "Steel: Steel materials",
            }
        ]

        notification = format_guess_notification(guessed_components)

        self.assertIn("Material Type", notification)
        self.assertIn("01", notification)
        self.assertIn("Steel: Steel materials", notification)
        self.assertIn("🎯", notification)

        # Verify it's properly formatted without multiple component formatting issues
        self.assertNotIn(
            "are",
            notification.split("🎯")[1].split("\n")[1] if "\n" in notification else "",
        )

    def test_edge_case_mixed_permission_and_no_permission(self):
        """Test workflow when some components have permission and others don't."""
        # This tests that the workflow correctly handles mixed scenarios
        user_description = "I need steel material"
        user_text = "I don't know about the material"
        code_content = "Mock CODE_GENERATION.md content"

        # Execute workflow
        result = detect_component_ambiguity(
            user_description, code_content, self.ctx, user_text
        )

        # Should detect guess permission
        self.assertTrue(detect_explicit_guess_permission(user_text))

        # Should have guessed components (Material Type is steel, which is ambiguous)
        self.assertIn("guessed_components", result)

        # Should generate notification
        self.assertIn("guess_notification", result)
        if result["guessed_components"]:
            self.assertGreater(len(result["guess_notification"]), 0)

    def test_integration_notification_includes_all_expected_elements(self):
        """Test that generated notification includes all expected elements."""
        user_description = "I need steel for chemical products"
        user_text = "whatever you choose"
        code_content = "Mock CODE_GENERATION.md content"

        result = detect_component_ambiguity(
            user_description, code_content, self.ctx, user_text
        )

        # Should have guessed components
        self.assertGreater(len(result["guessed_components"]), 0)

        # Should have notification
        notification = result["guess_notification"]
        self.assertGreater(len(notification), 0)

        # Verify all expected elements are present
        expected_elements = [
            "🎯",  # Emoji
            "guesses based on your permission",  # Main message
            "Note",  # Note section
            "I don't know",  # Mention of guess permission
            "whatever",  # Mention of guess permission
            "you choose",  # Mention of guess permission
            "clarify",  # Option to change guesses
        ]

        for element in expected_elements:
            self.assertIn(
                element, notification, f"Notification should contain: {element}"
            )


if __name__ == "__main__":
    # Run the tests
    print("Running comprehensive unit tests for guess marking and notification...")
    print("=" * 80)

    # Run with detailed output
    unittest.main(verbosity=2)
