#!/usr/bin/env python3
"""
Test script for explicit guess permission detection functionality.
This tests the implementation of task 4.1 from the disambiguation workflow.
"""

import re
import sys


def detect_explicit_guess_permission(user_text: str) -> bool:
    """
    Detect explicit guess permission phrases in user text.

    This function analyzes user input to identify phrases that indicate
    the user explicitly allows the agent to make a guess for ambiguous
    components. This implements the "explicit guess permission" requirement
    from the disambiguation workflow.

    Args:
        user_text: The user's input text to analyze

    Returns:
        bool: True if explicit guess permission is detected, False otherwise

    Examples:
        >>> detect_explicit_guess_permission("I don't know, you choose")
        True
        >>> detect_explicit_guess_permission("whatever you think is best")
        True
        >>> detect_explicit_guess_permission("please specify the material")
        False
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


print("✓ Successfully defined detect_explicit_guess_permission function")

# Test cases for explicit guess permission detection
test_cases = [
    # Positive cases (should return True)
    ("I don't know", True, "Direct I don't know"),
    ("i dont know", True, "I don't know without apostrophe"),
    ("whatever", True, "Single word whatever"),
    ("you choose", True, "Direct you choose"),
    ("you decide", True, "Alternative you decide"),
    ("up to you", True, "Up to you phrase"),
    ("idk", True, "IDK abbreviation"),
    ("I have no idea", True, "No idea phrase"),
    ("I'm not sure", True, "Not sure phrase"),
    ("any of them", True, "Any of them phrase"),
    ("doesn't matter", True, "Doesn't matter phrase"),
    ("just guess", True, "Just guess command"),
    ("take your best guess", True, "Take your best guess"),
    ("I don't know, whatever you choose", True, "Combined phrase"),
    ("whichever is fine, you decide", True, "Combined indifference + decision"),
    # Negative cases (should return False)
    ("please specify the material", False, "Request for specification"),
    ("I think it's steel", False, "Providing information"),
    ("can you help me", False, "General question"),
    ("what are the options", False, "Asking for options"),
    ("I prefer option A", False, "Expressing preference"),
    ("tell me more", False, "Request for more information"),
    ("explain the difference", False, "Request for explanation"),
    ("show me the codes", False, "Request for display"),
    ("which one is better", False, "Comparison question"),
    ("I need to think about it", False, "Thinking response"),
    ("maybe later", False, "Delay response"),
]


def run_tests():
    """Run all test cases for guess permission detection."""
    print(
        f"\nRunning {len(test_cases)} test cases for explicit guess permission detection..."
    )
    print("=" * 80)

    passed = 0
    failed = 0

    for i, (text, expected, description) in enumerate(test_cases, 1):
        try:
            result = detect_explicit_guess_permission(text)

            if result == expected:
                print(f"✓ Test {i:2d} PASSED: {description}")
                print(f"    Input: '{text}' -> Expected: {expected}, Got: {result}")
                passed += 1
            else:
                print(f"✗ Test {i:2d} FAILED: {description}")
                print(f"    Input: '{text}' -> Expected: {expected}, Got: {result}")
                failed += 1
        except Exception as e:
            print(f"✗ Test {i:2d} ERROR: {description}")
            print(f"    Input: '{text}' -> Error: {e}")
            failed += 1

        print("-" * 40)

    print(f"\nTest Results:")
    print(f"  Passed: {passed}")
    print(f"  Failed: {failed}")
    print(f"  Total:  {passed + failed}")

    if failed == 0:
        print(
            "\n🎉 All tests passed! Phrase detection for explicit guess permission is working correctly."
        )
        return True
    else:
        print(f"\n❌ {failed} tests failed. Please review the implementation.")
        return False


if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
