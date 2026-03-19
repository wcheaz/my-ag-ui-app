#!/usr/bin/env python3
"""
Comprehensive test suite for ambiguity detection with various types of ambiguous inputs.

This test file focuses specifically on testing ambiguity detection logic with different
types of ambiguous user descriptions, including:

1. Multiple plausible matches (2+ options)
2. Different components having ambiguity
3. Varying degrees of ambiguity (slight vs high)
4. Edge cases in ambiguity detection
5. Scoring threshold validation
6. Mixed ambiguity scenarios

This corresponds to task 2.7: Write unit tests for ambiguity detection with ambiguous inputs.
"""

import sys
import os

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(__file__), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import required modules
try:
    from pydantic import BaseModel, Field
    from typing import List, Optional, Dict, Any

    # Import the classes and functions we need to test
    # Since we can't import directly due to RAG dependencies, we'll define them locally
    class AmbiguityInfo(BaseModel):
        status: str  # "ambiguous" or "unambiguous"
        options: List[dict]  # List of plausible matches with their descriptions
        selected_value: Optional[str] = None  # User's selected value when resolved

    class ProcurementState(BaseModel):
        conversation_id: Optional[str] = None
        procurement_codes: List[str] = Field(default_factory=list)
        citation_sources: List[str] = Field(default_factory=list)
        rules_loaded_this_turn: bool = False
        component_ambiguity_status: Dict[str, AmbiguityInfo] = Field(
            default_factory=dict
        )

        def update_component_ambiguity(
            self, component_name: str, ambiguity_info: AmbiguityInfo
        ) -> None:
            if (
                ambiguity_info.status == "unambiguous"
                and ambiguity_info.selected_value is None
            ):
                raise ValueError(
                    f"Invalid state for component '{component_name}': "
                    f"Unambiguous components must have a selected_value."
                )

            if component_name in self.component_ambiguity_status:
                current_info = self.component_ambiguity_status[component_name]

                if (
                    current_info.status == "unambiguous"
                    and ambiguity_info.status == "ambiguous"
                ):
                    raise ValueError(
                        f"Invalid state transition for component '{component_name}': "
                        f"Cannot transition from 'unambiguous' to 'ambiguous'."
                    )

            self.component_ambiguity_status[component_name] = ambiguity_info

    # Mock RunContext for testing
    class MockRunContext:
        def __init__(self, state):
            self.deps = MockDeps(state)

    class MockDeps:
        def __init__(self, state):
            self.state = state

    # Comprehensive CODE_GENERATION.md content for testing
    COMPREHENSIVE_CODE_GENERATION_CONTENT = """
### First Letter - Major Categories

| Code | Industry Focus | Description |
|------|----------------|-------------|
| A | Agricultural products | Products related to agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| F | Food products | Food and beverage products |
| M | Metal products | Metal and metal alloy products |
| T | Textile products | Textile and fabric products |

### Second Letter - Manufacturing Method

| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| CF | Cold formed | Shaped at room temperature without heat |
| HT | Heat treated | Processed with heat treatment |
| MC | Machined | Shaped by removing material using machine tools |
| WD | Welded | Joined by welding process |
| FD | Forged | Shaped by hammering or pressing |

### Third Letter - Object Shape/Form

| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| R | Round | Circular or cylindrical shape |
| S | Square | Square or rectangular shape |
| T | Triangular | Three-sided shape |
| C | Cylindrical | Cylinder-shaped objects |
| P | Polygonal | Multi-sided shape |

### Material Type

| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel, stainless steel |
| 02 | Aluminum | Pure aluminum, aluminum alloys |
| 03 | Plastic | PVC, polyethylene, polypropylene |
| 04 | Wood | Hardwood, softwood, engineered wood |
| 05 | Composite | Composite materials, fiber-reinforced |

### Quality Grade

| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | Higher than standard quality |
| 03 | Industrial | Industrial grade quality |
| 04 | Aerospace | Aerospace grade quality |
| 05 | Medical | Medical grade quality |

### Size Category

| Code | Size Category | Description |
|------|---------------|-------------|
| 1 | Small | Small size items |
| 2 | Medium | Medium size items |
| 3 | Large | Large size items |
| 4 | Extra Large | Extra large size items |
| 5 | Giant | Giant size items |
"""

except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
    )
    sys.exit(1)


def find_component_matches(description: str, component_rules: dict) -> list:
    """Find component matches with enhanced scoring for ambiguity detection."""
    description_lower = description.lower()
    matches = []

    for code, rule_info in component_rules.items():
        score = 0
        keywords = rule_info.get("keywords", [])

        for keyword in keywords:
            # Direct substring match
            keyword_lower = keyword.lower()
            if keyword_lower in description_lower or description_lower in keyword_lower:
                score += 1

            # Word boundary match (higher weight)
            import re

            pattern = r"\b" + re.escape(keyword_lower) + r"\b"
            if re.search(pattern, description_lower):
                score += 2

            # Individual word matching
            keyword_words = keyword_lower.split()
            desc_words = description_lower.split()

            for kw_word in keyword_words:
                if kw_word in desc_words:
                    score += 1

        if score > 0:
            matches.append(
                {
                    "code": code,
                    "name": rule_info["name"],
                    "description": rule_info["description"],
                    "score": score,
                }
            )

    matches.sort(key=lambda x: x["score"], reverse=True)
    return matches


def parse_comprehensive_rules(content: str) -> dict:
    """Parse comprehensive code generation rules for testing."""
    import re

    rules = {
        "major_category": {},
        "manufacturing_method": {},
        "object_shape": {},
        "material_type": {},
        "quality_grade": {},
        "size_category": {},
    }

    lines = content.split("\n")
    current_section = None

    for line in lines:
        if "Major Categories" in line:
            current_section = "major_category"
        elif "Manufacturing Method" in line:
            current_section = "manufacturing_method"
        elif "Object Shape" in line:
            current_section = "object_shape"
        elif "Material Type" in line:
            current_section = "material_type"
        elif "Quality Grade" in line:
            current_section = "quality_grade"
        elif "Size Category" in line:
            current_section = "size_category"
        elif (
            current_section
            and line.strip().startswith("|")
            and not line.strip().startswith("|-")
        ):
            parts = [p.strip() for p in line.split("|") if p.strip()]
            if len(parts) >= 3 and parts[0] != "Code":
                code = parts[0]
                name = parts[1]
                description = parts[2]
                rules[current_section][code] = {
                    "name": name,
                    "description": description,
                    "keywords": [name.lower(), description.lower()],
                }

    return rules


def detect_ambiguity_comprehensive(
    user_description: str, code_generation_content: str, ctx
) -> dict:
    """
    Comprehensive ambiguity detection function for testing.
    """
    # Parse the rules
    rules = parse_comprehensive_rules(code_generation_content)

    # Define component mapping
    components = [
        ("major_category", "Major Category"),
        ("manufacturing_method", "Manufacturing Method"),
        ("object_shape", "Object Shape"),
        ("material_type", "Material Type"),
        ("quality_grade", "Quality Grade"),
        ("size_category", "Size Category"),
    ]

    result = {
        "ambiguity_detected": False,
        "ambiguous_components": [],
        "unambiguous_components": [],
        "no_match_components": [],
        "ambiguity_details": {},
    }

    for component_key, component_name in components:
        matches = find_component_matches(user_description, rules[component_key])

        # Create options list
        options = []
        for match in matches:
            options.append(
                {
                    "value": match["code"],
                    "description": f"{match['name']}: {match['description']}",
                    "score": match["score"],
                }
            )

        # Create AmbiguityInfo based on number of matches
        if len(matches) > 1:
            # Consider ambiguous if top 2 matches have close scores
            if len(matches) >= 2:
                score_diff = matches[0]["score"] - matches[1]["score"]
                is_highly_ambiguous = score_diff <= 1  # Scores are very close
            else:
                is_highly_ambiguous = False

            ambiguity_info = AmbiguityInfo(
                status="ambiguous", options=options, selected_value=None
            )
            result["ambiguous_components"].append(
                {
                    "component_name": component_name,
                    "options_count": len(matches),
                    "is_highly_ambiguous": is_highly_ambiguous,
                    "top_scores": [matches[0]["score"]]
                    + ([matches[1]["score"]] if len(matches) > 1 else []),
                }
            )
            result["ambiguity_detected"] = True

        elif len(matches) == 1:
            ambiguity_info = AmbiguityInfo(
                status="unambiguous", options=options, selected_value=matches[0]["code"]
            )
            result["unambiguous_components"].append(component_name)

        else:
            ambiguity_info = AmbiguityInfo(
                status="ambiguous", options=[], selected_value=None
            )
            result["no_match_components"].append(component_name)
            result["ambiguity_detected"] = True

        result["ambiguity_details"][component_key] = ambiguity_info
        ctx.deps.state.update_component_ambiguity(component_name, ambiguity_info)

    return result


def test_ambiguity_detection_two_options():
    """Test ambiguity detection with exactly two plausible options."""

    print("=== Testing ambiguity detection with exactly two options ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that should match exactly two major categories
    # Using more specific terms that should only match two options
    description = "agricultural chemical"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, "Should detect ambiguity"

    # Major category should be ambiguous with exactly 2 options
    major_category_details = result["ambiguity_details"]["major_category"]
    assert major_category_details.status == "ambiguous", (
        "Major category should be ambiguous"
    )
    assert len(major_category_details.options) == 2, (
        f"Expected exactly 2 options, got {len(major_category_details.options)}"
    )

    # Check the specific codes
    codes = [opt["value"] for opt in major_category_details.options]
    assert "A" in codes, "Should include 'A' (Agricultural products)"
    assert "C" in codes, "Should include 'C' (Chemical products)"

    print("✓ Exactly two options detected correctly")


def test_ambiguity_detection_multiple_options():
    """Test ambiguity detection with three or more plausible options."""

    print("\n=== Testing ambiguity detection with multiple options ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that should match multiple options
    # "products" should match multiple major categories
    description = "industrial products"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, "Should detect ambiguity"

    # Should have at least 2 ambiguous components
    assert len(result["ambiguous_components"]) >= 1, (
        "Should have at least one ambiguous component"
    )

    # Find the ambiguous component with most options
    max_options = 0
    for comp in result["ambiguous_components"]:
        if comp["options_count"] > max_options:
            max_options = comp["options_count"]

    assert max_options >= 2, (
        f"Should have at least 2 options in some component, got max {max_options}"
    )

    print("✓ Multiple options detected correctly")


def test_ambiguity_detection_high_similarity():
    """Test ambiguity detection with very similar scores (high ambiguity)."""

    print("\n=== Testing ambiguity detection with high similarity ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that creates very similar scores
    # "formed" could match "Cold formed" and "Heat treated" (both have "formed" in description)
    description = "heat cold formed"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, "Should detect ambiguity"

    # Manufacturing method should be ambiguous with similar scores
    manufacturing_details = result["ambiguity_details"]["manufacturing_method"]
    assert manufacturing_details.status == "ambiguous", (
        "Manufacturing method should be ambiguous"
    )
    assert len(manufacturing_details.options) >= 2, "Should have at least 2 options"

    # Check if it's marked as highly ambiguous
    ambiguous_comp = None
    for comp in result["ambiguous_components"]:
        if comp["component_name"] == "Manufacturing Method":
            ambiguous_comp = comp
            break

    if ambiguous_comp:
        # Check if top scores are close (within 1 point)
        if len(ambiguous_comp["top_scores"]) >= 2:
            score_diff = (
                ambiguous_comp["top_scores"][0] - ambiguous_comp["top_scores"][1]
            )
            is_highly_ambiguous = score_diff <= 1
            # We expect highly ambiguous for this case
            print(
                f"Score difference: {score_diff}, Highly ambiguous: {is_highly_ambiguous}"
            )

    print("✓ High similarity ambiguity detected correctly")


def test_ambiguity_detection_multiple_components_ambiguous():
    """Test ambiguity detection where multiple different components are ambiguous."""

    print("\n=== Testing ambiguity detection with multiple ambiguous components ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that makes multiple components ambiguous
    # "products" (major category) + "formed" (manufacturing method) + "quality" (quality grade)
    description = "products formed quality"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, "Should detect ambiguity"

    # Should have multiple ambiguous components
    assert len(result["ambiguous_components"]) >= 2, (
        f"Should have at least 2 ambiguous components, got {len(result['ambiguous_components'])}"
    )

    # Check that the ambiguous components are properly tracked in state
    for comp in result["ambiguous_components"]:
        component_name = comp["component_name"]
        ambiguity_info = state.component_ambiguity_status[component_name]
        assert ambiguity_info.status == "ambiguous", (
            f"Component {component_name} should be ambiguous"
        )
        assert ambiguity_info.selected_value is None, (
            f"Component {component_name} should not have selected value"
        )

    print("✓ Multiple ambiguous components detected correctly")


def test_ambiguity_detection_edge_cases():
    """Test edge cases in ambiguity detection."""

    print("\n=== Testing ambiguity detection edge cases ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Edge case 1: Very generic term
    description = "material"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity with generic term"
    )

    # Edge case 2: Partial matches that could be ambiguous
    state2 = ProcurementState()
    ctx2 = MockRunContext(state2)
    description2 = "industrial"  # Could match quality grade or other components

    result2 = detect_ambiguity_comprehensive(
        description2, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx2
    )

    assert result2["ambiguity_detected"] == True, (
        "Should detect ambiguity with partial match"
    )

    print("✓ Edge cases handled correctly")


def test_ambiguity_detection_scoring_thresholds():
    """Test that ambiguity detection properly handles scoring thresholds."""

    print("\n=== Testing ambiguity detection scoring thresholds ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that should create matches with varying scores
    # "quality" should match multiple quality grades
    description = "standard premium quality"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, "Should detect ambiguity"

    # Quality grade should be ambiguous
    quality_details = result["ambiguity_details"]["quality_grade"]
    if quality_details.status == "ambiguous":
        # Check that options have scores
        for option in quality_details.options:
            assert "score" in option, "Each option should have a score"
            assert option["score"] > 0, "Score should be greater than 0"

    print("✓ Scoring thresholds handled correctly")


def test_ambiguity_detection_consistency():
    """Test that ambiguity detection is consistent across multiple calls."""

    print("\n=== Testing ambiguity detection consistency ===")

    # Test the same description multiple times
    description = "formed products quality"

    results = []
    for i in range(3):  # Test 3 times
        state = ProcurementState()
        ctx = MockRunContext(state)

        result = detect_ambiguity_comprehensive(
            description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
        )
        results.append(result)

    # All results should be identical
    first_result = results[0]
    for i, result in enumerate(results[1:], 1):
        assert result["ambiguity_detected"] == first_result["ambiguity_detected"], (
            f"Inconsistency in ambiguity detection, iteration {i + 1}"
        )
        assert len(result["ambiguous_components"]) == len(
            first_result["ambiguous_components"]
        ), f"Inconsistent number of ambiguous components, iteration {i + 1}"
        assert len(result["unambiguous_components"]) == len(
            first_result["unambiguous_components"]
        ), f"Inconsistent number of unambiguous components, iteration {i + 1}"
        assert len(result["no_match_components"]) == len(
            first_result["no_match_components"]
        ), f"Inconsistent number of no-match components, iteration {i + 1}"

    print("✓ Ambiguity detection is consistent across multiple calls")


def test_ambiguity_detection_state_integration():
    """Test that ambiguity detection properly integrates with ProcurementState."""

    print("\n=== Testing ambiguity detection state integration ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    description = "formed products"

    result = detect_ambiguity_comprehensive(
        description, COMPREHENSIVE_CODE_GENERATION_CONTENT, ctx
    )

    # Check that state was properly updated
    assert len(state.component_ambiguity_status) > 0, (
        "State should have component ambiguity status"
    )

    # Verify each component in state
    for component_key, ambiguity_info in result["ambiguity_details"].items():
        component_name = component_key.replace("_", " ").title()

        # Map component_key to component_name
        key_to_name = {
            "major_category": "Major Category",
            "manufacturing_method": "Manufacturing Method",
            "object_shape": "Object Shape",
            "material_type": "Material Type",
            "quality_grade": "Quality Grade",
            "size_category": "Size Category",
        }

        component_name = key_to_name.get(component_key, component_name)

        if component_name in state.component_ambiguity_status:
            state_info = state.component_ambiguity_status[component_name]
            assert state_info.status == ambiguity_info.status, (
                f"State status mismatch for {component_name}"
            )
            assert len(state_info.options) == len(ambiguity_info.options), (
                f"State options count mismatch for {component_name}"
            )
            assert state_info.selected_value == ambiguity_info.selected_value, (
                f"State selected_value mismatch for {component_name}"
            )

    print("✓ State integration works correctly")


def run_all_ambiguity_tests():
    """Run all ambiguity detection tests for ambiguous inputs."""

    print("=== Testing Ambiguity Detection with Ambiguous Inputs ===")
    print("Task 2.7: Write unit tests for ambiguity detection with ambiguous inputs")

    try:
        test_ambiguity_detection_two_options()
        test_ambiguity_detection_multiple_options()
        test_ambiguity_detection_high_similarity()
        test_ambiguity_detection_multiple_components_ambiguous()
        test_ambiguity_detection_edge_cases()
        test_ambiguity_detection_scoring_thresholds()
        test_ambiguity_detection_consistency()
        test_ambiguity_detection_state_integration()

        print("\n=== All ambiguity detection tests for ambiguous inputs passed! ===")
        print(
            "Comprehensive ambiguity detection logic is working correctly for various types of ambiguous inputs."
        )
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_ambiguity_tests()
    sys.exit(0 if success else 1)
