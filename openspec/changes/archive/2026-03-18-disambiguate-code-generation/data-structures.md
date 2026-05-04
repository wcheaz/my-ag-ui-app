# Data Structures Documentation

## AmbiguityInfo Data Structure

### Overview

The `AmbiguityInfo` class is the core data structure for implementing the confirm-before-generate pattern in the procurement agent's disambiguation workflow. It tracks whether a component is ambiguous, unambiguous, or guessed, maintains the list of plausible options, and stores the user's selected value. This enables programmatic enforcement of the disambiguation workflow.

### Location

The `AmbiguityInfo` class is implemented in `/home/ncheaz/git/my-ag-ui-app/agent/src/agent.py` at line 293.

### Class Definition

```python
class AmbiguityInfo(BaseModel):
    """
    DISAMBIGUATION DATA STRUCTURE:
    Data class to track component ambiguity status during disambiguation workflow.

    This class is the core data structure for implementing the confirm-before-generate
    pattern. It tracks whether a component is ambiguous, unambiguous, or guessed,
    maintains the list of plausible options, and stores the user's selected value.
    This enables programmatic enforcement of the disambiguation workflow.
    """
    status: str  # "ambiguous", "unambiguous", or "guessed"
    options: List[dict]  # List of plausible matches with their descriptions
    selected_value: Optional[str] = None  # User's selected value when resolved
    guessed_value: Optional[str] = (
        None  # Value selected when user gave guess permission
    )
    is_guessed: bool = False  # Flag indicating if this component was guessed
```

### Attributes

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `status` | str | Current status of the component | "ambiguous", "unambiguous", or "guessed" |
| `options` | List[dict] | List of plausible matches with descriptions | `[{"value": "A", "description": "Agricultural products"}, ...]` |
| `selected_value` | Optional[str] | User's selected value when resolved | "A" |
| `guessed_value` | Optional[str] | Value selected when user gave guess permission | "C" |
| `is_guessed` | bool | Boolean flag indicating if component was guessed | True/False |

### State Transitions

The `AmbiguityInfo` class enforces valid state transitions during the disambiguation workflow:

```
"ambiguous" → "unambiguous" (user clarifies)
"ambiguous" → "guessed" (user gives explicit permission)
"unambiguous" → No further transitions allowed
"guessed" → No further transitions allowed
```

### Usage in Disambiguation Workflow

The `AmbiguityInfo` class is used throughout the disambiguation workflow:

1. **Creation**: Created by `clarify_components` tool when parsing user descriptions
2. **Storage**: Stored in `ProcurementState.component_ambiguity_status` for enforcement
3. **Update**: Updated during iterative clarification rounds
4. **Validation**: Validated by `save_procurement_code` before allowing code generation

### Example Usage

```python
# Creating an AmbiguityInfo for an ambiguous component
ambiguity_info = AmbiguityInfo(
    status="ambiguous",
    options=[
        {"value": "A", "description": "Agricultural products"},
        {"value": "C", "description": "Chemical products"}
    ]
)

# After user clarification
ambiguity_info.status = "unambiguous"
ambiguity_info.selected_value = "A"

# Or with explicit guess permission
ambiguity_info.status = "guessed"
ambiguity_info.guessed_value = "C"
ambiguity_info.is_guessed = True
```

### Integration with ProcurementState

The `AmbiguityInfo` objects are stored in the `ProcurementState` class:

```python
class ProcurementState(BaseModel):
    component_ambiguity_status: dict[str, AmbiguityInfo] = Field(default_factory=dict)
```

This enables programmatic enforcement of the disambiguation workflow, ensuring all components are unambiguous before code generation.

### Validation Rules

The `AmbiguityInfo` class is subject to validation rules:

1. **State Validation**: All state transitions must be valid
2. **Component Resolution**: All components must be unambiguous before saving
3. **Guess Permission**: Only allow guessing when user explicitly gives permission
4. **Context Preservation**: Previous selections must be preserved across clarification rounds

### Related Components

- **ProcurementState**: Stores AmbiguityInfo objects for workflow enforcement
- **clarify_components tool**: Creates and updates AmbiguityInfo objects
- **save_procurement_code tool**: Validates AmbiguityInfo before allowing saves
- **System Prompt**: Guides agent behavior regarding disambiguation workflow