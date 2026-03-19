#!/usr/bin/env python3
"""
Debug script to understand how the component extraction works and why tests are failing.
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

    def parse_debug_rules(content: str) -> dict:
        """Debug version of rule parsing."""
        rules = {
            "manufacturing_method": {},
        }

        def parse_section(section_content: str, component_type: str) -> None:
            """Parse a specific section of the content."""
            print(f"Debug - Parsing section content:")
            print(f"Debug - Section content: {section_content[:200]}...")

            # Find all table rows (skip header and separator)
            row_pattern = (
                r"\|\s*([^\s|]+)\s*\|\s*([^\s|]+)\s*\|\s*([^\s|]+(?:\s+[^\s|]*)*)\s*\|"
            )
            matches = re.findall(row_pattern, section_content)

            print(f"Debug - Found {len(matches)} row matches:")
            for i, match in enumerate(matches):
                print(f"Debug - Match {i}: {match}")

            for code, name, description in matches:
                if code and code.strip() and not code.startswith("-"):
                    print(f"Debug - Adding rule: {code} -> {name}")
                    # Create keywords for matching
                    keywords = [name.strip().lower()]
                    if description.strip():
                        keywords.append(description.strip().lower())
                        # Add individual words from description
                        desc_words = re.findall(r"\b\w+\b", description.strip().lower())
                        keywords.extend(desc_words)

                    # Remove duplicates
                    keywords = list(set(keywords))

                    rules[component_type][code.strip()] = {
                        "name": name.strip(),
                        "description": description.strip(),
                        "keywords": keywords,
                    }

        # Parse manufacturing method section
        print(f"Debug - Full content: {repr(content)}")
        section_pattern = r"### Second Letter - Manufacturing Method.*?(?=###|\Z)"
        section_match = re.search(section_pattern, content, re.DOTALL)

        print(f"Debug - Section pattern: {section_pattern}")
        print(f"Debug - Section match found: {section_match is not None}")

        if section_match:
            print(f"Debug - Full section content: {repr(section_match.group(0))}")
            parse_section(section_match.group(0), "manufacturing_method")
        else:
            # Try alternative pattern
            section_pattern2 = r"### Manufacturing Method.*?(?=###|$)"
            section_match2 = re.search(section_pattern2, content, re.DOTALL)
            print(f"Debug - Alternative pattern match: {section_match2 is not None}")
            if section_match2:
                print(
                    f"Debug - Alternative section content: {repr(section_match2.group(0))}"
                )
                parse_section(section_match2.group(0), "manufacturing_method")

        return rules

    def find_component_matches_debug(description: str, component_rules: dict) -> list:
        """Debug version of component matching."""
        description_lower = description.lower()
        matches = []

        print(f"Debug - Searching for matches in: '{description_lower}'")

        for code, rule_info in component_rules.items():
            score = 0
            keywords = rule_info.get("keywords", [])

            print(f"Debug - Checking code {code}: {rule_info['name']}")
            print(f"Debug - Keywords: {keywords}")

            for keyword in keywords:
                keyword_lower = keyword.lower()

                # Exact match (highest score)
                if keyword_lower == description_lower:
                    score += 10
                    print(
                        f"Debug - Exact match: '{keyword_lower}' == '{description_lower}' (+10)"
                    )
                # Word boundary match (high score)
                elif re.search(
                    r"\b" + re.escape(keyword_lower) + r"\b", description_lower
                ):
                    score += 5
                    print(
                        f"Debug - Word boundary match: '{keyword_lower}' in '{description_lower}' (+5)"
                    )
                # Substring match (medium score)
                elif keyword_lower in description_lower:
                    score += 2
                    print(
                        f"Debug - Substring match: '{keyword_lower}' in '{description_lower}' (+2)"
                    )
                # Partial word match (low score)
                else:
                    # Check if any part of the keyword matches
                    keyword_parts = keyword_lower.split()
                    desc_parts = description_lower.split()

                    for kw_part in keyword_parts:
                        if kw_part in desc_parts:
                            score += 1
                            print(
                                f"Debug - Partial word match: '{kw_part}' in '{description_lower}' (+1)"
                            )
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
                print(f"Debug - Added match: {code} with score {score}")

        # Sort matches by score (descending)
        matches.sort(key=lambda x: x["score"], reverse=True)
        return matches

    # Test content
    DEBUG_CODE_GENERATION_CONTENT = """
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
"""

    # Test different descriptions
    test_descriptions = ["formed", "cold formed", "heat treated", "machined"]

    rules = parse_debug_rules(DEBUG_CODE_GENERATION_CONTENT)

    print("=== Manufacturing Method Rules ===")
    for code, rule_info in rules["manufacturing_method"].items():
        print(f"{code}: {rule_info['name']}")
        print(f"  Keywords: {rule_info['keywords']}")
        print()

    for description in test_descriptions:
        print(f"=== Testing description: '{description}' ===")
        matches = find_component_matches_debug(
            description, rules["manufacturing_method"]
        )
        print(f"Matches found: {len(matches)}")
        for match in matches:
            print(f"  {match['code']}: {match['name']} (score: {match['score']})")
        print()

except Exception as e:
    print(f"Error: {e}")
    import traceback

    traceback.print_exc()
