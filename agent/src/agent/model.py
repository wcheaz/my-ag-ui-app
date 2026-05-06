import os
import datetime
from typing import Any
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from pydantic_ai import Agent
from pydantic_ai.ag_ui import StateDeps
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.messages import ModelMessage, ModelRequest, ModelResponse, SystemPromptPart, ThinkingPart
from pydantic_ai.models import (
    ModelRequestParameters,
    StreamedResponse,
)
from pydantic_ai.settings import ModelSettings
from pydantic_ai.providers.deepseek import DeepSeekProvider
from dotenv import load_dotenv

from src.agent.models import ProcurementState
from src.agent.prompt import STATIC_SYSTEM_PROMPT
from src.agent.tools import (
    read_code_generation_file,
    save_procurement_code,
    clarify_components,
)

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", "..", ".env"))


class LoggingOpenAIModel(OpenAIModel):
    def _log_messages(self, messages: list[ModelMessage]):
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

        try:
            basic_log_path = os.path.join(os.getcwd(), "hidden", "basic_prompt_log.txt")

            with open(basic_log_path, "a", encoding="utf-8") as f:
                f.write(f"\n{'=' * 80}\n")
                f.write(f"TIMESTAMP: {datetime.datetime.now().isoformat()}\n")
                f.write(f"{'=' * 80}\n")
                for msg in messages:
                    role = msg.kind
                    content_str = ""

                    if hasattr(msg, "parts"):
                        parts_content = []
                        for part in msg.parts:
                            content = getattr(part, "content", None)
                            if content is not None:
                                parts_content.append(str(content))
                            else:
                                tool_name = getattr(part, "tool_name", None)
                                args = getattr(part, "args", None)
                                if tool_name is not None and args is not None:
                                    parts_content.append(
                                        f"Tool Call: {tool_name}({args})"
                                    )
                        content_str = "\n".join(parts_content)
                    else:
                        content_str = str(msg)

                    f.write(f"[{role.upper()}]\n{content_str}\n")
                    f.write("-" * 20 + "\n")
                f.write("\n")
        except Exception as e:
            print(f"FAILED TO LOG BASIC PROMPTS: {e}")

    # Non-streaming path: pydantic-ai calls this when the agent needs a single
    # LLM response (e.g. during tool-call loops). The full conversation history
    # is passed in as `messages` — a list of ModelRequest/ModelResponse objects
    # that represent the back-and-forth between user and model.
    async def request(
        self,
        messages: list[ModelMessage],
        model_settings: ModelSettings | None,
        model_request_parameters: ModelRequestParameters,
    ) -> ModelResponse:
        # Ensure the system prompt is present. pydantic-ai *usually* injects it
        # automatically, but in some edge-cases (e.g. after a conversation reset)
        # the first message may not contain a SystemPromptPart.
        has_system = False
        if messages and isinstance(messages[0], ModelRequest):
            for part in messages[0].parts:
                if isinstance(part, SystemPromptPart):
                    has_system = True
                    break

        # If no system prompt was found, prepend one so the model always
        # receives its instructions. This mutates the list in-place.
        if not has_system:
            sys_req = ModelRequest(
                parts=[SystemPromptPart(content=STATIC_SYSTEM_PROMPT)]
            )
            messages.insert(0, sys_req)

        # Write the full message array to hidden/prompt_log.txt and
        # hidden/basic_prompt_log.txt for debugging.
        self._log_messages(messages)

        # Delegate to the parent OpenAIModel.request() which:
        #   1. Serializes the pydantic-ai ModelMessage list into the
        #      OpenAI-compatible JSON format (role/content arrays)
        #   2. Makes the HTTP POST to the DeepSeek (or OpenAI) chat/completions endpoint
        #   3. Deserializes the JSON response back into a ModelResponse object
        # The returned ModelResponse contains the model's text, any tool calls,
        # and (for reasoning models) ThinkingPart with reasoning_content.
        return await super().request(messages, model_settings, model_request_parameters)

    # Streaming path: pydantic-ai calls this when the agent streams its response
    # token-by-token to the frontend (the normal path for user-visible replies).
    # Instead of returning a complete ModelResponse, it yields a StreamedResponse
    # that emits deltas as they arrive from the LLM.
    @asynccontextmanager
    async def request_stream(
        self,
        messages: list[ModelMessage],
        model_settings: ModelSettings | None,
        model_request_parameters: ModelRequestParameters,
        run_context: Any | None = None,
    ) -> AsyncIterator[StreamedResponse]:
        # Same system-prompt guard as request() above.
        has_system = False
        if messages and isinstance(messages[0], ModelRequest):
            for part in messages[0].parts:
                if isinstance(part, SystemPromptPart):
                    has_system = True
                    break

        if not has_system:
            sys_req = ModelRequest(
                parts=[SystemPromptPart(content=STATIC_SYSTEM_PROMPT)]
            )
            messages.insert(0, sys_req)

        self._log_messages(messages)

        # Delegate to the parent OpenAIModel.request_stream() which:
        #   1. Serializes messages and opens an SSE connection to the
        #      DeepSeek chat/completions endpoint (stream=true)
        #   2. Returns a StreamedResponse that yields incremental deltas
        #      as the model generates tokens
        # The async-context-manager pattern ensures the SSE connection is
        # properly opened before yielding and closed when the caller is done.
        async with super().request_stream(
            messages, model_settings, model_request_parameters, run_context
        ) as stream:
            yield stream


api_key = os.environ.get("OPENAI_API_KEY")
base_url = os.environ.get("OPENAI_BASE_URL")

print(f"DEBUG: initializing LoggingOpenAIModel with DeepSeekProvider")

model = LoggingOpenAIModel(
    os.environ.get("OPENAI_MODEL", "deepseek-chat"),
    provider=DeepSeekProvider(api_key=api_key),
)

# model = LoggingOpenAIModel(
#     os.environ.get("OPENAI_MODEL", "deepseek-chat"),
# )

agent = Agent(
    model,
    deps_type=StateDeps[ProcurementState],
    tools=[
        read_code_generation_file,
        save_procurement_code,
        clarify_components,
    ],
    system_prompt=STATIC_SYSTEM_PROMPT,
)
