## Why

DeepSeek v4 reasoning models (`deepseek-v4-flash`, `deepseek-v4-pro`) return `reasoning_content` in API responses. The AG-UI protocol between CopilotKit and the Python agent lacks a field for this content in `AssistantMessage`, so it is silently dropped during streaming. On the next turn, CopilotKit sends history back without the prior `reasoning_content`, DeepSeek rejects the incomplete message history, and every multi-turn conversation after turn 1 fails with a 400 Bad Request.

## What Changes

- Add a `_strip_thinking_parts()` method to `LoggingOpenAIModel` in `agent/src/agent/model.py` that removes all `ThinkingPart` entries from `ModelResponse` objects in the message history
- Call this method in both `request()` and `request_stream()` after logging but before delegating to `super()`, so DeepSeek never receives a history where `reasoning_content` was previously present but is now missing
- Re-enable the `reset_conversation` tool if it was previously disabled due to this issue

## Non-goals

- Extending the AG-UI protocol to carry `reasoning_content` natively — that requires upstream changes to `ag-ui-protocol` and CopilotKit
- Preserving reasoning context across turns — the model will still produce `reasoning_content` each turn but will not see prior reasoning
- Changing the AG-UI adapter's `load_messages()` behavior — the fix is localized to the model layer only
- Adding new API surface, configuration flags, or model selection logic

## Capabilities

### New Capabilities
- `thinking-part-strip`: Strips `ThinkingPart` from `ModelResponse` message history before sending to the LLM API, preventing DeepSeek 400 errors caused by missing `reasoning_content` on subsequent turns

### Modified Capabilities
_(none)_

## Impact

- **Code**: `agent/src/agent/model.py` — one new method and two call sites in `LoggingOpenAIModel`
- **Dependencies**: Adds import of `ThinkingPart` from `pydantic_ai.messages` (already a project dependency)
- **APIs**: No external API changes
- **Behavioral trade-off**: DeepSeek loses prior-turn reasoning context. Multi-turn reasoning quality may degrade slightly, but conversations will succeed instead of failing with 400 errors
- **Verification**: Multi-turn conversation with `deepseek-v4-flash` must complete turn 2+ without 400 error
