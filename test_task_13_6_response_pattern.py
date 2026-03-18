#!/usr/bin/env python3
"""
Test script to verify that the agent response pattern follows the required format for task 13.6:
"Generated code: [CODE]. Justification: [explanation]" instead of asking for confirmation.
"""

import os
import sys


def test_task_13_6_response_pattern():
    """Test that the system prompt contains the required response pattern for task 13.6."""

    print("=== Testing Task 13.6 Response Pattern ===")

    # Read the agent.py file to extract the system prompt
    agent_file_path = os.path.join(
        os.path.dirname(__file__), "agent", "src", "agent.py"
    )

    try:
        with open(agent_file_path, "r", encoding="utf-8") as f:
            agent_content = f.read()
    except FileNotFoundError:
        print(f"✗ Could not find agent.py file at {agent_file_path}")
        return False
    except Exception as e:
        print(f"✗ Error reading agent.py file: {e}")
        return False

    # Extract the STATIC_SYSTEM_PROMPT
    try:
        # Find the start of the system prompt
        start_marker = 'STATIC_SYSTEM_PROMPT = """'
        start_idx = agent_content.find(start_marker)
        if start_idx == -1:
            print("✗ Could not find STATIC_SYSTEM_PROMPT definition")
            return False

        # Find the end of the system prompt
        end_marker = '"""'
        end_idx = agent_content.find(end_marker, start_idx + len(start_marker))
        if end_idx == -1:
            print("✗ Could not find end of STATIC_SYSTEM_PROMPT")
            return False

        # Extract the system prompt content
        prompt_start = start_idx + len(start_marker)
        prompt_content = agent_content[prompt_start:end_idx]

    except Exception as e:
        print(f"✗ Error extracting system prompt: {e}")
        return False

    # Test 1: Check for exact response pattern requirement
    print("\n--- Test 1: Checking for exact response pattern requirement ---")
    required_pattern = "Generated code: [CODE]. Justification: [explanation]"

    if required_pattern in prompt_content:
        print(f"✓ Found exact response pattern: {required_pattern}")
    else:
        print(f"✗ Missing exact response pattern: {required_pattern}")
        return False

    # Test 2: Check for task 13.6 specific requirement
    print("\n--- Test 2: Checking for task 13.6 specific requirement ---")
    task_13_6_requirement = "TASK 13.6 - RESPONSE PATTERN"

    if task_13_6_requirement in prompt_content:
        print(f"✓ Found task 13.6 requirement: {task_13_6_requirement}")
    else:
        print(f"✗ Missing task 13.6 requirement: {task_13_6_requirement}")
        return False

    # Test 3: Check for "instead of asking for confirmation" phrase
    print("\n--- Test 3: Checking for 'instead of asking for confirmation' phrase ---")
    confirmation_phrase = "instead of asking for confirmation"

    if confirmation_phrase in prompt_content:
        print(f"✓ Found confirmation phrase: {confirmation_phrase}")
    else:
        print(f"✗ Missing confirmation phrase: {confirmation_phrase}")
        return False

    # Test 4: Check for generate-then-justify workflow
    print("\n--- Test 4: Checking for generate-then-justify workflow ---")
    generate_then_justify_phrases = [
        "GENERATE-THEN-JUSTIFY WORKFLOW",
        "Generate the procurement code IMMEDIATELY",
        "NEVER wait for pre-generation confirmation",
        "ALWAYS generate first, then justify",
    ]

    all_found = True
    for phrase in generate_then_justify_phrases:
        if phrase in prompt_content:
            print(f"✓ Found generate-then-justity phrase: {phrase}")
        else:
            print(f"✗ Missing generate-then-justity phrase: {phrase}")
            all_found = False

    if not all_found:
        return False

    # Test 5: Check for forbidden confirmation patterns
    print("\n--- Test 5: Checking for forbidden confirmation patterns ---")
    forbidden_patterns = [
        "Should I generate this code?",
        "Do you want me to proceed?",
        "pre-generation confirmation",
    ]

    all_forbidden_found = True
    for pattern in forbidden_patterns:
        if pattern in prompt_content:
            print(f"✓ Found forbidden pattern (should be present): {pattern}")
        else:
            print(f"✗ Missing forbidden pattern (should be present): {pattern}")
            all_forbidden_found = False

    if not all_forbidden_found:
        return False

    # Test 6: Check for response format section
    print("\n--- Test 6: Checking for response format section ---")
    response_format_markers = [
        "RESPONSE FORMAT",
        "Generated code: [CODE]",
        "Justification: [explanation",
    ]

    all_format_found = True
    for marker in response_format_markers:
        if marker in prompt_content:
            print(f"✓ Found response format marker: {marker}")
        else:
            print(f"✗ Missing response format marker: {marker}")
            all_format_found = False

    if not all_format_found:
        return False

    print("\n=== Task 13.6 Response Pattern Test Passed! ===")
    print("✅ All required response pattern elements found in system prompt")
    print(
        "✅ Agent will use 'Generated code: [CODE]. Justification: [explanation]' format"
    )
    print("✅ Agent will NOT ask for confirmation before generating code")
    return True


if __name__ == "__main__":
    success = test_task_13_6_response_pattern()
    if success:
        print("\n🎉 Task 13.6 completed successfully!")
        print(
            "The agent response pattern has been modified to use 'Generated code: [CODE]. Justification: [explanation]' instead of asking for confirmation."
        )
        sys.exit(0)
    else:
        print("\n❌ Task 13.6 test failed!")
        sys.exit(1)
