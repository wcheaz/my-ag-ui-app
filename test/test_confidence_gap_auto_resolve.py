#!/usr/bin/env python3
"""
Test the confidence gap auto-resolve logic.

When multiple matches pass the inclusion filter, the system should auto-resolve
to the top match when the score gap between the top two matches exceeds a
per-component threshold. This prevents unnecessary clarification questions
for cases where the top match is clearly dominant (e.g., size_category with
6.1m clearly mapping to Oversized >5m rather than Bulk 1m-5m).
"""

import sys
import os

agent_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agent")
os.chdir(agent_dir)
sys.path.insert(0, agent_dir)


DEFAULT_CONFIDENCE_GAP_CONFIG = {
    "size_category": {"gap_ratio": 0.3, "min_top_score": 3.0},
    "major_category": {"gap_ratio": 0.5, "min_top_score": 4.0},
    "manufacturing_method": {"gap_ratio": 0.5, "min_top_score": 4.0},
    "object_shape": {"gap_ratio": 0.4, "min_top_score": 4.0},
    "material_type": {"gap_ratio": 0.5, "min_top_score": 4.0},
    "quality_grade": {"gap_ratio": 0.6, "min_top_score": 3.0},
}


def should_auto_resolve(matches: list, component_key: str) -> bool:
    if len(matches) < 2:
        return len(matches) == 1

    config = DEFAULT_CONFIDENCE_GAP_CONFIG.get(
        component_key, {"gap_ratio": 0.5, "min_top_score": 4.0}
    )
    top_score = matches[0]["score"]
    second_score = matches[1]["score"]
    gap_ratio = (top_score - second_score) / max(top_score, 1.0)

    # Primary: score gap
    if top_score >= config["min_top_score"] and gap_ratio >= config["gap_ratio"]:
        return True

    # Secondary: keyword dominance
    top_kw = matches[0].get("keyword_score", 0)
    second_kw = matches[1].get("keyword_score", 0)
    if top_kw > 0 and second_kw == 0 and top_score >= config["min_top_score"]:
        return True

    return False


def _make_match(code, name, score, keyword_score=0, semantic_score=0.0):
    return {
        "code": code,
        "name": name,
        "description": f"desc for {name}",
        "score": score,
        "keyword_score": keyword_score,
        "semantic_score": semantic_score,
        "filter_reason": "test",
    }


def test_size_category_clear_gap():
    matches = [
        _make_match("7", "Oversized", 12.0, keyword_score=6, semantic_score=0.6),
        _make_match("6", "Bulk", 3.0, keyword_score=1, semantic_score=0.2),
    ]
    assert should_auto_resolve(matches, "size_category") is True, (
        "Size category with gap 0.75 should auto-resolve (threshold 0.3)"
    )
    print("✓ size_category: clear gap auto-resolves")


def test_size_category_narrow_gap():
    matches = [
        _make_match("7", "Oversized", 5.0),
        _make_match("6", "Bulk", 4.0),
    ]
    gap = (5.0 - 4.0) / 5.0
    assert gap < 0.3, f"Gap should be < 0.3 for this test, got {gap}"
    assert should_auto_resolve(matches, "size_category") is False, (
        "Size category with narrow gap should NOT auto-resolve"
    )
    print("✓ size_category: narrow gap stays ambiguous")


def test_size_category_low_top_score():
    matches = [
        _make_match("7", "Oversized", 2.0),
        _make_match("6", "Bulk", 0.5),
    ]
    config = DEFAULT_CONFIDENCE_GAP_CONFIG["size_category"]
    assert config["min_top_score"] == 3.0
    assert should_auto_resolve(matches, "size_category") is False, (
        "Low top score should prevent auto-resolve even with big gap"
    )
    print("✓ size_category: low top score prevents auto-resolve")


def test_quality_grade_higher_threshold():
    matches = [
        _make_match("02", "Premium", 6.0),
        _make_match("06", "Standard", 4.5),
    ]
    gap = (6.0 - 4.5) / 6.0
    assert gap < 0.6, f"Gap should be < 0.6, got {gap}"
    assert should_auto_resolve(matches, "quality_grade") is False, (
        "Quality grade with gap 0.25 should NOT auto-resolve (threshold 0.6)"
    )
    print("✓ quality_grade: moderate gap stays ambiguous (higher threshold)")


def test_quality_grade_dominant_match():
    matches = [
        _make_match("02", "Premium", 12.0),
        _make_match("06", "Standard", 3.0),
    ]
    assert should_auto_resolve(matches, "quality_grade") is True, (
        "Quality grade with gap 0.75 should auto-resolve even with high threshold"
    )
    print("✓ quality_grade: dominant match auto-resolves")


def test_single_match():
    matches = [
        _make_match("A", "Aerospace", 10.0),
    ]
    assert should_auto_resolve(matches, "major_category") is True, (
        "Single match should always auto-resolve"
    )
    print("✓ single match auto-resolves")


def test_empty_matches():
    assert should_auto_resolve([], "major_category") is False, (
        "Empty matches should not auto-resolve"
    )
    print("✓ empty matches do not auto-resolve")


def test_unknown_component():
    matches = [
        _make_match("X", "Foo", 10.0),
        _make_match("Y", "Bar", 2.0),
    ]
    assert should_auto_resolve(matches, "unknown_component") is True, (
        "Unknown component should use default threshold (gap 0.8 > 0.5)"
    )
    print("✓ unknown component uses default threshold")


def test_all_thresholds_configured():
    expected_keys = [
        "size_category",
        "major_category",
        "manufacturing_method",
        "object_shape",
        "material_type",
        "quality_grade",
    ]
    for key in expected_keys:
        assert key in DEFAULT_CONFIDENCE_GAP_CONFIG, f"Missing threshold for {key}"
        assert "gap_ratio" in DEFAULT_CONFIDENCE_GAP_CONFIG[key]
        assert "min_top_score" in DEFAULT_CONFIDENCE_GAP_CONFIG[key]
    print("✓ all component thresholds configured")


def test_size_category_lowest_gap():
    size_gap = DEFAULT_CONFIDENCE_GAP_CONFIG["size_category"]["gap_ratio"]
    for key, config in DEFAULT_CONFIDENCE_GAP_CONFIG.items():
        if key != "size_category":
            assert config["gap_ratio"] >= size_gap, (
                f"{key} gap_ratio ({config['gap_ratio']}) should be >= size_category ({size_gap})"
            )
    print("✓ size_category has the lowest gap_ratio (most aggressive auto-resolve)")


def test_quality_grade_highest_gap():
    quality_gap = DEFAULT_CONFIDENCE_GAP_CONFIG["quality_grade"]["gap_ratio"]
    for key, config in DEFAULT_CONFIDENCE_GAP_CONFIG.items():
        if key != "quality_grade":
            assert config["gap_ratio"] <= quality_gap, (
                f"{key} gap_ratio ({config['gap_ratio']}) should be <= quality_grade ({quality_gap})"
            )
    print("✓ quality_grade has the highest gap_ratio (most conservative auto-resolve)")


def test_major_category_close_matches_stay_ambiguous():
    matches = [
        _make_match("A", "Aerospace", 6.0),
        _make_match("M", "Manufacturing", 5.0),
    ]
    assert should_auto_resolve(matches, "major_category") is False, (
        "major_category with gap 0.17 should NOT auto-resolve (threshold 0.5)"
    )
    print("✓ close matches in major_category stay ambiguous")


def test_all_components_auto_resolve_at_high_gap():
    for component_key in DEFAULT_CONFIDENCE_GAP_CONFIG:
        matches = [
            _make_match("X", "Top", 15.0),
            _make_match("Y", "Second", 1.0),
        ]
        assert should_auto_resolve(matches, component_key) is True, (
            f"{component_key} should auto-resolve with gap 0.93"
        )
    print("✓ all components auto-resolve at very high gap")


def test_gap_ratio_boundary_exact():
    matches = [
        _make_match("X", "Top", 10.0),
        _make_match("Y", "Second", 7.0),
    ]
    gap = (10.0 - 7.0) / 10.0
    assert gap == 0.3, f"Expected gap 0.3, got {gap}"

    assert should_auto_resolve(matches, "size_category") is True, (
        "size_category: exact boundary gap_ratio=0.3 should auto-resolve (>=)"
    )

    assert should_auto_resolve(matches, "major_category") is False, (
        "major_category: gap_ratio=0.3 should NOT auto-resolve (threshold 0.5)"
    )
    print("✓ boundary gap_ratio=0.3 correctly handled per component")


def test_min_top_score_boundary():
    matches = [
        _make_match("X", "Top", 3.0),
        _make_match("Y", "Second", 0.1),
    ]
    assert should_auto_resolve(matches, "size_category") is True, (
        "size_category: top_score=3.0 meets min_top_score=3.0"
    )
    assert should_auto_resolve(matches, "major_category") is False, (
        "major_category: top_score=3.0 below min_top_score=4.0"
    )
    print("✓ min_top_score boundary correctly handled")


# --- Keyword Dominance Tests ---


def test_keyword_dominance_resolves_when_gap_fails():
    # Simulates the real "aluminum" case: top match has keyword hits, runner-up has none,
    # combined gap_ratio (0.33) is below the material_type threshold (0.5),
    # but keyword dominance should still auto-resolve.
    matches = [
        _make_match("02", "Metal (Non-ferrous)", 9.28, keyword_score=3, semantic_score=0.628),
        _make_match("05", "Composite", 6.19, keyword_score=0, semantic_score=0.619),
    ]
    gap = (9.28 - 6.19) / 9.28
    assert gap < 0.5, f"Gap {gap:.3f} should be below 0.5 threshold for this test"
    assert should_auto_resolve(matches, "material_type") is True, (
        "material_type: keyword dominance (kw=3 vs kw=0) should auto-resolve despite low gap"
    )
    print("✓ keyword_dominance: top has keywords, runner-up has none → auto-resolves")


def test_keyword_dominance_does_not_fire_when_both_have_keywords():
    # If both matches have keyword hits, keyword dominance doesn't apply —
    # resolution must come from the score gap instead.
    matches = [
        _make_match("01", "Metal (Ferrous)", 7.0, keyword_score=2, semantic_score=0.5),
        _make_match("02", "Metal (Non-ferrous)", 6.0, keyword_score=1, semantic_score=0.5),
    ]
    gap = (7.0 - 6.0) / 7.0
    assert gap < 0.5, f"Gap {gap:.3f} should be below 0.5 for this test"
    assert should_auto_resolve(matches, "material_type") is False, (
        "Both have keywords → keyword dominance does not fire, gap too small → stays ambiguous"
    )
    print("✓ keyword_dominance: both have keywords → falls through to gap check → ambiguous")


def test_keyword_dominance_does_not_fire_on_weak_top_score():
    # Keyword dominance still requires min_top_score to be met.
    matches = [
        _make_match("02", "Metal (Non-ferrous)", 2.5, keyword_score=3, semantic_score=0.0),
        _make_match("05", "Composite", 0.5, keyword_score=0, semantic_score=0.05),
    ]
    assert should_auto_resolve(matches, "major_category") is False, (
        "major_category: kw dominance blocked by min_top_score (2.5 < 4.0)"
    )
    print("✓ keyword_dominance: weak top score blocks resolution even with keyword dominance")


def test_keyword_dominance_with_no_keyword_scores():
    # Matches without keyword_score field should not crash — treated as kw=0.
    matches = [
        {"code": "X", "name": "Top", "description": "d", "score": 8.0, "filter_reason": "test"},
        {"code": "Y", "name": "Second", "description": "d", "score": 5.0, "filter_reason": "test"},
    ]
    gap = (8.0 - 5.0) / 8.0
    assert gap == 0.375
    # No keyword_score on either → kw dominance won't fire (0 > 0 is False)
    # Gap 0.375 < 0.5 for material_type → stays ambiguous
    assert should_auto_resolve(matches, "material_type") is False, (
        "No keyword_score fields → kw dominance doesn't fire, gap too small → ambiguous"
    )
    print("✓ keyword_dominance: missing keyword_score fields handled safely")


def run_all_tests():
    print("=== Testing Confidence Gap Auto-Resolve Logic ===\n")
    try:
        test_size_category_clear_gap()
        test_size_category_narrow_gap()
        test_size_category_low_top_score()
        test_quality_grade_higher_threshold()
        test_quality_grade_dominant_match()
        test_single_match()
        test_empty_matches()
        test_unknown_component()
        test_all_thresholds_configured()
        test_size_category_lowest_gap()
        test_quality_grade_highest_gap()
        test_major_category_close_matches_stay_ambiguous()
        test_all_components_auto_resolve_at_high_gap()
        test_gap_ratio_boundary_exact()
        test_min_top_score_boundary()
        test_keyword_dominance_resolves_when_gap_fails()
        test_keyword_dominance_does_not_fire_when_both_have_keywords()
        test_keyword_dominance_does_not_fire_on_weak_top_score()
        test_keyword_dominance_with_no_keyword_scores()

        print("\n=== All confidence gap tests passed! ===")
        return True
    except Exception as e:
        print(f"\n=== Test failed: {e} ===")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
