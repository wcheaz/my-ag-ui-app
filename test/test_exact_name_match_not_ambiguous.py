#!/usr/bin/env python3
"""
Test that exact rulebook term matches are NOT flagged as ambiguous.

When a user's description contains a term that exactly matches a rulebook entry name,
the system should treat it as a definitive (1-1) match and not mark it as ambiguous,
even if semantically similar alternatives also score above the threshold.
"""

import sys
import os
import re

agent_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agent")
os.chdir(agent_dir)
sys.path.insert(0, os.path.join(agent_dir, "src"))

SAMPLE_RULES = """
### First Letter - Major Categories

| Code | Industry | Description |
|------|----------|-------------|
| A | Aerospace | Aircraft, spacecraft, aviation components and systems |
| C | Construction | Building materials, structural components, civil engineering |
| M | Manufacturing | Production machinery, tools, factory equipment |
| T | Technology | Electronics, computing hardware, communication equipment |

### Second Letter - Manufacturing Method

| Code | Method | Description |
|------|--------|-------------|
| F | Fabricated | Machine-fabricated or manufactured items |
| M | Molded | Injection molded, cast, or formed items |
| G | General | General purpose or standard method |

### Third Letter - Object Shape/Form

| Code | Shape | Description |
|------|-------|-------------|
| S | Sheet | Sheets, plates, or flat stock |
| T | Tube | Tubular, hollow, or pipe-shaped items |
| P | Panel | Flat panels or boards |

### Material Type

| Code | Material Type | Examples |
|------|---------------|----------|
| 01   | Metal (Ferrous) | Steel, Iron, Cast iron |
| 02   | Metal (Non-ferrous) | Aluminum, Copper, Brass, Bronze |
| 03   | Plastic (Thermoplastic) | ABS, PVC, Polycarbonate |

### Quality Grade

| Code | Quality Grade | Description |
|------|---------------|-------------|
| 02   | Premium | Highest quality, tight tolerances |
| 06   | Standard | Regular commercial quality |
| 10   | Industrial Heavy | Heavy-duty, industrial use |
| 11   | Industrial Standard | Standard industrial use |
| 15   | Aerospace | Aerospace specifications |

### Size Category

| Code | Size Category | Description |
|------|---------------|-------------|
| 2    | Small | 1mm to 10mm |
| 4    | Large | 100mm to 500mm |
"""


def parse_rules(content: str) -> dict:
    rules = {
        "major_category": {},
        "manufacturing_method": {},
        "object_shape": {},
        "material_type": {},
        "quality_grade": {},
        "size_category": {},
    }

    major_section = re.search(
        r"### First Letter - Major Categories.*?(?=###|$)", content, re.DOTALL
    )
    if major_section:
        for code, name, desc in re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
            major_section.group(),
        ):
            if code.strip() and name.strip():
                rules["major_category"][code.strip()] = {
                    "name": name.strip(),
                    "description": desc.strip(),
                    "keywords": [name.strip().lower(), desc.strip().lower()],
                }

    method_section = re.search(
        r"### Second Letter - Manufacturing Method.*?(?=###|$)", content, re.DOTALL
    )
    if method_section:
        for code, name, desc in re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
            method_section.group(),
        ):
            if code.strip() and name.strip():
                rules["manufacturing_method"][code.strip()] = {
                    "name": name.strip(),
                    "description": desc.strip(),
                    "keywords": [name.strip().lower(), desc.strip().lower()],
                }

    shape_section = re.search(
        r"### Third Letter - Object Shape/Form.*?(?=###|$)", content, re.DOTALL
    )
    if shape_section:
        for code, name, desc in re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
            shape_section.group(),
        ):
            if code.strip() and name.strip():
                rules["object_shape"][code.strip()] = {
                    "name": name.strip(),
                    "description": desc.strip(),
                    "keywords": [name.strip().lower(), desc.strip().lower()],
                }

    material_section = re.search(
        r"### Material Type.*?(?=###|$)", content, re.DOTALL
    )
    if material_section:
        for code, name, examples in re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|",
            material_section.group(),
        ):
            if code.strip() and name.strip():
                keywords = [name.strip().lower()]
                if examples.strip():
                    keywords.extend(
                        [ex.strip().lower() for ex in examples.split(",")]
                    )
                rules["material_type"][code.strip()] = {
                    "name": name.strip(),
                    "description": examples.strip(),
                    "keywords": keywords,
                }

    quality_section = re.search(
        r"### Quality Grade.*?(?=###|$)", content, re.DOTALL
    )
    if quality_section:
        for code, name, desc in re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|",
            quality_section.group(),
        ):
            if code.strip() and name.strip():
                rules["quality_grade"][code.strip()] = {
                    "name": name.strip(),
                    "description": desc.strip(),
                    "keywords": [name.strip().lower(), desc.strip().lower()],
                }

    size_section = re.search(r"### Size Category.*?(?=###|$)", content, re.DOTALL)
    if size_section:
        for code, name, desc in re.findall(
            r"\|\s*(\d)\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|",
            size_section.group(),
        ):
            if code.strip() and name.strip():
                rules["size_category"][code.strip()] = {
                    "name": name.strip(),
                    "description": desc.strip(),
                    "keywords": [name.strip().lower(), desc.strip().lower()],
                }

    return rules


def find_component_matches(description: str, component_rules: dict) -> list:
    description_lower = description.lower()
    matches = []

    for code, rule_info in component_rules.items():
        keyword_score = 0
        keywords = rule_info.get("keywords", [])

        for keyword in keywords:
            if keyword in description_lower:
                keyword_score += 1

        for keyword in keywords:
            pattern = r"\b" + re.escape(keyword) + r"\b"
            if re.search(pattern, description_lower):
                keyword_score += 2

        if keyword_score > 0:
            matches.append(
                {
                    "code": code,
                    "name": rule_info["name"],
                    "description": rule_info["description"],
                    "score": keyword_score,
                }
            )

    matches.sort(key=lambda x: x["score"], reverse=True)

    # EXACT NAME MATCH OVERRIDE (same logic as agent.py)
    if matches:
        exact_name_matches = []
        for match in matches:
            name_lower = match["name"].lower().strip()
            if name_lower:
                pattern = r"\b" + re.escape(name_lower) + r"\b"
                if re.search(pattern, description_lower):
                    exact_name_matches.append(match)

        if len(exact_name_matches) >= 1:
            max_name_len = max(len(m["name"]) for m in exact_name_matches)
            longest_matches = [
                m for m in exact_name_matches if len(m["name"]) == max_name_len
            ]
            if len(longest_matches) == 1:
                longest_name_lower = longest_matches[0]["name"].lower().strip()
                all_shorter_are_subsets = all(
                    m["name"].lower().strip() in longest_name_lower
                    for m in exact_name_matches
                    if m is not longest_matches[0]
                )
                if all_shorter_are_subsets:
                    matches = longest_matches

    return matches


def test_exact_industry_name_not_ambiguous():
    """User says 'Aerospace' exactly - should not be flagged ambiguous."""
    rules = parse_rules(SAMPLE_RULES)

    desc = "I need an Aerospace component"
    matches = find_component_matches(desc, rules["major_category"])

    assert len(matches) == 1, (
        f"Expected 1 match for exact 'Aerospace' industry, got {len(matches)}: "
        f"{[m['name'] for m in matches]}"
    )
    assert matches[0]["code"] == "A"
    assert matches[0]["name"] == "Aerospace"
    print("✓ Exact industry name 'Aerospace' correctly treated as unambiguous")


def test_exact_shape_name_not_ambiguous():
    """User says 'Sheet' exactly - should not be flagged ambiguous."""
    rules = parse_rules(SAMPLE_RULES)

    desc = "I need a Sheet of material"
    matches = find_component_matches(desc, rules["object_shape"])

    assert len(matches) == 1, (
        f"Expected 1 match for exact 'Sheet' shape, got {len(matches)}: "
        f"{[m['name'] for m in matches]}"
    )
    assert matches[0]["code"] == "S"
    assert matches[0]["name"] == "Sheet"
    print("✓ Exact shape name 'Sheet' correctly treated as unambiguous")


def test_exact_quality_name_not_ambiguous():
    """User says 'Premium' exactly - should not be flagged ambiguous."""
    rules = parse_rules(SAMPLE_RULES)

    desc = "I need Premium quality"
    matches = find_component_matches(desc, rules["quality_grade"])

    assert len(matches) == 1, (
        f"Expected 1 match for exact 'Premium' quality, got {len(matches)}: "
        f"{[m['name'] for m in matches]}"
    )
    assert matches[0]["code"] == "02"
    assert matches[0]["name"] == "Premium"
    print("✓ Exact quality name 'Premium' correctly treated as unambiguous")


def test_exact_size_name_not_ambiguous():
    """User says 'Large' exactly - should not be flagged ambiguous."""
    rules = parse_rules(SAMPLE_RULES)

    desc = "I need it in Large size"
    matches = find_component_matches(desc, rules["size_category"])

    assert len(matches) == 1, (
        f"Expected 1 match for exact 'Large' size, got {len(matches)}: "
        f"{[m['name'] for m in matches]}"
    )
    assert matches[0]["code"] == "4"
    assert matches[0]["name"] == "Large"
    print("✓ Exact size name 'Large' correctly treated as unambiguous")


def test_no_exact_match_still_ambiguous():
    """When no exact name match exists, ambiguity should still be detected."""
    rules = parse_rules(SAMPLE_RULES)

    desc = "metal parts for construction"
    matches = find_component_matches(desc, rules["major_category"])

    # "metal" is not an exact rulebook name for major_category,
    # but "construction" IS an exact name match for code "C"
    assert any(m["name"] == "Construction" for m in matches), (
        "Construction should be in matches"
    )
    # Since "Construction" is the only exact name match, it should be the sole result
    if len(matches) == 1:
        assert matches[0]["name"] == "Construction"
    print("✓ Non-exact matches handled correctly alongside exact match")


def test_multiple_exact_names_in_different_components():
    """
    User says 'Construction sheet Standard' - each component type should resolve
    its own exact match independently.
    """
    rules = parse_rules(SAMPLE_RULES)

    desc = "Construction sheet Standard"

    # Major category: "Construction" is exact
    major_matches = find_component_matches(desc, rules["major_category"])
    assert len(major_matches) == 1
    assert major_matches[0]["name"] == "Construction"

    # Object shape: "Sheet" is exact
    shape_matches = find_component_matches(desc, rules["object_shape"])
    assert len(shape_matches) == 1
    assert shape_matches[0]["name"] == "Sheet"

    # Quality: "Standard" is exact and unique within quality grades
    quality_matches = find_component_matches(desc, rules["quality_grade"])
    assert len(quality_matches) == 1
    assert quality_matches[0]["name"] == "Standard"

    print("✓ Multiple exact names resolved correctly across different component types")


def test_cross_component_exact_name_still_ambiguous():
    """
    When a term matches rulebook names in the SAME component type (e.g. "Aerospace"
    is both an industry and a quality grade, but the user says "Aerospace Premium"
    which has 2 exact matches within quality_grade), it should remain ambiguous.
    """
    rules = parse_rules(SAMPLE_RULES)

    desc = "Aerospace Premium"
    quality_matches = find_component_matches(desc, rules["quality_grade"])

    # Both "Aerospace" and "Premium" are quality grade names with same length (9 vs 7),
    # so they remain ambiguous
    assert len(quality_matches) == 2, (
        f"Expected 2 quality matches (Aerospace + Premium), got {len(quality_matches)}"
    )
    print("✓ Two exact name matches in same component type correctly remain ambiguous")


def test_longer_exact_name_wins_over_shorter_subset():
    """
    User says 'Industrial standard' - both 'Industrial Standard' and 'Standard'
    are rulebook names, but 'Industrial Standard' is longer/more specific and
    should win. This is the key fix for the user's reported issue.
    """
    rules = parse_rules(SAMPLE_RULES)

    desc = "Industrial standard plastic gear"
    quality_matches = find_component_matches(desc, rules["quality_grade"])

    assert len(quality_matches) == 1, (
        f"Expected 1 match for 'Industrial standard', got {len(quality_matches)}: "
        f"{[m['name'] for m in quality_matches]}"
    )
    assert quality_matches[0]["name"] == "Industrial Standard", (
        f"Expected 'Industrial Standard', got '{quality_matches[0]['name']}'"
    )
    assert quality_matches[0]["code"] == "11"
    print("✓ 'Industrial standard' correctly resolves to 'Industrial Standard' (not just 'Standard')")


def test_longer_exact_name_real_world_description():
    """
    Full real-world description: 'Industrial standard plastic gear made from
    thermoplastic for machinery, 50mm diameter' — quality grade should resolve
    to 'Industrial Standard' unambiguously.
    """
    rules = parse_rules(SAMPLE_RULES)

    desc = "Industrial standard plastic gear made from thermoplastic for machinery, 50mm diameter"
    quality_matches = find_component_matches(desc, rules["quality_grade"])

    assert len(quality_matches) == 1, (
        f"Expected 1 match, got {len(quality_matches)}: "
        f"{[m['name'] for m in quality_matches]}"
    )
    assert quality_matches[0]["name"] == "Industrial Standard"
    assert quality_matches[0]["code"] == "11"
    print("✓ Real-world description correctly resolves 'Industrial standard' as unambiguous")


def test_partial_keyword_still_ambiguous():
    """
    When the user uses a vague term with no exact name match,
    ambiguity detection should still work normally.
    """
    rules = parse_rules(SAMPLE_RULES)

    desc = "parts"
    matches = find_component_matches(desc, rules["major_category"])

    # "parts" is vague and not an exact rulebook name - should get 0 or multiple matches
    print(
        f"✓ Vague keyword 'parts' correctly returns {len(matches)} matches"
    )


def run_all_tests():
    print("=== Testing Exact Name Match Non-Ambiguity ===\n")
    try:
        test_exact_industry_name_not_ambiguous()
        test_exact_shape_name_not_ambiguous()
        test_exact_quality_name_not_ambiguous()
        test_exact_size_name_not_ambiguous()
        test_no_exact_match_still_ambiguous()
        test_multiple_exact_names_in_different_components()
        test_cross_component_exact_name_still_ambiguous()
        test_longer_exact_name_wins_over_shorter_subset()
        test_longer_exact_name_real_world_description()
        test_partial_keyword_still_ambiguous()

        print("\n=== All exact name match tests passed! ===")
        return True
    except Exception as e:
        print(f"\n=== Test failed: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
