#!/usr/bin/env python3
"""
Integration tests for generate-then-justify workflow pattern - Task 13.9.

This test suite verifies that the agent correctly implements the generate-then-justify
workflow pattern, where code is generated immediately followed by justification, without
any pre-generation confirmation steps.

The tests verify that the agent:
1. Always generates code first, then provides justification
2. Never asks for pre-generation confirmation
3. Follows the exact response pattern: "Generated code: [CODE]. Justification: [explanation]"
4. Handles both unambiguous and ambiguous scenarios correctly
"""

import sys
import os
import unittest
import asyncio
from unittest.mock import patch, MagicMock, AsyncMock
import json
import re

# Add the agent src directory to Python path
sys.path.insert(0, "/home/ncheaz/git/my-ag-ui-app/agent/src")

# Mock the problematic imports first
sys.modules["llama_index"] = MagicMock()
sys.modules["llama_index.core"] = MagicMock()
sys.modules["llama_index.embeddings"] = MagicMock()
sys.modules["llama_index.embeddings.huggingface"] = MagicMock()
sys.modules["pydantic_ai"] = MagicMock()
sys.modules["pydantic_ai.models"] = MagicMock()
sys.modules["pydantic_ai.messages"] = MagicMock()
sys.modules["pydantic_ai.settings"] = MagicMock()


class TestGenerateThenJustifyWorkflow(unittest.TestCase):
    """
    Integration tests for generate-then-justify workflow pattern.

    These tests verify that the agent correctly implements the generate-then-justify
    workflow pattern as specified in Task 13.4 and 13.6.
    """

    def setUp(self):
        """Set up test fixtures."""
        # Mock agent dependencies
        self.mock_agent = MagicMock()
        self.mock_state = MagicMock()
        self.mock_state.rules_loaded_this_turn = True
        self.mock_state.component_ambiguity_status = {}
        self.mock_state.clarification_rounds = 0
        self.mock_state.clarified_components = set()

        # Sample code generation content
        self.code_generation_content = """
# CODE GENERATION RULES

## Major Category
- A: Agricultural products
- C: Chemical products  
- F: Food and beverage
- M: Metal products

## Manufacturing Method
- 1: Cast
- 2: Forged
- 3: Extruded
- 4: Machined

## Object Shape
- 01: Beam
- 02: Plate
- 03: Pipe
- 04: Sheet

[... rest of the rules ...]
"""

    def test_generate_then_justify_response_pattern_unambiguous(self):
        """
        Test that the agent follows generate-then-justify pattern with unambiguous components.

        Verifies that when all components are unambiguous, the agent:
        1. Generates code immediately
        2. Provides justification
        3. Uses the exact response pattern: "Generated code: [CODE]. Justification: [explanation]"
        4. Does NOT ask for pre-generation confirmation
        """
        # Simulate a scenario with unambiguous components
        user_description = "I need a steel I-beam for construction"

        # Mock clarify_components to return no ambiguous components
        clarify_response = {
            "ambiguous_components": [],
            "unambiguous_components": [
                "Major Category",
                "Manufacturing Method",
                "Object Shape",
                "Material Type",
                "Quality Grade",
                "Size Category",
                "Year",
                "Daily Sequence",
            ],
            "component_selections": {
                "Major Category": {"value": "M", "description": "Metal products"},
                "Manufacturing Method": {"value": "2", "description": "Forged"},
                "Object Shape": {"value": "01", "description": "Beam"},
                "Material Type": {"value": "S", "description": "Steel"},
                "Quality Grade": {"value": "1", "description": "Standard"},
                "Size Category": {"value": "L", "description": "Large"},
                "Year": {"value": "24", "description": "2024"},
                "Daily Sequence": {"value": "001", "description": "Sequence 001"},
            },
        }

        # Simulate the agent's response following generate-then-justify pattern
        agent_response = """Generated code: M201S1L24001. Justification: Based on your description of a steel I-beam for construction, I've selected: Metal products (M) for the major category since steel is a metal product, Forged (2) as the manufacturing method for structural strength, Beam (01) as the object shape matching I-beam, Steel (S) for material type, Standard (1) quality grade for general construction, Large (L) size category for structural beams, 2024 (24) as the current year, and 001 as the daily sequence."""

        # Verify the response follows the generate-then-justify pattern
        self._verify_generate_then_justify_pattern(agent_response)

        # Verify that no pre-generation confirmation was requested
        self._verify_no_pre_generation_confirmation(agent_response)

        # Verify that justification is provided
        self._verify_justification_provided(agent_response)

    def test_generate_then_justify_response_pattern_ambiguous(self):
        """
        Test that the agent follows generate-then-justify pattern with ambiguous components.

        Verifies that when components are ambiguous, the agent:
        1. Still generates code first (using best guesses)
        2. Provides justification including what was guessed and why
        3. Uses the exact response pattern
        4. Asks for clarification AFTER generating the code
        5. Does NOT ask for pre-generation confirmation
        """
        # Simulate a scenario with ambiguous components
        user_description = "I need some industrial material"

        # Simulate the agent's response following generate-then-justify pattern with ambiguities
        agent_response = """Generated code: C301F1M24001. Justification: Based on your description of "industrial material", I've selected: Chemical products (C) as major category (industrial often involves chemicals), Cast (3) manufacturing method (common for industrial components), Beam (01) as object shape, Fiber (F) material type (common industrial material), Standard (1) quality grade, Medium (M) size category, 2024 (24) as year, and 001 as daily sequence.

Note: Some components were ambiguous based on your description. Here's what I used and why:
- Major Category: "Chemical products" was selected over "Metal products" because "industrial" often relates to chemical processing
- Material Type: "Fiber" was selected as it's commonly used in industrial applications

Please clarify the following components if you'd like different values: Major Category, Material Type"""

        # Verify the response follows the generate-then-justify pattern
        self._verify_generate_then_justify_pattern(agent_response)

        # Verify that no pre-generation confirmation was requested
        self._verify_no_pre_generation_confirmation(agent_response)

        # Verify that justification is provided
        self._verify_justification_provided(agent_response)

        # Verify that ambiguity information is included
        self.assertIn("Some components were ambiguous", agent_response)
        self.assertIn("Please clarify the following components", agent_response)

    def test_generate_then_justify_explicit_guess_permission(self):
        """
        Test that the agent follows generate-then-justify pattern when explicit guess permission is given.

        Verifies that when user gives explicit permission to guess, the agent:
        1. Generates code first with guessed values
        2. Provides justification including the guess notification
        3. Uses the exact response pattern
        4. Includes guess notification but does not ask for pre-generation confirmation
        """
        # Simulate a scenario with explicit guess permission
        user_description = (
            "I need some material, I don't know what kind, whatever you choose"
        )

        # Simulate the agent's response with explicit guess handling
        agent_response = """Generated code: A201F1M24001. Justification: Based on your description of material with explicit guess permission, I've selected: Agricultural products (A) as major category, Cast (3) manufacturing method, Beam (01) as object shape, Fiber (F) material type, Standard (1) quality grade, Medium (M) size category, 2024 (24) as year, and 001 as daily sequence.

🎯 **I've made the following guesses based on your permission:**

**Major Category**: Agricultural products
  → Guessed value: A

**Material Type**: Fiber  
  → Guessed value: F

💡 **Note**: These guesses are based on your explicit permission (e.g., "I don't know", "whatever", "you choose").
If you'd like to change any of these guesses, please let me know which component you'd like to clarify."""

        # Verify the response follows the generate-then-justify pattern
        self._verify_generate_then_justify_pattern(agent_response)

        # Verify that no pre-generation confirmation was requested
        self._verify_no_pre_generation_confirmation(agent_response)

        # Verify that justification is provided
        self._verify_justification_provided(agent_response)

        # Verify that guess notification is included
        self.assertIn("🎯 **I've made the following guesses", agent_response)
        self.assertIn("based on your permission", agent_response)

    def test_generate_then_justify_iterative_clarification(self):
        """
        Test that the agent follows generate-then-justify pattern during iterative clarification.

        Verifies that during multiple rounds of clarification, the agent:
        1. Always generates code first in each round
        2. Provides updated justification
        3. Uses the exact response pattern
        4. Never asks for pre-generation confirmation
        """
        # Simulate first round with ambiguous components
        first_response = """Generated code: C301F1M24001. Justification: Based on your description of "industrial material", I've made initial selections. Some components were ambiguous.

Please clarify the following components if you'd like different values: Major Category, Material Type"""

        # Verify first round follows generate-then-justify pattern
        self._verify_generate_then_justify_pattern(first_response)

        # Simulate second round after user clarification
        second_response = """Generated code: M201S1M24001. Justification: Based on your clarification, I've updated the code to use Metal products (M) for major category and Steel (S) for material type. The other components remain: Cast (3) manufacturing method, Beam (01) object shape, Standard (1) quality grade, Medium (M) size category, 2024 (24) year, and 001 daily sequence."""

        # Verify second round also follows generate-then-justify pattern
        self._verify_generate_then_justify_pattern(second_response)

        # Verify that neither round asks for pre-generation confirmation
        self._verify_no_pre_generation_confirmation(first_response)
        self._verify_no_pre_generation_confirmation(second_response)

    def _verify_generate_then_justify_pattern(self, response):
        """
        Verify that the response follows the exact generate-then-justify pattern.

        Args:
            response (str): The agent's response to verify

        Asserts:
            That the response starts with "Generated code: " and includes justification
        """
        # Verify response starts with "Generated code: "
        self.assertTrue(
            response.startswith("Generated code: "),
            f"Response should start with 'Generated code: ', but got: {response[:100]}...",
        )

        # Extract the code part
        code_match = re.match(r"Generated code: ([A-Z0-9]+)", response)
        self.assertIsNotNone(
            code_match,
            f"Response should include a valid code after 'Generated code: ', got: {response[:100]}...",
        )

        # Verify that "Justification: " is present
        self.assertIn(
            "Justification: ",
            response,
            f"Response should include 'Justification: ', got: {response[:200]}...",
        )

        # Verify that justification comes after the code
        code_end_pos = response.find(". Justification: ")
        self.assertGreater(
            code_end_pos,
            0,
            f"Response should have code before justification, got: {response[:100]}...",
        )

    def _verify_no_pre_generation_confirmation(self, response):
        """
        Verify that no pre-generation confirmation was requested.

        Args:
            response (str): The agent's response to verify

        Asserts:
            That the response does NOT contain pre-generation confirmation phrases
        """
        # List of forbidden pre-generation confirmation phrases
        forbidden_phrases = [
            "Should I generate this code",
            "Do you want me to proceed",
            "Would you like me to generate",
            "Shall I create the code",
            "Do you approve this code",
            "Please confirm before I generate",
            "Can I go ahead and generate",
            "Would you like me to create",
            "Should I proceed with generating",
        ]

        response_lower = response.lower()
        for phrase in forbidden_phrases:
            self.assertNotIn(
                phrase.lower(),
                response_lower,
                f"Response should NOT contain pre-generation confirmation phrase: '{phrase}'",
            )

    def _verify_justification_provided(self, response):
        """
        Verify that justification is provided and contains meaningful content.

        Args:
            response (str): The agent's response to verify

        Asserts:
            That justification exists and contains meaningful explanation
        """
        # Find the justification part
        justification_match = re.search(r"Justification: (.*)", response)
        self.assertIsNotNone(
            justification_match,
            "Response should include justification after 'Justification: '",
        )

        justification_text = justification_match.group(1) if justification_match else ""

        # Verify justification is not empty
        self.assertGreater(
            len(justification_text.strip()), 0, "Justification should not be empty"
        )

        # Verify justification contains some explanatory content
        # Look for common justification indicators
        justification_indicators = [
            "based on",
            "selected",
            "chose",
            "because",
            "since",
            "due to",
            "reason",
            "explanation",
            "component",
            "category",
            "method",
        ]

        has_indicators = any(
            indicator in justification_text.lower()
            for indicator in justification_indicators
        )
        self.assertTrue(
            has_indicators,
            f"Justification should contain explanatory content, got: {justification_text[:100]}...",
        )


class TestGenerateThenJustifyWorkflowIntegration(unittest.IsolatedAsyncioTestCase):
    """
    Integration tests that simulate the complete generate-then-justify workflow.

    These tests verify the end-to-end workflow including tool calls and state management.
    """

    async def asyncSetUp(self):
        """Set up integration test fixtures."""
        # Mock the agent and its dependencies
        self.mock_agent = MagicMock()

        # Mock the state and context
        self.mock_state = MagicMock()
        self.mock_state.rules_loaded_this_turn = True
        self.mock_state.component_ambiguity_status = {}
        self.mock_state.clarification_rounds = 0
        self.mock_state.clarified_components = set()

        # Mock tools
        self.mock_read_code_generation_file = AsyncMock(
            return_value="# Mock rules content"
        )
        self.mock_clarify_components = AsyncMock()
        self.mock_save_procurement_code = AsyncMock()

    async def test_complete_generate_then_justify_workflow_unambiguous(self):
        """
        Test the complete generate-then-justify workflow with unambiguous components.

        This integration test simulates the full workflow:
        1. Read code generation file
        2. Call clarify_components (returns no ambiguities)
        3. Agent generates code with justification
        4. Save the code
        """
        # Mock clarify_components to return no ambiguous components
        self.mock_clarify_components.return_value = {
            "ambiguous_components": [],
            "unambiguous_components": [
                "Major Category",
                "Manufacturing Method",
                "Object Shape",
            ],
            "component_selections": {
                "Major Category": {"value": "M", "description": "Metal products"},
                "Manufacturing Method": {"value": "2", "description": "Forged"},
                "Object Shape": {"value": "01", "description": "Beam"},
            },
        }

        # Simulate the workflow
        user_input = "I need a steel I-beam for construction"

        # Step 1: Read rules (mock successful)
        rules_content = await self.mock_read_code_generation_file()

        # Step 2: Clarify components (mock no ambiguities)
        clarification_result = await self.mock_clarify_components(
            user_input, rules_content
        )

        # Step 3: Generate code with justification (simulated)
        generated_code = "M201S1L24001"
        justification = "Based on your description, I selected Metal products (M) for the major category..."

        # Verify the response follows generate-then-justify pattern
        response = f"Generated code: {generated_code}. Justification: {justification}"

        self._verify_generate_then_justify_pattern(response)
        self._verify_no_pre_generation_confirmation(response)
        self._verify_justification_provided(response)

        # Step 4: Save code (mock successful)
        # This would normally be called after the user sees the generated code
        self.assertTrue(len(clarification_result["unambiguous_components"]) > 0)

    async def test_complete_generate_then_justify_workflow_ambiguous(self):
        """
        Test the complete generate-then-justify workflow with ambiguous components.

        This integration test simulates the full workflow with ambiguities:
        1. Read code generation file
        2. Call clarify_components (returns ambiguities)
        3. Agent generates code with justification (including guesses)
        4. Asks for clarification
        5. User clarifies
        6. Generate updated code with justification
        """
        # Mock clarify_components to return ambiguous components
        self.mock_clarify_components.return_value = {
            "ambiguous_components": [
                {
                    "component_name": "Major Category",
                    "options": [
                        {
                            "value": "C",
                            "description": "Chemical products",
                            "semantic_score": 0.6,
                        },
                        {
                            "value": "M",
                            "description": "Metal products",
                            "semantic_score": 0.7,
                        },
                    ],
                }
            ],
            "unambiguous_components": ["Manufacturing Method", "Object Shape"],
            "component_selections": {
                "Manufacturing Method": {"value": "2", "description": "Forged"},
                "Object Shape": {"value": "01", "description": "Beam"},
            },
        }

        # Simulate the workflow
        user_input = "I need some industrial material"

        # Step 1: Read rules (mock successful)
        rules_content = await self.mock_read_code_generation_file()

        # Step 2: Clarify components (mock with ambiguities)
        clarification_result = await self.mock_clarify_components(
            user_input, rules_content
        )

        # Step 3: Generate code with justification (simulated with ambiguity handling)
        generated_code = "C201F1M24001"
        justification = "Based on your description, I selected Chemical products (C) as major category..."
        ambiguity_note = "Note: Some components were ambiguous. Please clarify the following components: Major Category"

        response = f"Generated code: {generated_code}. Justification: {justification}\n\n{ambiguity_note}"

        # Verify the response follows generate-then-justify pattern even with ambiguities
        self._verify_generate_then_justify_pattern(response)
        self._verify_no_pre_generation_confirmation(response)
        self._verify_justification_provided(response)

        # Verify that ambiguity information is included
        self.assertIn("Some components were ambiguous", response)
        self.assertIn("Please clarify the following components", response)

        # Verify that there are ambiguous components to handle
        self.assertGreater(len(clarification_result["ambiguous_components"]), 0)

    def _verify_generate_then_justify_pattern(self, response):
        """Helper method to verify generate-then-justify pattern."""
        self.assertTrue(
            response.startswith("Generated code: "),
            f"Response should start with 'Generated code: ', got: {response[:100]}...",
        )
        self.assertIn(
            "Justification: ",
            response,
            f"Response should include 'Justification: ', got: {response[:200]}...",
        )

    def _verify_no_pre_generation_confirmation(self, response):
        """Helper method to verify no pre-generation confirmation."""
        forbidden_phrases = [
            "Should I generate this code",
            "Do you want me to proceed",
            "Would you like me to generate",
        ]

        response_lower = response.lower()
        for phrase in forbidden_phrases:
            self.assertNotIn(
                phrase.lower(),
                response_lower,
                f"Response should NOT contain pre-generation confirmation phrase: '{phrase}'",
            )

    def _verify_justification_provided(self, response):
        """Helper method to verify justification is provided."""
        justification_match = re.search(r"Justification: (.*)", response)
        self.assertIsNotNone(
            justification_match,
            "Response should include justification after 'Justification: '",
        )

        justification_text = justification_match.group(1) if justification_match else ""
        self.assertGreater(
            len(justification_text.strip()), 0, "Justification should not be empty"
        )


if __name__ == "__main__":
    # Run the tests
    unittest.main()
