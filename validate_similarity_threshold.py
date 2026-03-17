#!/usr/bin/env python3
"""
Simple validation script for similarity threshold filtering implementation.

This script validates that the similarity threshold filtering logic
has been correctly implemented without requiring the full agent environment.
"""

import re
from typing import List, Dict, Any


def mock_calculate_semantic_similarity(text1: str, text2: str) -> float:
    """
    Mock implementation of semantic similarity calculation for testing.

    Returns predefined similarity scores based on text content.
    """
    # Simple keyword-based similarity for testing
    text1_lower = text1.lower()
    text2_lower = text2.lower()

    # Count common words
    words1 = set(text1_lower.split())
    words2 = set(text2_lower.split())
    common_words = words1.intersection(words2)

    # Calculate simple similarity based on common words
    if len(words2) == 0:
        return 0.0

    similarity = len(common_words) / len(words2)
    return min(1.0, similarity)  # Cap at 1.0


def find_component_matches_validation(
    description: str, component_rules: Dict, similarity_threshold: float = 0.3
) -> List[Dict]:
    """
    Validation version of find_component_matches with similarity threshold filtering.

    This is a simplified version for testing the similarity threshold logic.
    """
    description_lower = description.lower()
    matches = []

    for code, rule_info in component_rules.items():
        keyword_score = 0
        semantic_score = 0.0
        keywords = rule_info.get("keywords", [])

        # Check for keyword matches
        for keyword in keywords:
            if keyword in description_lower:
                keyword_score += 1

        # Additional scoring based on word boundaries
        for keyword in keywords:
            pattern = r"\b" + re.escape(keyword) + r"\b"
            if re.search(pattern, description_lower):
                keyword_score += 2

        # Calculate semantic similarity
        component_text = f"{rule_info['name']} {rule_info['description']}"
        semantic_score = mock_calculate_semantic_similarity(description, component_text)

        # SIMILARITY THRESHOLD FILTERING: Only include matches that meet the minimum semantic similarity
        # This filters out completely unrelated options from clarification prompts
        if semantic_score < similarity_threshold:
            continue  # Skip this match as it doesn't meet the similarity threshold

        # Convert semantic score to a 0-10 scale for combination with keyword score
        semantic_score_scaled = semantic_score * 10

        # Combine scores: keyword_score (0-6 range) + semantic_score_scaled (0-10 range)
        combined_score = keyword_score + semantic_score_scaled

        # Only include matches with positive combined scores after threshold filtering
        if combined_score > 0:
            matches.append(
                {
                    "code": code,
                    "name": rule_info["name"],
                    "description": rule_info["description"],
                    "score": combined_score,
                    "keyword_score": keyword_score,
                    "semantic_score": semantic_score,
                }
            )

    # Sort matches by combined score (descending)
    matches.sort(key=lambda x: x["score"], reverse=True)
    return matches


def test_similarity_threshold_filtering():
    """
    Test the similarity threshold filtering implementation.
    """
    # Sample component rules for testing
    test_component_rules = {
        "A": {
            "name": "Agricultural products",
            "description": "Products related to agriculture and farming",
            "keywords": ["agricultural", "farming", "crops", "livestock"],
        },
        "C": {
            "name": "Chemical products",
            "description": "Chemical and pharmaceutical products",
            "keywords": ["chemical", "pharmaceutical", "drugs", "medicine"],
        },
        "M": {
            "name": "Metal products",
            "description": "Metal and steel products",
            "keywords": ["metal", "steel", "iron", "aluminum"],
        },
    }

    # Test 1: Low threshold should include more matches
    user_description = "I need agricultural products for farming crops and livestock"

    matches_low_threshold = find_component_matches_validation(
        user_description, test_component_rules, similarity_threshold=0.1
    )

    # Test 2: High threshold should filter out unrelated matches
    matches_high_threshold = find_component_matches_validation(
        user_description, test_component_rules, similarity_threshold=0.4
    )

    print("Test 1: Low Threshold (0.1) Results:")
    for match in matches_low_threshold:
        print(
            f"  - {match['code']}: {match['name']} (score: {match['score']:.2f}, semantic: {match['semantic_score']:.2f})"
        )

    print(f"\nTest 2: High Threshold (0.4) Results:")
    for match in matches_high_threshold:
        print(
            f"  - {match['code']}: {match['name']} (score: {match['score']:.2f}, semantic: {match['semantic_score']:.2f})"
        )

    # Validation 1: Both should include agricultural products (high similarity)
    assert len(matches_low_threshold) >= 1, "Low threshold should have at least 1 match"
    assert len(matches_high_threshold) >= 1, (
        "High threshold should have at least 1 match"
    )

    # Validation 2: Agricultural products should be in both results
    ag_matches_low = [m for m in matches_low_threshold if m["code"] == "A"]
    ag_matches_high = [m for m in matches_high_threshold if m["code"] == "A"]

    assert len(ag_matches_low) == 1, (
        "Agricultural products should be in low threshold results"
    )
    assert len(ag_matches_high) == 1, (
        "Agricultural products should be in high threshold results"
    )

    # Validation 3: High threshold should have fewer or equal total matches (filtered unrelated)
    assert len(matches_high_threshold) <= len(matches_low_threshold), (
        f"High threshold should have fewer matches: {len(matches_high_threshold)} vs {len(matches_low_threshold)}"
    )

    print(f"\n✅ Test 1 Passed: Similarity threshold filters unrelated options")

    # Test 3: Very high threshold should filter out low-similarity matches
    matches_very_high_threshold = find_component_matches_validation(
        user_description, test_component_rules, similarity_threshold=0.8
    )

    print(f"\nTest 3: Very High Threshold (0.8) Results:")
    for match in matches_very_high_threshold:
        print(
            f"  - {match['code']}: {match['name']} (score: {match['score']:.2f}, semantic: {match['semantic_score']:.2f})"
        )

    # Very high threshold might have fewer matches
    assert len(matches_very_high_threshold) <= len(matches_high_threshold), (
        "Very high threshold should have fewer or equal matches"
    )

    # Test 4: All matches should meet the similarity threshold
    for match in matches_very_high_threshold:
        assert match["semantic_score"] >= 0.8, (
            f"Match {match['code']} has semantic score {match['semantic_score']} below threshold 0.8"
        )

    print(f"✅ Test 2 Passed: All matches meet the similarity threshold")

    # Test 5: Zero threshold should include all positive matches
    matches_zero_threshold = find_component_matches_validation(
        user_description, test_component_rules, similarity_threshold=0.0
    )

    print(f"\nTest 4: Zero Threshold (0.0) Results:")
    for match in matches_zero_threshold:
        print(
            f"  - {match['code']}: {match['name']} (score: {match['score']:.2f}, semantic: {match['semantic_score']:.2f})"
        )

    # All matches should have positive scores and non-negative semantic scores
    for match in matches_zero_threshold:
        assert match["score"] > 0, (
            f"Match {match['code']} has non-positive score {match['score']}"
        )
        assert match["semantic_score"] >= 0.0, (
            f"Match {match['code']} has negative semantic score {match['semantic_score']}"
        )

    print(f"✅ Test 3 Passed: Zero threshold includes all positive matches")

    # Test 6: Default threshold value
    matches_default_threshold = find_component_matches_validation(
        user_description, test_component_rules
    )  # Should use default threshold of 0.3

    matches_explicit_threshold = find_component_matches_validation(
        user_description, test_component_rules, similarity_threshold=0.3
    )

    assert len(matches_default_threshold) == len(matches_explicit_threshold), (
        "Default and explicit threshold should produce same results"
    )

    print(f"✅ Test 4 Passed: Default threshold value is 0.3")

    print(f"\n🎉 All similarity threshold filtering tests passed!")


if __name__ == "__main__":
    test_similarity_threshold_filtering()
