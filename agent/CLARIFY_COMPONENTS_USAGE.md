# clarify_components Tool Usage Documentation

## Overview

The `clarify_components` tool is the primary disambiguation tool in the procurement agent's confirm-before-generate workflow. It analyzes user descriptions, identifies ambiguous components that require clarification, and returns structured options for user confirmation before code generation.

## Purpose

This tool implements the core intelligence of the disambiguation system by:

1. **Component Analysis**: Parsing user descriptions against CODE_GENERATION.md rules
2. **Ambiguity Detection**: Identifying components with multiple plausible matches
3. **Similarity Filtering**: Using semantic similarity and keyword matching to present only relevant options
4. **Structured Output**: Providing JSON-formatted options for UI rendering and user interaction
5. **State Management**: Integrating with ProcurementState for workflow enforcement

## Tool Signature

```python
def clarify_components(
    ctx: RunContext[StateDeps[ProcurementState]],
    user_description: str,
    similarity_threshold: float = DEFAULT_SIMILARITY_THRESHOLD,
) -> str
```

## Parameters

### Required Parameters

- **`ctx`** (RunContext[StateDeps[ProcurementState]]): 
  - The run context containing the ProcurementState with disambiguation tracking
  - Provides access to component ambiguity status and clarification progress

- **`user_description`** (str):
  - The user's description text to analyze for component extraction
  - Should be a non-empty string containing the item description
  - Example: "Steel I-beam for office building construction"

### Optional Parameters

- **`similarity_threshold`** (float, default: 0.3):
  - Minimum semantic similarity score (0.0-1.0) for option filtering
  - Controls how strictly options are filtered based on relevance
  - Range: 0.1 (very permissive) to 0.8 (very strict)
  - Higher values = fewer but more relevant options presented

## Preconditions

The tool enforces these preconditions:

1. **Rules File Must Be Loaded**: `read_code_generation_file` MUST be called first
2. **Valid Context**: ProcurementState must be available and properly initialized
3. **Non-empty Description**: User description must be a valid non-empty string

## Return Value

Returns a JSON string containing structured disambiguation information:

```json
{
  "ambiguous_components": [
    {
      "component_name": "Major Category",
      "component_key": "major_category",
      "options": [
        {
          "value": "A",
          "description": "Agricultural products",
          "similarity_info": {
            "semantic_score": 0.45,
            "keyword_score": 2,
            "filter_reason": "high_semantic_similarity (0.45 >= 0.3)"
          }
        }
      ],
      "match_count": 2
    }
  ],
  "unambiguous_components": [
    {
      "component_name": "Manufacturing Method",
      "component_key": "manufacturing_method",
      "selected_value": "C",
      "description": "Cast: Metal casting processes",
      "similarity_info": {
        "semantic_score": 0.72,
        "keyword_score": 4,
        "filter_reason": "high_semantic_similarity (0.72 >= 0.3)"
      }
    }
  ],
  "guessed_components": [
    {
      "component_name": "Material Type",
      "component_key": "material_type",
      "guessed_value": "01",
      "description": "Steel: Carbon steel, alloy steel, stainless steel",
      "is_guessed": true
    }
  ],
  "component_details": {
    "major_category": {
      "component_name": "Major Category",
      "status": "ambiguous",
      "match_count": 2,
      "is_guessed": false
    }
  },
  "similarity_threshold_info": {
    "threshold_used": 0.3,
    "filtering_applied": true,
    "description": "Only options with semantic similarity >= 0.3 or strong keyword matches (score >= 4) are included",
    "total_options_filtered": 15,
    "options_presented": 8
  },
  "guess_notification": "🎯 **I've made the following guesses based on your permission:**\n\n**Material Type**: Steel: Carbon steel, alloy steel, stainless steel\n  → Guessed value: 01\n\n💡 **Note**: These guesses are based on your explicit permission (e.g., \"I don't know\", \"whatever\", \"you choose\").\nIf you'd like to change any of these guesses, please let me know which component you'd like to clarify.\n"
}
```

### Response Fields Explained

#### ambiguous_components
List of components that need user clarification. Each contains:
- `component_name`: Human-readable component name
- `component_key`: Internal component identifier
- `options`: Array of possible matches with descriptions
- `match_count`: Total number of matches found

#### unambiguous_components
List of components with single clear matches. Each contains:
- `component_name`: Human-readable component name
- `component_key`: Internal component identifier
- `selected_value`: The determined value for this component
- `description`: Description of the matched option
- `similarity_info`: Details about why this match was selected

#### guessed_components
List of components that were guessed based on explicit user permission. Each contains:
- `component_name`: Human-readable component name
- `component_key`: Internal component identifier
- `guessed_value`: The value that was guessed
- `description`: Description of the guessed option
- `is_guessed`: Always true for guessed components

#### component_details
Comprehensive information about all components including their current status.

#### similarity_threshold_info
Transparency information about the filtering applied:
- `threshold_used`: The similarity threshold that was applied
- `filtering_applied`: Whether filtering was enabled
- `description`: Explanation of the filtering logic
- `total_options_filtered`: Total options considered before filtering
- `options_presented`: Options remaining after filtering

#### guess_notification
User-friendly message explaining any guesses made based on explicit permission.

## Usage Examples

### Basic Usage

```python
# After reading the code generation file
result = clarify_components(
    ctx=run_context,
    user_description="Steel I-beam for office building construction"
)
```

### With Custom Similarity Threshold

```python
# Use stricter filtering for more precise options
result = clarify_components(
    ctx=run_context,
    user_description="Steel I-beam for office building construction",
    similarity_threshold=0.5  # Higher threshold = stricter filtering
)
```

### Iterative Clarification

```python
# First call - identify ambiguous components
first_result = clarify_components(ctx, "Steel beam for construction")

# User clarifies one component
# Second call - will skip already-clarified components
second_result = clarify_components(ctx, "Steel I-beam for office building")
```

## Workflow Integration

### 1. Initial Call
```python
# Step 1: Must read rules file first
rules_content = read_code_generation_file(ctx)

# Step 2: Call clarify_components to detect ambiguities
clarification_result = clarify_components(ctx, user_description)
```

### 2. Handle Ambiguities
```python
import json
result_data = json.loads(clarification_result)

if result_data["ambiguous_components"]:
    # Present options to user for clarification
    for component in result_data["ambiguous_components"]:
        print(f"Please clarify {component['component_name']}:")
        for option in component["options"]:
            print(f"  - {option['value']}: {option['description']}")
```

### 3. Iterative Process
```python
# Continue calling clarify_components until no ambiguities remain
while result_data["ambiguous_components"]:
    # Get user clarification
    user_response = get_user_input()
    
    # Call again with updated context
    clarification_result = clarify_components(ctx, user_response)
    result_data = json.loads(clarification_result)
```

### 4. Final Validation
```python
# Once all components are resolved, generate and save code
if not result_data["ambiguous_components"]:
    generated_code = generate_procurement_code(result_data)
    save_result = save_procurement_code(ctx, generated_code, "Description")
```

## Error Handling

The tool provides comprehensive error handling:

### Common Errors

1. **Rules Not Loaded**
   ```
   ERROR: You must call read_code_generation_file before using clarify_components.
   ```
   - **Solution**: Call `read_code_generation_file` first

2. **Invalid Description**
   ```
   ERROR: user_description must be a non-empty string
   ```
   - **Solution**: Provide a valid non-empty description

3. **State Transition Error**
   ```
   ERROR: Invalid state transition for component 'ComponentName'
   ```
   - **Solution**: Check component state consistency

### Error Response Format

```json
{
  "error": "Error message describing the issue",
  "error_type": "validation_error|file_not_found|runtime_error|unexpected_error",
  "ambiguous_components": [],
  "unambiguous_components": [],
  "component_details": {}
}
```

## Similarity Threshold Filtering

The tool uses sophisticated filtering to present only relevant options:

### Filtering Logic
1. **High Semantic Similarity**: Options with semantic score ≥ threshold
2. **Strong Keyword Matches**: Options with keyword score ≥ 4
3. **Combined Relevance**: Options that meet either criteria

### Threshold Guidelines
- **0.1-0.2**: Very permissive, shows most options
- **0.3-0.4**: Balanced (recommended default)
- **0.5-0.6**: Strict, shows only highly relevant options
- **0.7-0.8**: Very strict, minimal options presented

## Iterative Clarification Support

The tool supports multi-round clarification:

### Automatic Context Preservation
- Already-clarified components are automatically skipped
- User selections are preserved across rounds
- Clarification progress is tracked

### Clarification Round Tracking
- `ctx.deps.state.clarification_rounds` tracks progress
- `ctx.deps.state.clarified_components` stores resolved components

## Guess Permission Integration

The tool integrates with explicit guess permission detection:

### Permission Phrases Detected
- "I don't know", "I dont know", "idk"
- "whatever", "whichever", "either one"
- "you choose", "you decide", "your choice"
- "doesn't matter", "I don't care"
- "just guess", "make a guess", "your best guess"

### Guess Process
1. User provides explicit permission phrase
2. Tool detects permission and marks component as "guessed"
3. Highest-scoring match is selected as guessed value
4. User receives notification about the guess made

## Best Practices

### 1. Always Call After Reading Rules
```python
# Correct workflow
rules = read_code_generation_file(ctx)
clarification = clarify_components(ctx, description)
```

### 2. Handle Ambiguities Gracefully
```python
result = json.loads(clarification_result)
if result["ambiguous_components"]:
    present_clarification_options(result["ambiguous_components"])
elif result["guessed_components"]:
    confirm_guessed_values(result["guessed_components"])
else:
    proceed_with_code_generation()
```

### 3. Use Appropriate Similarity Thresholds
```python
# For experienced users providing detailed descriptions
strict_result = clarify_components(ctx, detailed_description, 0.5)

# For new users or vague descriptions
lenient_result = clarify_components(ctx, vague_description, 0.2)
```

### 4. Leverage Iterative Clarification
```python
# Don't try to resolve all ambiguities at once
# Let users clarify one component at a time if needed
```

## Integration with UI

The JSON output is designed for easy UI integration:

### React Component Example
```javascript
function ClarificationOptions({ data }) {
  return (
    <div>
      {data.ambiguous_components.map(comp => (
        <ComponentOptions key={comp.component_key} component={comp} />
      ))}
      {data.guess_notification && (
        <GuessNotification notification={data.guess_notification} />
      )}
    </div>
  );
}
```

## Testing

The tool includes comprehensive test coverage:

### Unit Tests
- Component extraction with clear inputs
- Ambiguity detection with ambiguous inputs
- Edge cases (no matches, single match, multiple matches)
- Similarity threshold filtering
- Guess permission detection

### Integration Tests
- Complete disambiguation workflow
- Iterative clarification scenarios
- Save validation with ambiguous components
- Guess permission workflow

## Performance Considerations

### Similarity Calculation
- Semantic similarity uses embeddings (can be computationally expensive)
- Keyword matching is fast and lightweight
- Similarity threshold filtering reduces processing overhead

### Caching
- Component rules are parsed fresh each call
- Embeddings are cached when available
- Consider adding rule caching for high-frequency usage

## Related Components

- **`read_code_generation_file`**: Must be called before clarify_components
- **`save_procurement_code`**: Validates that all components are unambiguous
- **`AmbiguityInfo`**: Data structure tracking component ambiguity status
- **`ProcurementState`**: State management for disambiguation workflow

## Troubleshooting

### Common Issues

1. **Tool returns empty ambiguous_components**
   - User description may be too clear (all components resolved)
   - Check unambiguous_components for resolved values

2. **Too many options presented**
   - Lower the similarity_threshold parameter
   - Or improve user description specificity

3. **Too few options presented**
   - Raise the similarity_threshold parameter
   - Or provide more detailed user description

4. **State transition errors**
   - Check ProcurementState consistency
   - Ensure proper workflow sequence is followed

### Debug Mode
Enable debug logging to see detailed matching information:
```python
# Debug information is included in similarity_info for each option
```

## Version History

- **v1.0**: Initial implementation with basic ambiguity detection
- **v1.1**: Added similarity threshold filtering
- **v1.2**: Enhanced iterative clarification support
- **v1.3**: Integrated guess permission detection
- **v1.4**: Added comprehensive error handling and validation