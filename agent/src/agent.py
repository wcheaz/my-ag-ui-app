# Standard library imports
import os
import re
import datetime
import json
from typing import List, Optional, Any, Union
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

# Third-party imports
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.messages import ModelMessage, ModelRequest, SystemPromptPart
from pydantic_ai.models import (
    ModelRequestParameters,
    ModelSettings,
    ModelResponse,
    StreamedResponse,
)
from ag_ui.core import EventType, StateSnapshotEvent
from llama_index.core import Settings
import numpy as np

# Local application imports
from src.rag.index import get_index
from src.rag.settings import init_settings
from src.rag.citation import enable_citation, CITATION_SYSTEM_PROMPT
from src.rag.query import get_query_engine_tool

# LOAD ENVIRONMENT VARIABLES manually since init_settings is disabled


def load_env():
    # Try finding .env file
    paths = [
        os.path.join(os.getcwd(), ".env"),
        os.path.join(os.getcwd(), "..", ".env"),
        os.path.join(os.path.dirname(__file__), "..", ".env"),
        os.path.join(os.path.dirname(__file__), "..", "..", ".env"),
    ]
    for p in paths:
        if os.path.exists(p):
            with open(p, "r") as f:
                for line in f:
                    if "=" in line and not line.strip().startswith("#"):
                        key, val = line.strip().split("=", 1)
                        if not os.environ.get(key):
                            os.environ[key] = val.strip().strip("'").strip('"')
            break


load_env()

# Configuration constants for similarity threshold filtering
DEFAULT_SIMILARITY_THRESHOLD = 0.3
MINIMUM_SIMILARITY_THRESHOLD = 0.1
MAXIMUM_SIMILARITY_THRESHOLD = 0.8
KEYWORD_ONLY_THRESHOLD = (
    0.0  # Threshold for keyword-only matches (no semantic filtering)
)


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
        # Initialize embeddings if not already done
        from llama_index.embeddings.huggingface import HuggingFaceEmbedding

        # Use the same model as configured in settings
        embed_model = Settings.embed_model
        if embed_model is None:
            embed_model = HuggingFaceEmbedding(
                model_name=os.getenv("EMBEDDING_MODEL") or "BAAI/bge-large-en-v1.5"
            )
            Settings.embed_model = embed_model

        # Get embeddings for both texts
        embedding1 = embed_model.get_text_embedding(text1)
        embedding2 = embed_model.get_text_embedding(text2)

        # Convert to numpy arrays
        vec1 = np.array(embedding1)
        vec2 = np.array(embedding2)

        # Calculate cosine similarity
        cosine_sim = np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))

        # Ensure the result is between 0 and 1
        return max(0.0, min(1.0, float(cosine_sim)))

    except Exception as e:
        # If semantic similarity fails, return 0.0
        print(f"Warning: Semantic similarity calculation failed: {e}")
        return 0.0


def detect_explicit_guess_permission(user_text: str) -> bool:
    """
    Detect explicit guess permission phrases in user text.

    This function analyzes user input to identify phrases that indicate
    the user explicitly allows the agent to make a guess for ambiguous
    components. This implements the "explicit guess permission" requirement
    from the disambiguation workflow.

    Args:
        user_text: The user's input text to analyze

    Returns:
        bool: True if explicit guess permission is detected, False otherwise

    Examples:
        >>> detect_explicit_guess_permission("I don't know, you choose")
        True
        >>> detect_explicit_guess_permission("whatever you think is best")
        True
        >>> detect_explicit_guess_permission("please specify the material")
        False
    """
    # Normalize the text for case-insensitive matching
    normalized_text = user_text.lower().strip()

    # Define explicit guess permission phrases
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

    # Check for exact phrase matches using word boundaries
    for phrase in guess_permission_phrases:
        # Use regex with word boundaries to avoid partial matches
        pattern = r"\b" + re.escape(phrase) + r"\b"
        if re.search(pattern, normalized_text):
            return True

    # Check for variations and combinations
    # Handle "I don't know" followed by indifference
    if re.search(r"\bi don't know\b.*\bwhatever\b", normalized_text):
        return True

    # Handle "you choose" variations with indifference
    if re.search(r"\byou choose\b.*\bdoesn't matter\b", normalized_text):
        return True

    # Handle combined permission phrases
    combined_patterns = [
        r"\bi don't know\b.*\byou choose\b",
        r"\bwhatever\b.*\byou decide\b",
        r"\bup to you\b.*\bi don't care\b",
    ]

    for pattern in combined_patterns:
        if re.search(pattern, normalized_text):
            return True

    return False


class ProcurementCode(BaseModel):
    code: str
    description: str


class AmbiguityInfo(BaseModel):
    """
    Data class to track component ambiguity status during disambiguation workflow.

    This class tracks whether a component is ambiguous, unambiguous, or guessed,
    maintains the list of plausible options, and stores the user's selected value.

    Attributes:
        status: Either "ambiguous", "unambiguous", or "guessed"
        options: List of plausible matches for the component
        selected_value: The user's selected value (if resolved)
        guessed_value: The value selected when user gave explicit guess permission
        is_guessed: Boolean flag indicating if this component was guessed
    """

    status: str  # "ambiguous", "unambiguous", or "guessed"
    options: List[dict]  # List of plausible matches with their descriptions
    selected_value: Optional[str] = None  # User's selected value when resolved
    guessed_value: Optional[str] = (
        None  # Value selected when user gave guess permission
    )
    is_guessed: bool = False  # Flag indicating if this component was guessed


class ProcurementState(BaseModel):
    """
    State for the Procurement Agent.
    Maintains conversation history and other session-specific data.
    """

    # Placeholder for message history or other state tracking
    conversation_id: Optional[str] = None
    procurement_codes: List[ProcurementCode] = Field(default_factory=list)
    citation_sources: List[str] = Field(
        default_factory=list
    )  # Accumulated citation sources
    # ENFORCEMENT MECHANISM: Flag to track if rules file has been loaded this turn
    # This flag enforces the workflow: read_code_generation_file MUST be called before save_procurement_code
    # The flag defaults to False and is reset per request to prevent stale state
    rules_loaded_this_turn: bool = False
    # DISAMBIGUATION TRACKING: Dictionary to track component ambiguity status
    # Key: component_name (str), Value: AmbiguityInfo object
    # This enables programmatic enforcement of disambiguation workflow
    component_ambiguity_status: dict[str, AmbiguityInfo] = Field(default_factory=dict)
    # ITERATIVE CLARIFICATION: Counter to track number of clarification rounds completed
    # This enables iterative clarification workflows and context preservation across rounds
    clarification_rounds: int = 0
    # ITERATIVE CLARIFICATION: Set to track which components have been successfully clarified
    # This prevents asking about the same component multiple times across clarification rounds
    clarified_components: set[str] = Field(default_factory=set)

    def update_component_ambiguity(
        self, component_name: str, ambiguity_info: AmbiguityInfo
    ) -> None:
        """
        Update component ambiguity status with validation for state transitions.
        Preserves previous user selections when updating component ambiguity status.

        Args:
            component_name: Name of the component to update
            ambiguity_info: New AmbiguityInfo for the component

        Raises:
            ValueError: If state transition is invalid
        """
        # Check if we're updating an existing component and validate state transition
        if component_name in self.component_ambiguity_status:
            current_info = self.component_ambiguity_status[component_name]

            # Use comprehensive state transition validation with error handling
            try:
                self.validate_state_transition(
                    current_info.status, ambiguity_info.status, component_name
                )
            except ValueError as e:
                # Re-raise with additional context about the transition
                raise ValueError(
                    f"{str(e)} "
                    f"Current state: {current_info.status}, Target state: {ambiguity_info.status}. "
                    f"This transition violates the state machine rules for component ambiguity resolution."
                ) from e

            # PRESERVE PREVIOUS USER SELECTIONS: If the component already has a selected_value
            # and the new status is unambiguous, preserve the existing selection if it's valid
            if current_info.selected_value is not None:
                if ambiguity_info.status == "unambiguous":
                    # Check if the existing selected_value is still valid in the new options
                    existing_selection_valid = any(
                        option["value"] == current_info.selected_value
                        for option in ambiguity_info.options
                    )

                    if existing_selection_valid:
                        # Preserve the existing user selection
                        ambiguity_info.selected_value = current_info.selected_value
                    # If existing selection is not valid, use the new selected_value
                elif ambiguity_info.status == "guessed":
                    # For guessed components, preserve the existing guessed_value if valid
                    if current_info.guessed_value is not None:
                        existing_guess_valid = any(
                            option["value"] == current_info.guessed_value
                            for option in ambiguity_info.options
                        )

                        if existing_guess_valid:
                            ambiguity_info.guessed_value = current_info.guessed_value
                            ambiguity_info.selected_value = current_info.guessed_value
                            ambiguity_info.is_guessed = True

        # For new components (not in state), validate the initial state is valid
        else:
            try:
                self.validate_state_transition(
                    "new",  # Special case for new components
                    ambiguity_info.status,
                    component_name,
                )
            except ValueError as e:
                raise ValueError(
                    f"Invalid initial state for component '{component_name}': {str(e)} "
                    f"New components must start in 'ambiguous' or 'unambiguous' state."
                ) from e

        # Now validate after potential preservation of selections
        # Validate that unambiguous components have a selected_value
        if (
            ambiguity_info.status == "unambiguous"
            and ambiguity_info.selected_value is None
        ):
            raise ValueError(
                f"Invalid state for component '{component_name}': "
                f"Unambiguous components must have a selected_value."
            )

        # Validate that guessed components have a guessed_value
        if ambiguity_info.status == "guessed" and ambiguity_info.guessed_value is None:
            raise ValueError(
                f"Invalid state for component '{component_name}': "
                f"Guessed components must have a guessed_value."
            )

        # Apply the update
        self.component_ambiguity_status[component_name] = ambiguity_info

    def validate_state_transition(
        self, current_status: str, new_status: str, component_name: str
    ) -> None:
        """
        Validate that a state transition is allowed for a component.

        This method implements comprehensive error handling for unexpected state transitions,
        ensuring that components follow valid state progression according to business rules.

        Args:
            current_status: The current status of the component
            new_status: The desired new status for the component
            component_name: Name of the component being transitioned

        Raises:
            ValueError: If the state transition is not allowed
        """
        # Define valid states
        valid_states = ["ambiguous", "unambiguous", "guessed"]

        # Handle special case for new components
        if current_status == "new":
            # New components can start in any valid state
            if new_status not in valid_states:
                raise ValueError(
                    f"Invalid initial state '{new_status}' for new component '{component_name}'. "
                    f"New components must start in one of: {', '.join(valid_states)}"
                )
            return  # New component transition is always valid

        # Validate that both states are valid for existing components
        if current_status not in valid_states:
            raise ValueError(
                f"Invalid current state '{current_status}' for component '{component_name}'. "
                f"Valid states are: {', '.join(valid_states)}"
            )

        if new_status not in valid_states:
            raise ValueError(
                f"Invalid target state '{new_status}' for component '{component_name}'. "
                f"Valid states are: {', '.join(valid_states)}"
            )

        # Define allowed transitions
        allowed_transitions = {
            "ambiguous": ["unambiguous", "guessed"],
            "unambiguous": [],  # No transitions allowed from resolved states
            "guessed": [],  # No transitions allowed from resolved states
        }

        # Check if transition is allowed
        if new_status not in allowed_transitions.get(current_status, []):
            if current_status == new_status:
                raise ValueError(
                    f"Invalid state transition for component '{component_name}': "
                    f"Cannot transition from '{current_status}' to '{current_status}' (same state). "
                    f"Component is already in the '{current_status}' state."
                )
            else:
                raise ValueError(
                    f"Invalid state transition for component '{component_name}': "
                    f"Cannot transition from '{current_status}' to '{new_status}'. "
                    f"Once a component is resolved (unambiguous or guessed), it cannot change state again."
                )

    def validate_all_component_states(self) -> None:
        """
        Validate that all component states are valid and consistent.
        This provides comprehensive error handling for unexpected state transitions
        by checking all components for valid states and data consistency.

        Raises:
            ValueError: If any component has an invalid state or inconsistent data
        """
        valid_states = ["ambiguous", "unambiguous", "guessed"]

        for component_name, ambiguity_info in self.component_ambiguity_status.items():
            # Validate that the status is one of the allowed states
            if ambiguity_info.status not in valid_states:
                raise ValueError(
                    f"Invalid state '{ambiguity_info.status}' for component '{component_name}'. "
                    f"Valid states are: {', '.join(valid_states)}"
                )

            # Validate data consistency based on status
            if ambiguity_info.status == "unambiguous":
                if ambiguity_info.selected_value is None:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Unambiguous components must have a selected_value."
                    )
                if ambiguity_info.is_guessed:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Unambiguous components cannot be marked as guessed."
                    )

            elif ambiguity_info.status == "guessed":
                if ambiguity_info.guessed_value is None:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Guessed components must have a guessed_value."
                    )
                if ambiguity_info.selected_value != ambiguity_info.guessed_value:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Guessed components must have selected_value equal to guessed_value."
                    )
                if not ambiguity_info.is_guessed:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Guessed components must have is_guessed=True."
                    )

            elif ambiguity_info.status == "ambiguous":
                if ambiguity_info.selected_value is not None:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Ambiguous components cannot have a selected_value."
                    )
                if ambiguity_info.guessed_value is not None:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Ambiguous components cannot have a guessed_value."
                    )
                if ambiguity_info.is_guessed:
                    raise ValueError(
                        f"Invalid state for component '{component_name}': "
                        f"Ambiguous components cannot be marked as guessed."
                    )

    def validate_all_components_unambiguous(self) -> None:
        """
        Validate that all components are resolved (either unambiguous or guessed).
        This allows code generation to proceed when components have been explicitly
        guessed with user permission.

        Raises:
            ValueError: If any component is still ambiguous or has invalid state
        """
        # First validate that all component states are valid
        self.validate_all_component_states()

        # Then check for ambiguous components
        ambiguous_components = [
            name
            for name, info in self.component_ambiguity_status.items()
            if info.status == "ambiguous"
        ]

        if ambiguous_components:
            component_list = ", ".join(ambiguous_components)
            raise ValueError(
                f"Cannot proceed with code generation: "
                f"The following components are still ambiguous and need clarification: {component_list}"
            )

    def get_ambiguous_components(self) -> dict[str, AmbiguityInfo]:
        """
        Get all components that are currently ambiguous.

        Returns:
            Dictionary of ambiguous component names to their AmbiguityInfo
        """
        return {
            name: info
            for name, info in self.component_ambiguity_status.items()
            if info.status == "ambiguous"
        }

    def get_unambiguous_components(self) -> dict[str, AmbiguityInfo]:
        """
        Get all components that are currently unambiguous.

        Returns:
            Dictionary of unambiguous component names to their AmbiguityInfo
        """
        return {
            name: info
            for name, info in self.component_ambiguity_status.items()
            if info.status == "unambiguous"
        }


def read_code_generation_file(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Read the contents of the CODE_GENERATION.md file which contains the procurement code generation template.

    Returns:
        The contents of the CODE_GENERATION.md file as a string
    """
    try:
        # DEBUG: Log context messages
        try:
            with open(
                os.path.join(os.getcwd(), "hidden", "debug_context.txt"), "a"
            ) as f:
                f.write(f"\nCTX MESSAGES AT {datetime.datetime.now()}:\n")
                if hasattr(ctx, "messages"):
                    for i, m in enumerate(ctx.messages):
                        f.write(
                            f"MSG {i}: Type={type(m).__name__}, Parts={len(m.parts) if hasattr(m, 'parts') else 'N/A'}\n"
                        )
                        if hasattr(m, "parts"):
                            for p in m.parts:
                                f.write(f"  PART: {type(p).__name__}\n")
        except Exception as deb_e:
            print(f"Debug log failed: {deb_e}")

        # Try finding the file relative to CWD
        paths_to_check = [
            os.path.join(
                os.getcwd(), "agent", "data", "CODE_GENERATION.md"
            ),  # From project root
            os.path.join("data", "CODE_GENERATION.md"),  # From agent dir
            os.path.join("..", "data", "CODE_GENERATION.md"),  # From src dir
        ]

        file_path = None
        for path in paths_to_check:
            if os.path.exists(path):
                file_path = path
                break

        if not file_path:
            raise FileNotFoundError(
                "CODE_GENERATION.md not found. Cannot generate codes without rules."
            )

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # ENFORCEMENT MECHANISM: Set flag to indicate rules were successfully loaded this turn
        # This flag is used by save_procurement_code to validate that rules were loaded before saving
        # The flag is set ONLY after successful file read to ensure atomic operation
        ctx.deps.state.rules_loaded_this_turn = True
        return content
    except FileNotFoundError:
        # Re-raise FileNotFoundError directly as per specification
        raise
    except Exception as e:
        raise Exception(f"Error reading CODE_GENERATION.md file: {str(e)}")


def get_rag_tool():
    """
    Initialize and return the RAG query tool.
    In PydanticAI, we might wrap this, but for now we initialize the LlamaIndex components.
    """
    init_settings()
    index = get_index()
    if index is None:
        return None

    query_tool = enable_citation(
        get_query_engine_tool(
            index=index,
            description="CITATIONS ONLY: Use this tool ONLY to get citations for information you've already obtained from the document reading tool. This tool is NOT for information gathering - it only provides citations for facts you already know from the document. Do NOT use this tool to learn about procurement codes or rules.",
        )
    )
    return query_tool


# Initialize the RAG tool instance to be used by the agent wrapper
rag_engine_tool = get_rag_tool()


def query_rag_system(ctx: RunContext[StateDeps[ProcurementState]], query: str) -> str:
    """
    CITATIONS ONLY: Use this tool ONLY to get citations for information you've already obtained from the document reading tool.
    This tool is NOT for information gathering - it only provides citations for facts you already know from the document.
    Do NOT use this tool to learn about procurement codes or rules.
    """
    if rag_engine_tool is None:
        return "RAG system not initialized (Index not found)."

    try:
        response = rag_engine_tool.query_engine.query(query)

        # Get the current citation count (how many sources we've accumulated so far)
        current_count = len(ctx.deps.state.citation_sources)
        citation_num = current_count + 1

        # Build the response text
        result = str(response)

        # Store the most relevant source from this RAG call
        if hasattr(response, "source_nodes") and response.source_nodes:
            # Take the first (most relevant) source node
            node = response.source_nodes[0]
            source_text = (
                node.node.text
                if hasattr(node.node, "text") and node.node.text
                else node.node.get_content()
            )
            # Reduced preview to 150 characters (about 15 words)
            preview = (
                source_text[:150] + "..." if len(source_text) > 150 else source_text
            )
            ctx.deps.state.citation_sources.append(preview)

            # Replace all citation markers in the response with the single citation number
            # This handles cases where the RAG response has [1], [2], [3], etc.
            for i in range(1, 10):  # Handle up to 9 citations in RAG response
                result = result.replace(f"[{i}]", f"[{citation_num}]")

        return result
    except Exception as e:
        return f"Error querying RAG system: {str(e)}"


def get_citation_sources(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Get all accumulated citation sources to display to the user.
    Call this at the end of your response to show what each citation number refers to.
    """
    if not ctx.deps.state.citation_sources:
        return "No citation sources available."

    result = "--- Citation Sources ---\n"
    for idx, source in enumerate(ctx.deps.state.citation_sources, start=1):
        result += f"\n[{idx}] {source}\n"

    return result


def parse_code_generation_rules(content: str) -> dict:
    """
    Parse the CODE_GENERATION.md content to extract component rules and options.

    Args:
        content: The content of CODE_GENERATION.md file

    Returns:
        Dictionary with component rules structured for matching
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
    major_pattern = r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|"
    major_matches = re.findall(major_pattern, content)

    # Find the major category section
    major_section = re.search(
        r"### First Letter - Major Categories.*?(?=###|$)", content, re.DOTALL
    )
    if major_section:
        major_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", major_section.group()
        )
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
    if method_section:
        method_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", method_section.group()
        )
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
    if shape_section:
        shape_matches = re.findall(
            r"\|\s*([A-Z])\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|", shape_section.group()
        )
        for code, shape, description in shape_matches:
            if code.strip() and shape.strip():
                rules["object_shape"][code.strip()] = {
                    "name": shape.strip(),
                    "description": description.strip(),
                    "keywords": [shape.lower(), description.lower()],
                }

    # Extract material types (MM)
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

    # Extract quality grades (QQ)
    quality_section = re.search(r"### Quality Grade.*?(?=###|$)", content, re.DOTALL)
    if quality_section:
        quality_matches = re.findall(
            r"\|\s*(\d{2})\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", quality_section.group()
        )
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
    if size_section:
        size_matches = re.findall(
            r"\|\s*(\d)\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", size_section.group()
        )
        for code, size, description in size_matches:
            if code.strip() and size.strip():
                rules["size_category"][code.strip()] = {
                    "name": size.strip(),
                    "description": description.strip(),
                    "keywords": [size.lower(), description.lower()],
                }

    return rules


def find_component_matches(
    description: str,
    component_rules: dict,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> list:
    """
    Find matches for a component based on user description using both keyword matching
    and semantic similarity scoring. Uses improved similarity threshold filtering to
    effectively filter out unrelated options while preserving relevant matches.

    Args:
        description: User's description text
        component_rules: Dictionary of component rules
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for a match to be included

    Returns:
        List of matching component options with their combined scores
    """
    description_lower = description.lower()
    matches = []

    # Validate and normalize the similarity threshold
    similarity_threshold = max(
        MINIMUM_SIMILARITY_THRESHOLD,
        min(MAXIMUM_SIMILARITY_THRESHOLD, similarity_threshold),
    )

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
            # Check for whole word matches
            pattern = r"\b" + re.escape(keyword) + r"\b"
            if re.search(pattern, description_lower):
                keyword_score += 2

        # Calculate semantic similarity
        # Create a text representation of the component for semantic comparison
        component_text = f"{rule_info['name']} {rule_info['description']}"
        semantic_score = calculate_semantic_similarity(description, component_text)

        # IMPROVED SIMILARITY THRESHOLD FILTERING: Use nuanced filtering logic
        # This filters out completely unrelated options while preserving relevant matches

        # Case 1: High semantic similarity (above threshold) - always include
        if semantic_score >= similarity_threshold:
            pass  # Will be included if combined score > 0

        # Case 2: Low semantic similarity but high keyword relevance - include if keyword score is strong
        elif semantic_score < similarity_threshold and keyword_score >= 4:
            # If there are strong keyword matches (4+ points), include even with lower semantic similarity
            # This preserves matches that are relevant based on keywords alone
            pass  # Will be included if combined score > 0

        # Case 3: Both low semantic similarity and low keyword relevance - filter out
        else:
            continue  # Skip this match as it doesn't meet relevance criteria

        # Convert semantic score to a 0-10 scale for combination with keyword score
        semantic_score_scaled = semantic_score * 10

        # Combine scores: keyword_score (0-6 range) + semantic_score_scaled (0-10 range)
        # This gives semantic similarity more weight in the matching
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
                    "filter_reason": _get_filter_reason(
                        semantic_score, keyword_score, similarity_threshold
                    ),
                }
            )

    # Sort matches by combined score (descending)
    matches.sort(key=lambda x: x["score"], reverse=True)
    return matches


def _get_filter_reason(
    semantic_score: float, keyword_score: int, threshold: float
) -> str:
    """
    Helper function to determine the reason why a match was included or filtered.

    Args:
        semantic_score: The semantic similarity score
        keyword_score: The keyword match score
        threshold: The similarity threshold used for filtering

    Returns:
        String describing the filter reason
    """
    if semantic_score >= threshold:
        return f"high_semantic_similarity ({semantic_score:.2f} >= {threshold})"
    elif keyword_score >= 4:
        return f"strong_keyword_matches ({keyword_score} >= 4)"
    else:
        return f"combined_relevance (semantic: {semantic_score:.2f}, keywords: {keyword_score})"


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

    component_matches = {}

    for component_key, component_name in components_to_check:
        # Pass similarity threshold to filter out unrelated options
        matches = find_component_matches(
            user_description, rules[component_key], similarity_threshold
        )
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
        # Check if the option has similarity information
        if "semantic_score" in option:
            semantic_score = option["semantic_score"]
            if semantic_score >= similarity_threshold:
                validated_options.append(option)
            # Note: Options with keyword_score >= 4 are also included from find_component_matches
            # so we don't need to re-validate that logic here
        else:
            # If no similarity info is available, include the option (fallback behavior)
            validated_options.append(option)

    return validated_options


def clarify_components(
    ctx: RunContext[StateDeps[ProcurementState]], user_description: str
) -> str:
    """
    Implement clarify_components tool to parse user description and identify ambiguous components.

    This tool serves as the primary disambiguation mechanism, returning structured JSON
    with clarification options for ambiguous components while providing context about
    unambiguous components.

    Args:
        ctx: The run context containing the ProcurementState
        user_description: The user's description text to analyze

    Returns:
        JSON string containing:
        - ambiguous_components: List of components that need clarification
        - unambiguous_components: List of components already resolved
        - component_details: Detailed information about each component
    """
    try:
        # Input validation
        if not user_description or not isinstance(user_description, str):
            raise ValueError("ERROR: user_description must be a non-empty string")

        if not ctx or not hasattr(ctx, "deps") or not hasattr(ctx.deps, "state"):
            raise ValueError(
                "ERROR: Invalid context provided - missing state dependency"
            )

        # Check if rules file has been loaded this turn
        if not ctx.deps.state.rules_loaded_this_turn:
            raise ValueError(
                "ERROR: You must call read_code_generation_file before using clarify_components."
            )

        # Get the code generation content from context or read it
        # For now, we'll read it fresh each time (could be optimized)
        try:
            code_generation_content = read_code_generation_file(ctx)
        except FileNotFoundError as e:
            raise FileNotFoundError(
                f"ERROR: Code generation rules file not found: {str(e)}"
            )
        except Exception as e:
            raise RuntimeError(f"ERROR: Failed to read code generation file: {str(e)}")

        # Get component extraction results with ambiguity detection and similarity threshold filtering
        try:
            ambiguity_results = detect_component_ambiguity(
                user_description,
                code_generation_content,
                ctx,
                user_description,
                similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD,
            )
        except ValueError as e:
            # Handle state transition errors specifically
            error_response = {
                "error": str(e),
                "error_type": "state_transition_error",
                "error_details": "A component state transition was invalid. This may indicate a workflow issue.",
                "ambiguous_components": [],
                "unambiguous_components": [],
                "component_details": {},
            }
            return json.dumps(error_response, indent=2, ensure_ascii=False)
        except Exception as e:
            # Handle other ambiguity detection errors
            raise RuntimeError(f"ERROR: Ambiguity detection failed: {str(e)}")

        # Prepare the structured response
        response = {
            "ambiguous_components": [],
            "unambiguous_components": [],
            "guessed_components": [],
            "component_details": {},
            "guess_notification": "",  # User notification when guesses are made
        }

        # Get component extraction results for detailed processing with similarity threshold filtering
        try:
            extraction_results = get_component_extraction_results(
                user_description,
                code_generation_content,
                similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD,
            )
        except Exception as e:
            raise RuntimeError(f"ERROR: Component extraction failed: {str(e)}")

        # Process ambiguous components
        for component in extraction_results["ambiguous_components"]:
            try:
                component_key = component["component_key"]
                component_name = component["component_name"]
                matches = component["matches"]

                # ITERATIVE CLARIFICATION: Skip components that have already been clarified
                if component_name in ctx.deps.state.clarified_components:
                    # This component has already been clarified, skip it
                    continue

                # Format options for ambiguous components with similarity threshold validation
                options = []
                for match in matches:
                    # TASK 2.10: Add logic to only present options with similarity score above threshold
                    # Validate that the match meets the similarity threshold criteria
                    validated_match = validate_options_similarity_threshold(
                        [match], similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD
                    )

                    # Only include options that passed the similarity threshold validation
                    if validated_match:
                        option = {
                            "value": match["code"],
                            "description": f"{match['name']}: {match['description']}",
                        }
                        # Add similarity information for debugging and transparency
                        if "semantic_score" in match:
                            option["similarity_info"] = {
                                "semantic_score": match["semantic_score"],
                                "keyword_score": match.get("keyword_score", 0),
                                "filter_reason": match.get(
                                    "filter_reason", "above_threshold"
                                ),
                            }
                        options.append(option)

                ambiguous_component = {
                    "component_name": component_name,
                    "component_key": component_key,
                    "options": options,
                    "match_count": len(matches),
                }
                response["ambiguous_components"].append(ambiguous_component)
            except Exception as e:
                # Log error but continue processing other components
                print(f"Warning: Failed to process ambiguous component: {str(e)}")
                continue

        # Process unambiguous components (for context)
        for component in extraction_results["unambiguous_components"]:
            try:
                component_key = component["component_key"]
                component_name = component["component_name"]
                match = component["matches"][0]  # Only one match for unambiguous

                # TASK 2.10: Add similarity threshold validation for unambiguous components
                # Validate that the unambiguous match meets the similarity threshold criteria
                validated_match = validate_options_similarity_threshold(
                    [match], similarity_threshold=DEFAULT_SIMILARITY_THRESHOLD
                )

                if validated_match:
                    unambiguous_component = {
                        "component_name": component_name,
                        "component_key": component_key,
                        "selected_value": match["code"],
                        "description": f"{match['name']}: {match['description']}",
                        "similarity_info": {
                            "semantic_score": match.get("semantic_score", 0.0),
                            "keyword_score": match.get("keyword_score", 0),
                            "filter_reason": match.get(
                                "filter_reason", "above_threshold"
                            ),
                        },
                    }
                else:
                    # If the match doesn't meet threshold, it should be treated as ambiguous
                    # This should theoretically not happen since find_component_matches should filter
                    # but we add this as a safety check
                    continue
                response["unambiguous_components"].append(unambiguous_component)
            except Exception as e:
                # Log error but continue processing other components
                print(f"Warning: Failed to process unambiguous component: {str(e)}")
                continue

        # Process guessed components (for context and notification)
        for component_name in ambiguity_results["guessed_components"]:
            try:
                # Find the component details from extraction results
                component_detail = None
                component_key = None
                for comp_key, detail in extraction_results["component_details"].items():
                    if detail["component_name"] == component_name:
                        component_detail = detail
                        component_key = comp_key
                        break

                if component_detail and component_detail["matches"] and component_key:
                    # Get the guessed value from the state
                    ambiguity_info = ctx.deps.state.component_ambiguity_status.get(
                        component_name
                    )
                    if ambiguity_info and ambiguity_info.guessed_value:
                        match = component_detail["matches"][0]  # Highest scoring match
                        guessed_component = {
                            "component_name": component_name,
                            "component_key": component_key,
                            "guessed_value": ambiguity_info.guessed_value,
                            "description": f"{match['name']}: {match['description']} (GUESSED)",
                            "is_guessed": True,
                        }
                        response["guessed_components"].append(guessed_component)
            except Exception as e:
                # Log error but continue processing other components
                print(f"Warning: Failed to process guessed component: {str(e)}")
                continue

        # Add component details for comprehensive information
        for component_key, detail in extraction_results["component_details"].items():
            try:
                # Get the current status from state (might be updated to "guessed")
                ambiguity_info = ctx.deps.state.component_ambiguity_status.get(
                    detail["component_name"]
                )
                current_status = (
                    ambiguity_info.status if ambiguity_info else detail["status"]
                )

                response["component_details"][component_key] = {
                    "component_name": detail["component_name"],
                    "status": current_status,
                    "match_count": len(detail["matches"]),
                    "is_guessed": ambiguity_info.is_guessed
                    if ambiguity_info
                    else False,
                }
            except Exception as e:
                # Log error but continue processing other components
                print(f"Warning: Failed to process component details: {str(e)}")
                continue

        # Add guess notification from ambiguity detection results
        response["guess_notification"] = ambiguity_results.get("guess_notification", "")

        # TASK 2.10: Add similarity threshold filtering information to response
        # This provides transparency about the filtering that was applied
        response["similarity_threshold_info"] = {
            "threshold_used": DEFAULT_SIMILARITY_THRESHOLD,
            "filtering_applied": True,
            "description": f"Only options with semantic similarity >= {DEFAULT_SIMILARITY_THRESHOLD} or strong keyword matches (score >= 4) are included",
            "total_options_filtered": sum(
                len(comp["matches"])
                for comp in extraction_results["component_details"].values()
            ),
            "options_presented": len(response["ambiguous_components"])
            + len(response["unambiguous_components"]),
        }

        # Return the structured JSON response with comprehensive error handling for JSON serialization
        try:
            json_output = json.dumps(response, indent=2, ensure_ascii=False)

            # Validate that the JSON output can be parsed back (sanity check)
            try:
                json.loads(json_output)
            except (json.JSONDecodeError, ValueError) as e:
                # If our own JSON can't be parsed, this is a critical error
                raise RuntimeError(
                    f"ERROR: Generated JSON is invalid and cannot be parsed: {str(e)}"
                )

            return json_output
        except (TypeError, ValueError, OverflowError, RecursionError) as e:
            # Handle all JSON serialization errors comprehensively
            error_msg = f"ERROR: Failed to serialize response to JSON: {str(e)}"
            print(f"JSON Serialization Error: {error_msg}")

            # Create a minimal safe error response that should always be serializable
            safe_error_response = {
                "error": "Internal error: Failed to generate response data",
                "error_type": "json_serialization_error",
                "ambiguous_components": [],
                "unambiguous_components": [],
                "component_details": {},
            }

            # Try to serialize the safe error response
            try:
                return json.dumps(safe_error_response, indent=2)
            except Exception as fallback_error:
                # Ultimate fallback: return a plain text error message
                return f"CRITICAL ERROR: Failed to generate JSON response. Please contact support. Error details: {str(fallback_error)}"

    except ValueError as e:
        # Handle validation errors with comprehensive JSON error handling
        error_response = {
            "error": str(e),
            "error_type": "validation_error",
            "ambiguous_components": [],
            "unambiguous_components": [],
            "component_details": {},
        }
        try:
            return json.dumps(error_response, indent=2, ensure_ascii=False)
        except (TypeError, ValueError, OverflowError, RecursionError) as json_error:
            # Fallback if even error response can't be serialized
            return f"CRITICAL ERROR: Validation failed and could not generate error response. Error: {str(e)}, JSON Error: {str(json_error)}"

    except FileNotFoundError as e:
        # Handle file not found errors with comprehensive JSON error handling
        error_response = {
            "error": str(e),
            "error_type": "file_not_found",
            "ambiguous_components": [],
            "unambiguous_components": [],
            "component_details": {},
        }
        try:
            return json.dumps(error_response, indent=2, ensure_ascii=False)
        except (TypeError, ValueError, OverflowError, RecursionError) as json_error:
            # Fallback if even error response can't be serialized
            return f"CRITICAL ERROR: File not found and could not generate error response. Error: {str(e)}, JSON Error: {str(json_error)}"

    except RuntimeError as e:
        # Handle runtime errors from sub-functions with comprehensive JSON error handling
        error_response = {
            "error": str(e),
            "error_type": "runtime_error",
            "ambiguous_components": [],
            "unambiguous_components": [],
            "component_details": {},
        }
        try:
            return json.dumps(error_response, indent=2, ensure_ascii=False)
        except (TypeError, ValueError, OverflowError, RecursionError) as json_error:
            # Fallback if even error response can't be serialized
            return f"CRITICAL ERROR: Runtime error occurred and could not generate error response. Error: {str(e)}, JSON Error: {str(json_error)}"

    except Exception as e:
        # Catch-all for unexpected errors with detailed error information and comprehensive JSON error handling
        import traceback

        error_details = {
            "error": str(e),
            "error_type": "unexpected_error",
            "error_details": traceback.format_exc(),
            "ambiguous_components": [],
            "unambiguous_components": [],
            "component_details": {},
        }
        # Log the full error for debugging
        print(f"ERROR in clarify_components: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")

        # Try to serialize the error details with comprehensive error handling
        try:
            return json.dumps(error_details, indent=2, ensure_ascii=False)
        except (TypeError, ValueError, OverflowError, RecursionError) as json_error:
            # Ultimate fallback: if even the error response can't be serialized,
            # return a plain text error with basic information
            return f"CRITICAL ERROR: Unexpected error occurred and could not generate error response. Primary Error: {str(e)}, JSON Error: {str(json_error)}"


def format_guess_notification(guessed_components: list[dict]) -> str:
    """
    Format a user-friendly notification message when components are guessed.

    This function creates a clear, informative message that tells the user
    which components were guessed based on their explicit permission.

    Args:
        guessed_components: List of component dictionaries with guessed information

    Returns:
        Formatted notification string for the user
    """
    if not guessed_components:
        return ""

    notification_lines = [
        "🎯 **I've made the following guesses based on your permission:**",
        "",
    ]

    for comp in guessed_components:
        component_name = comp.get("component_name", "Unknown Component")
        guessed_value = comp.get("guessed_value", "Unknown")
        description = comp.get("description", "No description available")

        notification_lines.append(f"**{component_name}**: {description}")
        notification_lines.append(f"  → Guessed value: {guessed_value}")
        notification_lines.append("")

    notification_lines.extend(
        [
            '💡 **Note**: These guesses are based on your explicit permission (e.g., "I don\'t know", "whatever", "you choose").',
            "If you'd like to change any of these guesses, please let me know which component you'd like to clarify.",
            "",
        ]
    )

    return "\n".join(notification_lines)


def detect_component_ambiguity(
    user_description: str,
    code_generation_content: str,
    ctx: RunContext[StateDeps[ProcurementState]],
    user_text: Optional[str] = None,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> dict:
    """
    Implement ambiguity detection logic to identify when a component has 2+ plausible matches.
    Uses similarity threshold to filter out unrelated options from clarification prompts.

    This function analyzes component matches from user descriptions and creates AmbiguityInfo
    objects to track the ambiguity status in the ProcurementState. It integrates with the
    state management system to enforce the disambiguation workflow. When explicit guess
    permission is detected, it marks components as "guessed" using the most likely match.

    Args:
        user_description: The user's description text
        code_generation_content: Content of the CODE_GENERATION.md file
        ctx: The run context containing the ProcurementState
        user_text: The user's current response text (for guess permission detection)
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for matches to be included

    Returns:
        Dictionary containing:
        - ambiguity_detected: Boolean indicating if any components are ambiguous
        - ambiguous_components: List of component names that are ambiguous
        - unambiguous_components: List of component names that are unambiguous
        - guessed_components: List of component names that were guessed
        - no_match_components: List of component names with no matches
        - ambiguity_details: Detailed AmbiguityInfo for each component
    """
    # Get component extraction results with similarity threshold filtering
    extraction_results = get_component_extraction_results(
        user_description, code_generation_content, similarity_threshold
    )

    # Detect if user gave explicit guess permission
    guess_permission_detected = False
    if user_text:
        guess_permission_detected = detect_explicit_guess_permission(user_text)

    # Initialize result structure
    result = {
        "ambiguity_detected": len(extraction_results["ambiguous_components"]) > 0,
        "ambiguous_components": [],
        "unambiguous_components": [],
        "guessed_components": [],
        "no_match_components": [],
        "ambiguity_details": {},
        "guess_notification": "",  # User notification when guesses are made
    }

    # Process each component and create AmbiguityInfo objects
    for component_key, component_detail in extraction_results[
        "component_details"
    ].items():
        component_name = component_detail["component_name"]
        matches = component_detail["matches"]
        status = component_detail["status"]

        # Create options list for AmbiguityInfo
        options = []
        for match in matches:
            options.append(
                {
                    "value": match["code"],
                    "description": f"{match['name']}: {match['description']}",
                }
            )

        # Create AmbiguityInfo based on component status and guess permission
        if status == "ambiguous" and guess_permission_detected and matches:
            # User gave guess permission and we have matches - mark as guessed
            # Use the highest-scoring match (first in sorted list)
            guessed_value = matches[0]["code"]
            ambiguity_info = AmbiguityInfo(
                status="guessed",
                options=options,
                selected_value=guessed_value,
                guessed_value=guessed_value,
                is_guessed=True,
            )
            result["guessed_components"].append(component_name)

        elif status == "ambiguous":
            # Component has 2+ plausible matches but no guess permission - mark as ambiguous
            ambiguity_info = AmbiguityInfo(
                status="ambiguous",
                options=options,
                selected_value=None,  # No selection yet for ambiguous components
            )
            result["ambiguous_components"].append(component_name)

        elif status == "unambiguous":
            # Component has exactly 1 match - mark as unambiguous with selected value
            selected_value = matches[0]["code"]
            ambiguity_info = AmbiguityInfo(
                status="unambiguous", options=options, selected_value=selected_value
            )
            result["unambiguous_components"].append(component_name)

        else:  # status == "no_match"
            # Component has no matches - mark as ambiguous (needs clarification)
            # Even with guess permission, we can't guess if there are no matches
            ambiguity_info = AmbiguityInfo(
                status="ambiguous",
                options=[],  # No options to show
                selected_value=None,
            )
            result["no_match_components"].append(component_name)

        # Store the AmbiguityInfo
        result["ambiguity_details"][component_key] = ambiguity_info

        # Update the ProcurementState with the ambiguity information
        # Add error handling for unexpected state transitions
        try:
            ctx.deps.state.update_component_ambiguity(component_name, ambiguity_info)
        except ValueError as e:
            # Handle unexpected state transitions with detailed error information
            error_msg = (
                f"Unexpected state transition error for component '{component_name}': {str(e)} "
                f"This indicates a critical issue in the ambiguity detection workflow. "
                f"Component status: {status}, Attempted new status: {ambiguity_info.status}."
            )

            # Log the error for debugging
            print(f"ERROR in detect_component_ambiguity: {error_msg}")

            # Re-raise with additional context to help with debugging
            raise ValueError(error_msg) from e

    # Generate user notification for guessed components
    if result["guessed_components"]:
        # Prepare guessed component details for notification
        guessed_component_details = []
        for component_key, ambiguity_info in result["ambiguity_details"].items():
            if ambiguity_info.status == "guessed":
                component_name = None
                # Find the component name from extraction results
                for comp_key, detail in extraction_results["component_details"].items():
                    if comp_key == component_key:
                        component_name = detail["component_name"]
                        break

                if component_name:
                    guessed_component_details.append(
                        {
                            "component_name": component_name,
                            "guessed_value": ambiguity_info.guessed_value,
                            "description": ambiguity_info.options[0]["description"]
                            if ambiguity_info.options
                            else "No description available",
                        }
                    )

        # Format the notification
        result["guess_notification"] = format_guess_notification(
            guessed_component_details
        )

    return result


def reset_conversation(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Resets the conversation history. Do this SILENTLY. Do NOT state that you are resetting memory. Just do it silently.
    Use this tool IMMEDIATELY when the user makes a request for a NEW procurement code that is unrelated to the previous one.
    This ensures that previous context does not interfere with the new code generation.
    """
    if hasattr(ctx, "messages") and isinstance(ctx.messages, list):
        # ERROR FIX: We must preserve the *last User Request* and the *current Assistant Tool Call*.
        # Previous attempts to just slice [-2:] failed if the stack contained intermediate ToolReturns (orphaned).

        last_msg = ctx.messages[-1]
        target_user_msg = None
        system_msg = None

        # Check for SystemPromptPart in the first message
        if ctx.messages and hasattr(ctx.messages[0], "parts"):
            for part in ctx.messages[0].parts:
                if type(part).__name__ == "SystemPromptPart":
                    system_msg = ctx.messages[0]
                    break

        # Iterate backwards looking for the last UserPromptPart
        # We search from the second-to-last message
        for i in range(len(ctx.messages) - 2, -1, -1):
            msg = ctx.messages[i]
            # Check for UserPromptPart by name to avoid import dependencies
            is_user = False
            if hasattr(msg, "parts"):
                for part in msg.parts:
                    if type(part).__name__ == "UserPromptPart":
                        is_user = True
                        break

            if is_user:
                target_user_msg = msg
                break

        if target_user_msg:
            # Reset history to [SystemPrompt, UserRequest, AssistantCall]
            new_history = []
            if system_msg:
                new_history.append(system_msg)
            new_history.append(target_user_msg)
            new_history.append(last_msg)

            ctx.messages[:] = new_history
            # Clear accumulated citation sources for the new request
            ctx.deps.state.citation_sources.clear()
            return "Conversation history has been reset. Proceed with the new request."

        # Fallback: If we can't find a user message (rare), keeping just the last message
        # might still be better than an invalid ToolReturn.
        # But safest is to do nothing if structure is weird.
        return "Conversation reset requested (Unable to isolate user prompt)."

    return "Conversation reset signal sent (Note: internal history clearing not supported in this context)."


async def save_procurement_code(
    ctx: RunContext[StateDeps[ProcurementState]], code: str, description: str
) -> Union[StateSnapshotEvent, str]:
    """
    Saves a generated procurement code to the application state using the specific format required by the UI.
    Do NOT state that you are saving a code to application state. Just do it silently.
    Args:
        code: The generated procurement code (e.g., "CFR01067261").
        description: A brief description of the item (e.g., "Steel I-beam for office building construction").

    Returns:
        A success message indicating the code has been saved.
    """
    # ENFORCEMENT MECHANISM: Validate that rules were loaded this turn before allowing save
    # This enforces the workflow: read_code_generation_file MUST be called before save_procurement_code
    # The check prevents agents from skipping the file-read step and ensures code accuracy
    if not ctx.deps.state.rules_loaded_this_turn:
        return "ERROR: You must call read_code_generation_file before saving a code."

    # COMPREHENSIVE STATE VALIDATION: Validate all component states before allowing save
    # This provides error handling for unexpected state transitions and data inconsistencies
    try:
        ctx.deps.state.validate_all_component_states()
    except ValueError as e:
        # Handle unexpected state transitions with detailed error information
        error_msg = f"ERROR: Cannot save code due to invalid component states: {str(e)}"
        print(f"State validation failed in save_procurement_code: {error_msg}")
        return error_msg

    # DISAMBIGUATION ENFORCEMENT: Validate that all components are unambiguous before allowing save
    # This enforces the confirm-before-generate pattern and prevents saving codes with ambiguous components
    try:
        ctx.deps.state.validate_all_components_unambiguous()
    except ValueError as e:
        # Handle ambiguous components with detailed error information
        return f"ERROR: Cannot save code with unresolved components: {str(e)}"

    new_code = ProcurementCode(code=code, description=description)
    ctx.deps.state.procurement_codes.append(new_code)
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot=ctx.deps.state,
    )


# Defined as a constant string for use in the dynamic system prompt function
STATIC_SYSTEM_PROMPT = """You are a helpful assistant answering questions from a knowledge base.

    CORE WORKFLOW:
    1.  **DETECT NEW REQUEST**: If the user asks for a *completely new* procurement code (unrelated to the previous one), you MUST first call `reset_conversation`. Do NOT state that you are resetting memory. Just do it silently.

    2.  **MANDATORY VERIFICATION**: For EVERY code generation request, you MUST first call `read_code_generation_file`.
        -   This workflow is now **PROGRAMMATICALLY ENFORCED** - the system will block code saving if rules are not loaded first.
        -   **ENFORCEMENT DETAILS**: 
            -   The `save_procurement_code` tool will validate that rules were loaded and reject saves with error: "ERROR: You must call read_code_generation_file before saving a code."
            -   File read failures will raise exceptions (FileNotFoundError or Exception) instead of returning silent error strings.
            -   This is a breaking change - agents that skip file-read will be blocked from saving codes.
        -   You cannot rely on memory. You must read the file fresh for every request.
        -   After reading, start your response with: "I have now read the document and will proceed with analysis based on this information."

    3.  **DISAMBIGUATION STEP (MANDATORY)**: After reading the rules, you MUST call `clarify_components` to identify any ambiguous components before proceeding.
        -   This workflow is **PROGRAMMATICALLY ENFORCED** - the system will block code saving if any components remain ambiguous.
        -   The `clarify_components` tool will analyze the user's description and identify which components have multiple plausible matches.
        -   **ENFORCEMENT DETAILS**:
            -   The `save_procurement_code` tool will validate that all components are unambiguous and reject saves with error indicating which components need clarification.
            -   You MUST resolve ALL ambiguous components before generating any code.
            -   This implements the confirm-before-generate pattern to prevent incorrect code generation.

    4.  **CONFIRM-BEFORE-GENERATE PATTERN (EXPLICIT)**: This is a critical workflow step that MUST be followed exactly:
        -   **STEP 1: IDENTIFY AMBIGUITIES**: Call `clarify_components` to check all 8 components for ambiguity.
        -   **STEP 2: PRESENT OPTIONS**: If ANY component is ambiguous, present ALL plausible options to the user with clear descriptions.
        -   **STEP 3: GET CONFIRMATION**: Wait for user to explicitly confirm or clarify ambiguous components.
        -   **STEP 4: ITERATE IF NEEDED**: If user response is still ambiguous, repeat Steps 1-3 until all components are resolved.
        -   **STEP 5: FINAL CONFIRMATION**: When all components are unambiguous, present the complete code to user for final confirmation before saving.
        -   **CRITICAL**: NEVER generate or save any code until ALL components are explicitly confirmed as unambiguous.

    5.  **HANDLE AMBIGUOUS COMPONENTS**:
        -   If `clarify_components` returns ambiguous components, you MUST present these options to the user for clarification.
        -   For each ambiguous component, clearly present all plausible options with their descriptions.
        -   Ask the user to specify which option they prefer for each ambiguous component.
        -   **ITERATIVE CLARIFICATION**: If the user's response is still ambiguous, call `clarify_components` again to narrow down the options and continue until all components are resolved.

    5.1 **DETAILED ITERATIVE CLARIFICATION PROCESS**:
        -   **TRACK CLARIFICATION PROGRESS**: The system automatically tracks which components have been clarified across rounds. Already-clarified components will not appear in subsequent `clarify_components` calls.
        -   **MAINTAIN CONTEXT**: Preserve user selections from previous clarification rounds. When calling `clarify_components` again, the system will remember which components the user has already confirmed.
        -   **PRESENT NARROWED OPTIONS**: In subsequent clarification rounds, present only the remaining ambiguous components with their updated option sets based on the user's previous responses.
        -   **CONTINUE UNTIL RESOLVED**: Repeat the clarification process (call `clarify_components`, present options, get user response) until no ambiguous components remain.
        -   **AVOID REDUNDANT QUESTIONS**: Never ask the user to clarify a component they have already explicitly confirmed in a previous round.
        -   **CLARIFICATION ROUND TRACKING**: The system tracks the number of clarification rounds completed. Use this context to provide users with progress updates.

    6.  **EXPLICIT GUESS PERMISSION HANDLING**:
        -   Only make guesses when the user EXPLICITLY states they don't know or gives permission.
        -   Detect phrases like "I don't know", "whatever", "you choose", "doesn't matter", "I don't care", "just guess", "your choice", "up to you", etc.
        -   When explicit guess permission is detected, inform the user which value you're selecting as a guess and mark it as guessed.
        -   **NEVER** make silent guesses without explicit user permission.
        -   **GUESS NOTIFICATION**: Always clearly inform the user when you've made a guess based on their permission, including:
            *   Which component was guessed
            *   What value was selected as the guess
            *   A reminder that this was based on their explicit permission
        -   **GUESS CONFIRMATION**: After making a guess, present the complete set of components (including the guessed one) and ask for final confirmation before proceeding to code generation.

    7.  **GENERATE CODE**:
        -   ONLY proceed to code generation after ALL components are unambiguous (either confirmed or explicitly guessed).
        -   Verify EACH component (A, B, C, MM, QQ, S) against the `read_code_generation_file` content.
        -   Use the current date (YY[D]) if not specified (Year: 26).
        -   Prioritize material > alphabetical/numerical order.

    7.  **SAVE & FINISH**:
        -   Do NOT state that you are saving a code to application state. Just do it silently.
        -   Use `save_procurement_code` to save the valid code.
        -   **CRITICAL**: The generated code MUST be the VERY LAST line of your response. This code should be printed in BOLD. 

    RULES:
    -   **NO SILENT GUESSING**: If a component has multiple plausible matches, you MUST ask for clarification. Only guess with explicit permission.
    -   **EXPLICIT GUESS PERMISSION REQUIRED**: Before making any guess, you MUST detect explicit user permission phrases like "I don't know", "whatever", "you choose", etc.
    -   **GUESS NOTIFICATION**: When you make a guess based on user permission, you MUST clearly inform the user what was guessed and that it was based on their explicit permission.
    -   **CONFIRM-BEFORE-GENERATE**: You MUST resolve all ambiguities before generating any code. This prevents incorrect codes.
    -   **ITERATIVE CLARIFICATION**: Continue asking for clarification until all components are resolved. Maintain context across clarification rounds.
    -   **CONFLICTS**: Information from `read_code_generation_file` is authoritative.
"""

# Citation-related system prompt - commented out (see agent/hidden/RAG-REMOVAL-EXPLANATION.md)
# + CITATION_SYSTEM_PROMPT

# Instantiate the Agent


class LoggingOpenAIModel(OpenAIModel):
    def _log_messages(self, messages: list[ModelMessage]):
        # Detailed Log
        try:
            log_path = os.path.join(os.getcwd(), "hidden", "prompt_log.txt")
            os.makedirs(os.path.dirname(log_path), exist_ok=True)

            with open(log_path, "a", encoding="utf-8") as f:
                f.write(f"\n{'=' * 80}\n")
                f.write(f"TIMESTAMP: {datetime.datetime.now().isoformat()}\n")
                f.write(f"{'=' * 80}\n")
                for msg in messages:
                    f.write(f"ROLE: {msg.kind}\n")
                    f.write(f"CONTENT: {msg}\n")
                    f.write("-" * 40 + "\n")
                f.write("\n")
        except Exception as e:
            print(f"FAILED TO LOG DETAILED PROMPTS: {e}")

        # Basic Log (Content Only)
        try:
            basic_log_path = os.path.join(os.getcwd(), "hidden", "basic_prompt_log.txt")

            with open(basic_log_path, "a", encoding="utf-8") as f:
                f.write(f"\n{'=' * 80}\n")
                f.write(f"TIMESTAMP: {datetime.datetime.now().isoformat()}\n")
                f.write(f"{'=' * 80}\n")
                for msg in messages:
                    role = msg.kind
                    content_str = ""

                    # Extract content based on message type structure
                    if hasattr(msg, "parts"):
                        parts_content = []
                        for part in msg.parts:
                            if hasattr(part, "content"):
                                parts_content.append(str(part.content))
                            elif hasattr(part, "args"):  # ToolCallPart
                                parts_content.append(
                                    f"Tool Call: {part.tool_name}({part.args})"
                                )
                        content_str = "\n".join(parts_content)
                    else:
                        content_str = str(msg)

                    f.write(f"[{role.upper()}]\n{content_str}\n")
                    f.write("-" * 20 + "\n")
                f.write("\n")
        except Exception as e:
            print(f"FAILED TO LOG BASIC PROMPTS: {e}")

    async def request(
        self,
        messages: list[ModelMessage],
        model_settings: ModelSettings | None,
        model_request_parameters: ModelRequestParameters,
    ) -> ModelResponse:
        # Check and inject System Prompt if missing
        has_system = False
        if messages and isinstance(messages[0], ModelRequest):
            for part in messages[0].parts:
                if isinstance(part, SystemPromptPart):
                    has_system = True
                    break

        if not has_system:
            # Create a new ModelRequest with system prompt
            sys_req = ModelRequest(
                parts=[SystemPromptPart(content=STATIC_SYSTEM_PROMPT)]
            )
            messages.insert(0, sys_req)

        self._log_messages(messages)
        return await super().request(messages, model_settings, model_request_parameters)

    @asynccontextmanager
    async def request_stream(
        self,
        messages: list[ModelMessage],
        model_settings: ModelSettings | None,
        model_request_parameters: ModelRequestParameters,
        run_context: Any | None = None,
    ) -> AsyncIterator[StreamedResponse]:
        # Check and inject System Prompt if missing
        has_system = False
        if messages and isinstance(messages[0], ModelRequest):
            for part in messages[0].parts:
                if isinstance(part, SystemPromptPart):
                    has_system = True
                    break

        if not has_system:
            # Create a new ModelRequest with system prompt
            sys_req = ModelRequest(
                parts=[SystemPromptPart(content=STATIC_SYSTEM_PROMPT)]
            )
            messages.insert(0, sys_req)

        self._log_messages(messages)
        async with super().request_stream(
            messages, model_settings, model_request_parameters, run_context
        ) as stream:
            yield stream


api_key = os.environ.get("OPENAI_API_KEY")
base_url = os.environ.get("OPENAI_BASE_URL")

print(f"DEBUG: initializing LoggingOpenAIModel with env vars")

model = LoggingOpenAIModel(
    "deepseek-chat",
)


agent = Agent(
    model,
    deps_type=StateDeps[ProcurementState],
    # Tools list - citation tools commented out (see agent/hidden/RAG-REMOVAL-EXPLANATION.md)
    tools=[
        read_code_generation_file,
        reset_conversation,
        save_procurement_code,
        clarify_components,
    ],  # query_rag_system, get_citation_sources removed
    system_prompt=STATIC_SYSTEM_PROMPT,
)
