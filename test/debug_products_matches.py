#!/usr/bin/env python3
"""
Quick debug to check what "products" matches
"""

import sys
import os
import re

# We need to run this from the agent directory to access dependencies
agent_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agent")
os.chdir(agent_dir)

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(agent_dir, "src"))

# Import the function from the edge case test file
sys.path.append(".")

try:
    from test_edge_cases_component_extraction import (
        parse_edge_case_rules,
        find_component_matches_enhanced,
    )

    # Use the same content as in the edge case tests
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
"""

    rules = parse_edge_case_rules(EDGE_CASE_CODE_GENERATION_CONTENT)

    print("=== Parsed Major Category Rules ===")
    for code, rule in rules["major_category"].items():
        print(f"{code}: {rule['name']}")
        print(f"  Keywords: {rule['keywords']}")
        print()

    print("=== Testing 'products' ===")
    matches = find_component_matches_enhanced("products", rules["major_category"])
    print(f"Matches found: {len(matches)}")
    for match in matches:
        print(f"  {match['code']}: {match['name']} (score: {match['score']})")

except Exception as e:
    print(f"Error: {e}")
    import traceback

    traceback.print_exc()
