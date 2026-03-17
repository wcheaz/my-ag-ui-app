#!/usr/bin/env python3
"""
Unit tests for guess permission detection functionality.

This module provides comprehensive unit tests for the detect_explicit_guess_permission
function. These tests ensure that guess permission detection works correctly across
various scenarios including edge cases.

Tests cover:
- Positive cases (all supported guess permission phrases)
- Negative cases (phrases that should not be detected)
- Edge cases (empty strings, mixed case, punctuation)
- Combination patterns
- Word boundary enforcement
- Case sensitivity
"""

import sys
import os
import re
import unittest


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


class TestGuessPermissionDetection(unittest.TestCase):
    """Test suite for guess permission detection functionality."""

    def setUp(self):
        """Set up test fixtures."""
        self.test_function = detect_explicit_guess_permission

    def test_direct_statements_of_not_knowing(self):
        """Test detection of direct 'I don't know' type phrases."""
        positive_cases = [
            ("I don't know", True, "Standard apostrophe version"),
            ("i dont know", True, "Missing apostrophe version"),
            ("I don't know.", True, "With period"),
            ("I don't know!", True, "With exclamation"),
            ("I don't know?", True, "With question mark"),
            ("I don't know what you mean", True, "Extended phrase"),
            ("Well I don't know", True, "With prefix word"),
            ("I don't know right now", True, "With suffix words"),
            ("idk", True, "Abbreviation"),
            ("IDK", True, "Uppercase abbreviation"),
            ("idk about that", True, "Abbreviation in context"),
            ("I have no idea", True, "No idea phrase"),
            ("I have no idea.", True, "No idea with period"),
            ("no idea", True, "Short no idea"),
            ("no idea really", True, "No idea extended"),
            ("I'm not sure", True, "Not sure with apostrophe"),
            ("im not sure", True, "Not sure missing apostrophe"),
            ("I'm not sure about this", True, "Not sure in context"),
            ("not sure", True, "Short not sure"),
            ("not sure really", True, "Not sure extended"),
        ]

        for text, expected, description in positive_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_delegative_phrases(self):
        """Test detection of delegative phrases like 'you choose'."""
        positive_cases = [
            ("you choose", True, "Basic you choose"),
            ("You choose", True, "Capitalized you choose"),
            ("YOU CHOOSE", True, "Uppercase you choose"),
            ("you choose.", True, "With period"),
            ("you choose!", True, "With exclamation"),
            ("you choose for me", True, "Extended you choose"),
            ("if you choose", True, "With prefix"),
            ("you choose then", True, "With suffix"),
            ("you decide", True, "Alternative you decide"),
            ("you decide for me", True, "Extended you decide"),
            ("your choice", True, "Your choice phrase"),
            ("your decision", True, "Your decision phrase"),
            ("up to you", True, "Up to you phrase"),
            ("it's up to you", True, "Extended up to you"),
            ("your call", True, "Your call phrase"),
            ("your judgment", True, "Your judgment phrase"),
            ("use your judgment", True, "Extended judgment"),
        ]

        for text, expected, description in positive_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_indifference_phrases(self):
        """Test detection of indifference phrases like 'whatever'."""
        positive_cases = [
            ("whatever", True, "Basic whatever"),
            ("Whatever", True, "Capitalized whatever"),
            ("WHATEVER", True, "Uppercase whatever"),
            ("whatever.", True, "With period"),
            ("whatever!", True, "With exclamation"),
            ("whatever you want", True, "Extended whatever"),
            ("I said whatever", True, "With prefix"),
            ("whatever then", True, "With suffix"),
            ("whichever", True, "Alternative whichever"),
            ("whichever one", True, "Extended whichever"),
            ("either one", True, "Either one phrase"),
            ("either one is fine", True, "Extended either one"),
            ("any of them", True, "Any of them phrase"),
            ("any of them are fine", True, "Extended any of them"),
            ("any is fine", True, "Any is fine phrase"),
            ("doesn't matter", True, "Doesn't matter phrase"),
            ("doesn't matter to me", True, "Extended doesn't matter"),
            ("I don't care", True, "I don't care phrase"),
            ("i dont care", True, "I don't care missing apostrophe"),
            ("don't care", True, "Short don't care"),
            ("really don't care", True, "Extended don't care"),
        ]

        for text, expected, description in positive_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_explicit_permission_to_guess(self):
        """Test detection of explicit permission to guess."""
        positive_cases = [
            ("just guess", True, "Basic just guess"),
            ("just guess for me", True, "Extended just guess"),
            ("guess for me", True, "Basic guess for me"),
            ("make a guess", True, "Make a guess phrase"),
            ("make a guess for me", True, "Extended make a guess"),
            ("take your best guess", True, "Take your best guess"),
            ("your best guess", True, "Your best guess phrase"),
            ("go ahead and guess", True, "Go ahead and guess"),
            ("feel free to guess", True, "Feel free to guess"),
            ("please feel free to guess", True, "Extended feel free to guess"),
        ]

        for text, expected, description in positive_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_combined_patterns(self):
        """Test detection of combined permission phrases."""
        positive_cases = [
            (
                "I don't know, whatever you choose",
                True,
                "I don't know + whatever + you choose",
            ),
            ("I don't know whatever you choose", True, "Without comma"),
            ("I don't know, you choose", True, "I don't know + you choose"),
            ("whatever you decide", True, "Whatever + you decide"),
            ("up to you, I don't care", True, "Up to you + I don't care"),
            ("up to you I don't care", True, "Without comma"),
            ("you choose doesn't matter", True, "You choose + doesn't matter"),
            ("whatever, you decide", True, "Whatever + you decide"),
            ("I don't know and whatever", True, "I don't know + whatever with and"),
        ]

        for text, expected, description in positive_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_negative_cases(self):
        """Test phrases that should NOT be detected as guess permission."""
        negative_cases = [
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
            ("I know what I want", False, "Statement of knowledge"),
            ("I don't want to guess", False, "Explicit refusal to guess"),
            ("please don't guess", False, "Request not to guess"),
            ("I have some idea", False, "Partial knowledge (not no idea)"),
            ("I'm somewhat sure", False, "Partial certainty (not not sure)"),
            ("know", False, "Partial match of 'I don't know'"),
            ("choose", False, "Partial match of 'you choose'"),
            ("matter", False, "Partial match of 'doesn't matter'"),
            (
                "whatever happens",
                True,
                "Whatever in different context - still contains 'whatever'",
            ),
            (
                "I don't know why",
                True,
                "I don't know in different context - still contains 'I don't know'",
            ),
            (
                "you choose the color",
                True,
                "You choose in command context - still contains 'you choose'",
            ),
            ("guess what", False, "Guess in different context"),
            ("best guess is", False, "Best guess in statement context"),
        ]

        for text, expected, description in negative_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_edge_cases(self):
        """Test edge cases like empty strings, punctuation, etc."""
        edge_cases = [
            ("", False, "Empty string"),
            (" ", False, "Single space"),
            ("   ", False, "Multiple spaces"),
            ("?", False, "Question mark only"),
            ("!", False, "Exclamation mark only"),
            (".", False, "Period only"),
            (",", False, "Comma only"),
            ("i", False, "Single letter i"),
            ("you", False, "Single word you"),
            ("know", False, "Single word know"),
            ("guess", False, "Single word guess"),
            ("I don't", False, "Incomplete I don't"),
            ("you whatever", True, "Reverse order - still contains 'whatever'"),
            ("matter doesn't", False, "Reverse order doesn't matter"),
            ("care don't", False, "Reverse order don't care"),
            ("i dont", False, "Incomplete I don't"),
            ("you choos", False, "Misspelled choose"),
            ("whatevr", False, "Misspelled whatever"),
            ("I don't knoww", False, "Misspelled know"),
            ("I don't kn0w", False, "Number substitution"),
            ("y0u choose", False, "Number substitution"),
            ("id k", False, "Space in idk"),
        ]

        for text, expected, description in edge_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_word_boundary_enforcement(self):
        """Test that word boundaries prevent partial matches."""
        word_boundary_cases = [
            ("knowing", False, "Contains 'know' but should not match"),
            ("knowledge", False, "Contains 'know' but should not match"),
            ("chosen", False, "Contains 'chose' but should not match"),
            ("choosing", False, "Contains 'choose' but should not match"),
            ("matters", False, "Contains 'matter' but should not match"),
            ("caring", False, "Contains 'care' but should not match"),
            ("whatsoever", False, "Contains 'whatever' but should not match"),
            ("whichever way", True, "Whichever is a valid phrase"),
            ("I don't knowingly", False, "Contains 'know' in different word"),
            ("you chooser", False, "Contains 'choose' but should not match"),
            ("whatevering", False, "Contains 'whatever' but should not match"),
        ]

        for text, expected, description in word_boundary_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_case_sensitivity(self):
        """Test that the function is case-insensitive."""
        case_sensitivity_cases = [
            ("I DON'T KNOW", True, "All caps I don't know"),
            ("i DoN't KnOw", True, "Mixed case I don't know"),
            ("WhAtEvEr", True, "Mixed case whatever"),
            ("YoU cHoOsE", True, "Mixed case you choose"),
            ("IDK", True, "All caps IDK"),
            ("No IdEa", True, "Mixed case no idea"),
            ("DoesN't MaTtEr", True, "Mixed case doesn't matter"),
        ]

        for text, expected, description in case_sensitivity_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )

    def test_long_strings(self):
        """Test performance and correctness with very long strings."""
        long_text_negative = (
            "This is a very long text that does not contain any guess permission phrases. "
            * 100
        )
        long_text_positive = (
            "This is a very long text that contains I don't know permission. " * 100
        )

        with self.subTest(description="Long negative text"):
            result = self.test_function(long_text_negative)
            self.assertFalse(
                result, "Long text without guess permission should return False"
            )

        with self.subTest(description="Long positive text"):
            result = self.test_function(long_text_positive)
            self.assertTrue(
                result, "Long text with guess permission should return True"
            )

    def test_special_characters(self):
        """Test handling of special characters and Unicode."""
        special_char_cases = [
            ("I don't know!", True, "With exclamation"),
            ("you choose?", True, "With question mark"),
            ("whatever...", True, "With ellipsis"),
            ("I don't know, you choose!", True, "Comma and exclamation"),
            ("I don't know; you choose", True, "With semicolon"),
            ("I don't know: you choose", True, "With colon"),
            ("I don't know\nyou choose", True, "With newline"),
            ("I don't know\tyou choose", True, "With tab"),
            ("I don't know - you choose", True, "With hyphen"),
            ("I don't know—you choose", True, "With em dash"),
        ]

        for text, expected, description in special_char_cases:
            with self.subTest(text=text, description=description):
                result = self.test_function(text)
                self.assertEqual(
                    result,
                    expected,
                    f"Failed: {description} - '{text}' -> expected {expected}, got {result}",
                )


if __name__ == "__main__":
    # Run the tests
    print("Running comprehensive unit tests for guess permission detection...")
    print("=" * 70)

    # Run with detailed output
    unittest.main(verbosity=2)
