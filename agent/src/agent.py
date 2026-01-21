import os
import re
from pydantic import BaseModel, Field
from typing import List, Optional, Any
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from ag_ui.core import EventType, StateSnapshotEvent

from src.rag.index import get_index
from src.rag.settings import init_settings
from src.rag.citation import enable_citation, CITATION_SYSTEM_PROMPT
from src.rag.query import get_query_engine_tool

# LOAD ENVIRONMENT VARIABLES manually since init_settings is disabled
import os
def load_env():
    # Try finding .env file
    paths = [
        os.path.join(os.getcwd(), ".env"),
        os.path.join(os.getcwd(), "..", ".env"),
        os.path.join(os.path.dirname(__file__), "..", ".env"),
        os.path.join(os.path.dirname(__file__), "..", "..", ".env"),
    ]
    for p in paths:
        if os.path.exists(p):
            with open(p, "r") as f:
                for line in f:
                    if "=" in line and not line.strip().startswith("#"):
                        key, val = line.strip().split("=", 1)
                        if not os.environ.get(key):
                            os.environ[key] = val.strip().strip("'").strip('"')
            break

load_env()

class ProcurementCode(BaseModel):
    code: str
    description: str

class ProcurementState(BaseModel):
    """
    State for the Procurement Agent.
    Maintains conversation history and other session-specific data.
    """
    # Placeholder for message history or other state tracking
    conversation_id: Optional[str] = None
    procurement_codes: List[ProcurementCode] = Field(default_factory=list)
    citation_sources: List[str] = Field(default_factory=list)  # Accumulated citation sources

def read_code_generation_file(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Read the contents of the CODE_GENERATION.md file which contains the procurement code generation template.
    
    Returns:
        The contents of the CODE_GENERATION.md file as a string
    """
    try:
        # DEBUG: Log context messages
        try:
            with open(os.path.join(os.getcwd(), "hidden", "debug_context.txt"), "a") as f:
                f.write(f"\nCTX MESSAGES AT {datetime.datetime.now()}:\n")
                if hasattr(ctx, 'messages'):
                    for i, m in enumerate(ctx.messages):
                        f.write(f"MSG {i}: Type={type(m).__name__}, Parts={len(m.parts) if hasattr(m, 'parts') else 'N/A'}\n")
                        if hasattr(m, 'parts'):
                            for p in m.parts:
                                f.write(f"  PART: {type(p).__name__}\n")
        except Exception as deb_e:
            print(f"Debug log failed: {deb_e}")

        # Try finding the file relative to CWD
        paths_to_check = [
            os.path.join(os.getcwd(), "agent", "data", "CODE_GENERATION.md"), # From project root
            os.path.join("data", "CODE_GENERATION.md"), # From agent dir
            os.path.join("..", "data", "CODE_GENERATION.md"), # From src dir
        ]
        
        file_path = None
        for path in paths_to_check:
            if os.path.exists(path):
                file_path = path
                break
        
        if not file_path:
             return "Error: CODE_GENERATION.md file not found in expected locations."

        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return content
    except Exception as e:
        return f"Error reading CODE_GENERATION.md file: {str(e)}"

def get_rag_tool():
    """
    Initialize and return the RAG query tool.
    In PydanticAI, we might wrap this, but for now we initialize the LlamaIndex components.
    """
    init_settings()
    index = get_index()
    if index is None:
        return None
        
    query_tool = enable_citation(get_query_engine_tool(
        index=index,
        description="CITATIONS ONLY: Use this tool ONLY to get citations for information you've already obtained from the document reading tool. This tool is NOT for information gathering - it only provides citations for facts you already know from the document. Do NOT use this tool to learn about procurement codes or rules."
    ))
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
        if hasattr(response, 'source_nodes') and response.source_nodes:
            # Take the first (most relevant) source node
            node = response.source_nodes[0]
            source_text = node.node.text if hasattr(node.node, 'text') and node.node.text else node.node.get_content()
            # Reduced preview to 150 characters (about 15 words)
            preview = source_text[:150] + "..." if len(source_text) > 150 else source_text
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

def reset_conversation(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Resets the conversation history. Do this SILENTLY. Do NOT state that you are resetting memory. Just do it silently.
    Use this tool IMMEDIATELY when the user makes a request for a NEW procurement code that is unrelated to the previous one.
    This ensures that previous context does not interfere with the new code generation.
    """
    if hasattr(ctx, 'messages') and isinstance(ctx.messages, list):
        # ERROR FIX: We must preserve the *last User Request* and the *current Assistant Tool Call*.
        # Previous attempts to just slice [-2:] failed if the stack contained intermediate ToolReturns (orphaned).
        
        last_msg = ctx.messages[-1]
        target_user_msg = None
        system_msg = None

        # Check for SystemPromptPart in the first message
        if ctx.messages and hasattr(ctx.messages[0], 'parts'):
            for part in ctx.messages[0].parts:
                if type(part).__name__ == 'SystemPromptPart':
                    system_msg = ctx.messages[0]
                    break
        
        # Iterate backwards looking for the last UserPromptPart
        # We search from the second-to-last message
        for i in range(len(ctx.messages) - 2, -1, -1):
            msg = ctx.messages[i]
            # Check for UserPromptPart by name to avoid import dependencies
            is_user = False
            if hasattr(msg, 'parts'):
                for part in msg.parts:
                    if type(part).__name__ == 'UserPromptPart':
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

async def save_procurement_code(ctx: RunContext[StateDeps[ProcurementState]], code: str, description: str) -> StateSnapshotEvent:
    """
    Saves a generated procurement code to the application state using the specific format required by the UI.
    Do NOT state that you are saving a code to application state. Just do it silently.
    Args:
        code: The generated procurement code (e.g., "CFR01067261").
        description: A brief description of the item (e.g., "Steel I-beam for office building construction").
        
    Returns:
        A success message indicating the code has been saved.
    """
    new_code = ProcurementCode(code=code, description=description)
    ctx.deps.state.procurement_codes.append(new_code)
    return StateSnapshotEvent(
        type=EventType.STATE_SNAPSHOT,
        snapshot=ctx.deps.state,
    )

# Defined as a constant string for use in the dynamic system prompt function
STATIC_SYSTEM_PROMPT = """You are a helpful assistant answering questions from a knowledge base.

    CORE WORKFLOW:
    1.  **DETECT NEW REQUEST**: If the user asks for a *completely new* procurement code (unrelated to the previous one), you MUST first call `reset_conversation`. Do NOT state that you are resetting memory. Just do it silently.

    2.  **MANDATORY VERIFICATION**: For EVERY code generation request, you MUST first call `read_code_generation_file`.
        -   You cannot rely on memory. You must read the file fresh for every request.
        -   After reading, start your response with: "I have now read the document and will proceed with analysis based on this information."

    3.  **GENERATE CODE**:
        -   Verify EACH component (A, B, C, MM, QQ, S) against the `read_code_generation_file` content.
        -   Use the current date (YY[D]) if not specified (Year: 26).
        -   Prioritize material > alphabetical/numerical order.
    4.  **SAVE & FINISH**:
        -   Do NOT state that you are saving a code to application state. Just do it silently.
        -   Use `save_procurement_code` to save the valid code.
        -   **CRITICAL**: The generated code MUST be the VERY LAST line of your response. This code should be printed in BOLD. 

    RULES:
    -   **NO GUESSING**: If a component isn't in the knowledge base, ask the user. Do not invent codes.
    -   **CONFLICTS**: Information from `read_code_generation_file` is authoritative.
"""

# Citation-related system prompt - commented out (see agent/hidden/RAG-REMOVAL-EXPLANATION.md)
# + CITATION_SYSTEM_PROMPT

# Instantiate the Agent

from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.messages import ModelMessage, ModelRequest, SystemPromptPart
from pydantic_ai.models import ModelRequestParameters, ModelSettings, ModelResponse, StreamedResponse
from collections.abc import AsyncIterator
from typing import Any
import datetime
import json

from contextlib import asynccontextmanager

class LoggingOpenAIModel(OpenAIModel):
    def _log_messages(self, messages: list[ModelMessage]):
        # Detailed Log
        try:
            log_path = os.path.join(os.getcwd(), "hidden", "prompt_log.txt")
            os.makedirs(os.path.dirname(log_path), exist_ok=True)
            
            with open(log_path, "a", encoding="utf-8") as f:
                f.write(f"\n{'='*80}\n")
                f.write(f"TIMESTAMP: {datetime.datetime.now().isoformat()}\n")
                f.write(f"{'='*80}\n")
                for msg in messages:
                    f.write(f"ROLE: {msg.kind}\n")
                    f.write(f"CONTENT: {msg}\n") 
                    f.write("-" * 40 + "\n")
                f.write("\n")
        except Exception as e:
            print(f"FAILED TO LOG DETAILED PROMPTS: {e}")

        # Basic Log (Content Only)
        try:
            basic_log_path = os.path.join(os.getcwd(), "hidden", "basic_prompt_log.txt")
            
            with open(basic_log_path, "a", encoding="utf-8") as f:
                f.write(f"\n{'='*80}\n")
                f.write(f"TIMESTAMP: {datetime.datetime.now().isoformat()}\n")
                f.write(f"{'='*80}\n")
                for msg in messages:
                    role = msg.kind
                    content_str = ""
                    
                    # Extract content based on message type structure
                    if hasattr(msg, 'parts'):
                        parts_content = []
                        for part in msg.parts:
                            if hasattr(part, 'content'):
                                parts_content.append(str(part.content))
                            elif hasattr(part, 'args'): # ToolCallPart
                                parts_content.append(f"Tool Call: {part.tool_name}({part.args})")
                        content_str = "\n".join(parts_content)
                    else:
                        content_str = str(msg)

                    f.write(f"[{role.upper()}]\n{content_str}\n")
                    f.write("-" * 20 + "\n")
                f.write("\n")
        except Exception as e:
             print(f"FAILED TO LOG BASIC PROMPTS: {e}") 

    async def request(
        self, 
        messages: list[ModelMessage], 
        model_settings: ModelSettings | None, 
        model_request_parameters: ModelRequestParameters
    ) -> ModelResponse:
        # Check and inject System Prompt if missing
        has_system = False
        if messages and isinstance(messages[0], ModelRequest):
             for part in messages[0].parts:
                 if isinstance(part, SystemPromptPart):
                     has_system = True
                     break
        
        if not has_system:
             # Create a new ModelRequest with system prompt
             sys_req = ModelRequest(parts=[SystemPromptPart(content=STATIC_SYSTEM_PROMPT)])
             messages.insert(0, sys_req)

        self._log_messages(messages)
        return await super().request(messages, model_settings, model_request_parameters)

    @asynccontextmanager
    async def request_stream(
        self, 
        messages: list[ModelMessage], 
        model_settings: ModelSettings | None, 
        model_request_parameters: ModelRequestParameters,
        run_context: Any | None = None
    ) -> AsyncIterator[StreamedResponse]:
        # Check and inject System Prompt if missing
        has_system = False
        if messages and isinstance(messages[0], ModelRequest):
             for part in messages[0].parts:
                 if isinstance(part, SystemPromptPart):
                     has_system = True
                     break
        
        if not has_system:
             # Create a new ModelRequest with system prompt
             sys_req = ModelRequest(parts=[SystemPromptPart(content=STATIC_SYSTEM_PROMPT)])
             messages.insert(0, sys_req)
             
        self._log_messages(messages)
        async with super().request_stream(messages, model_settings, model_request_parameters, run_context) as stream:
            yield stream

api_key = os.environ.get("OPENAI_API_KEY")
base_url = os.environ.get("OPENAI_BASE_URL")

print(f"DEBUG: initializing LoggingOpenAIModel with env vars")

model = LoggingOpenAIModel(
    'deepseek-chat',
)


agent = Agent(
    model, 
    deps_type=StateDeps[ProcurementState],
    # Tools list - citation tools commented out (see agent/hidden/RAG-REMOVAL-EXPLANATION.md)
    tools=[read_code_generation_file, reset_conversation, save_procurement_code],  # query_rag_system, get_citation_sources removed
    system_prompt=STATIC_SYSTEM_PROMPT,
)


