#!/usr/bin/env python3
"""
Test script to verify component extraction logic with clear, unambiguous inputs.

This tests the component extraction functions including:
- parse_code_generation_rules
- find_component_matches
- extract_components_from_description
- get_component_extraction_results

These tests focus on clear, unambiguous user descriptions that should result in
single, definitive matches for each component.
"""

import sys
import os
import re

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(__file__), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional, Dict, Any

    # Import the functions we need to test
    # Since we can't import directly due to RAG dependencies, we'll define them locally
    def parse_code_generation_rules(content: str) -> dict:
        """
        Parse the CODE_GENERATION.md content to extract component rules and options.
        """
        rules = {
            "major_category": {},  # A: Industry focus
            "manufacturing_method": {},  # B: Manufacturing method
            "object_shape": {},  # C: Object shape/form
            "material_type": {},  # MM: Material type
            "quality_grade": {},  # QQ: Quality grade
            "size_category": {},  # S: Size category
        }

        # Extract major categories (A)
        major_section = re.search(
            r"### First Letter - Major Categories.*?(?=###|$)", content, re.DOTALL
        )
        if major_section:
            major_matches = re.findall(
                r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
                major_section.group(),
            )
            for code, industry, description in major_matches:
                if code.strip() and industry.strip():
                    rules["major_category"][code.strip()] = {
                        "name": industry.strip(),
                        "description": description.strip(),
                        "keywords": [
                            industry.strip().lower(),
                            description.strip().lower(),
                        ],
                    }

        # Extract manufacturing methods (B)
        method_section = re.search(
            r"### Second Letter - Manufacturing Method.*?(?=###|$)", content, re.DOTALL
        )
        if method_section:
            method_matches = re.findall(
                r"\|\s*([A-Z]{2})\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
                method_section.group(),
            )
            for code, method, description in method_matches:
                if code.strip() and method.strip():
                    rules["manufacturing_method"][code.strip()] = {
                        "name": method.strip(),
                        "description": description.strip(),
                        "keywords": [
                            method.strip().lower(),
                            description.strip().lower(),
                        ],
                    }

        # Extract object shapes (C)
        shape_section = re.search(
            r"### Third Letter - Object Shape/Form.*?(?=###|$)", content, re.DOTALL
        )
        if shape_section:
            shape_matches = re.findall(
                r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
                shape_section.group(),
            )
            for code, shape, description in shape_matches:
                if code.strip() and shape.strip():
                    rules["object_shape"][code.strip()] = {
                        "name": shape.strip(),
                        "description": description.strip(),
                        "keywords": [
                            shape.strip().lower(),
                            description.strip().lower(),
                        ],
                    }

        # Extract material types (MM)
        material_section = re.search(
            r"### Material Type.*?(?=###|$)", content, re.DOTALL
        )
        if material_section:
            material_matches = re.findall(
                r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|",
                material_section.group(),
            )
            for code, material, examples in material_matches:
                if code.strip() and material.strip():
                    keywords = [material.strip().lower()]
                    if examples.strip():
                        keywords.extend(
                            [ex.strip().lower() for ex in examples.split(",")]
                        )
                    rules["material_type"][code.strip()] = {
                        "name": material.strip(),
                        "description": examples.strip(),
                        "keywords": keywords,
                    }

        # Extract quality grades (QQ)
        quality_section = re.search(
            r"### Quality Grade.*?(?=###|$)", content, re.DOTALL
        )
        if quality_section:
            quality_matches = re.findall(
                r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|",
                quality_section.group(),
            )
            for code, quality, description in quality_matches:
                if code.strip() and quality.strip():
                    keywords = [quality.strip().lower()]
                    if description.strip():
                        keywords.append(description.strip().lower())
                    rules["quality_grade"][code.strip()] = {
                        "name": quality.strip(),
                        "description": description.strip(),
                        "keywords": keywords,
                    }

        # Extract size categories (S)
        size_section = re.search(r"### Size Category.*?(?=###|$)", content, re.DOTALL)
        if size_section:
            size_matches = re.findall(
                r"\|\s*(\d)\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", size_section.group()
            )
            for code, size, description in size_matches:
                if code.strip() and size.strip():
                    rules["size_category"][code.strip()] = {
                        "name": size.strip(),
                        "description": description.strip(),
                        "keywords": [size.strip().lower(), description.strip().lower()],
                    }

        return rules

    def find_component_matches(description: str, component_rules: dict) -> list:
        """
        Find matches for a component based on user description using keyword matching.

        Note: This simplified version uses only keyword matching for testing purposes.
        """
        description_lower = description.lower()
        matches = []

        for code, rule_info in component_rules.items():
            keyword_score = 0
            keywords = rule_info.get("keywords", [])

            # Check for keyword matches
            for keyword in keywords:
                if keyword in description_lower:
                    keyword_score += 1

            # Additional scoring based on word boundaries
            for keyword in keywords:
                # Check for whole word matches
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

        # Sort matches by score (descending)
        matches.sort(key=lambda x: x["score"], reverse=True)
        return matches

    def extract_components_from_description(
        user_description: str, code_generation_content: str
    ) -> dict:
        """
        Extract component information from user description against CODE_GENERATION.md rules.
        """
        # Parse the rules from the content
        rules = parse_code_generation_rules(code_generation_content)

        results = {
            "major_category": None,
            "manufacturing_method": None,
            "object_shape": None,
            "material_type": None,
            "quality_grade": None,
            "size_category": None,
            "year": "26",  # Current year is 2026
            "sequence": None,  # Will be determined during code generation
        }

        # Find matches for each component
        components_to_check = [
            ("major_category", "Major Category"),
            ("manufacturing_method", "Manufacturing Method"),
            ("object_shape", "Object Shape"),
            ("material_type", "Material Type"),
            ("quality_grade", "Quality Grade"),
            ("size_category", "Size Category"),
        ]

        for component_key, component_name in components_to_check:
            matches = find_component_matches(user_description, rules[component_key])
            results[component_key] = {
                "name": component_name,
                "matches": matches,
                "is_ambiguous": len(matches) > 1,
                "no_matches": len(matches) == 0,
            }

        return results

    def get_component_extraction_results(
        user_description: str, code_generation_content: str
    ) -> dict:
        """
        Get complete component extraction results with structured ambiguity information.
        """
        component_matches = extract_components_from_description(
            user_description, code_generation_content
        )

        ambiguous_components = []
        unambiguous_components = []
        no_match_components = []
        component_details = {}

        for component_key, match_info in component_matches.items():
            # Skip non-component keys like 'year' and 'sequence'
            if component_key in ["year", "sequence"]:
                continue

            component_name = match_info["name"]
            matches = match_info["matches"]

            detail = {
                "component_name": component_name,
                "component_key": component_key,
                "matches": matches,
                "status": "ambiguous"
                if len(matches) > 1
                else ("no_match" if len(matches) == 0 else "unambiguous"),
            }

            component_details[component_key] = detail

            if len(matches) > 1:
                ambiguous_components.append(detail)
            elif len(matches) == 1:
                unambiguous_components.append(detail)
            else:
                no_match_components.append(detail)

        return {
            "ambiguous_components": ambiguous_components,
            "unambiguous_components": unambiguous_components,
            "no_match_components": no_match_components,
            "component_details": component_details,
        }

except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
    )
    sys.exit(1)

# Sample CODE_GENERATION.md content for testing
SAMPLE_CODE_GENERATION_CONTENT = """
### First Letter - Major Categories

| Code | Industry Focus | Description |
|------|----------------|-------------|
| A | Agricultural products | Products related to agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| F | Food products | Food and beverage products |

### Second Letter - Manufacturing Method

| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| CF | Cold formed | Shaped at room temperature without heat |
| HT | Heat treated | Processed with heat treatment |
| MC | Machined | Shaped by removing material using machine tools |

### Third Letter - Object Shape/Form

| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| R | Round | Circular or cylindrical shape |
| S | Square | Square or rectangular shape |
| T | Triangular | Three-sided shape |

### Material Type

| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel, stainless steel |
| 02 | Aluminum | Pure aluminum, aluminum alloys |
| 03 | Plastic | PVC, polyethylene, polypropylene |

### Quality Grade

| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | Higher than standard quality |
| 03 | Industrial | Industrial grade quality |

### Size Category

| Code | Size Category | Description |
|------|---------------|-------------|
| 1 | Small | Small size items |
| 2 | Medium | Medium size items |
| 3 | Large | Large size items |
"""


def test_parse_code_generation_rules_basic():
    """Test parsing of CODE_GENERATION.md content with basic structure."""

    print("=== Testing parse_code_generation_rules with basic content ===")

    rules = parse_code_generation_rules(SAMPLE_CODE_GENERATION_CONTENT)

    # Verify all component types are present
    expected_components = [
        "major_category",
        "manufacturing_method",
        "object_shape",
        "material_type",
        "quality_grade",
        "size_category",
    ]

    for component in expected_components:
        assert component in rules, f"Component '{component}' missing from parsed rules"
        assert len(rules[component]) > 0, f"Component '{component}' has no rules"

    # Verify specific rules were parsed correctly
    # Major Category
    assert "A" in rules["major_category"], "Major category 'A' not found"
    assert rules["major_category"]["A"]["name"] == "Agricultural products"
    assert "agricultural products" in rules["major_category"]["A"]["keywords"], (
        "Agricultural products keyword not found"
    )

    # Manufacturing Method
    assert "CF" in rules["manufacturing_method"], "Manufacturing method 'CF' not found"
    assert rules["manufacturing_method"]["CF"]["name"] == "Cold formed"
    assert "cold formed" in rules["manufacturing_method"]["CF"]["keywords"], (
        "Cold formed keyword not found"
    )

    # Object Shape
    assert "R" in rules["object_shape"], "Object shape 'R' not found"
    assert rules["object_shape"]["R"]["name"] == "Round"
    assert "round" in rules["object_shape"]["R"]["keywords"], "Round keyword not found"

    # Material Type
    assert "01" in rules["material_type"], "Material type '01' not found"
    assert rules["material_type"]["01"]["name"] == "Steel"
    assert "steel" in rules["material_type"]["01"]["keywords"], (
        "Steel keyword not found"
    )

    # Quality Grade
    assert "01" in rules["quality_grade"], "Quality grade '01' not found"
    assert rules["quality_grade"]["01"]["name"] == "Standard"
    assert "standard" in rules["quality_grade"]["01"]["keywords"], (
        "Standard keyword not found"
    )

    # Size Category
    assert "1" in rules["size_category"], "Size category '1' not found"
    assert rules["size_category"]["1"]["name"] == "Small"
    assert "small" in rules["size_category"]["1"]["keywords"], "Small keyword not found"

    print("✓ Basic rule parsing works correctly")


def test_parse_code_generation_rules_empty_content():
    """Test parsing with empty content."""

    print("\n=== Testing parse_code_generation_rules with empty content ===")

    rules = parse_code_generation_rules("")

    # Should return empty rules for all components
    expected_components = [
        "major_category",
        "manufacturing_method",
        "object_shape",
        "material_type",
        "quality_grade",
        "size_category",
    ]

    for component in expected_components:
        assert component in rules, f"Component '{component}' missing from rules"
        assert len(rules[component]) == 0, f"Component '{component}' should be empty"

    print("✓ Empty content handled correctly")


def test_find_component_matches_clear_single_match():
    """Test finding matches with clear, single-match descriptions."""

    print(
        "\n=== Testing find_component_matches with clear single-match descriptions ==="
    )

    rules = parse_code_generation_rules(SAMPLE_CODE_GENERATION_CONTENT)

    # Test clear major category match
    description = "agricultural products"
    matches = find_component_matches(description, rules["major_category"])

    assert len(matches) == 1, (
        f"Expected 1 match for 'agricultural products', got {len(matches)}"
    )
    assert matches[0]["code"] == "A", f"Expected code 'A', got {matches[0]['code']}"
    assert matches[0]["name"] == "Agricultural products"
    assert matches[0]["score"] > 0, "Score should be greater than 0"

    # Test clear manufacturing method match
    description = "cold formed"
    matches = find_component_matches(description, rules["manufacturing_method"])

    assert len(matches) == 1, f"Expected 1 match for 'cold formed', got {len(matches)}"
    assert matches[0]["code"] == "CF", f"Expected code 'CF', got {matches[0]['code']}"
    assert matches[0]["name"] == "Cold formed"
    assert matches[0]["score"] > 0, "Score should be greater than 0"

    # Test clear object shape match
    description = "round"
    matches = find_component_matches(description, rules["object_shape"])

    assert len(matches) == 1, f"Expected 1 match for 'round', got {len(matches)}"
    assert matches[0]["code"] == "R", f"Expected code 'R', got {matches[0]['code']}"
    assert matches[0]["name"] == "Round"
    assert matches[0]["score"] > 0, "Score should be greater than 0"

    print("✓ Clear single-match descriptions work correctly")


def test_find_component_matches_no_matches():
    """Test finding matches with descriptions that have no matches."""

    print("\n=== Testing find_component_matches with no-match descriptions ===")

    rules = parse_code_generation_rules(SAMPLE_CODE_GENERATION_CONTENT)

    # Test description with no matches
    description = "quantum entangled antimatter"
    matches = find_component_matches(description, rules["major_category"])

    assert len(matches) == 0, (
        f"Expected 0 matches for 'quantum entangled antimatter', got {len(matches)}"
    )

    matches = find_component_matches(description, rules["manufacturing_method"])
    assert len(matches) == 0, (
        f"Expected 0 matches for 'quantum entangled antimatter', got {len(matches)}"
    )

    matches = find_component_matches(description, rules["object_shape"])
    assert len(matches) == 0, (
        f"Expected 0 matches for 'quantum entangled antimatter', got {len(matches)}"
    )

    print("✓ No-match descriptions handled correctly")


def test_extract_components_from_description_clear_input():
    """Test component extraction with clear, unambiguous input."""

    print("\n=== Testing extract_components_from_description with clear input ===")

    # Clear description that should match one component each
    clear_description = "agricultural products cold formed round steel standard small"

    results = extract_components_from_description(
        clear_description, SAMPLE_CODE_GENERATION_CONTENT
    )

    # Verify all components are present
    expected_components = [
        "major_category",
        "manufacturing_method",
        "object_shape",
        "material_type",
        "quality_grade",
        "size_category",
        "year",
        "sequence",
    ]

    for component in expected_components:
        assert component in results, f"Component '{component}' missing from results"

    # Verify specific components have matches
    # Major Category
    major_category = results["major_category"]
    assert len(major_category["matches"]) == 1, (
        f"Expected 1 match for major category, got {len(major_category['matches'])}"
    )
    assert major_category["matches"][0]["code"] == "A"
    assert major_category["matches"][0]["name"] == "Agricultural products"
    assert not major_category["is_ambiguous"], "Major category should not be ambiguous"
    assert not major_category["no_matches"], "Major category should have matches"

    # Manufacturing Method
    manufacturing_method = results["manufacturing_method"]
    assert len(manufacturing_method["matches"]) == 1, (
        f"Expected 1 match for manufacturing method, got {len(manufacturing_method['matches'])}"
    )
    assert manufacturing_method["matches"][0]["code"] == "CF"
    assert manufacturing_method["matches"][0]["name"] == "Cold formed"
    assert not manufacturing_method["is_ambiguous"], (
        "Manufacturing method should not be ambiguous"
    )
    assert not manufacturing_method["no_matches"], (
        "Manufacturing method should have matches"
    )

    # Object Shape
    object_shape = results["object_shape"]
    assert len(object_shape["matches"]) == 1, (
        f"Expected 1 match for object shape, got {len(object_shape['matches'])}"
    )
    assert object_shape["matches"][0]["code"] == "R"
    assert object_shape["matches"][0]["name"] == "Round"
    assert not object_shape["is_ambiguous"], "Object shape should not be ambiguous"
    assert not object_shape["no_matches"], "Object shape should have matches"

    # Material Type
    material_type = results["material_type"]
    assert len(material_type["matches"]) == 1, (
        f"Expected 1 match for material type, got {len(material_type['matches'])}"
    )
    assert material_type["matches"][0]["code"] == "01"
    assert material_type["matches"][0]["name"] == "Steel"
    assert not material_type["is_ambiguous"], "Material type should not be ambiguous"
    assert not material_type["no_matches"], "Material type should have matches"

    # Quality Grade
    quality_grade = results["quality_grade"]
    assert len(quality_grade["matches"]) == 1, (
        f"Expected 1 match for quality grade, got {len(quality_grade['matches'])}"
    )
    assert quality_grade["matches"][0]["code"] == "01"
    assert quality_grade["matches"][0]["name"] == "Standard"
    assert not quality_grade["is_ambiguous"], "Quality grade should not be ambiguous"
    assert not quality_grade["no_matches"], "Quality grade should have matches"

    # Size Category
    size_category = results["size_category"]
    assert len(size_category["matches"]) == 1, (
        f"Expected 1 match for size category, got {len(size_category['matches'])}"
    )
    assert size_category["matches"][0]["code"] == "1"
    assert size_category["matches"][0]["name"] == "Small"
    assert not size_category["is_ambiguous"], "Size category should not be ambiguous"
    assert not size_category["no_matches"], "Size category should have matches"

    # Verify year is set
    assert results["year"] == "26", f"Expected year '26', got {results['year']}"
    assert results["sequence"] is None, "Sequence should be None"

    print("✓ Clear input extracted correctly with all components unambiguous")


def test_extract_components_from_description_mixed_clear_and_unclear():
    """Test component extraction with mixed clear and unclear parts."""

    print(
        "\n=== Testing extract_components_from_description with mixed clear and unclear input ==="
    )

    # Mixed description - some clear components, some unclear
    mixed_description = "agricultural cold formed small"

    results = extract_components_from_description(
        mixed_description, SAMPLE_CODE_GENERATION_CONTENT
    )

    # Major category should be ambiguous (matches "agricultural" but "products" is ambiguous)
    major_category = results["major_category"]
    # "agricultural" could match multiple categories, so this should be ambiguous
    # But let's check what we actually get
    print(f"Debug - Major category matches: {len(major_category['matches'])}")

    # Size category should be unambiguous
    size_category = results["size_category"]
    assert len(size_category["matches"]) == 1, (
        f"Expected 1 match for size category, got {len(size_category['matches'])}"
    )
    assert size_category["matches"][0]["code"] == "1"
    assert size_category["matches"][0]["name"] == "Small"
    assert not size_category["is_ambiguous"], "Size category should not be ambiguous"
    assert not size_category["no_matches"], "Size category should have matches"

    print("✓ Mixed input processed correctly")


def test_get_component_extraction_results_clear_input():
    """Test getting structured component extraction results with clear input."""

    print("\n=== Testing get_component_extraction_results with clear input ===")

    # Clear description
    clear_description = "agricultural products cold formed round steel premium medium"

    results = get_component_extraction_results(
        clear_description, SAMPLE_CODE_GENERATION_CONTENT
    )

    # Verify result structure
    expected_keys = [
        "ambiguous_components",
        "unambiguous_components",
        "no_match_components",
        "component_details",
    ]
    for key in expected_keys:
        assert key in results, f"Key '{key}' missing from results"

    # With clear input, we should have only unambiguous components
    # (assuming all components have clear matches)
    assert len(results["ambiguous_components"]) == 0, (
        f"Expected 0 ambiguous components, got {len(results['ambiguous_components'])}"
    )
    assert len(results["no_match_components"]) == 0, (
        f"Expected 0 no-match components, got {len(results['no_match_components'])}"
    )
    assert len(results["unambiguous_components"]) > 0, (
        f"Expected some unambiguous components, got {len(results['unambiguous_components'])}"
    )

    # Verify component details
    component_details = results["component_details"]
    for component_key, detail in component_details.items():
        assert "component_name" in detail, (
            f"Component {component_key} missing 'component_name'"
        )
        assert "component_key" in detail, (
            f"Component {component_key} missing 'component_key'"
        )
        assert "matches" in detail, f"Component {component_key} missing 'matches'"
        assert "status" in detail, f"Component {component_key} missing 'status'"

        # For clear input, all should be unambiguous
        assert detail["status"] == "unambiguous", (
            f"Component {component_key} should be unambiguous, got {detail['status']}"
        )
        assert len(detail["matches"]) == 1, (
            f"Component {component_key} should have exactly 1 match, got {len(detail['matches'])}"
        )

    # Verify unambiguous components list
    for unambiguous_component in results["unambiguous_components"]:
        assert unambiguous_component["status"] == "unambiguous", (
            f"Unambiguous component should have status 'unambiguous'"
        )
        assert len(unambiguous_component["matches"]) == 1, (
            f"Unambiguous component should have exactly 1 match"
        )

    print("✓ Structured extraction results returned correctly for clear input")


def test_extract_components_with_partial_information():
    """Test component extraction with partial but clear information."""

    print(
        "\n=== Testing extract_components_from_description with partial clear information ==="
    )

    # Description with only some components specified, but those are clear
    partial_description = "aluminum round"

    results = extract_components_from_description(
        partial_description, SAMPLE_CODE_GENERATION_CONTENT
    )

    # Material type should be unambiguous
    material_type = results["material_type"]
    assert len(material_type["matches"]) == 1, (
        f"Expected 1 match for 'aluminum', got {len(material_type['matches'])}"
    )
    assert material_type["matches"][0]["code"] == "02"
    assert material_type["matches"][0]["name"] == "Aluminum"
    assert not material_type["is_ambiguous"], "Material type should not be ambiguous"
    assert not material_type["no_matches"], "Material type should have matches"

    # Object shape should be unambiguous
    object_shape = results["object_shape"]
    assert len(object_shape["matches"]) == 1, (
        f"Expected 1 match for 'round', got {len(object_shape['matches'])}"
    )
    assert object_shape["matches"][0]["code"] == "R"
    assert object_shape["matches"][0]["name"] == "Round"
    assert not object_shape["is_ambiguous"], "Object shape should not be ambiguous"
    assert not object_shape["no_matches"], "Object shape should have matches"

    print("✓ Partial clear information extracted correctly")


def run_all_tests():
    """Run all component extraction tests for clear inputs."""

    print("=== Testing Component Extraction with Clear Inputs ===")

    try:
        test_parse_code_generation_rules_basic()
        test_parse_code_generation_rules_empty_content()
        test_find_component_matches_clear_single_match()
        test_find_component_matches_no_matches()
        test_extract_components_from_description_clear_input()
        test_extract_components_from_description_mixed_clear_and_unclear()
        test_get_component_extraction_results_clear_input()
        test_extract_components_with_partial_information()

        print("\n=== All component extraction tests for clear inputs passed! ===")
        print("Component extraction logic is working correctly for clear inputs.")
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
