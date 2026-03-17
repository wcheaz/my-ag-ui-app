#!/usr/bin/env python3
"""
Debug script to test the parsing logic
"""

import re

# Sample content
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


def parse_code_generation_rules(content: str) -> dict:
    """
    Parse the CODE_GENERATION.md content to extract component rules and options.
    """
    import re

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
    print(f"Major section found: {major_section is not None}")
    if major_section:
        print(f"Major section content: {major_section.group()[:200]}...")
        major_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", major_section.group()
        )
        print(f"Major matches: {major_matches}")
        for code, industry, description in major_matches:
            if code.strip() and industry.strip():
                rules["major_category"][code.strip()] = {
                    "name": industry.strip(),
                    "description": description.strip(),
                    "keywords": [industry.lower(), description.lower()],
                }

    # Extract manufacturing methods (B)
    method_section = re.search(
        r"### Second Letter - Manufacturing Method.*?(?=###|$)", content, re.DOTALL
    )
    print(f"Method section found: {method_section is not None}")
    if method_section:
        print(f"Method section content: {method_section.group()[:200]}...")
        method_matches = re.findall(
            r"\|\s*([A-Z]{2})\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|",
            method_section.group(),
        )
        print(f"Method matches: {method_matches}")
        for code, method, description in method_matches:
            if code.strip() and method.strip():
                rules["manufacturing_method"][code.strip()] = {
                    "name": method.strip(),
                    "description": description.strip(),
                    "keywords": [method.lower(), description.lower()],
                }

    # Extract object shapes (C)
    shape_section = re.search(
        r"### Third Letter - Object Shape/Form.*?(?=###|$)", content, re.DOTALL
    )
    print(f"Shape section found: {shape_section is not None}")
    if shape_section:
        shape_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", shape_section.group()
        )
        print(f"Shape matches: {shape_matches}")
        for code, shape, description in shape_matches:
            if code.strip() and shape.strip():
                rules["object_shape"][code.strip()] = {
                    "name": shape.strip(),
                    "description": description.strip(),
                    "keywords": [shape.lower(), description.lower()],
                }

    # Extract material types (MM)
    material_section = re.search(r"### Material Type.*?(?=###|$)", content, re.DOTALL)
    print(f"Material section found: {material_section is not None}")
    if material_section:
        material_matches = re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", material_section.group()
        )
        print(f"Material matches: {material_matches}")
        for code, material, examples in material_matches:
            if code.strip() and material.strip():
                keywords = [material.lower()]
                if examples.strip():
                    keywords.extend([ex.strip().lower() for ex in examples.split(",")])
                rules["material_type"][code.strip()] = {
                    "name": material.strip(),
                    "description": examples.strip(),
                    "keywords": keywords,
                }

    # Extract quality grades (QQ)
    quality_section = re.search(r"### Quality Grade.*?(?=###|$)", content, re.DOTALL)
    print(f"Quality section found: {quality_section is not None}")
    if quality_section:
        quality_matches = re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", quality_section.group()
        )
        print(f"Quality matches: {quality_matches}")
        for code, quality, description in quality_matches:
            if code.strip() and quality.strip():
                keywords = [quality.lower()]
                if description.strip():
                    keywords.append(description.lower())
                rules["quality_grade"][code.strip()] = {
                    "name": quality.strip(),
                    "description": description.strip(),
                    "keywords": keywords,
                }

    # Extract size categories (S)
    size_section = re.search(r"### Size Category.*?(?=###|$)", content, re.DOTALL)
    print(f"Size section found: {size_section is not None}")
    if size_section:
        size_matches = re.findall(
            r"\|\s*(\d)\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", size_section.group()
        )
        print(f"Size matches: {size_matches}")
        for code, size, description in size_matches:
            if code.strip() and size.strip():
                rules["size_category"][code.strip()] = {
                    "name": size.strip(),
                    "description": description.strip(),
                    "keywords": [size.lower(), description.lower()],
                }

    return rules


# Test the parsing
rules = parse_code_generation_rules(SAMPLE_CODE_GENERATION_CONTENT)
print(f"\nFinal rules:")
for component, component_rules in rules.items():
    print(f"{component}: {len(component_rules)} rules")
    for code, rule_info in component_rules.items():
        print(f"  {code}: {rule_info['name']}")
