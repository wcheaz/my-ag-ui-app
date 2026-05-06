## Context

The agent uses `LoggingOpenAIModel` (a subclass of Pydantic AI's `OpenAIModel`) in `agent/src/agent/model.py` to communicate with DeepSeek v4 reasoning models. Conversation history flows through this model on every turn via `request()` (non-streaming) and `request_stream()` (streaming).

DeepSeek v4 models return `reasoning_content` in their API responses. Pydantic AI stores this as a `ThinkingPart` dataclass inside `ModelResponse.parts`. The AG-UI protocol — used to stream responses to CopilotKit — has no field for `reasoning_content` in its `AssistantMessage` type, so `ThinkingPart` is silently dropped during serialization. On the next turn, CopilotKit sends the history back, the AG-UI adapter reconstructs `ModelResponse` objects without the missing `ThinkingPart`, and DeepSeek rejects the request with a 400 because its API contract requires prior `reasoning_content` to be present if it was ever emitted.

## Goals / Non-Goals

**Goals:**
- Ensure multi-turn conversations with DeepSeek v4 reasoning models complete without 400 errors
- Localize the fix to the model layer — no AG-UI protocol or adapter changes
- Preserve debug logging of thinking content (logs should still capture `ThinkingPart`)
- Keep the change reversible: a single-line removal restores prior behavior

**Non-Goals:**
- Preserving reasoning context across turns (accepted trade-off)
- Extending the AG-UI protocol
- Adding model-specific configuration or conditional logic per provider
- Fixing unrelated conversation-state corruption unrelated to `ThinkingPart`

## Decisions

### 1. Strip at the model layer, not the AG-UI adapter

**Decision**: Strip `ThinkingPart` from `ModelResponse.parts` inside `LoggingOpenAIModel` before calling `super().request()` / `super().request_stream()`.

**Rationale**: This is the narrowest interception point. The model layer is where `ModelMessage` history is assembled before serialization to the DeepSeek API. Stripping here means:
- No changes to the AG-UI adapter or CopilotKit
- No changes to Pydantic AI internals
- The strip runs after logging, so `hidden/prompt_log.txt` still captures thinking for debugging

**Alternatives considered**:
- **Extend AG-UI `AssistantMessage`**: Most correct long-term, but requires upstream changes to `ag-ui-protocol` and CopilotKit — not actionable in this change
- **Custom AG-UI adapter with metadata passthrough**: Fragile, depends on undocumented serialization behavior, risks silent data loss
- **Use non-reasoning model**: DeepSeek no longer offers non-reasoning models on their API

### 2. In-place list mutation, not message reconstruction

**Decision**: Filter `msg.parts` in-place with a list comprehension: `msg.parts = [p for p in msg.parts if not isinstance(p, ThinkingPart)]`

**Rationale**: `ModelResponse.parts` is a regular list. In-place reassignment is simpler than deep-copying the entire message list and avoids unnecessary object allocation. The `messages` list is already being mutated for the system-prompt injection, so this follows the existing pattern.

**Failure semantics**: If `ThinkingPart` is not present (non-reasoning models), the filter is a no-op. No error path.

### 3. Strip in both `request()` and `request_stream()`

**Decision**: Call `_strip_thinking_parts()` in both code paths, identically.

**Rationale**: Pydantic AI uses `request()` for tool-call loops and `request_stream()` for user-visible streaming. Both paths receive the full message history. Missing either path leaves the other vulnerable to the same 400 error.

### 4. Placement: after logging, before super()

**Decision**: Call order within each method: system-prompt guard → log messages → strip thinking parts → call `super()`.

**Rationale**: Logs must capture the unmodified message history (including `ThinkingPart`) for debugging. The strip must happen before `super()` so Pydantic AI never serializes `ThinkingPart` into the DeepSeek API request.

## Risks / Trade-offs

- **Degraded multi-turn reasoning quality** → DeepSeek loses prior-turn reasoning context. The model still reasons on each new turn but cannot reference earlier reasoning. Acceptable because the alternative is a hard 400 failure on every turn 2+. Mitigation: if reasoning quality becomes a problem, the strip can be removed once AG-UI protocol adds `reasoning_content` support.
- **`ThinkingPart` API changes in pydantic-ai** → The strip uses `isinstance(p, ThinkingPart)` which is stable. If Pydantic AI renames or restructures the type, the import breaks at startup with a clear `ImportError`. Mitigation: pin pydantic-ai version in requirements.
- **Stripping affects non-DeepSeek models** → If `LoggingOpenAIModel` is later used with non-reasoning providers, the filter is a harmless no-op (no `ThinkingPart` present). No risk.

## Open Questions

None. All policy decisions resolved in this design.
