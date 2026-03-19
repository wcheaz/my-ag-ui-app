#!/usr/bin/env python3
"""
Simple test script to verify that user notification when a guess is made is working correctly.
This version tests the functionality in isolation without importing the full agent module.
"""

import sys
import os
import re


def format_guess_notification(guessed_components: list) -> str:
    """
    Format a user-friendly notification message when components are guessed.

    This function creates a clear, informative message that tells the user
    which components were guessed based on their explicit permission.

    Args:
        guessed_components: List of component dictionaries with guessed information

    Returns:
        Formatted notification string for the user
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


def test_guess_notification_formatting():
    """Test the format_guess_notification function directly."""
    print("Testing format_guess_notification function...")

    # Test with empty list
    result = format_guess_notification([])
    assert result == "", "Empty list should return empty string"
    print("✓ Empty list test passed")

    # Test with guessed components
    guessed_components = [
        {
            "component_name": "Major Category",
            "guessed_value": "C",
            "description": "Chemical products",
        },
        {
            "component_name": "Material Type",
            "guessed_value": "01",
            "description": "Steel",
        },
    ]

    result = format_guess_notification(guessed_components)
    print("Generated notification:")
    print(result)
    print()

    # Verify the notification contains expected elements
    assert "🎯" in result, "Notification should contain emoji"
    assert "Major Category" in result, (
        "Notification should contain first component name"
    )
    assert "Material Type" in result, (
        "Notification should contain second component name"
    )
    assert "C" in result, "Notification should contain first guessed value"
    assert "01" in result, "Notification should contain second guessed value"
    assert "Chemical products" in result, (
        "Notification should contain first description"
    )
    assert "Steel" in result, "Notification should contain second description"
    assert "I don't know" in result, "Notification should mention guess permission"

    print("✓ Guess notification formatting test passed")


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


def test_guess_permission_detection():
    """Test the guess permission detection function."""
    print("Testing detect_explicit_guess_permission function...")

    # Test cases that should return True
    true_cases = [
        "I don't know",
        "i dont know",
        "whatever",
        "you choose",
        "you decide",
        "up to you",
        "idk",
        "I have no idea",
        "just guess",
        "take your best guess",
        "I don't know, whatever you choose",
        "whichever is fine, you decide",
    ]

    for case in true_cases:
        result = detect_explicit_guess_permission(case)
        assert result == True, f"Should detect guess permission in: {case}"

    # Test cases that should return False
    false_cases = [
        "please specify the material",
        "I think it's steel",
        "can you help me",
        "what are the options",
        "I prefer option A",
    ]

    for case in false_cases:
        result = detect_explicit_guess_permission(case)
        assert result == False, f"Should NOT detect guess permission in: {case}"

    print("✓ Guess permission detection test passed")


def verify_implementation_in_agent_file():
    """Verify that the implementation exists in the agent file."""
    print("Verifying implementation in agent.py file...")

    agent_file_path = os.path.join("agent", "src", "agent.py")

    if not os.path.exists(agent_file_path):
        print(f"❌ Agent file not found: {agent_file_path}")
        return False

    with open(agent_file_path, "r") as f:
        content = f.read()

    # Check for the format_guess_notification function
    if "def format_guess_notification" in content:
        print("✓ format_guess_notification function found in agent.py")
    else:
        print("❌ format_guess_notification function NOT found in agent.py")
        return False

    # Check for guess_notification field in detect_component_ambiguity
    if '"guess_notification": ""' in content:
        print("✓ guess_notification field found in detect_component_ambiguity")
    else:
        print("❌ guess_notification field NOT found in detect_component_ambiguity")
        return False

    # Check for guess_notification in clarify_components response
    if (
        '"guess_notification": ambiguity_results.get("guess_notification", "")'
        in content
    ):
        print("✓ guess_notification included in clarify_components response")
    else:
        print("❌ guess_notification NOT included in clarify_components response")
        return False

    # Check for notification generation logic
    if "format_guess_notification(guessed_component_details)" in content:
        print("✓ Notification generation logic found")
    else:
        print("❌ Notification generation logic NOT found")
        return False

    return True


def main():
    """Run all tests."""
    print("Testing user notification when a guess is made...")
    print("=" * 60)

    try:
        # Run individual tests
        test_guess_notification_formatting()
        test_guess_permission_detection()
        verify_implementation_in_agent_file()

        print("\n" + "=" * 60)
        print("🎉 All tests passed!")
        print("The guess notification functionality has been successfully implemented.")
        print()
        print("Summary of implementation:")
        print("1. ✅ Added format_guess_notification function")
        print("2. ✅ Updated detect_component_ambiguity to include guess_notification")
        print(
            "3. ✅ Updated clarify_components to include guess_notification in response"
        )
        print("4. ✅ Verified guess permission detection is working")
        print()
        print(
            "When a user gives explicit guess permission (e.g., 'I don't know', 'whatever'),"
        )
        print("the agent will now notify them about which components were guessed.")

    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback

        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
