import json
import os
import re
import datetime

import numpy as np
from llama_index.core import Settings


DEFAULT_SIMILARITY_THRESHOLD = 0.3
MINIMUM_SIMILARITY_THRESHOLD = 0.1
MAXIMUM_SIMILARITY_THRESHOLD = 0.8
KEYWORD_ONLY_THRESHOLD = 0.0

# Per-component confidence gap thresholds for auto-resolving ambiguous matches.
#
# When multiple matches pass the inclusion filter, the system computes a "gap ratio"
# between the top two scores: gap_ratio = (top_score - second_score) / top_score.
# If this gap exceeds the component's threshold AND the top score is strong enough,
# the component is auto-resolved to the top match instead of asking the user.
#
# gap_ratio:     How dominant the top match must be relative to the second.
#                Lower = more aggressive auto-resolve (fewer questions asked).
#                0.3 means the top match only needs to be 30% ahead of the second.
#                0.6 means the top match needs to be 60% ahead — much more conservative.
#
# min_top_score: Absolute floor the top match must exceed to be eligible for auto-resolve.
#                Prevents auto-resolving when ALL scores are weak (e.g., top=1.5, second=0.2).
#
# Rationale for values:
#   size_category (0.3):        Numeric ranges are objective — a small score gap is sufficient.
#   object_shape (0.4):         Shape terms are moderately distinct.
#   major_category (0.5):       Industry categories overlap more, needs clearer dominance.
#   manufacturing_method (0.5): Similar overlap to major_category.
#   material_type (0.5):        Keywords like "aluminum" are strong discriminators.
#   quality_grade (0.6):        22 overlapping options with subjective descriptions — most conservative.
DEFAULT_CONFIDENCE_GAP_CONFIG = {
    "size_category": {"gap_ratio": 0.3, "min_top_score": 3.0},
    "major_category": {"gap_ratio": 0.5, "min_top_score": 4.0},
    "manufacturing_method": {"gap_ratio": 0.5, "min_top_score": 4.0},
    "object_shape": {"gap_ratio": 0.4, "min_top_score": 4.0},
    "material_type": {"gap_ratio": 0.5, "min_top_score": 4.0},
    "quality_grade": {"gap_ratio": 0.6, "min_top_score": 3.0},
}


# Load confidence gap config from env var (JSON string) or fall back to defaults above.
# Set COMPONENT_CONFIDENCE_THRESHOLDS in .env to override per-component thresholds at deploy time.
def _load_confidence_gap_config() -> dict:
    env_val = os.getenv("COMPONENT_CONFIDENCE_THRESHOLDS", "")
    if env_val:
        try:
            return json.loads(env_val)
        except (json.JSONDecodeError, TypeError):
            pass
    return dict(DEFAULT_CONFIDENCE_GAP_CONFIG)


COMPONENT_CONFIDENCE_THRESHOLDS = _load_confidence_gap_config()


# Determines whether a set of matches should be auto-resolved to a single best match
# instead of being flagged as "ambiguous" (which would trigger a clarification question).
#
# How it works:
#   1. If there's 0 or 1 match, it's trivially decided (no match → False, 1 match → True).
#   2. For 2+ matches, compute gap_ratio = (top_score - second_score) / max(top_score, 1.0).
#      This measures how dominant the #1 match is vs. the runner-up.
#   3. Look up the per-component threshold (e.g., size_category allows 0.3, quality_grade requires 0.6).
#   4. Auto-resolve only if BOTH conditions hold:
#      - top_score >= min_top_score (the top match is strong enough in absolute terms)
#      - gap_ratio >= threshold's gap_ratio (the top match is dominant enough relative to #2)
#
# Example: size_category with scores [12.0, 3.0]:
#   gap_ratio = (12.0 - 3.0) / 12.0 = 0.75, which exceeds the 0.3 threshold → auto-resolve.
#   The agent skips asking "Would Oversized or Bulk work?" because 75% gap is clearly decisive.
SIZE_NUMERIC_RANGES = {
    "1": (0, 1),        # Micro: Less than 1mm
    "2": (1, 10),       # Small: 1mm to 10mm
    "3": (10, 100),     # Medium: 10mm to 100mm
    "4": (100, 500),    # Large: 100mm to 500mm
    "5": (500, 1000),   # Extra Large: 500mm to 1m (1000mm)
    "6": (1000, 5000),  # Bulk: 1m to 5m (1000mm to 5000mm)
    "7": (5000, None),  # Oversized: Greater than 5m (5000mm)
}


# Parses measurement values from user description text into millimeters.
# Handles: "150mm", "150 mm", "6.1m", "6.1 m", "20 feet", "20ft", "20'", "2.5cm"
# Returns a list of float values in mm.
def _parse_measurements_mm(description: str) -> list[float]:
    measurements = []
    desc_lower = description.lower()

    # Match number + unit patterns, ordered from most specific to least
    patterns = [
        (r"(\d+(?:\.\d+)?)\s*mm\b", 1.0),
        (r"(\d+(?:\.\d+)?)\s*cm\b", 10.0),
        (r"(\d+(?:\.\d+)?)\s*m\b(?!m)", 1000.0),
        (r"(\d+(?:\.\d+)?)\s*millimeter", 1.0),
        (r"(\d+(?:\.\d+)?)\s*centimeter", 10.0),
        (r"(\d+(?:\.\d+)?)\s*meter", 1000.0),
        (r"(\d+(?:\.\d+)?)\s*(?:feet|foot|ft|')\b", 304.8),
        (r"(\d+(?:\.\d+)?)\s*(?:inches|inch|in|\")\b", 25.4),
    ]

    for pattern, multiplier in patterns:
        for match in re.finditer(pattern, desc_lower):
            try:
                value_mm = float(match.group(1)) * multiplier
                measurements.append(value_mm)
            except (ValueError, IndexError):
                continue

    return measurements


RESOLVE_LOG_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "hidden",
    "resolve_log.txt",
)


def _log_resolve_decision(
    component_key: str,
    matches: list,
    resolved: bool,
    gap_ratio: float,
    config: dict,
    reason: str = "",
) -> None:
    try:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        lines = [
            f"\n{'=' * 70}",
            f"[{timestamp}] RESOLVE CHECK: {component_key}",
            f"  Matches: {len(matches)}",
        ]

        for i, m in enumerate(matches[:5]):
            marker = " <-- TOP" if i == 0 else ""
            lines.append(
                f"  #{i + 1}  code={m['code']:<4}  name={m['name']:<30}  "
                f"score={m['score']:<8.2f}  "
                f"kw={m.get('keyword_score', 0):<3}  sem={m.get('semantic_score', 0.0):.3f}"
                f"{marker}"
            )

        if len(matches) > 5:
            lines.append(f"  ... and {len(matches) - 5} more matches")

        if len(matches) >= 2:
            lines.append(
                f"  Gap: top={matches[0]['score']:.2f}  second={matches[1]['score']:.2f}  "
                f"gap_ratio={gap_ratio:.4f}  threshold={config['gap_ratio']}  "
                f"min_top_score={config['min_top_score']}"
            )

        result_label = "AUTO-RESOLVED → " + matches[0]["name"] if resolved and matches else "KEPT AMBIGUOUS"
        if reason:
            result_label += f"  ({reason})"
        lines.append(f"  Result: {result_label}")

        with open(RESOLVE_LOG_PATH, "a", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
    except Exception:
        pass


# Determines whether a set of matches should be auto-resolved to a single best match
# instead of being flagged as "ambiguous" (which would trigger a clarification question).
#
# Two resolution paths:
#
#   1. SCORE GAP (primary): Compute gap_ratio = (top - second) / top. If both:
#      - top_score >= min_top_score
#      - gap_ratio >= component's gap_ratio threshold
#      → auto-resolve. Works when semantic + keyword combined score clearly separates the top match.
#
#   2. KEYWORD DOMINANCE (secondary): If the top match has keyword hits (kw > 0) and the
#      runner-up has zero keyword hits (kw == 0), the user explicitly named the option while
#      the others only ride on semantic similarity noise. This handles cases like "aluminum"
#      where 22 materials all score ~0.6 semantically but only one has the "aluminum" keyword.
#      Requires top_score >= min_top_score to prevent resolving on weak keyword-only matches.
#
# Example: "Aerospace grade aluminum panel" → material_type:
#   Match #1: Metal (Non-ferrous)  score=9.28  kw=3   sem=0.628
#   Match #2: Composite            score=6.19  kw=0   sem=0.619
#   gap_ratio = 0.33 < threshold 0.5  → score gap fails
#   But kw_dominance (3 > 0, 0 == 0)  → keyword dominance fires → AUTO-RESOLVED
def should_auto_resolve(
    matches: list, component_key: str
) -> bool:
    if len(matches) < 2:
        return len(matches) == 1

    config = COMPONENT_CONFIDENCE_THRESHOLDS.get(
        component_key, {"gap_ratio": 0.5, "min_top_score": 4.0}
    )
    top_score = matches[0]["score"]
    second_score = matches[1]["score"]
    gap_ratio = (top_score - second_score) / max(top_score, 1.0)

    # Primary: combined score gap exceeds threshold
    if top_score >= config["min_top_score"] and gap_ratio >= config["gap_ratio"]:
        _log_resolve_decision(component_key, matches, True, gap_ratio, config, reason="score_gap")
        return True

    # Secondary: keyword dominance — top match has keywords, runner-up has none
    top_kw = matches[0].get("keyword_score", 0)
    second_kw = matches[1].get("keyword_score", 0)
    if top_kw > 0 and second_kw == 0 and top_score >= config["min_top_score"]:
        _log_resolve_decision(component_key, matches, True, gap_ratio, config, reason="keyword_dominance")
        return True

    _log_resolve_decision(component_key, matches, False, gap_ratio, config)
    return False


def calculate_semantic_similarity(text1: str, text2: str) -> float:
    """
    Calculate semantic similarity between two texts using embeddings.

    Args:
        text1: First text string
        text2: Second text string

    Returns:
        Similarity score between 0.0 and 1.0
    """
    try:
        from llama_index.embeddings.huggingface import HuggingFaceEmbedding

        embed_model = Settings.embed_model
        if embed_model is None:
            embed_model = HuggingFaceEmbedding(
                model_name=os.getenv("EMBEDDING_MODEL") or "BAAI/bge-large-en-v1.5"
            )
            Settings.embed_model = embed_model

        embedding1 = embed_model.get_text_embedding(text1)
        embedding2 = embed_model.get_text_embedding(text2)

        vec1 = np.array(embedding1)
        vec2 = np.array(embedding2)

        cosine_sim = np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))

        return max(0.0, min(1.0, float(cosine_sim)))

    except Exception as e:
        print(f"Warning: Semantic similarity calculation failed: {e}")
        return 0.0


def detect_explicit_guess_permission(user_text: str) -> bool:
    """
    GUESS PERMISSION DETECTION:
    Identifies when users explicitly allow the agent to make guesses for ambiguous components.

    This function is a critical component of the guess permission system in the
    disambiguation workflow. It implements the requirement that agents can only
    make guesses when users give explicit permission, preventing silent guessing
    and ensuring users are always in control of the disambiguation process.

    GUESS PERMISSION PHILOSOPHY:
    - Users MUST explicitly state they don't know or give permission
    - Agents MUST NEVER make silent guesses without permission
    - All guesses MUST be clearly communicated to users
    - Users retain full control over the disambiguation process

    DETECTION APPROACH:
    1. Uses comprehensive phrase matching with word boundaries
    2. Supports multiple categories of permission phrases:
       - Direct statements of not knowing ("I don't know", "no idea")
       - Delegative phrases ("you choose", "your decision")
       - Indifference phrases ("whatever", "doesn't matter")
       - Explicit permission phrases ("just guess", "make a guess")
    3. Handles combined phrases ("I don't know, whatever you choose")
    4. Uses case-insensitive matching with regex word boundaries
    5. Provides comprehensive coverage of common permission patterns

    WORKFLOW INTEGRATION:
    - Called by detect_component_ambiguity when analyzing user responses
    - When True is returned, ambiguous components are marked as "guessed"
    - When False is returned, users must provide clarification for ambiguities
    - Results in user notification about any guesses made based on their permission

    Args:
        user_text: The user's input text to analyze for guess permission phrases

    Returns:
        bool: True if explicit guess permission is detected, False otherwise
        - True: User has given explicit permission to guess ambiguous components
        - False: No explicit permission detected - must clarify all ambiguities

    Examples:
        >>> detect_explicit_guess_permission("I don't know, you choose")
        True  # Combined permission phrases
        >>> detect_explicit_guess_permission("whatever you think is best")
        True  # Indifference + delegative
        >>> detect_explicit_guess_permission("please specify the material")
        False # No permission detected - requires clarification

    CRITICAL: This function is the primary mechanism for preventing unauthorized
    guessing. Without this detection, agents might make inappropriate assumptions
    about user preferences, leading to incorrect procurement codes.
    """
    normalized_text = user_text.lower().strip()

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

    for phrase in guess_permission_phrases:
        pattern = r"\b" + re.escape(phrase) + r"\b"
        if re.search(pattern, normalized_text):
            return True

    if re.search(r"\bi don't know\b.*\bwhatever\b", normalized_text):
        return True

    if re.search(r"\byou choose\b.*\bdoesn't matter\b", normalized_text):
        return True

    combined_patterns = [
        r"\bi don't know\b.*\byou choose\b",
        r"\bwhatever\b.*\byou decide\b",
        r"\bup to you\b.*\bi don't care\b",
    ]

    for pattern in combined_patterns:
        if re.search(pattern, normalized_text):
            return True

    return False


def parse_code_generation_rules(content: str) -> dict:
    """
    Parse the CODE_GENERATION.md content to extract component rules and options.

    Args:
        content: The content of CODE_GENERATION.md file

    Returns:
        Dictionary with component rules structured for matching
    """
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
        major_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", major_section.group()
        )
        for code, industry, description in major_matches:
            if code.strip() and industry.strip():
                base_keywords = [industry.lower(), description.lower()]

                enhanced_keywords = []
                industry_lower = industry.lower()

                if "agricultural" in industry_lower or "farm" in industry_lower:
                    enhanced_keywords.extend(
                        ["agriculture", "farming", "crop", "harvest", "rural"]
                    )

                elif "chemical" in industry_lower:
                    enhanced_keywords.extend(
                        ["chemicals", "compound", "formula", "synthetic", "industrial"]
                    )

                elif "food" in industry_lower or "beverage" in industry_lower:
                    enhanced_keywords.extend(
                        [
                            "food",
                            "drink",
                            "beverage",
                            "edible",
                            "consumable",
                            "nutrition",
                        ]
                    )

                elif "metal" in industry_lower:
                    enhanced_keywords.extend(
                        [
                            "metal",
                            "metallic",
                            "steel",
                            "iron",
                            "aluminum",
                            "titanium",
                            "alloy",
                            "forging",
                            "casting",
                            "machining",
                            "aircraft",
                            "aerospace",
                            "aviation",
                        ]
                    )

                elif "textile" in industry_lower or "fabric" in industry_lower:
                    enhanced_keywords.extend(
                        [
                            "textile",
                            "fabric",
                            "cloth",
                            "weaving",
                            "sewing",
                            "apparel",
                            "clothing",
                        ]
                    )

                all_keywords = base_keywords + enhanced_keywords

                rules["major_category"][code.strip()] = {
                    "name": industry.strip(),
                    "description": description.strip(),
                    "keywords": all_keywords,
                }

    method_section = re.search(
        r"### Second Letter - Manufacturing Method.*?(?=###|$)", content, re.DOTALL
    )
    if method_section:
        method_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", method_section.group()
        )
        for code, method, description in method_matches:
            if code.strip() and method.strip():
                base_keywords = [method.lower(), description.lower()]

                enhanced_keywords = []
                method_lower = method.lower()

                if "additive" in method_lower or "3d" in method_lower:
                    enhanced_keywords.extend(
                        [
                            "3d",
                            "printing",
                            "additive",
                            "layer",
                            "digital",
                            "prototype",
                            "printed",
                        ]
                    )

                elif "blow" in method_lower or "molding" in method_lower:
                    enhanced_keywords.extend(
                        [
                            "blow",
                            "mold",
                            "molding",
                            "plastic",
                            "bottle",
                            "container",
                            "hollow",
                        ]
                    )

                elif "cast" in method_lower:
                    enhanced_keywords.extend(
                        [
                            "cast",
                            "casting",
                            "mold",
                            "pour",
                            "metal",
                            "foundry",
                            "molten",
                        ]
                    )

                elif "forg" in method_lower:
                    enhanced_keywords.extend(
                        [
                            "forged",
                            "forging",
                            "hammer",
                            "press",
                            "shape",
                            "metal",
                            "hot",
                        ]
                    )

                elif "machin" in method_lower:
                    enhanced_keywords.extend(
                        [
                            "machined",
                            "machining",
                            "cnc",
                            "machine",
                            "mill",
                            "lathe",
                            "cut",
                            "drill",
                            "precision",
                            "turn",
                        ]
                    )

                elif "weld" in method_lower:
                    enhanced_keywords.extend(
                        ["weld", "welding", "join", "fuse", "bond", "heat", "seam"]
                    )

                all_keywords = base_keywords + enhanced_keywords

                rules["manufacturing_method"][code.strip()] = {
                    "name": method.strip(),
                    "description": description.strip(),
                    "keywords": all_keywords,
                }

    shape_section = re.search(
        r"### Third Letter - Object Shape/Form.*?(?=###|$)", content, re.DOTALL
    )
    if shape_section:
        shape_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", shape_section.group()
        )
        for code, shape, description in shape_matches:
            if code.strip() and shape.strip():
                base_keywords = [shape.lower(), description.lower()]

                enhanced_keywords = []
                shape_lower = shape.lower()

                if "angular" in shape_lower:
                    enhanced_keywords.extend(
                        [
                            "angular",
                            "sharp",
                            "corner",
                            "edge",
                            "pointed",
                            "angled",
                            "cornered",
                        ]
                    )

                elif "barrel" in shape_lower or "cylindrical" in shape_lower:
                    enhanced_keywords.extend(
                        [
                            "barrel",
                            "cylindrical",
                            "cylinder",
                            "round",
                            "tube",
                            "pipe",
                            "circular",
                            "curved",
                        ]
                    )

                elif "cubic" in shape_lower or "cube" in shape_lower:
                    enhanced_keywords.extend(
                        [
                            "cubic",
                            "cube",
                            "box",
                            "rectangular",
                            "square",
                            "block",
                            "solid",
                        ]
                    )

                elif "flat" in shape_lower or "sheet" in shape_lower:
                    enhanced_keywords.extend(
                        [
                            "flat",
                            "sheet",
                            "plate",
                            "planar",
                            "surface",
                            "level",
                            "plain",
                            "layer",
                        ]
                    )

                elif "round" in shape_lower or "spherical" in shape_lower:
                    enhanced_keywords.extend(
                        [
                            "round",
                            "spherical",
                            "sphere",
                            "ball",
                            "orb",
                            "circular",
                            "curved",
                            "globe",
                        ]
                    )

                elif "tubular" in shape_lower or "tube" in shape_lower:
                    enhanced_keywords.extend(
                        [
                            "tubular",
                            "tube",
                            "pipe",
                            "hollow",
                            "cylinder",
                            "cylindrical",
                            "conduit",
                        ]
                    )

                all_keywords = base_keywords + enhanced_keywords

                rules["object_shape"][code.strip()] = {
                    "name": shape.strip(),
                    "description": description.strip(),
                    "keywords": all_keywords,
                }

    material_section = re.search(r"### Material Type.*?(?=###|$)", content, re.DOTALL)
    if material_section:
        material_matches = re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", material_section.group()
        )
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

    quality_section = re.search(r"### Quality Grade.*?(?=###|$)", content, re.DOTALL)
    if quality_section:
        quality_matches = re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", quality_section.group()
        )
        for code, quality, description in quality_matches:
            if code.strip() and quality.strip():
                base_keywords = [quality.lower()]
                if description.strip():
                    base_keywords.append(description.lower())

                enhanced_keywords = []
                quality_lower = quality.lower()

                if "standard" in quality_lower:
                    enhanced_keywords.extend(
                        [
                            "standard",
                            "regular",
                            "normal",
                            "basic",
                            "common",
                            "commercial",
                        ]
                    )

                elif "premium" in quality_lower:
                    enhanced_keywords.extend(
                        [
                            "premium",
                            "high",
                            "superior",
                            "enhanced",
                            "quality",
                            "plus",
                            "select",
                        ]
                    )

                elif "industrial" in quality_lower:
                    enhanced_keywords.extend(
                        [
                            "industrial",
                            "heavy",
                            "duty",
                            "commercial",
                            "strong",
                            "robust",
                            "tough",
                            "machinery",
                        ]
                    )

                elif "aerospace" in quality_lower:
                    enhanced_keywords.extend(
                        [
                            "aerospace",
                            "aircraft",
                            "aviation",
                            "flight",
                            "aeronautical",
                            "airplane",
                            "grade",
                            "precision",
                        ]
                    )

                elif "medical" in quality_lower:
                    enhanced_keywords.extend(
                        [
                            "medical",
                            "surgical",
                            "hospital",
                            "clinic",
                            "healthcare",
                            "sterile",
                            "biocompatible",
                            "implant",
                        ]
                    )

                grade_variations = [f"{quality_lower}-grade", f"{quality_lower}grade"]
                enhanced_keywords.extend(grade_variations)

                all_keywords = base_keywords + enhanced_keywords

                rules["quality_grade"][code.strip()] = {
                    "name": quality.strip(),
                    "description": description.strip(),
                    "keywords": all_keywords,
                }

    size_section = re.search(r"### Size Category.*?(?=###|$)", content, re.DOTALL)
    if size_section:
        size_matches = re.findall(
            r"\|\s*(\d)\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", size_section.group()
        )
        for code, size, description in size_matches:
            if code.strip() and size.strip():
                base_keywords = [size.lower(), description.lower()]

                enhanced_keywords = []
                size_lower = size.lower()

                if "small" in size_lower:
                    enhanced_keywords.extend(
                        [
                            "small",
                            "tiny",
                            "mini",
                            "micro",
                            "compact",
                            "little",
                            "minute",
                            " undersized",
                        ]
                    )

                elif "medium" in size_lower or "med" in size_lower:
                    enhanced_keywords.extend(
                        [
                            "medium",
                            "med",
                            "average",
                            "moderate",
                            "middle",
                            "intermediate",
                            "normal",
                            "regular",
                        ]
                    )

                elif "large" in size_lower:
                    enhanced_keywords.extend(
                        [
                            "large",
                            "big",
                            "huge",
                            "sizable",
                            "substantial",
                            "major",
                            "generous",
                            "oversized",
                        ]
                    )

                elif "extra" in size_lower or "xl" in size_lower:
                    enhanced_keywords.extend(
                        [
                            "extra",
                            "xl",
                            "extra large",
                            "jumbo",
                            "giant",
                            "enormous",
                            "massive",
                            "colossal",
                            "oversized",
                        ]
                    )

                all_keywords = base_keywords + enhanced_keywords

                rules["size_category"][code.strip()] = {
                    "name": size.strip(),
                    "description": description.strip(),
                    "keywords": all_keywords,
                }

    return rules


def find_component_matches(
    description: str,
    component_rules: dict,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> list:
    """
    COMPONENT MATCHING ENGINE:
    Core matching logic that identifies plausible component options from user descriptions.

    This function implements the intelligence behind component extraction by combining
    keyword matching with semantic similarity scoring. It uses a strict filtering
    system to ensure only options that match the user's description are presented,
    preventing users from seeing irrelevant choices during clarification.

    MATCHING ALGORITHM:
    1. KEYWORD MATCHING:
       - Searches for exact keyword matches in component rules
       - Uses word boundaries for precise matching
       - Scores based on keyword frequency and relevance
       - Handles partial and complete phrase matches

    2. SEMANTIC SIMILARITY:
       - Calculates semantic similarity using embeddings
       - Compares user description with component text representations
       - Uses cosine similarity for scoring (0.0 to 1.0)
       - Provides nuanced understanding beyond exact keywords

    3. STRICT DESCRIPTION MATCHING (Task 13.1):
       - Only presents options that match the user's description through either:
         * Sufficient semantic similarity (>= threshold), OR
         * Meaningful keyword matches (>= threshold combined with semantic relevance)
       - Filters out completely unrelated options that don't match user description
       - Ensures all presented options are relevant to the user's specific description

    SCORING SYSTEM:
    - Keyword score: 0-6 points based on exact and word-boundary matches
    - Semantic score: 0-10 points (scaled from 0.0-1.0 similarity)
    - Combined score: Keyword + Semantic scores (0-16 range)
    - Sorts by combined score for relevance ranking

    DISAMBIGUATION ROLE:
    - Called by extract_components_from_description for each component type
    - Returns scored matches that drive ambiguity detection
    - Enables clarify_components to present only description-matching options
    - Implements strict filtering to present only options that match user description

    Args:
        description: User's description text to analyze for component matches
        component_rules: Dictionary of component rules from CODE_GENERATION.md
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for inclusion

    Returns:
        List of matching component options with detailed scoring information:
        - code: Component code value (e.g., "A", "01")
        - name: Component name (e.g., "Agricultural products")
        - description: Component description
        - score: Combined relevance score (keyword + semantic)
        - keyword_score: Points from keyword matches
        - semantic_score: Semantic similarity score
        - filter_reason: Why this option was included or filtered

    CRITICAL: This function implements task 13.1 requirement to only present options
    that match the user's description. Options must have either sufficient semantic
    similarity or meaningful keyword matches combined with semantic relevance.
    """
    description_lower = description.lower()
    matches = []

    similarity_threshold = max(
        MINIMUM_SIMILARITY_THRESHOLD,
        min(MAXIMUM_SIMILARITY_THRESHOLD, similarity_threshold),
    )

    for code, rule_info in component_rules.items():
        keyword_score = 0
        semantic_score = 0.0
        keywords = rule_info.get("keywords", [])

        for keyword in keywords:
            if keyword in description_lower:
                keyword_score += 1

        for keyword in keywords:
            pattern = r"\b" + re.escape(keyword) + r"\b"
            if re.search(pattern, description_lower):
                keyword_score += 2

        # Numeric range matching for size_category: if the user provides a measurement
        # like "150mm" and this size code's range includes 150mm, award keyword points.
        # This handles cases where the embedding model can't differentiate between
        # size categories because they all score ~0.60-0.65 semantically.
        if code in SIZE_NUMERIC_RANGES:
            range_min, range_max = SIZE_NUMERIC_RANGES[code]
            for value_mm in _parse_measurements_mm(description):
                in_range = value_mm >= range_min
                if range_max is not None:
                    in_range = in_range and value_mm < range_max
                if in_range:
                    keyword_score += 6
                    break

        component_text = f"{rule_info['name']} {rule_info['description']}"
        semantic_score = calculate_semantic_similarity(description, component_text)

        if semantic_score >= similarity_threshold:
            pass

        elif semantic_score >= (similarity_threshold * 0.7) and keyword_score >= 2:
            pass

        elif semantic_score == 0.0 and keyword_score >= 1:
            pass

        else:
            continue

        semantic_score_scaled = semantic_score * 10

        combined_score = keyword_score + semantic_score_scaled

        if combined_score > 0:
            matches.append(
                {
                    "code": code,
                    "name": rule_info["name"],
                    "description": rule_info["description"],
                    "score": combined_score,
                    "keyword_score": keyword_score,
                    "semantic_score": semantic_score,
                    "filter_reason": _get_filter_reason(
                        semantic_score, keyword_score, similarity_threshold
                    ),
                }
            )

    matches.sort(key=lambda x: x["score"], reverse=True)

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


def _get_filter_reason(
    semantic_score: float, keyword_score: int, threshold: float
) -> str:
    """
    Helper function to determine the reason why a match was included or filtered.
    Updated for task 13.1 to reflect strict description matching requirements.

    Args:
        semantic_score: The semantic similarity score
        keyword_score: The keyword match score
        threshold: The similarity threshold used for filtering

    Returns:
        String describing the filter reason
    """
    if semantic_score >= threshold:
        return f"high_semantic_similarity ({semantic_score:.2f} >= {threshold})"
    elif semantic_score >= (threshold * 0.7) and keyword_score >= 2:
        return f"moderate_semantic_with_keywords ({semantic_score:.2f} >= {threshold * 0:.1f}, keywords: {keyword_score})"
    else:
        return f"description_match (semantic: {semantic_score:.2f}, keywords: {keyword_score})"


def extract_components_from_description(
    user_description: str,
    code_generation_content: str,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> dict:
    """
    Extract component information from user description against CODE_GENERATION.md rules.
    Uses similarity threshold to filter out unrelated options from clarification prompts.

    Args:
        user_description: The user's description text
        code_generation_content: Content of the CODE_GENERATION.md file
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for matches to be included

    Returns:
        Dictionary with component extraction results including ambiguity information
    """
    rules = parse_code_generation_rules(code_generation_content)

    results = {
        "major_category": None,
        "manufacturing_method": None,
        "object_shape": None,
        "material_type": None,
        "quality_grade": None,
        "size_category": None,
        "year": "26",
        "sequence": None,
    }

    components_to_check = [
        ("major_category", "Major Category"),
        ("manufacturing_method", "Manufacturing Method"),
        ("object_shape", "Object Shape"),
        ("material_type", "Material Type"),
        ("quality_grade", "Quality Grade"),
        ("size_category", "Size Category"),
    ]

    component_matches = {}

    for component_key, component_name in components_to_check:
        matches = find_component_matches(
            user_description, rules[component_key], similarity_threshold
        )

        # Auto-resolve: if the top match is clearly dominant (per-component gap threshold),
        # collapse multi-match results to just the top match so it's classified as "unambiguous"
        # instead of "ambiguous". This is the primary resolution point.
        if len(matches) > 1 and should_auto_resolve(matches, component_key):
            matches = [matches[0]]

        component_matches[component_key] = {
            "name": component_name,
            "matches": matches,
            "is_ambiguous": len(matches) > 1,
            "no_matches": len(matches) == 0,
        }

    return component_matches


def get_component_extraction_results(
    user_description: str,
    code_generation_content: str,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> dict:
    """
    Get complete component extraction results with structured ambiguity information.
    Uses similarity threshold to filter out unrelated options from clarification prompts.

    This function serves as the main entry point for component extraction logic,
    providing structured information about which components are ambiguous and
    need clarification.

    Args:
        user_description: The user's description text
        code_generation_content: Content of the CODE_GENERATION.md file
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for matches to be included

    Returns:
        Dictionary with:
        - ambiguous_components: List of components with multiple matches
        - unambiguous_components: List of components with single matches
        - no_match_components: List of components with no matches
        - component_details: Detailed information about each component
    """
    component_matches = extract_components_from_description(
        user_description, code_generation_content, similarity_threshold
    )

    ambiguous_components = []
    unambiguous_components = []
    no_match_components = []
    component_details = {}

    for component_key, match_info in component_matches.items():
        component_name = match_info["name"]
        matches = match_info["matches"]

        # Defensive re-check: matches were already collapsed by
        # extract_components_from_description() above, so this is a no-op
        # in normal flow. Kept as a safety net in case this function is ever
        # called with pre-built match data that bypasses the initial collapse.
        if len(matches) > 1 and should_auto_resolve(matches, component_key):
            matches = [matches[0]]

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


def validate_options_similarity_threshold(
    options: list, similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD
) -> list:
    """
    Validate that all options have similarity scores above the threshold.

    This function implements explicit similarity threshold validation to ensure
    that only options with sufficient similarity scores are presented to users.

    Args:
        options: List of option dictionaries with similarity information
        similarity_threshold: Minimum similarity score (0.0-1.0) required

    Returns:
        List of options that meet the similarity threshold requirement
    """
    validated_options = []

    for option in options:
        if "semantic_score" in option:
            semantic_score = option["semantic_score"]
            if semantic_score >= similarity_threshold:
                validated_options.append(option)
        else:
            validated_options.append(option)

    return validated_options
