from typing import List, Optional
from pydantic import BaseModel, Field


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

    conversation_id: Optional[str] = None
    procurement_codes: List[ProcurementCode] = Field(default_factory=list)
    citation_sources: List[str] = Field(
        default_factory=list
    )
    rules_loaded_this_turn: bool = False
    component_ambiguity_status: dict[str, AmbiguityInfo] = Field(default_factory=dict)
    clarification_rounds: int = 0
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
        if component_name in self.component_ambiguity_status:
            current_info = self.component_ambiguity_status[component_name]

            try:
                self.validate_state_transition(
                    current_info.status, ambiguity_info.status, component_name
                )
            except ValueError as e:
                raise ValueError(
                    f"{str(e)} "
                    f"Current state: {current_info.status}, Target state: {ambiguity_info.status}. "
                    f"This transition violates the state machine rules for component ambiguity resolution."
                ) from e

            if current_info.selected_value is not None:
                if ambiguity_info.status == "unambiguous":
                    existing_selection_valid = any(
                        option["value"] == current_info.selected_value
                        for option in ambiguity_info.options
                    )

                    if existing_selection_valid:
                        ambiguity_info.selected_value = current_info.selected_value
                elif ambiguity_info.status == "guessed":
                    if current_info.guessed_value is not None:
                        existing_guess_valid = any(
                            option["value"] == current_info.guessed_value
                            for option in ambiguity_info.options
                        )

                        if existing_guess_valid:
                            ambiguity_info.guessed_value = current_info.guessed_value
                            ambiguity_info.selected_value = current_info.guessed_value
                            ambiguity_info.is_guessed = True

        else:
            try:
                self.validate_state_transition(
                    "new",
                    ambiguity_info.status,
                    component_name,
                )
            except ValueError as e:
                raise ValueError(
                    f"Invalid initial state for component '{component_name}': {str(e)} "
                    f"New components must start in 'ambiguous' or 'unambiguous' state."
                ) from e

        if (
            ambiguity_info.status == "unambiguous"
            and ambiguity_info.selected_value is None
        ):
            raise ValueError(
                f"Invalid state for component '{component_name}': "
                f"Unambiguous components must have a selected_value."
            )

        if ambiguity_info.status == "guessed" and ambiguity_info.guessed_value is None:
            raise ValueError(
                f"Invalid state for component '{component_name}': "
                f"Guessed components must have a guessed_value."
            )

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
        valid_states = ["ambiguous", "unambiguous", "guessed"]

        if current_status == "new":
            if new_status not in valid_states:
                raise ValueError(
                    f"Invalid initial state '{new_status}' for new component '{component_name}'. "
                    f"New components must start in one of: {', '.join(valid_states)}"
                )
            return

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

        allowed_transitions = {
            "ambiguous": ["unambiguous", "guessed"],
            "unambiguous": [],
            "guessed": [],
        }

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
            if ambiguity_info.status not in valid_states:
                raise ValueError(
                    f"Invalid state '{ambiguity_info.status}' for component '{component_name}'. "
                    f"Valid states are: {', '.join(valid_states)}"
                )

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
        self.validate_all_component_states()

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
