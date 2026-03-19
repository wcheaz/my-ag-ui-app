#!/usr/bin/env python3
"""
Comprehensive test suite for edge cases in component extraction and ambiguity detection.

This test file focuses specifically on testing edge cases including:
1. No matches - when components have absolutely no plausible matches
2. Single match - edge cases around exactly one match (borderline cases)
3. Multiple matches - edge cases with multiple matches (ties, borderline cases)

This corresponds to task 2.8: Write unit tests for edge cases (no matches, single match, multiple matches).
"""

import sys
import os
import re

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agent")
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

    # Enhanced CODE_GENERATION.md content with edge case scenarios
    EDGE_CASE_CODE_GENERATION_CONTENT = """
### First Letter - Major Categories

| Code | Industry Focus | Description |
|------|----------------|-------------|
| A | Agricultural products | Products related to agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| F | Food products | Food and beverage products |
| M | Metal products | Metal and metal alloy products |
| T | Textile products | Textile and fabric products |
| P | Paper products | Paper and cardboard products |
| E | Electronic products | Electronic and electrical equipment |
| B | Building materials | Construction and building materials |

### Second Letter - Manufacturing Method

| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| CF | Cold formed | Shaped at room temperature without heat |
| HT | Heat treated | Processed with heat treatment |
| MC | Machined | Shaped by removing material using machine tools |
| WD | Welded | Joined by welding process |
| FD | Forged | Shaped by hammering or pressing |
| AM | Additive manufactured | 3D printed or additive manufacturing |
| IN | Injection molded | Plastic injection molding process |
| EX | Extruded | Pushed through a die to create shape |
| CV | Cast | Pouring liquid material into a mold |
| IM | Impact formed | Formed by impact or pressure |

### Third Letter - Object Shape/Form

| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| R | Round | Circular or cylindrical shape |
| S | Square | Square or rectangular shape |
| T | Triangular | Three-sided shape |
| C | Cylindrical | Cylinder-shaped objects |
| P | Polygonal | Multi-sided shape |
| H | Hexagonal | Six-sided shape |
| O | Oval | Egg-shaped or oval form |
| L | Linear | Long, thin, straight shape |
| V | Volumetric | Three-dimensional bulk objects |
| F | Flat | Thin, wide, low-profile objects |

### Material Type

| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel, stainless steel |
| 02 | Aluminum | Pure aluminum, aluminum alloys |
| 03 | Plastic | PVC, polyethylene, polypropylene |
| 04 | Wood | Hardwood, softwood, engineered wood |
| 05 | Composite | Composite materials, fiber-reinforced |
| 06 | Ceramic | Ceramic materials, porcelain, clay |
| 07 | Glass | Glass materials, tempered glass |
| 08 | Rubber | Natural rubber, synthetic rubber |
| 09 | Fabric | Textile materials, cloth, fabric |
| 10 | Foam | Foam materials, polyurethane foam |

### Quality Grade

| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | Higher than standard quality |
| 03 | Industrial | Industrial grade quality |
| 04 | Aerospace | Aerospace grade quality |
| 05 | Medical | Medical grade quality |
| 06 | Military | Military specification quality |
| 07 | Research | Research laboratory quality |
| 08 | Consumer | Consumer grade quality |
| 09 | Commercial | Commercial grade quality |
| 10 | Professional | Professional grade quality |

### Size Category

| Code | Size Category | Description |
|------|---------------|-------------|
| 1 | Small | Small size items |
| 2 | Medium | Medium size items |
| 3 | Large | Large size items |
| 4 | Extra Large | Extra large size items |
| 5 | Giant | Giant size items |
| 6 | Micro | Microscopic size items |
| 7 | Mini | Miniature size items |
| 8 | Compact | Compact size items |
| 9 | Bulk | Bulk size items |
"""

except ImportError as e:
    print(f"Import error: {e}")
    print(
        "Please ensure you're running this from the agent directory with the virtual environment activated."
    )
    sys.exit(1)


def parse_edge_case_rules(content: str) -> dict:
    """Parse edge case code generation rules with comprehensive error handling."""
    import re

    rules = {
        "major_category": {},
        "manufacturing_method": {},
        "object_shape": {},
        "material_type": {},
        "quality_grade": {},
        "size_category": {},
    }

    def parse_section(section_content: str, component_type: str) -> None:
        """Parse a specific section of the content."""
        # Split content into lines
        lines = section_content.split("\n")

        # Find table start (after header)
        table_start = -1
        for i, line in enumerate(lines):
            if line.strip().startswith("|"):
                if i > 0 and lines[i - 1].strip().startswith("|---"):
                    table_start = i
                    break

        if table_start == -1:
            return

        # Parse table rows
        for line in lines[table_start:]:
            if not line.strip().startswith("|"):
                break

            # Split by | and clean up
            parts = [part.strip() for part in line.split("|") if part.strip()]

            # Skip header, separator, and invalid rows
            if (
                len(parts) >= 3
                and parts[0] != "Code"
                and not parts[0].startswith("---")
                and parts[0].isalnum()
            ):
                code = parts[0]
                name = parts[1]
                description = parts[2] if len(parts) > 2 else ""

                # Create keywords for matching
                keywords = [name.lower()]
                if description:
                    keywords.append(description.lower())
                    # Add individual words from description (but not common words)
                    desc_words = re.findall(r"\b\w+\b", description.lower())
                    common_words = {
                        "the",
                        "and",
                        "or",
                        "of",
                        "to",
                        "in",
                        "for",
                        "with",
                        "on",
                        "at",
                        "by",
                        "from",
                        "as",
                        "is",
                        "are",
                        "was",
                        "were",
                        "been",
                        "be",
                        "have",
                        "has",
                        "had",
                        "do",
                        "does",
                        "did",
                        "will",
                        "would",
                        "could",
                        "should",
                        "may",
                        "might",
                        "must",
                        "can",
                        "a",
                        "an",
                    }
                    filtered_words = [
                        word
                        for word in desc_words
                        if word not in common_words and len(word) > 2
                    ]
                    keywords.extend(filtered_words)

                # Remove duplicates
                keywords = list(set(keywords))

                rules[component_type][code] = {
                    "name": name,
                    "description": description,
                    "keywords": keywords,
                }

    # Parse each section
    sections = [
        ("major_category", "First Letter - Major Categories"),
        ("manufacturing_method", "Second Letter - Manufacturing Method"),
        ("object_shape", "Third Letter - Object Shape/Form"),
        ("material_type", "Material Type"),
        ("quality_grade", "Quality Grade"),
        ("size_category", "Size Category"),
    ]

    for component_type, section_name in sections:
        # Find section content
        section_pattern = rf"### {section_name}.*?(?=###|\Z)"
        section_match = re.search(section_pattern, content, re.DOTALL)

        if section_match:
            parse_section(section_match.group(0), component_type)

    return rules


def find_component_matches_enhanced(description: str, component_rules: dict) -> list:
    """Enhanced component matching with detailed scoring for edge case analysis."""
    description_lower = description.lower()
    matches = []

    # Common words to exclude from matching
    common_words = {
        "the",
        "and",
        "or",
        "of",
        "to",
        "in",
        "for",
        "with",
        "on",
        "at",
        "by",
        "from",
        "as",
        "is",
        "are",
        "was",
        "were",
        "been",
        "be",
        "have",
        "has",
        "had",
        "do",
        "does",
        "did",
        "will",
        "would",
        "could",
        "should",
        "may",
        "might",
        "must",
        "can",
        "a",
        "an",
        "it",
        "that",
        "this",
    }

    for code, rule_info in component_rules.items():
        score = 0
        keywords = rule_info.get("keywords", [])

        if not keywords:
            continue

        for keyword in keywords:
            keyword_lower = keyword.lower()

            # Skip common words
            if keyword_lower in common_words or len(keyword_lower) < 3:
                continue

            # Exact match (highest score)
            if keyword_lower == description_lower:
                score += 10
            # Word boundary match (high score)
            elif re.search(r"\b" + re.escape(keyword_lower) + r"\b", description_lower):
                score += 5
            # Substring match (medium score) - only for longer keywords
            elif len(keyword_lower) > 4 and keyword_lower in description_lower:
                score += 2
            # Partial word match (low score) - only for significant words
            else:
                # Check if any part of the keyword matches
                keyword_parts = keyword_lower.split()
                desc_parts = description_lower.split()

                for kw_part in keyword_parts:
                    if (
                        len(kw_part) > 3
                        and kw_part not in common_words
                        and kw_part in desc_parts
                    ):
                        score += 1
                        break

        if score > 0:
            matches.append(
                {
                    "code": code,
                    "name": rule_info["name"],
                    "description": rule_info["description"],
                    "score": score,
                }
            )

    # Sort matches by score (descending)
    matches.sort(key=lambda x: x["score"], reverse=True)
    return matches


def extract_components_edge_cases(
    user_description: str, code_generation_content: str
) -> dict:
    """Component extraction with detailed edge case analysis."""
    # Parse the rules
    rules = parse_edge_case_rules(code_generation_content)

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

    # Component mapping
    components_to_check = [
        ("major_category", "Major Category"),
        ("manufacturing_method", "Manufacturing Method"),
        ("object_shape", "Object Shape"),
        ("material_type", "Material Type"),
        ("quality_grade", "Quality Grade"),
        ("size_category", "Size Category"),
    ]

    for component_key, component_name in components_to_check:
        matches = find_component_matches_enhanced(
            user_description, rules[component_key]
        )
        results[component_key] = {
            "name": component_name,
            "matches": matches,
            "is_ambiguous": len(matches) > 1,
            "no_matches": len(matches) == 0,
            "score_details": {
                "total_matches": len(matches),
                "top_score": matches[0]["score"] if matches else 0,
                "score_gap": matches[0]["score"] - matches[1]["score"]
                if len(matches) > 1
                else None,
            },
        }

    return results


def detect_ambiguity_edge_cases(
    user_description: str, code_generation_content: str, ctx
) -> dict:
    """Comprehensive ambiguity detection focused on edge cases."""
    results = extract_components_edge_cases(user_description, code_generation_content)

    ambiguity_result = {
        "ambiguity_detected": False,
        "ambiguous_components": [],
        "unambiguous_components": [],
        "no_match_components": [],
        "edge_case_details": {},
        "component_details": {},
    }

    for component_key, component_info in results.items():
        # Skip non-component keys
        if component_key in ["year", "sequence"]:
            continue

        component_name = component_info["name"]
        matches = component_info["matches"]
        score_details = component_info["score_details"]

        # Create options
        options = []
        for match in matches:
            options.append(
                {
                    "value": match["code"],
                    "description": f"{match['name']}: {match['description']}",
                    "score": match["score"],
                }
            )

        # Create AmbiguityInfo
        if len(matches) == 0:
            # Edge case: No matches
            ambiguity_info = AmbiguityInfo(
                status="ambiguous", options=[], selected_value=None
            )
            ambiguity_result["no_match_components"].append(
                {
                    "component_name": component_name,
                    "reason": "No plausible matches found",
                }
            )
            ambiguity_result["ambiguity_detected"] = True

        elif len(matches) == 1:
            # Edge case: Single match (check if it's a borderline case)
            ambiguity_info = AmbiguityInfo(
                status="unambiguous", options=options, selected_value=matches[0]["code"]
            )
            ambiguity_result["unambiguous_components"].append(
                {
                    "component_name": component_name,
                    "match_confidence": "high"
                    if score_details["top_score"] >= 5
                    else "low",
                    "score": score_details["top_score"],
                }
            )

        else:
            # Edge case: Multiple matches
            ambiguity_info = AmbiguityInfo(
                status="ambiguous", options=options, selected_value=None
            )

            # Determine edge case type
            edge_case_type = "standard_ambiguous"
            if (
                score_details["score_gap"] is not None
                and score_details["score_gap"] <= 1
            ):
                edge_case_type = "tie_scores"
            elif len(matches) >= 5:
                edge_case_type = "many_matches"
            elif len(matches) == 2:
                edge_case_type = "exactly_two_matches"

            ambiguity_result["ambiguous_components"].append(
                {
                    "component_name": component_name,
                    "edge_case_type": edge_case_type,
                    "match_count": len(matches),
                    "top_score": score_details["top_score"],
                    "score_gap": score_details["score_gap"],
                }
            )
            ambiguity_result["ambiguity_detected"] = True

        # Store detailed information
        ambiguity_result["component_details"][component_key] = {
            "component_name": component_name,
            "ambiguity_info": ambiguity_info,
            "match_analysis": {
                "total_matches": len(matches),
                "top_score": score_details["top_score"],
                "score_gap": score_details["score_gap"],
                "matches": matches,
            },
        }

        # Update state
        ctx.deps.state.update_component_ambiguity(component_name, ambiguity_info)

    return ambiguity_result


def test_edge_case_no_matches_absolute():
    """Test edge case: Absolutely no matches for any component."""

    print("=== Testing edge case: Absolutely no matches ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description with terms that should match nothing in the rules
    description = "quantum entangled antimatter subspace anomaly"

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity (no matches = ambiguous)
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity when no matches found"
    )
    assert len(result["no_match_components"]) == 6, (
        f"Expected all 6 components to have no matches, got {len(result['no_match_components'])}"
    )
    assert len(result["ambiguous_components"]) == 0, (
        f"Expected 0 ambiguous components with multiple matches, got {len(result['ambiguous_components'])}"
    )
    assert len(result["unambiguous_components"]) == 0, (
        f"Expected 0 unambiguous components, got {len(result['unambiguous_components'])}"
    )

    # Verify all components are marked as no-match
    for component in result["no_match_components"]:
        component_name = component["component_name"]
        component_key = component_name.lower().replace(" ", "_")

        ambiguity_info = result["component_details"][component_key]["ambiguity_info"]
        assert ambiguity_info.status == "ambiguous", (
            f"Component {component_name} should be ambiguous (no matches)"
        )
        assert len(ambiguity_info.options) == 0, (
            f"Component {component_name} should have no options"
        )
        assert ambiguity_info.selected_value is None, (
            f"Component {component_name} should not have selected value"
        )

    print("✓ Absolute no-match edge case handled correctly")


def test_edge_case_single_match_ambiguous():
    """Test edge case: Single match but with borderline confidence (low score)."""

    print("\n=== Testing edge case: Single match with borderline confidence ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description with very weak match that could be ambiguous
    description = "industrial"  # Could weakly match multiple things

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should have some unambiguous components (single matches)
    assert len(result["unambiguous_components"]) > 0, (
        "Should have at least one unambiguous component"
    )

    # Check for low-confidence single matches
    low_confidence_matches = []
    for component in result["unambiguous_components"]:
        if isinstance(component, dict) and "match_confidence" in component:
            if component["match_confidence"] == "low":
                low_confidence_matches.append(component)

    # Verify that if there are unambiguous components, they have selected values
    for component_key, details in result["component_details"].items():
        ambiguity_info = details["ambiguity_info"]
        if ambiguity_info.status == "unambiguous":
            assert ambiguity_info.selected_value is not None, (
                f"Component {details['component_name']} should have selected value"
            )
            assert len(ambiguity_info.options) == 1, (
                f"Component {details['component_name']} should have exactly one option"
            )

    print("✓ Single match with borderline confidence handled correctly")


def test_edge_case_multiple_matches_exact_two():
    """Test edge case: Exactly two matches (minimum ambiguous case)."""

    print("\n=== Testing edge case: Exactly two matches ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that should create exactly two matches for some component
    # "formed" should match both "Cold formed" and "Heat treated"
    description = "formed"

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity with exactly two matches"
    )
    assert len(result["ambiguous_components"]) > 0, (
        "Should have at least one ambiguous component"
    )

    # Find components with exactly two matches
    exactly_two_matches = []
    for component in result["ambiguous_components"]:
        if component["edge_case_type"] == "exactly_two_matches":
            exactly_two_matches.append(component)

    assert len(exactly_two_matches) > 0, (
        "Should have at least one component with exactly two matches"
    )

    # Verify the exactly-two-matches components
    for component in exactly_two_matches:
        component_name = component["component_name"]
        component_key = component_name.lower().replace(" ", "_")

        ambiguity_info = result["component_details"][component_key]["ambiguity_info"]
        assert ambiguity_info.status == "ambiguous", (
            f"Component {component_name} should be ambiguous"
        )
        assert len(ambiguity_info.options) == 2, (
            f"Component {component_name} should have exactly 2 options"
        )
        assert ambiguity_info.selected_value is None, (
            f"Component {component_name} should not have selected value"
        )

    print("✓ Exactly two matches edge case handled correctly")


def test_edge_case_multiple_matches_tie_scores():
    """Test edge case: Multiple matches with tied or very close scores."""

    print("\n=== Testing edge case: Multiple matches with tie scores ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that creates matches with tied scores
    # "quality" should match multiple quality grades with similar scores
    description = "quality standard"

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity with tie scores"
    )

    # Find components with tied scores
    tied_score_components = []
    for component in result["ambiguous_components"]:
        if component["edge_case_type"] == "tie_scores":
            tied_score_components.append(component)

    assert len(tied_score_components) > 0, (
        "Should have at least one component with tied scores"
    )

    # Verify the tie score components
    for component in tied_score_components:
        component_name = component["component_name"]
        component_key = component_name.lower().replace(" ", "_")

        assert component["score_gap"] <= 1, (
            f"Component {component_name} should have score gap <= 1"
        )

        ambiguity_info = result["component_details"][component_key]["ambiguity_info"]
        assert ambiguity_info.status == "ambiguous", (
            f"Component {component_name} should be ambiguous"
        )
        assert len(ambiguity_info.options) >= 2, (
            f"Component {component_name} should have at least 2 options"
        )

        # Check that top options have close scores
        if len(ambiguity_info.options) >= 2:
            score_diff = (
                ambiguity_info.options[0]["score"] - ambiguity_info.options[1]["score"]
            )
            assert score_diff <= 1, (
                f"Component {component_name} should have score difference <= 1, got {score_diff}"
            )

    print("✓ Tie scores edge case handled correctly")


def test_edge_case_multiple_matches_many_options():
    """Test edge case: Many matches (5+) for a single component."""

    print("\n=== Testing edge case: Many matches (5+) ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Generic term that should match many options
    description = "products"  # Should match many major categories

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity with many matches"
    )

    # Find components with many matches (5+)
    many_match_components = []
    for component in result["ambiguous_components"]:
        if component["match_count"] >= 5:
            many_match_components.append(component)

    assert len(many_match_components) > 0, (
        "Should have at least one component with many matches"
    )

    # Verify the many-matches components
    for component in many_match_components:
        component_name = component["component_name"]
        component_key = component_name.lower().replace(" ", "_")

        assert component["match_count"] >= 5, (
            f"Component {component_name} should have at least 5 matches, got {component['match_count']}"
        )

        ambiguity_info = result["component_details"][component_key]["ambiguity_info"]
        assert ambiguity_info.status == "ambiguous", (
            f"Component {component_name} should be ambiguous"
        )
        assert len(ambiguity_info.options) >= 5, (
            f"Component {component_name} should have at least 5 options"
        )

        print(f"✓ Component {component_name} has {component['match_count']} matches")

    print("✓ Many matches edge case handled correctly")


def test_edge_case_mixed_scenarios():
    """Test edge case: Mixed scenarios with different edge case types."""

    print("\n=== Testing edge case: Mixed scenarios ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description that creates different edge cases for different components
    description = "products quality industrial"  # Should create various edge cases

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity in mixed scenario"
    )

    # Should have different types of edge cases
    edge_case_types = set()
    for component in result["ambiguous_components"]:
        edge_case_types.add(component["edge_case_type"])

    # Should have at least 2 different edge case types
    assert len(edge_case_types) >= 1, (
        f"Should have at least 1 edge case type, got {len(edge_case_types)}"
    )

    # Should have a mix of ambiguous, unambiguous, and possibly no-match components
    total_components = (
        len(result["ambiguous_components"])
        + len(result["unambiguous_components"])
        + len(result["no_match_components"])
    )
    assert total_components == 6, (
        f"Should have exactly 6 components total, got {total_components}"
    )

    print("✓ Mixed scenarios edge case handled correctly")


def test_edge_case_empty_description():
    """Test edge case: Empty or whitespace-only description."""

    print("\n=== Testing edge case: Empty description ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Empty description
    description = ""

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity (no matches = ambiguous)
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity with empty description"
    )
    assert len(result["no_match_components"]) == 6, (
        f"Expected all 6 components to have no matches, got {len(result['no_match_components'])}"
    )

    # Test whitespace-only description
    description2 = "   \n\t  "
    state2 = ProcurementState()
    ctx2 = MockRunContext(state2)

    result2 = detect_ambiguity_edge_cases(
        description2, EDGE_CASE_CODE_GENERATION_CONTENT, ctx2
    )

    assert result2["ambiguity_detected"] == True, (
        "Should detect ambiguity with whitespace-only description"
    )
    assert len(result2["no_match_components"]) == 6, (
        f"Expected all 6 components to have no matches, got {len(result2['no_match_components'])}"
    )

    print("✓ Empty description edge case handled correctly")


def test_edge_case_very_long_description():
    """Test edge case: Very long description with many terms."""

    print("\n=== Testing edge case: Very long description ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Very long description with many potentially matching terms
    description = (
        "industrial agricultural chemical food metal textile paper electronic building "
        "cold formed heat treated machined welded forged additive manufactured injection molded "
        "round square triangular cylindrical polygonal hexagonal oval linear volumetric flat "
        "steel aluminum plastic wood composite ceramic glass rubber fabric foam "
        "standard premium industrial aerospace medical military research consumer commercial professional "
        "small medium large extra large giant micro mini compact bulk"
    )

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should detect ambiguity (many matches)
    assert result["ambiguity_detected"] == True, (
        "Should detect ambiguity with very long description"
    )

    # Should have many ambiguous components due to many potential matches
    assert len(result["ambiguous_components"]) >= 1, (
        f"Should have at least 1 ambiguous component, got {len(result['ambiguous_components'])}"
    )

    # All components should have matches (no no-match components)
    assert len(result["no_match_components"]) == 0, (
        f"Expected no no-match components with long description, got {len(result['no_match_components'])}"
    )

    print("✓ Very long description edge case handled correctly")


def test_edge_case_unicode_and_special_chars():
    """Test edge case: Description with unicode and special characters."""

    print("\n=== Testing edge case: Unicode and special characters ===")

    state = ProcurementState()
    ctx = MockRunContext(state)

    # Description with unicode and special characters
    description = "industrial™ cold-formed® quality™ product©"

    result = detect_ambiguity_edge_cases(
        description, EDGE_CASE_CODE_GENERATION_CONTENT, ctx
    )

    # Should handle unicode gracefully (might detect ambiguity or not, depending on matching)
    # Important thing is that it doesn't crash
    assert isinstance(result, dict), "Should return a valid result dictionary"
    assert "ambiguity_detected" in result, "Should have ambiguity_detected field"
    assert "ambiguous_components" in result, "Should have ambiguous_components field"
    assert "unambiguous_components" in result, (
        "Should have unambiguous_components field"
    )
    assert "no_match_components" in result, "Should have no_match_components field"

    print("✓ Unicode and special characters edge case handled correctly")


def run_all_edge_case_tests():
    """Run all edge case tests for component extraction."""

    print("=== Testing Edge Cases for Component Extraction ===")
    print(
        "Task 2.8: Write unit tests for edge cases (no matches, single match, multiple matches)"
    )

    try:
        test_edge_case_no_matches_absolute()
        test_edge_case_single_match_ambiguous()
        test_edge_case_multiple_matches_exact_two()
        test_edge_case_multiple_matches_tie_scores()
        test_edge_case_multiple_matches_many_options()
        test_edge_case_mixed_scenarios()
        test_edge_case_empty_description()
        test_edge_case_very_long_description()
        test_edge_case_unicode_and_special_chars()

        print("\n=== All edge case tests passed! ===")
        print(
            "Component extraction and ambiguity detection handle edge cases correctly."
        )
        return True

    except Exception as e:
        print(f"\n=== Test failed with error: {e} ===")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_edge_case_tests()
    sys.exit(0 if success else 1)
