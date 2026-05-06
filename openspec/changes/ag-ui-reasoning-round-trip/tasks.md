## 1. Implementation

- [x] 1.1 Add `ThinkingPart` import to `agent/src/agent/model.py`. Add `from pydantic_ai.messages import ThinkingPart` to the existing imports from `pydantic_ai.messages` (line 10).
  - Done when: `ThinkingPart` is importable from the module and `python -c "from src.agent.model import LoggingOpenAIModel"` succeeds from the `agent/` directory.
  - Stop and hand off if: import fails with `ImportError` (pydantic-ai version may not export `ThinkingPart`).

- [x] 1.2 Add `_strip_thinking_parts(self, messages: list[ModelMessage]) -> None` method to `LoggingOpenAIModel` in `agent/src/agent/model.py`. The method SHALL iterate all messages, and for each `ModelResponse`, replace `msg.parts` with a filtered list excluding `ThinkingPart` entries: `msg.parts = [p for p in msg.parts if not isinstance(p, ThinkingPart)]`.
  - Done when: method exists on the class, accepts `list[ModelMessage]`, mutates in-place, returns `None`.
  - Verify by: running `python -c "from src.agent.model import LoggingOpenAIModel; print(hasattr(LoggingOpenAIModel, '_strip_thinking_parts'))"` from `agent/` — must print `True`.

- [x] 1.3 Call `self._strip_thinking_parts(messages)` in `LoggingOpenAIModel.request()` after `self._log_messages(messages)` (line 113) and before `return await super().request(...)` (line 122).
  - Done when: call order in `request()` is system-prompt guard → log → strip → super().
  - Verify by: reading `agent/src/agent/model.py` and confirming the call site.

- [x] 1.4 Call `self._strip_thinking_parts(messages)` in `LoggingOpenAIModel.request_stream()` after `self._log_messages(messages)` (line 150) and before `async with super().request_stream(...)` (line 159).
  - Done when: call order in `request_stream()` is system-prompt guard → log → strip → super().
  - Verify by: reading `agent/src/agent/model.py` and confirming the call site.

## 2. Unit Tests

- [x] 2.1 Create `test/test_thinking_part_strip.py` with unit tests for `_strip_thinking_parts()`. Tests SHALL cover:
  - Messages with `ModelResponse` containing both `ThinkingPart` and `TextPart` — after strip, only `TextPart` remains.
  - Messages with `ModelResponse` containing only `ThinkingPart` — after strip, `parts` list is empty but `ModelResponse` stays in list.
  - Messages with no `ThinkingPart` at all (non-reasoning model) — list unchanged.
  - Empty messages list — no error.
  - Done when: `pytest test/test_thinking_part_strip.py` passes all cases.

## 3. Manual Verification

- [ ] 3.1 Run a multi-turn conversation with `deepseek-v4-flash` (or whichever DeepSeek v4 model is configured). Send at least 3 messages and confirm no 400 error occurs on turn 2 or turn 3.
  - Done when: conversation completes 3+ turns without HTTP 400.
  - Stop and hand off if: 400 persists — check that `ThinkingPart` import resolves and strip is actually called (add temporary print/logging if needed).
