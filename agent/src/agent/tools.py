import os
import datetime
import json
from typing import Optional, Union

from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps
from ag_ui.core import EventType, StateSnapshotEvent

from src.agent.models import ProcurementState, ProcurementCode, AmbiguityInfo
from src.agent.matching import (
    get_component_extraction_results,
    validate_options_similarity_threshold,
    detect_explicit_guess_permission,
    DEFAULT_SIMILARITY_THRESHOLD,
    MINIMUM_SIMILARITY_THRESHOLD,
    MAXIMUM_SIMILARITY_THRESHOLD,
)
from src.agent.metrics import disambiguation_metrics, disambiguation_logger

from src.rag.index import get_index
from src.rag.settings import init_settings
from src.rag.citation import enable_citation
from src.rag.query import get_query_engine_tool


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
        "**I've made the following guesses based on your permission:**",
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
            '**Note**: These guesses are based on your explicit permission (e.g., "I don\'t know", "whatever", "you choose").',
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
        system_msg = None

        # Check for SystemPromptPart in the first message
        if ctx.messages and hasattr(ctx.messages[0], "parts"):
            for part in ctx.messages[0].parts:
                if type(part).__name__ == "SystemPromptPart":
                    system_msg = ctx.messages[0]
                    break

        # Iterate backwards looking for the last UserPromptPart
        # We search from the second-to-last message
        target_user_msg = None
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
