## 1. Data Model and State Management

- [x] 1.1 Create `AmbiguityInfo` data class to track component ambiguity status (status, options, selected value)
- [x] 1.2 Extend `ProcurementState` with `component_ambiguity_status` field (Dict[str, AmbiguityInfo])
- [x] 1.3 Add validation logic to ensure state transitions are valid (ambiguous → unambiguous)
- [x] 1.4 Write unit tests for state management and ambiguity tracking

## 2. Component Parsing and Ambiguity Detection

- [x] 2.1 Implement component extraction logic to parse user descriptions against CODE_GENERATION.md rules
- [x] 2.2 Implement ambiguity detection logic to identify when a component has 2+ plausible matches
- [x] 2.3 Implement keyword-based matching for component options
- [x] 2.4 Implement semantic similarity scoring for component options (initial version)
- [x] 2.5 Add logic to handle "no matches found" scenario
- [x] 2.6 Write unit tests for component extraction with clear inputs
- [x] 2.7 Write unit tests for ambiguity detection with ambiguous inputs
- [x] 2.8 Write unit tests for edge cases (no matches, single match, multiple matches)

## 3. Disambiguation Tool Implementation

- [x] 3.1 Implement `clarify_components` tool in `agent.py`
- [x] 3.2 Add tool to agent's available tools list
- [x] 3.3 Implement JSON output format for structured disambiguation options
- [x] 3.4 Add logic to filter and present only ambiguous components
- [x] 3.5 Add logic to include unambiguous components in output for context
- [x] 3.6 Write unit tests for `clarify_components` tool
- [x] 3.7 Write integration tests for tool with various input scenarios

## 4. User Intent Detection for Guess Permission

- [x] 4.1 Implement phrase detection for explicit guess permission ("I don't know", "whatever", "you choose")
- [x] 4.2 Add logic to mark components as "guessed" when permission detected
- [x] 4.3 Implement user notification when a guess is made
- [x] 4.4 Write unit tests for guess permission detection
- [x] 4.5 Write unit tests for guess marking and notification

## 5. Iterative Clarification Logic

- [x] 5.1 Add `clarification_rounds` counter to ProcurementState to track number of clarification rounds completed
- [x] 5.2 Add `clarified_components` set to ProcurementState to track which components have been successfully clarified
- [x] 5.3 Modify `clarify_components` tool to filter out already-clarified components from ambiguity output
- [x] 5.4 Add logic to preserve previous user selections when updating `component_ambiguity_status` after each clarification round
- [x] 5.5 Write unit tests for iterative clarification scenarios with multiple rounds
- [x] 5.6 Write unit tests for context preservation across clarification rounds

## 6. Workflow Enforcement in Save Tool

- [x] 6.1 Modify `save_procurement_code` to check `component_ambiguity_status`
- [x] 6.2 Add validation to reject saves with ambiguous components
- [x] 6.3 Implement clear error message indicating which components need clarification
- [x] 6.4 Ensure existing `rules_loaded_this_turn` validation still works
- [x] 6.5 Write unit tests for save rejection with ambiguous components
- [x] 6.6 Write unit tests for save success with all unambiguous components

## 7. System Prompt Enhancement

- [x] 7.1 Update system prompt to include disambiguation workflow instructions
- [x] 7.2 Add explicit instructions for confirm-before-generate pattern
- [x] 7.3 Add instructions for iterative clarification
- [x] 7.4 Add instructions for explicit guess permission handling
- [SKIP - Human intervention required] 7.5 Review and refine prompt for clarity and effectiveness

## 8. Integration and Workflow Testing

- [x] 8.1 Run existing test suite to ensure no regressions
- [x] 8.2 Write integration test for complete disambiguation workflow (clear input)
- [x] 8.3 Write integration test for single ambiguous component scenario
- [x] 8.4 Write integration test for multiple ambiguous components scenario
- [x] 8.5 Write integration test for iterative clarification (multiple rounds)
- [x] 8.6 Write integration test for explicit guess permission scenario
- [x] 8.7 Write integration test for save rejection with ambiguous components
- [x] 8.8 Write integration test for successful save after disambiguation

## 9. Error Handling and Edge Cases

- [x] 9.1 Add error handling for `clarify_components` tool failures
- [x] 9.2 Add error handling for invalid JSON output
- [ ] 9.3 Add error handling for unexpected state transitions
- [ ] 9.4 Write unit tests for error handling scenarios
- [ ] 9.5 Write integration tests for edge cases

## 10. Documentation and Deployment

- [ ] 10.1 Document the disambiguation workflow in agent code comments
- [ ] 10.2 Document the `AmbiguityInfo` data structure
- [ ] 10.3 Document the `clarify_components` tool usage
- [SKIP - Human intervention required] 10.4 Update README or SETUP.md with disambiguation feature description
- [ ] 10.5 Prepare deployment notes for the disambiguation feature
- [ ] 10.6 Create rollback plan documentation

## 11. Performance Optimization (Optional - SKIP for automated implementation)

- [SKIP - Optional task] 11.1 Profile disambiguation logic performance with complex descriptions
- [SKIP - Optional task] 11.2 Optimize component parsing logic if needed
- [SKIP - Optional task] 11.3 Optimize ambiguity detection logic if needed
- [SKIP - Optional task] 11.4 Add caching for frequently accessed component rules
- [SKIP - Optional task] 11.5 Write performance benchmarks for disambiguation workflow

## 12. Monitoring and Feedback Collection

- [ ] 12.1 Add logging for disambiguation events (component ambiguity, clarification rounds)
- [ ] 12.2 Add metrics for disambiguation success rate
- [ ] 12.3 Add metrics for average clarification rounds per request
- [SKIP - Human intervention required] 12.4 Implement user feedback mechanism for disambiguation experience
- [SKIP - Human intervention required] 12.5 Set up monitoring dashboards for disambiguation metrics