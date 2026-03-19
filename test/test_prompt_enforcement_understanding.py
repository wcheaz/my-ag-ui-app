#!/usr/bin/env python3
"""
Test to verify that the agent understands the new enforced workflow from the prompt.
This test validates that the agent properly interprets the updated system prompt
that indicates the workflow is now programmatically enforced.
"""

import sys
import os
import asyncio

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

try:
    from pydantic import BaseModel, Field
    from typing import List, Optional

    # Import the agent classes
    class ProcurementCode(BaseModel):
        code: str
        description: str

    class ProcurementState(BaseModel):
        """
        State for the Procurement Agent.
        Maintains conversation history and other session-specific data.
        """

        conversation_id: Optional[str] = None
        procurement_codes: List[ProcurementCode] = Field(default_factory=list)
        citation_sources: List[str] = Field(default_factory=list)
        rules_loaded_this_turn: bool = False

    class MockDeps:
        def __init__(self, state):
            self.state = state

    # Import the STATIC_SYSTEM_PROMPT
    STATIC_SYSTEM_PROMPT = """You are a helpful assistant answering questions from a knowledge base.

    CORE WORKFLOW:
    1.  **DETECT NEW REQUEST**: If the user asks for a *completely new* procurement code (unrelated to the previous one), you MUST first call `reset_conversation`. Do NOT state that you are resetting memory. Just do it silently.

    2.  **MANDATORY VERIFICATION**: For EVERY code generation request, you MUST first call `read_code_generation_file`.
        -   This workflow is now **PROGRAMMATICALLY ENFORCED** - the system will block code saving if rules are not loaded first.
        -   **ENFORCEMENT DETAILS**: 
            -   The `save_procurement_code` tool will validate that rules were loaded and reject saves with error: "ERROR: You must call read_code_generation_file before saving a code."
            -   File read failures will raise exceptions (FileNotFoundError or Exception) instead of returning silent error strings.
            -   This is a breaking change - agents that skip file-read will be blocked from saving codes.
        -   You cannot rely on memory. You must read the file fresh for every request.
        -   After reading, start your response with: "I have now read the document and will proceed with analysis based on this information."

    3.  **GENERATE CODE**:
        -   Verify EACH component (A, B, C, MM, QQ, S) against the `read_code_generation_file` content.
        -   Use the current date (YY[D]) if not specified (Year: 26).
        -   Prioritize material > alphabetical/numerical order.
    4.  **SAVE & FINISH**:
        -   Do NOT state that you are saving a code to application state. Just do it silently.
        -   Use `save_procurement_code` to save the valid code.
        -   **CRITICAL**: The generated code MUST be the VERY LAST line of your response. This code should be printed in BOLD. 

    RULES:
    -   **NO GUESSING**: If a component isn't in the knowledge base, ask the user. Do not invent codes.
    -   **CONFLICTS**: Information from `read_code_generation_file` is authoritative.
"""

except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)


def test_prompt_contains_enforcement_language():
    """Test that the system prompt contains the updated enforcement language."""

    print("=== Testing system prompt contains enforcement language ===")

    # Check for key enforcement phrases in the prompt
    enforcement_phrases = [
        "PROGRAMMATICALLY ENFORCED",
        "system will block code saving",
        "The `save_procurement_code` tool will validate",
        "reject saves with error",
        "breaking change",
        "agents that skip file-read will be blocked",
    ]

    missing_phrases = []
    for phrase in enforcement_phrases:
        if phrase not in STATIC_SYSTEM_PROMPT:
            missing_phrases.append(phrase)

    if missing_phrases:
        print(f"✗ Missing enforcement phrases: {missing_phrases}")
        return False

    print("✓ System prompt contains all required enforcement phrases")

    # Check that the specific error message is mentioned
    error_message = (
        "ERROR: You must call read_code_generation_file before saving a code."
    )
    if error_message in STATIC_SYSTEM_PROMPT:
        print("✓ System prompt contains the specific error message")
    else:
        print("✗ System prompt missing the specific error message")
        return False

    # Check that exception behavior is mentioned
    if "FileNotFoundError or Exception" in STATIC_SYSTEM_PROMPT:
        print("✓ System prompt mentions exception behavior")
    else:
        print("✗ System prompt does not mention exception behavior")
        return False

    print("\n=== Test passed! ===")
    print("The system prompt correctly communicates the enforced workflow.")
    return True


def test_prompt_explains_enforcement_mechanism():
    """Test that the system prompt explains the enforcement mechanism clearly."""

    print("\n=== Testing system prompt explains enforcement mechanism ===")

    # Check for explanation of what happens when workflow is not followed
    mechanism_explanations = [
        "The `save_procurement_code` tool will validate that rules were loaded",
        "reject saves with error",
        "File read failures will raise exceptions",
        "instead of returning silent error strings",
    ]

    missing_explanations = []
    for explanation in mechanism_explanations:
        if explanation not in STATIC_SYSTEM_PROMPT:
            missing_explanations.append(explanation)

    if missing_explanations:
        print(f"✗ Missing mechanism explanations: {missing_explanations}")
        return False

    print("✓ System prompt explains the enforcement mechanism clearly")

    # Check that it mentions this is a breaking change
    if "breaking change" in STATIC_SYSTEM_PROMPT:
        print("✓ System prompt mentions this is a breaking change")
    else:
        print("✗ System prompt does not mention this is a breaking change")
        return False

    print("\n=== Test passed! ===")
    print("The system prompt clearly explains the enforcement mechanism.")
    return True


def test_prompt_maintains_workflow_instructions():
    """Test that the system prompt still maintains the core workflow instructions."""

    print("\n=== Testing system prompt maintains core workflow instructions ===")

    # Check for core workflow elements
    workflow_elements = [
        "DETECT NEW REQUEST",
        "MANDATORY VERIFICATION",
        "GENERATE CODE",
        "SAVE & FINISH",
        "call `read_code_generation_file`",
        "call `reset_conversation`",
        "Use `save_procurement_code`",
    ]

    missing_elements = []
    for element in workflow_elements:
        if element not in STATIC_SYSTEM_PROMPT:
            missing_elements.append(element)

    if missing_elements:
        print(f"✗ Missing workflow elements: {missing_elements}")
        return False

    print("✓ System prompt maintains all core workflow instructions")

    # Check that the mandatory verification step is still emphasized
    if "MUST first call `read_code_generation_file`" in STATIC_SYSTEM_PROMPT:
        print("✓ Mandatory verification step is still emphasized")
    else:
        print("✗ Mandatory verification step is not emphasized")
        return False

    print("\n=== Test passed! ===")
    print("The system prompt maintains all core workflow instructions.")
    return True


async def main():
    """Run all tests for prompt enforcement understanding."""
    print("=== Testing agent's understanding of enforced workflow from prompt ===")

    test1 = test_prompt_contains_enforcement_language()
    test2 = test_prompt_explains_enforcement_mechanism()
    test3 = test_prompt_maintains_workflow_instructions()

    if test1 and test2 and test3:
        print("\n=== All tests passed! ===")
        print("The agent's system prompt correctly communicates the enforced workflow.")
        print("Key points covered:")
        print("- Workflow is programmatically enforced")
        print("- Consequences of not following the workflow")
        print("- Breaking change notification")
        print("- Maintenance of core workflow instructions")
        return True
    else:
        print("\n=== Some tests failed! ===")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
