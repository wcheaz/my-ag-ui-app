# thinking-part-strip Specification

## Purpose
Defines the requirement for stripping ThinkingPart entries from message history before API calls to prevent 400 errors with DeepSeek reasoning models on multi-turn conversations.

## Requirements
### Requirement: ThinkingPart stripped from message history before API call

`LoggingOpenAIModel` SHALL remove all `ThinkingPart` entries from every `ModelResponse` in the `messages` list before delegating to `super().request()` and `super().request_stream()`. The strip SHALL occur after logging so that `ThinkingPart` content is still captured in `hidden/prompt_log.txt` and `hidden/basic_prompt_log.txt`.

#### Scenario: Multi-turn conversation with DeepSeek reasoning model succeeds past turn 1

- **GIVEN** the model is configured with a DeepSeek v4 reasoning model (`deepseek-v4-flash` or `deepseek-v4-pro`)
- **AND** a first turn completes successfully and returns `reasoning_content` (stored as `ThinkingPart` in the `ModelResponse`)
- **WHEN** the user sends a second message, causing the agent to call `LoggingOpenAIModel.request()` or `LoggingOpenAIModel.request_stream()` with the full conversation history
- **THEN** `_strip_thinking_parts()` SHALL remove all `ThinkingPart` entries from every `ModelResponse` in the `messages` list before the call to `super()`
- **AND** the DeepSeek API SHALL return a successful response (not a 400 Bad Request)
- **AND** the conversation SHALL continue normally with no error

#### Scenario: ThinkingPart content preserved in debug logs

- **GIVEN** the model is configured with a DeepSeek v4 reasoning model
- **AND** a `ModelResponse` in the message history contains one or more `ThinkingPart` entries
- **WHEN** `_strip_thinking_parts()` is called
- **THEN** the `ThinkingPart` content SHALL already be present in `hidden/prompt_log.txt` and `hidden/basic_prompt_log.txt` (logged before stripping)
- **AND** the `ThinkingPart` entries SHALL be absent from the `messages` list passed to `super().request()` or `super().request_stream()`

### Requirement: Strip is a no-op on non-reasoning models

When no `ThinkingPart` entries exist in the message history (e.g., non-reasoning models or first-turn responses without thinking content), `_strip_thinking_parts()` SHALL complete without error and leave the `messages` list unchanged.

#### Scenario: Non-reasoning model history passes through unchanged

- **GIVEN** the model is configured with a non-reasoning provider or the message history contains no `ThinkingPart` entries
- **WHEN** `_strip_thinking_parts()` is called on the `messages` list
- **THEN** every `ModelResponse.parts` list SHALL remain identical to its input
- **AND** no error or exception SHALL be raised

### Requirement: Both request paths strip thinking parts

`LoggingOpenAIModel` SHALL strip `ThinkingPart` entries in both `request()` (non-streaming) and `request_stream()` (streaming) code paths. The call order within each method SHALL be: system-prompt guard → log messages → strip thinking parts → call `super()`.

#### Scenario: Non-streaming request path strips thinking parts

- **GIVEN** a message history containing `ModelResponse` objects with `ThinkingPart` entries
- **WHEN** `LoggingOpenAIModel.request()` is called
- **THEN** `_strip_thinking_parts()` SHALL be invoked after `_log_messages()` and before `super().request()`

#### Scenario: Streaming request path strips thinking parts

- **GIVEN** a message history containing `ModelResponse` objects with `ThinkingPart` entries
- **WHEN** `LoggingOpenAIModel.request_stream()` is called
- **THEN** `_strip_thinking_parts()` SHALL be invoked after `_log_messages()` and before `super().request_stream()`

### Requirement: Conversation history remains structurally valid after stripping

After `_strip_thinking_parts()` removes `ThinkingPart` entries, every `ModelResponse` in the `messages` list SHALL still contain at least one non-`ThinkingPart` entry (e.g., `TextPart` or `ToolCallPart`). This ensures the message history is never left with an empty `parts` list that could cause downstream errors.

#### Scenario: ModelResponse with both ThinkingPart and TextPart

- **GIVEN** a `ModelResponse` whose `parts` list contains one `ThinkingPart` and one `TextPart`
- **WHEN** `_strip_thinking_parts()` is called
- **THEN** the `ModelResponse.parts` list SHALL contain only the `TextPart`
- **AND** the `ModelResponse` SHALL remain in the `messages` list

#### Scenario: ModelResponse with only ThinkingPart (edge case)

- **GIVEN** a `ModelResponse` whose `parts` list contains only `ThinkingPart` entries and no `TextPart` or `ToolCallPart`
- **WHEN** `_strip_thinking_parts()` is called
- **THEN** the `ModelResponse.parts` list SHALL be empty
- **AND** the `ModelResponse` SHALL still remain in the `messages` list (no message removal)
