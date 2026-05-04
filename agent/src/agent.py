# Standard library imports
import os
import re
import datetime
import json
import logging
from typing import List, Optional, Any, Union
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

# ============================================================================
# DISAMBIGUATION WORKFLOW DOCUMENTATION
# ============================================================================
#
# OVERVIEW:
# This agent implements a confirm-before-generate pattern for procurement code
# generation to ensure accuracy by preventing ambiguous inputs from being
# silently guessed. The disambiguation workflow is programmatically enforced
# through state management and tool validation.
#
# KEY COMPONENTS:
#
# 1. DISAMBIGUATION WORKFLOW:
#    - User provides description → Agent reads rules → Agent detects ambiguities
#    → Agent presents clarification options → User confirms → Agent generates code
#
# 2. STATE MANAGEMENT:
#    - ProcurementState tracks component ambiguity status via component_ambiguity_status
#    - AmbiguityInfo class tracks each component's status (ambiguous/unambiguous/guessed)
#    - State transitions are validated to prevent invalid workflow progression
#
# 3. CORE TOOLS:
#    - clarify_components: Parses user description and identifies ambiguous components
#    - save_procurement_code: Validates all components are unambiguous before saving
#    - read_code_generation_file: Must be called before any other operations
#
# 4. ITERATIVE CLARIFICATION:
#    - System tracks which components have been clarified across multiple rounds
#    - Already-clarified components are filtered out from subsequent clarification calls
#    - User selections are preserved across clarification rounds
#
# 5. GUESS PERMISSION HANDLING:
#    - Only makes guesses when user explicitly states they don't know
#    - Detects phrases like "I don't know", "whatever", "you choose"
#    - Always informs user when a guess is made based on their permission
#
# 6. PROGRAMMATIC ENFORCEMENT:
#    - save_procurement_code rejects saves with ambiguous components
#    - State validation ensures only valid transitions occur
#    - Workflow cannot be bypassed through system prompt alone
#
# WORKFLOW SEQUENCE:
# 1. User requests procurement code
# 2. Agent calls read_code_generation_file (enforced)
# 3. Agent calls clarify_components to detect ambiguities
# 4. If ambiguous components exist, present options to user
# 5. User clarifies ambiguous components (iterative if needed)
# 6. When all components are unambiguous, generate code confidently
# 7. Call save_procurement_code (validates no ambiguous components)
# 8. Complete with justification and generated code
#
# For detailed implementation, see individual function documentation below.
# ============================================================================

# Third-party imports
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.messages import ModelMessage, ModelRequest, SystemPromptPart
from pydantic_ai.models import (
    ModelRequestParameters,
    StreamedResponse,
)
from pydantic_ai.settings import ModelSettings
from pydantic_ai.messages import ModelResponse
from ag_ui.core import EventType, StateSnapshotEvent
from llama_index.core import Settings
import numpy as np
from dotenv import load_dotenv

# Local application imports
from src.rag.index import get_index
from src.rag.settings import init_settings
from src.rag.citation import enable_citation, CITATION_SYSTEM_PROMPT
from src.rag.query import get_query_engine_tool

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", "..", ".env"))

# Set up logging for disambiguation events
logging.basicConfig(level=logging.INFO)
disambiguation_logger = logging.getLogger("disambiguation_events")
disambiguation_logger.setLevel(logging.INFO)

# Create file handler for disambiguation events
try:
    os.makedirs(os.path.join(os.getcwd(), "logs"), exist_ok=True)
    file_handler = logging.FileHandler(
        os.path.join(os.getcwd(), "logs", "disambiguation_events.log")
    )
    file_handler.setLevel(logging.INFO)

    # Create formatter
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    file_handler.setFormatter(formatter)

    # Add handler to logger
    disambiguation_logger.addHandler(file_handler)
except Exception as e:
    print(f"Warning: Could not set up disambiguation logging: {e}")

# ============================================================================
# DISAMBIGUATION METRICS TRACKING
# ============================================================================


class DisambiguationMetrics:
    """
    DISAMBIGUATION METRICS SYSTEM:
    Tracks and calculates disambiguation success rate and related metrics.

    This class implements the metrics collection system for monitoring the
    effectiveness of the disambiguation workflow. It tracks key performance
    indicators including success rate, clarification patterns, and component
    resolution statistics.

    METRICS TRACKED:
    - Total disambiguation attempts
    - Successful disambiguations (all components resolved)
    - Failed disambiguations (components still ambiguous)
    - Average clarification rounds per request
    - Component resolution statistics (ambiguous, unambiguous, guessed)
    - Success rate calculation

    USAGE:
    - Metrics are automatically collected during disambiguation workflow
    - Call get_success_rate() to calculate current success rate
    - Call log_metrics_summary() to output comprehensive metrics report
    - Call reset_metrics() to clear all metrics (for testing or periodic reset)

    INTEGRATION:
    - Integrated with detect_component_ambiguity for component-level metrics
    - Integrated with clarify_components for round-level metrics
    - Integrated with save_procurement_code for completion metrics
    - Metrics are logged to both file and console for monitoring
    """

    def __init__(self):
        """Initialize metrics tracking with default values."""
        self.total_disambiguation_attempts = 0
        self.successful_disambiguations = 0
        self.failed_disambiguations = 0
        self.total_clarification_rounds = 0
        self.components_analyzed = 0
        self.components_ambiguous = 0
        self.components_unambiguous = 0
        self.components_guessed = 0
        self.components_no_match = 0

    def record_disambiguation_attempt(self):
        """Record a new disambiguation attempt."""
        self.total_disambiguation_attempts += 1
        disambiguation_logger.info(
            f"Metrics: New disambiguation attempt recorded. Total attempts: {self.total_disambiguation_attempts}"
        )

    def record_successful_disambiguation(self, clarification_rounds: int = 0):
        """
        Record a successful disambiguation where all components were resolved.

        Args:
            clarification_rounds: Number of clarification rounds required
        """
        self.successful_disambiguations += 1
        self.total_clarification_rounds += clarification_rounds
        disambiguation_logger.info(
            f"Metrics: Successful disambiguation recorded. "
            f"Total successful: {self.successful_disambiguations}, "
            f"Rounds for this attempt: {clarification_rounds}"
        )

    def record_failed_disambiguation(self, clarification_rounds: int = 0):
        """
        Record a failed disambiguation where components remain ambiguous.

        Args:
            clarification_rounds: Number of clarification rounds attempted
        """
        self.failed_disambiguations += 1
        self.total_clarification_rounds += clarification_rounds
        disambiguation_logger.info(
            f"Metrics: Failed disambiguation recorded. "
            f"Total failed: {self.failed_disambiguations}, "
            f"Rounds for this attempt: {clarification_rounds}"
        )

    def record_component_analysis(
        self,
        ambiguous: int = 0,
        unambiguous: int = 0,
        guessed: int = 0,
        no_match: int = 0,
    ):
        """
        Record component-level analysis statistics.

        Args:
            ambiguous: Number of components marked as ambiguous
            unambiguous: Number of components marked as unambiguous
            guessed: Number of components marked as guessed
            no_match: Number of components with no matches
        """
        total_this_batch = ambiguous + unambiguous + guessed + no_match
        self.components_analyzed += total_this_batch
        self.components_ambiguous += ambiguous
        self.components_unambiguous += unambiguous
        self.components_guessed += guessed
        self.components_no_match += no_match

        disambiguation_logger.info(
            f"Metrics: Component analysis recorded. "
            f"This batch - Ambiguous: {ambiguous}, Unambiguous: {unambiguous}, "
            f"Guessed: {guessed}, No match: {no_match}"
        )

    def get_success_rate(self) -> float:
        """
        Calculate the disambiguation success rate.

        Returns:
            Success rate as a percentage (0.0 to 100.0)
            Returns 0.0 if no attempts have been made
        """
        if self.total_disambiguation_attempts == 0:
            return 0.0

        success_rate = (
            self.successful_disambiguations / self.total_disambiguation_attempts
        ) * 100.0
        return round(success_rate, 2)

    def get_average_clarification_rounds(self) -> float:
        """
        Calculate average number of clarification rounds per disambiguation attempt.

        Returns:
            Average rounds as float, or 0.0 if no attempts
        """
        if self.total_disambiguation_attempts == 0:
            return 0.0

        return round(
            self.total_clarification_rounds / self.total_disambiguation_attempts, 2
        )

    def get_component_resolution_rates(self) -> dict:
        """
        Calculate component resolution statistics.

        Returns:
            Dictionary with resolution rates for each component type
        """
        if self.components_analyzed == 0:
            return {
                "ambiguous_rate": 0.0,
                "unambiguous_rate": 0.0,
                "guessed_rate": 0.0,
                "no_match_rate": 0.0,
            }

        return {
            "ambiguous_rate": round(
                (self.components_ambiguous / self.components_analyzed) * 100.0, 2
            ),
            "unambiguous_rate": round(
                (self.components_unambiguous / self.components_analyzed) * 100.0, 2
            ),
            "guessed_rate": round(
                (self.components_guessed / self.components_analyzed) * 100.0, 2
            ),
            "no_match_rate": round(
                (self.components_no_match / self.components_analyzed) * 100.0, 2
            ),
        }

    def log_metrics_summary(self):
        """Log a comprehensive summary of all disambiguation metrics."""
        success_rate = self.get_success_rate()
        avg_rounds = self.get_average_clarification_rounds()
        resolution_rates = self.get_component_resolution_rates()

        summary_lines = [
            "=== DISAMBIGUATION METRICS SUMMARY ===",
            f"Total disambiguation attempts: {self.total_disambiguation_attempts}",
            f"Successful disambiguations: {self.successful_disambiguations}",
            f"Failed disambiguations: {self.failed_disambiguations}",
            f"Success rate: {success_rate}%",
            f"Average clarification rounds per attempt: {avg_rounds}",
            f"Total clarification rounds: {self.total_clarification_rounds}",
            "",
            "=== COMPONENT ANALYSIS ===",
            f"Total components analyzed: {self.components_analyzed}",
            f"Components ambiguous: {self.components_ambiguous} ({resolution_rates['ambiguous_rate']}%)",
            f"Components unambiguous: {self.components_unambiguous} ({resolution_rates['unambiguous_rate']}%)",
            f"Components guessed: {self.components_guessed} ({resolution_rates['guessed_rate']}%)",
            f"Components no match: {self.components_no_match} ({resolution_rates['no_match_rate']}%)",
            "=====================================",
        ]

        summary = "\n".join(summary_lines)
        disambiguation_logger.info(summary)
        print(summary)  # Also print to console for immediate visibility

        return summary

    def reset_metrics(self):
        """Reset all metrics to zero (for testing or periodic reset)."""
        self.total_disambiguation_attempts = 0
        self.successful_disambiguations = 0
        self.failed_disambiguations = 0
        self.total_clarification_rounds = 0
        self.components_analyzed = 0
        self.components_ambiguous = 0
        self.components_unambiguous = 0
        self.components_guessed = 0
        self.components_no_match = 0

        disambiguation_logger.info(
            "Metrics: All disambiguation metrics have been reset."
        )
        print("Disambiguation metrics have been reset.")


# Global metrics instance for use across the disambiguation workflow
disambiguation_metrics = DisambiguationMetrics()


def get_disambiguation_metrics() -> dict:
    """
    Get current disambiguation metrics including success rate and statistics.

    This function provides comprehensive access to the current disambiguation
    metrics, including success rate calculation, component resolution statistics,
    and clarification round analysis. It's designed for monitoring and reporting
    purposes.

    Returns:
        Dictionary containing all current disambiguation metrics:
        - success_rate: Current success rate as percentage
        - total_attempts: Total disambiguation attempts
        - successful_disambiguations: Number of successful completions
        - failed_disambiguations: Number of failed attempts
        - average_clarification_rounds: Average rounds per attempt
        - component_resolution_rates: Breakdown by component type
        - total_components_analyzed: Total components processed
    """
    success_rate = disambiguation_metrics.get_success_rate()
    avg_rounds = disambiguation_metrics.get_average_clarification_rounds()
    resolution_rates = disambiguation_metrics.get_component_resolution_rates()

    return {
        "success_rate": success_rate,
        "total_attempts": disambiguation_metrics.total_disambiguation_attempts,
        "successful_disambiguations": disambiguation_metrics.successful_disambiguations,
        "failed_disambiguations": disambiguation_metrics.failed_disambiguations,
        "average_clarification_rounds": avg_rounds,
        "total_clarification_rounds": disambiguation_metrics.total_clarification_rounds,
        "component_resolution_rates": resolution_rates,
        "total_components_analyzed": disambiguation_metrics.components_analyzed,
        "components_breakdown": {
            "ambiguous": disambiguation_metrics.components_ambiguous,
            "unambiguous": disambiguation_metrics.components_unambiguous,
            "guessed": disambiguation_metrics.components_guessed,
            "no_match": disambiguation_metrics.components_no_match,
        },
    }


def log_disambiguation_metrics_summary():
    """
    Log a comprehensive summary of disambiguation metrics.

    This function logs a detailed summary of all current disambiguation metrics,
    including success rate, component analysis, and clarification statistics.
    The summary is both logged to file and printed to console for immediate visibility.
    """
    return disambiguation_metrics.log_metrics_summary()


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
    DISAMBIGUATION DATA STRUCTURE:
    Data class to track component ambiguity status during disambiguation workflow.

    This class is the core data structure for implementing the confirm-before-generate
    pattern. It tracks whether a component is ambiguous, unambiguous, or guessed,
    maintains the list of plausible options, and stores the user's selected value.
    This enables programmatic enforcement of the disambiguation workflow.

    STATE TRANSITIONS:
    - "ambiguous" → "unambiguous" (user clarifies)
    - "ambiguous" → "guessed" (user gives explicit permission)
    - "unambiguous" → No further transitions allowed
    - "guessed" → No further transitions allowed

    Attributes:
        status: Either "ambiguous", "unambiguous", or "guessed"
        options: List of plausible matches for the component
        selected_value: The user's selected value (if resolved)
        guessed_value: The value selected when user gave explicit guess permission
        is_guessed: Boolean flag indicating if this component was guessed

    Usage in Disambiguation Workflow:
    1. Created by clarify_components tool when parsing user descriptions
    2. Stored in ProcurementState.component_ambiguity_status for enforcement
    3. Updated during iterative clarification rounds
    4. Validated by save_procurement_code before allowing code generation
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
    DISAMBIGUATION STATE MANAGEMENT:
    State for the Procurement Agent with comprehensive disambiguation tracking.

    This class implements the state management required for the confirm-before-generate
    workflow. It maintains conversation history, tracks component ambiguity status,
    and enforces the disambiguation workflow programmatically. The state prevents
    agents from bypassing the disambiguation process and ensures all components
    are resolved before code generation.

    DISAMBIGUATION ENFORCEMENT FIELDS:
    - rules_loaded_this_turn: Enforces workflow step ordering (must read rules before save)
    - component_ambiguity_status: Tracks ambiguity status for all 8 components
    - clarification_rounds: Enables iterative clarification with progress tracking
    - clarified_components: Prevents redundant questions across clarification rounds

    WORKFLOW ENFORCEMENT:
    1. rules_loaded_this_turn must be True before save_procurement_code can be called
    2. All components in component_ambiguity_status must be unambiguous before saving
    3. State transitions are validated to prevent invalid workflow progression
    4. Iterative clarification preserves context and tracks progress

    STATE VALIDATION:
    - validate_all_component_states(): Ensures all component states are valid
    - validate_all_components_unambiguous(): Blocks saves with ambiguous components
    - validate_state_transition(): Prevents invalid state changes

    Usage:
    - Initialized at start of each procurement code request
    - Updated by clarify_components tool during disambiguation
    - Validated by save_procurement_code before allowing code generation
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
            _node = node.node
            if hasattr(_node, "text") and _node.text:  # type: ignore[union-attr]
                source_text = _node.text  # type: ignore[union-attr]
            else:
                source_text = _node.get_content()
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
                # Enhanced keyword extraction for better matching
                base_keywords = [industry.lower(), description.lower()]

                # Add enhanced keywords based on the industry type
                enhanced_keywords = []
                industry_lower = industry.lower()

                # Agricultural products
                if "agricultural" in industry_lower or "farm" in industry_lower:
                    enhanced_keywords.extend(
                        ["agriculture", "farming", "crop", "harvest", "rural"]
                    )

                # Chemical products
                elif "chemical" in industry_lower:
                    enhanced_keywords.extend(
                        ["chemicals", "compound", "formula", "synthetic", "industrial"]
                    )

                # Food and beverage
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

                # Metal products
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

                # Textile products
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
                # Enhanced keyword extraction for manufacturing methods
                base_keywords = [method.lower(), description.lower()]

                # Add enhanced keywords based on the manufacturing method
                enhanced_keywords = []
                method_lower = method.lower()

                # Additive manufacturing / 3D printing
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

                # Blow molding
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

                # Casting
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

                # Forging
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

                # Machining
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

                # Welding
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
                # Enhanced keyword extraction for object shapes
                base_keywords = [shape.lower(), description.lower()]

                # Add enhanced keywords based on the object shape
                enhanced_keywords = []
                shape_lower = shape.lower()

                # Angular shapes
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

                # Barrel/cylindrical shapes
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

                # Cubic shapes
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

                # Flat/sheet shapes
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

                # Round/spherical shapes
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

                # Tubular shapes
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
                # Enhanced keyword extraction for quality grades
                base_keywords = [quality.lower()]
                if description.strip():
                    base_keywords.append(description.lower())

                # Add enhanced keywords based on the quality grade
                enhanced_keywords = []
                quality_lower = quality.lower()

                # Standard quality
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

                # Premium quality
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

                # Industrial quality
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

                # Aerospace quality
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

                # Medical quality
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

                # Add "-grade" variations for all quality types (important for matching "Aerospace-grade", "Medical-grade")
                grade_variations = [f"{quality_lower}-grade", f"{quality_lower}grade"]
                enhanced_keywords.extend(grade_variations)

                all_keywords = base_keywords + enhanced_keywords

                rules["quality_grade"][code.strip()] = {
                    "name": quality.strip(),
                    "description": description.strip(),
                    "keywords": all_keywords,
                }

    # Extract size categories (S)
    size_section = re.search(r"### Size Category.*?(?=###|$)", content, re.DOTALL)
    if size_section:
        size_matches = re.findall(
            r"\|\s*(\d)\s*\|\s*([^|]+)\s*\|\s*([^|]*)\s*\|", size_section.group()
        )
        for code, size, description in size_matches:
            if code.strip() and size.strip():
                # Enhanced keyword extraction for size categories
                base_keywords = [size.lower(), description.lower()]

                # Add enhanced keywords based on the size category
                enhanced_keywords = []
                size_lower = size.lower()

                # Small size
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

                # Medium size
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

                # Large size
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

                # Extra Large size
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
         * Sufficient semantic similarity (≥ threshold), OR
         * Meaningful keyword matches (≥ threshold combined with semantic relevance)
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

        # TASK 13.1: STRICT DESCRIPTION MATCHING - Only present options that match user's description
        # Modified filtering logic to ensure all options genuinely match the user's description

        # Case 1: High semantic similarity (≥ threshold) - Strong description match
        # These options are semantically relevant to the user's description
        if semantic_score >= similarity_threshold:
            pass  # Will be included - this option matches the user's description semantically

        # Case 2: Moderate semantic similarity with keyword evidence - Description match with keyword support
        # These options have both some semantic relevance AND keyword evidence of matching
        elif semantic_score >= (similarity_threshold * 0.7) and keyword_score >= 2:
            # Reduced semantic threshold (70% of original) but requires keyword evidence
            # This ensures the option is relevant to the description while requiring keyword support
            pass  # Will be included - this option matches with keyword and semantic evidence

        # Case 3: Semantic similarity failed (returned 0.0) - Fall back to keyword-only matching
        # This handles cases where llama_index is not available or semantic calculation fails
        elif semantic_score == 0.0 and keyword_score >= 1:
            # When semantic similarity fails, rely on keyword evidence
            # This ensures basic functionality when semantic features are unavailable
            pass  # Will be included - fallback to keyword matching when semantic fails

        # Case 4: All other cases - Filter out as not matching user's description
        else:
            # Options that don't meet the above criteria don't truly match the user's description
            # This includes:
            # - Very low semantic similarity with insufficient keyword evidence
            # - Options that are unrelated to the user's specific description
            continue  # Skip this match - doesn't match user's description

        # Convert semantic score to a 0-10 scale for combination with keyword score
        semantic_score_scaled = semantic_score * 10

        # Combine scores: keyword_score (0-6 range) + semantic_score_scaled (0-10 range)
        # This gives semantic similarity more weight in the matching
        combined_score = keyword_score + semantic_score_scaled

        # Only include matches with positive combined scores after strict filtering
        # Since we've already filtered for description matches, all should be relevant
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

    # EXACT NAME MATCH OVERRIDE:
    # When the user's description contains a term that exactly matches a rulebook entry's
    # name, treat it as a definitive (1-1) match. This prevents the system from flagging
    # clearly-specified rulebook terms as ambiguous just because semantically similar
    # alternatives also score above the threshold.
    #
    # When multiple exact name matches are found (e.g., "Industrial Standard" and
    # "Standard" both match because "standard" appears inside "industrial standard"),
    # check whether the longer match's name CONTAINS the shorter match's name as a
    # substring. If so, the shorter match is a subset of the longer one and the longer
    # (more specific) match wins. If the names are independent (neither contains the
    # other), both are legitimate matches and ambiguity is preserved.
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
        # This case should not be reached with the new filtering logic
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
    ctx: RunContext[StateDeps[ProcurementState]],
    user_description: str,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> str:
    """
    PRIMARY DISAMBIGUATION TOOL:
    Core component of the confirm-before-generate workflow. Parses user descriptions
    and identifies ambiguous components that require clarification before code generation.

    This tool is the heart of the disambiguation system and implements the programmatic
    enforcement mechanism. It analyzes user descriptions against CODE_GENERATION.md rules,
    identifies components with multiple plausible matches, and returns structured JSON
    that can be rendered by the UI for user clarification. Uses similarity threshold
    filtering to ensure only relevant options are presented.

    WORKFLOW ROLE:
    1. Called AFTER read_code_generation_file (enforced by state validation)
    2. Called BEFORE any code generation attempt
    3. Returns structured options for ambiguous components
    4. Enables iterative clarification by tracking already-resolved components
    5. Integrates with guess permission detection when user gives explicit permission

    SIMILARITY THRESHOLD FILTERING:
    - Filters out completely unrelated options from clarification prompts
    - Uses both semantic similarity and keyword matching
    - Ensures users only see options that actually match their description
    - Prevents overwhelming users with irrelevant choices

    ITERATIVE CLARIFICATION SUPPORT:
    - Skips components already in ctx.deps.state.clarified_components
    - Preserves previous user selections across clarification rounds
    - Tracks clarification progress via ctx.deps.state.clarification_rounds
    - Prevents redundant questions about already-confirmed components

    Args:
        ctx: The run context containing the ProcurementState with disambiguation tracking
        user_description: The user's description text to analyze for component extraction
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for option filtering

    Returns:
        JSON string containing structured disambiguation information:
        - ambiguous_components: List of components that need user clarification
        - unambiguous_components: List of components already resolved (for context)
        - guessed_components: List of components guessed with user permission
        - component_details: Detailed information about each component including scores
        - similarity_threshold_info: Transparency about filtering applied
        - guess_notification: User-friendly message about any guesses made

    ENFORCEMENT:
    - Validates rules_loaded_this_turn is True (workflow enforcement)
    - Updates ProcurementState.component_ambiguity_status with detected ambiguities
    - Integrates with state validation to prevent invalid transitions
    - Provides structured output for UI rendering and programmatic processing
    """
    try:
        # Input validation
        if not user_description or not isinstance(user_description, str):
            raise ValueError("ERROR: user_description must be a non-empty string")

        if not ctx or not hasattr(ctx, "deps") or not hasattr(ctx.deps, "state"):
            raise ValueError(
                "ERROR: Invalid context provided - missing state dependency"
            )

        # Validate and normalize the similarity threshold
        similarity_threshold = max(
            MINIMUM_SIMILARITY_THRESHOLD,
            min(MAXIMUM_SIMILARITY_THRESHOLD, similarity_threshold),
        )

        # Check if rules file has been loaded this turn

        # Check if rules file has been loaded this turn
        if not ctx.deps.state.rules_loaded_this_turn:
            raise ValueError(
                "ERROR: You must call read_code_generation_file before using clarify_components."
            )

        # Log the start of clarification process
        current_round = ctx.deps.state.clarification_rounds + 1
        disambiguation_logger.info(
            f"Starting clarification round {current_round} - "
            f"User description: {user_description[:100]}..., "
            f"Similarity threshold: {similarity_threshold}"
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
                similarity_threshold=similarity_threshold,
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
                similarity_threshold=similarity_threshold,
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
                    disambiguation_logger.info(
                        f"Skipping already clarified component '{component_name}' - "
                        f"Already in clarified_components set"
                    )
                    continue

                # Log that we're processing this ambiguous component
                disambiguation_logger.info(
                    f"Processing ambiguous component '{component_name}' for clarification - "
                    f"Original matches: {len(matches)}, "
                    f"Similarity threshold: {similarity_threshold}"
                )

                # Format options for ambiguous components with similarity threshold validation
                options = []
                for match in matches:
                    # TASK 2.10: Add logic to only present options with similarity score above threshold
                    # Validate that the match meets the similarity threshold criteria
                    validated_match = validate_options_similarity_threshold(
                        [match], similarity_threshold=similarity_threshold
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

                # Log the filtered options count
                disambiguation_logger.info(
                    f"Component '{component_name}' - "
                    f"Options after similarity threshold filtering: {len(options)} (from {len(matches)} original matches)"
                )

                ambiguous_component = {
                    "component_name": component_name,
                    "component_key": component_key,
                    "options": options,
                    "match_count": len(matches),
                }
                response["ambiguous_components"].append(ambiguous_component)
            except Exception as e:
                # Log error but continue processing other components
                error_msg = f"Failed to process ambiguous component: {str(e)}"
                print(f"Warning: {error_msg}")
                disambiguation_logger.error(error_msg)
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
                    [match], similarity_threshold=similarity_threshold
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

        # TASK 13.1: Update similarity threshold filtering information to reflect strict description matching
        # This provides transparency about the strict description matching filtering that was applied
        response["similarity_threshold_info"] = {
            "threshold_used": similarity_threshold,
            "filtering_applied": True,
            "description": f"Only options that match the user's description are included: high semantic similarity (>= {similarity_threshold}) OR moderate semantic similarity (>= {similarity_threshold * 0.7:.1f}) with keyword evidence (>= 2 keywords)",
            "filtering_logic": "strict_description_matching",
            "total_options_filtered": sum(
                len(comp["matches"])
                for comp in extraction_results["component_details"].values()
            ),
            "options_presented": len(response["ambiguous_components"])
            + len(response["unambiguous_components"]),
        }

        # Log the completion of this clarification round
        ambiguous_count = len(response["ambiguous_components"])
        unambiguous_count = len(response["unambiguous_components"])
        guessed_count = len(response["guessed_components"])

        # Update clarification rounds counter
        ctx.deps.state.clarification_rounds = current_round

        disambiguation_logger.info(
            f"Clarification round {current_round} completed - "
            f"Ambiguous components: {ambiguous_count}, "
            f"Unambiguous components: {unambiguous_count}, "
            f"Guessed components: {guessed_count}, "
            f"Total rounds completed: {ctx.deps.state.clarification_rounds}"
        )

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
    GUESS NOTIFICATION SYSTEM:
    Creates user-friendly notifications when components are guessed based on explicit permission.

    This function implements the transparency requirement for the guess permission
    system. When users give explicit permission to guess ambiguous components,
    this function generates a clear, informative notification that explains
    exactly what was guessed and why, maintaining user trust and control over
    the disambiguation process.

    NOTIFICATION PRINCIPLES:
    1. TRANSPARENCY: Clearly state what was guessed and why
    2. ACCOUNTABILITY: Show that guesses are based on user's explicit permission
    3. CLARITY: Present information in a user-friendly, readable format
    4. EMPOWERMENT: Remind users they can change guesses if desired
    5. CONTEXT: Provide enough detail for informed decision-making

    NOTIFICATION STRUCTURE:
    1. HEADER: Clear indication that guesses were made
    2. COMPONENT DETAILS: For each guessed component:
       - Component name
       - Guessed value selected
       - Description of the guessed option
    3. PERMISSION REMINDER: Explanation that guesses were based on explicit permission
    4. USER CONTROL: Information about changing guesses if needed

    FORMATTING APPROACH:
    - Uses markdown formatting for readability
    - Includes visual indicators (🎯, 💡) for better user experience
    - Structures information hierarchically for easy scanning
    - Provides actionable information for user follow-up

    WORKFLOW INTEGRATION:
    - Called by detect_component_ambiguity when guesses are made
    - Included in clarify_components JSON response as guess_notification
    - Presented to users during the disambiguation process
    - Maintains user trust and process transparency

    Args:
        guessed_components: List of component dictionaries with guessed information:
                          - component_name: Name of the guessed component
                          - guessed_value: The value that was guessed
                          - description: Description of the guessed option

    Returns:
        Formatted notification string ready for user display:
        - Clear header indicating guesses were made
        - Detailed list of each guessed component
        - Permission reminder and user control information

    CRITICAL: This function is essential for maintaining user trust in the
    disambiguation process. Without clear notifications, users might not
    understand that guesses were made based on their permission, leading to
    confusion or distrust in the system.
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
    CORE AMBIGUITY DETECTION ENGINE:
    Implements the logic to identify when components have 2+ plausible matches,
    creating AmbiguityInfo objects that drive the disambiguation workflow.

    This function is the intelligence behind the confirm-before-generate pattern.
    It analyzes user descriptions against CODE_GENERATION.md rules, identifies
    ambiguous components, creates AmbiguityInfo objects, and integrates with
    the state management system. When explicit guess permission is detected,
    it handles the guess workflow by marking components as "guessed".

    AMBIGUITY DETECTION PROCESS:
    1. Parse user description against CODE_GENERATION.md rules
    2. Find matches for each of the 8 required components
    3. Apply similarity threshold filtering to remove unrelated options
    4. Classify components as: ambiguous (2+ matches), unambiguous (1 match),
       no_match (0 matches), or guessed (with explicit permission)
    5. Create AmbiguityInfo objects for each component
    6. Update ProcurementState with ambiguity information

    GUESS PERMISSION INTEGRATION:
    - Detects explicit guess permission phrases in user_text
    - When detected, automatically marks ambiguous components as "guessed"
    - Uses highest-scoring match as the guessed value
    - Generates user notification about the guess made
    - Ensures guesses are only made with explicit user permission

    STATE INTEGRATION:
    - Creates AmbiguityInfo objects for all 8 components
    - Updates ProcurementState.component_ambiguity_status
    - Validates state transitions to prevent invalid updates
    - Enables iterative clarification by tracking which components are resolved

    Args:
        user_description: The user's description text to analyze
        code_generation_content: Content of the CODE_GENERATION.md file with rules
        ctx: The run context containing the ProcurementState for state updates
        user_text: The user's current response text (for guess permission detection)
        similarity_threshold: Minimum semantic similarity score (0.0-1.0) for filtering

    Returns:
        Dictionary containing comprehensive ambiguity analysis:
        - ambiguity_detected: Boolean indicating if any components are ambiguous
        - ambiguous_components: List of component names that need clarification
        - unambiguous_components: List of component names with single matches
        - guessed_components: List of component names marked as guessed
        - no_match_components: List of component names with no valid matches
        - ambiguity_details: Detailed AmbiguityInfo for each component
        - guess_notification: User-friendly message about any guesses made

    STATE VALIDATION:
    - Validates all state transitions before updating ProcurementState
    - Prevents invalid transitions (e.g., unambiguous → ambiguous)
    - Provides detailed error messages for state transition failures
    - Ensures data consistency across the disambiguation workflow
    """
    # Log the start of ambiguity detection
    disambiguation_logger.info(
        f"Starting ambiguity detection for user description: {user_description[:100]}..."
    )

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

    # Log ambiguity detection summary
    ambiguous_count = len(extraction_results["ambiguous_components"])
    unambiguous_count = len(extraction_results["unambiguous_components"])
    no_match_count = len(extraction_results["no_match_components"])

    disambiguation_logger.info(
        f"Ambiguity detection completed - "
        f"Ambiguous: {ambiguous_count}, "
        f"Unambiguous: {unambiguous_count}, "
        f"No matches: {no_match_count}, "
        f"Guess permission: {guess_permission_detected}"
    )

    # Process each component and create AmbiguityInfo objects
    for component_key, component_detail in extraction_results[
        "component_details"
    ].items():
        component_name = component_detail["component_name"]
        matches = component_detail["matches"]
        status = component_detail["status"]

        # Log individual component processing
        disambiguation_logger.info(
            f"Processing component '{component_name}' - "
            f"Status: {status}, "
            f"Matches: {len(matches)}"
        )

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

            # Log the guess event
            disambiguation_logger.info(
                f"Component '{component_name}' marked as guessed - "
                f"Guessed value: {guessed_value}, "
                f"Based on explicit user permission"
            )

        elif status == "ambiguous":
            # Component has 2+ plausible matches but no guess permission - mark as ambiguous
            ambiguity_info = AmbiguityInfo(
                status="ambiguous",
                options=options,
                selected_value=None,  # No selection yet for ambiguous components
            )
            result["ambiguous_components"].append(component_name)

            # Log the ambiguity event
            disambiguation_logger.info(
                f"Component '{component_name}' marked as ambiguous - "
                f"Options: {len(options)}, "
                f"Requires user clarification"
            )

        elif status == "unambiguous":
            # Component has exactly 1 match - mark as unambiguous with selected value
            selected_value = matches[0]["code"]
            ambiguity_info = AmbiguityInfo(
                status="unambiguous", options=options, selected_value=selected_value
            )
            result["unambiguous_components"].append(component_name)

            # Log the unambiguous determination
            disambiguation_logger.info(
                f"Component '{component_name}' determined as unambiguous - "
                f"Selected value: {selected_value}"
            )

        else:  # status == "no_match"
            # Component has no matches - mark as ambiguous (needs clarification)
            # Even with guess permission, we can't guess if there are no matches
            ambiguity_info = AmbiguityInfo(
                status="ambiguous",
                options=[],  # No options to show
                selected_value=None,
            )
            result["no_match_components"].append(component_name)

            # Log the no-match event
            disambiguation_logger.warning(
                f"Component '{component_name}' has no valid matches - "
                f"Marked as ambiguous for user clarification"
            )

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
            disambiguation_logger.error(
                f"State transition error for component '{component_name}': {str(e)}"
            )

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

    # Log the completion of ambiguity detection process
    total_components = (
        len(result["ambiguous_components"])
        + len(result["unambiguous_components"])
        + len(result["guessed_components"])
        + len(result["no_match_components"])
    )
    resolved_components = len(result["unambiguous_components"]) + len(
        result["guessed_components"]
    )

    disambiguation_logger.info(
        f"Ambiguity detection process completed - "
        f"Total components processed: {total_components}, "
        f"Resolved components: {resolved_components}, "
        f"Still ambiguous: {len(result['ambiguous_components'])}, "
        f"No matches: {len(result['no_match_components'])}"
    )

    # Log if all components are resolved (disambiguation complete)
    if (
        len(result["ambiguous_components"]) == 0
        and len(result["no_match_components"]) == 0
    ):
        disambiguation_logger.info(
            f"✓ DISAMBIGUATION COMPLETE - All {total_components} components resolved "
            f"({len(result['unambiguous_components'])} unambiguous, {len(result['guessed_components'])} guessed)"
        )

    # METRICS TRACKING: Record disambiguation attempt and component analysis
    disambiguation_metrics.record_disambiguation_attempt()
    disambiguation_metrics.record_component_analysis(
        ambiguous=len(result["ambiguous_components"]),
        unambiguous=len(result["unambiguous_components"]),
        guessed=len(result["guessed_components"]),
        no_match=len(result["no_match_components"]),
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
    WORKFLOW ENFORCEMENT GATE:
    Final validation step in the confirm-before-generate pattern. Enforces that all
    components are unambiguous before allowing code generation to proceed.

    This function is the critical enforcement point in the disambiguation workflow.
    It validates that both workflow requirements have been met: (1) rules file has
    been read this turn, and (2) all components are unambiguous. If either check
    fails, it rejects the save with a detailed error message, preventing agents from
    bypassing the disambiguation process.

    ENFORCEMENT MECHANISMS:
    1. RULES LOADING VALIDATION:
       - Validates ctx.deps.state.rules_loaded_this_turn is True
       - Ensures read_code_generation_file was called first
       - Prevents workflow bypass attempts
       - Returns error: "ERROR: You must call read_code_generation_file before saving a code."

    2. DISAMBIGUATION VALIDATION:
       - Calls ctx.deps.state.validate_all_component_states()
       - Calls ctx.deps.state.validate_all_components_unambiguous()
       - Ensures all 8 components are resolved (unambiguous or guessed)
       - Returns detailed error listing which components need clarification

    3. STATE CONSISTENCY CHECKING:
       - Validates all AmbiguityInfo objects have valid states
       - Ensures no unexpected state transitions occurred
       - Verifies data consistency across all components
       - Provides detailed error messages for validation failures

    WORKFLOW ROLE:
    - Must be called AFTER read_code_generation_file
    - Must be called AFTER all components are resolved (via clarify_iterations)
    - Must be called BEFORE any code is considered final
    - Serves as the final gatekeeper in the disambiguation workflow

    Args:
        ctx: The run context containing the ProcurementState with disambiguation tracking
        code: The generated procurement code (e.g., "CFR01067261")
        description: A brief description of the item (e.g., "Steel I-beam for office building construction")

    Returns:
        StateSnapshotEvent on successful save (for UI state update)
        Error message string on validation failure with detailed diagnostics

    ERROR HANDLING:
    - Rules not loaded: Returns explicit error about required file read step
    - Ambiguous components: Returns detailed list of which components need clarification
    - Invalid states: Returns detailed state validation error with component details
    - State transitions: Returns detailed error about invalid state changes

    CRITICAL: This function is the primary enforcement mechanism for the entire
    disambiguation workflow. Without this validation, agents could bypass the
    confirm-before-generate pattern and generate incorrect codes.
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

    # Log successful code generation and save after disambiguation
    total_components = len(ctx.deps.state.component_ambiguity_status)
    clarified_components = len(ctx.deps.state.clarified_components)
    total_rounds = ctx.deps.state.clarification_rounds

    disambiguation_logger.info(
        f"✓ CODE SUCCESSFULLY GENERATED AND SAVED - "
        f"Code: {code}, "
        f"Description: {description}, "
        f"Total components: {total_components}, "
        f"Clarified components: {clarified_components}, "
        f"Clarification rounds: {total_rounds}"
    )

    # METRICS TRACKING: Record successful disambiguation completion
    disambiguation_metrics.record_successful_disambiguation(
        clarification_rounds=total_rounds
    )

    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot=ctx.deps.state,
    )


# Defined as a constant string for use in the dynamic system prompt function

# [LEGACY PROMPT - preserved for rollback]
# STATIC_SYSTEM_PROMPT = """You are a helpful assistant answering questions from a knowledge base.
#
#     CORE WORKFLOW:
#     1.  **DETECT NEW REQUEST**: If the user asks for a *completely new* procurement code (unrelated to the previous one), you MUST first call `reset_conversation`. Do NOT state that you are resetting memory. Just do it silently.
#
#     2.  **MANDATORY VERIFICATION**: For EVERY code generation request, you MUST first call `read_code_generation_file`.
#         -   This workflow is now **PROGRAMMATICALLY ENFORCED** - the system will block code saving if rules are not loaded first.
#         -   **ENFORCEMENT DETAILS**:
#             -   The `save_procurement_code` tool will validate that rules were loaded and reject saves with error: "ERROR: You must call read_code_generation_file before saving a code."
#             -   File read failures will raise exceptions (FileNotFoundError or Exception) instead of returning silent error strings.
#             -   This is a breaking change - agents that skip file-read will be blocked from saving codes.
#         -   You cannot rely on memory. You must read the file fresh for every request.
#         -   After reading, start your response with: "I have now read the document and will proceed with analysis based on this information."
#
#     3.  **DISAMBIGUATION STEP (MANDATORY)**: After reading the rules, you MUST call `clarify_components` to identify any ambiguous components before proceeding.
#         -   This workflow is **PROGRAMMATICALLY ENFORCED** - the system will block code saving if any components remain ambiguous.
#         -   The `clarify_components` tool will analyze the user's description and identify which components have multiple plausible matches.
#         -   **ENFORCEMENT DETAILS**:
#             -   The `save_procurement_code` tool will validate that all components are unambiguous and reject saves with error indicating which components need clarification.
#             -   You MUST resolve ALL ambiguous components before generating any code.
#             -   This implements the generate-then-justify pattern to ensure accurate code generation.
#
#     4.  **GENERATE-THEN-JUSTIFY WORKFLOW (CRITICAL)**: This is the core workflow that MUST be followed exactly:
#         -   **STEP 1: IDENTIFY AMBIGUITIES**: Call `clarify_components` to check all 8 components for ambiguity.
#         -   **STEP 2: GENERATE IMMEDIATELY**: Generate the procurement code IMMEDIATELY using the best available matches. NEVER wait for pre-generation confirmation.
#         -   **STEP 3: PROVIDE JUSTIFICATION**: After generating the code, provide a clear justification explaining how each component was determined.
#         -   **STEP 4: HANDLE REMAINING AMBIGUITIES**: If any components were ambiguous, explain the alternatives considered and ask for clarification, but ALWAYS generate the code first.
#         -   **ABSOLUTELY NO PRE-GENERATION CONFIRMATION**: Never ask "Should I generate this code?" or "Do you want me to proceed?" - ALWAYS generate first, then justify.
#
#         **TASK 13.6 REQUIREMENT**: Your response pattern MUST be "Generated code: [CODE]. Justification: [explanation]" instead of asking for confirmation. This is non-negotiable - generate the code first, then provide the justification, always.
#
#     5.  **RESPONSE FORMAT (EXACT PATTERN)**: ALWAYS follow this exact pattern:
#         -   Start with: "Generated code: [CODE]"
#         -   Follow with: "Justification: [explanation of how each component was determined]"
#         -   If ambiguities exist: "Note: Some components were ambiguous. Here's what I used and why: [explanation]"
#         -   If clarification needed: "Please clarify the following components if you'd like different values: [list of ambiguous components]"
#
#         **CRITICAL**: Your response must ALWAYS be "Generated code: [CODE]. Justification: [explanation]" - NEVER ask for confirmation before generating the code. This is not optional - generate first, then justify, always.
#
#     6.  **HANDLE AMBIGUOUS COMPONENTS**:
#         -   If `clarify_components` returns ambiguous components, you MUST present these options to the user for clarification AFTER generating the code.
#         -   For each ambiguous component, clearly present ONLY the options that MATCH the user's description with their descriptions. Do NOT present all possible options - only those that are relevant to the user's specific description.
#         -   Ask the user to specify which option they prefer for each ambiguous component.
#         -   **ITERATIVE CLARIFICATION**: If the user's response is still ambiguous, call `clarify_components` again to narrow down the options and continue until all components are resolved.
#
#     6.1 **DETAILED ITERATIVE CLARIFICATION PROCESS**:
#         -   **TRACK CLARIFICATION PROGRESS**: The system automatically tracks which components have been clarified across rounds. Already-clarified components will not appear in subsequent `clarify_components` calls.
#         -   **MAINTAIN CONTEXT**: Preserve user selections from previous clarification rounds. When calling `clarify_components` again, the system will remember which components the user has already confirmed.
#         -   **PRESENT NARROWED OPTIONS**: In subsequent clarification rounds, present only the remaining ambiguous components with their updated option sets based on the user's previous responses.
#         -   **CONTINUE UNTIL RESOLVED**: Repeat the clarification process (call `clarify_components`, present options, get user response) until no ambiguous components remain.
#         -   **AVOID REDUNDANT QUESTIONS**: Never ask the user to clarify a component they have already explicitly confirmed in a previous round.
#         -   **CLARIFICATION ROUND TRACKING**: The system tracks the number of clarification rounds completed. Use this context to provide users with progress updates.
#
#     7.  **EXPLICIT GUESS PERMISSION HANDLING**:
#         -   Only make guesses when the user EXPLICITLY states they don't know or gives permission.
#         -   Detect phrases like "I don't know", "whatever", "you choose", "doesn't matter", "I don't care", "just guess", "your choice", "up to you", etc.
#         -   When explicit guess permission is detected, inform the user which value you're selecting as a guess and mark it as guessed.
#         -   **NEVER** make silent guesses without explicit user permission.
#         -   **GUESS NOTIFICATION**: Always clearly inform the user when you've made a guess based on their permission, including:
#             *   Which component was guessed
#             *   What value was selected as the guess
#             *   A reminder that this was based on their explicit permission
#
#     8.  **BE CONFIDENT AND DIRECT**:
#         -   **CRITICAL**: Generate code IMMEDIATELY and DIRECTLY when ALL components are unambiguous (either confirmed or explicitly guessed).
#         -   **CORE BEHAVIOR**: When components are unambiguous, this is your moment to shine - be ABSOLUTELY CONFIDENT and generate the code without any hesitation, doubt, or additional questions.
#         -   **NO HESITATION**: Unambiguous components mean you have clear, definitive answers. There is ZERO reason to pause, question, or seek additional confirmation. Generate the code DIRECTLY.
#         -   **EXPECTED WORKFLOW**: This is not optional - when you detect unambiguous components, immediate code generation is your REQUIRED behavior. This is what users expect and what makes you effective.
#         -   **CONFIDENCE IS KEY**: Your confidence when components are clear is your greatest strength. Users trust you because you can generate accurate codes decisively when the inputs are clear.
#         -   Verify EACH component (A, B, C, MM, QQ, S) against the `read_code_generation_file` content.
#         -   Use the current date (YY[D]) if not specified (Year: 26).
#         -   Prioritize material > alphabetical/numerical order.
#
#     9.  **SAVE & FINISH**:
#         -   Do NOT state that you are saving a code to application state. Just do it silently.
#         -   Use `save_procurement_code` to save the valid code.
#         -   **CRITICAL**: The generated code MUST be the VERY LAST line of your response. This code should be printed in BOLD.
#
#     RULES:
#     -   **TASK 13.6 - RESPONSE PATTERN**: Your response MUST ALWAYS be "Generated code: [CODE]. Justification: [explanation]" instead of asking for confirmation. This is the required pattern - generate first, then justify, always.
#     -   **NO PRE-GENERATION CONFIRMATION**: NEVER ask for confirmation before generating code. ALWAYS generate first, then justify.
#     -   **NO SILENT GUESSING**: If a component has multiple plausible matches, you MUST ask for clarification. Only guess with explicit permission.
#     -   **EXPLICIT GUESS PERMISSION REQUIRED**: Before making any guess, you MUST detect explicit user permission phrases like "I don't know", "whatever", "you choose", etc.
#     -   **GUESS NOTIFICATION**: When you make a guess based on user permission, you MUST clearly inform the user what was guessed and that it was based on their explicit permission.
#     -   **GENERATE-THEN-JUSTIFY**: ALWAYS generate code first, then provide justification. This is non-negotiable.
#     -   **ITERATIVE CLARIFICATION**: Continue asking for clarification until all components are resolved. Maintain context across clarification rounds.
#     -   **CONFLICTS**: Information from `read_code_generation_file` is authoritative.
#     """

STATIC_SYSTEM_PROMPT = """You are a procurement code generation assistant. You generate CCS procurement codes from user descriptions.

    ## INVISIBILITY RULE (highest priority)

    The user never sees your tool calls. Never narrate your process. Never announce that you are reading a file, resetting context, calling a tool, or performing an internal step. Your output should read as if you simply knew the answer.

    Bad: "Let me read the rules file first…" or "I'll now reset the conversation and then…"
    Good: <call tools silently, then respond with results>

    ## WORKFLOW

    Follow these steps in order for every code request:

    1. **New topic → reset.** If the user's request is unrelated to the previous code, call `reset_conversation`. Do this without comment.

    2. **Load rules.** Call `read_code_generation_file` for every request. Never rely on cached knowledge from prior turns.

    3. **Disambiguate.** Call `clarify_components` to check each of the 8 code components (A, B, C, MM, QQ, S, etc.) for ambiguity.

    4. **Generate first, justify second.** This is your core behavioral rule:
       - Produce the procurement code immediately using the best available matches for each component.
       - Then explain how each component was determined.
       - Never ask "Shall I generate this?" or "Would you like me to proceed?" — always generate first.

    5. **Handle ambiguities after generation.** If `clarify_components` found ambiguous components:
       - Present only the relevant options for each ambiguous component (not every possible option).
       - Ask the user which they prefer.
       - The system tracks previously clarified components across rounds — call `clarify_components` again to refine remaining ambiguities.
       - Repeat until all components are resolved, then regenerate the code.

    6. **Guess only with explicit permission.** Only select a value without user input when the user explicitly defers (e.g., "I don't know", "whatever", "you choose", "doesn't matter", "just guess", "up to you"). When you guess:
       - State which component was guessed and what value was chosen.
       - Note that this was based on the user's permission.
       - Never guess silently.

    7. **Save silently.** Call `save_procurement_code` without mentioning it. The generated code must be the final line of your response, printed in **bold**.

    ## RESPONSE FORMAT

    Every code response must follow this structure:
    ```
    Generated code: **CODE**
    Justification: <explain each component>
    ```
    If ambiguities existed, append:
    ```
    Note: <what was ambiguous, what alternatives were considered>
    Please clarify if you'd like different values: <list of ambiguous components>
    ```

    ## COMPONENT RESOLUTION RULES

    - Verify each component against the rules loaded from `read_code_generation_file`.
    - Default date: use the current date in YY[D] format (Year: 26) if not specified.
    - Priority: material > alphabetical/numerical order.
    - `read_code_generation_file` content is authoritative in all conflicts.
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
                                parts_content.append(str(part.content))  # type: ignore[union-attr]
                            elif hasattr(part, "args"):
                                parts_content.append(
                                    f"Tool Call: {part.tool_name}({part.args})"  # type: ignore[union-attr]
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
    os.environ.get("OPENAI_MODEL", "deepseek-chat"),
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
