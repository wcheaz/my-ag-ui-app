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

def read_code_generation_file(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Read the contents of the CODE_GENERATION.md file which contains the procurement code generation template.
    
    Returns:
        The contents of the CODE_GENERATION.md file as a string
    """
    try:
        # Try finding the file relative to CWD
        paths_to_check = [
            os.path.join("agent", "data", "CODE_GENERATION.md"), # From project root
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
        return str(response)
    except Exception as e:
        return f"Error querying RAG system: {str(e)}"

def reset_conversation(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Resets the conversation history. 
    Use this tool IMMEDIATELY when the user makes a request for a NEW procurement code that is unrelated to the previous one.
    This ensures that previous context does not interfere with the new code generation.
    """
    if hasattr(ctx, 'message_history') and isinstance(ctx.message_history, list):
        # Clear the history list
        ctx.message_history.clear()
        return "Conversation history has been reset. Proceed with the new request."
    return "Failed to reset history (context not mutable)."

async def save_procurement_code(ctx: RunContext[StateDeps[ProcurementState]], code: str, description: str) -> StateSnapshotEvent:
    """
    Saves a generated procurement code to the application state using the specific format required by the UI.
    
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
1.  **DETECT NEW REQUEST**: If the user asks for a *completely new* procurement code (unrelated to the previous one), you MUST first call `reset_conversation`.
2.  **MANDATORY VERIFICATION**: For EVERY code generation request, you MUST first call `read_code_generation_file`.
    -   You cannot rely on memory. You must read the file fresh for every request.
    -   After reading, start your response with: "I have now read the document and will proceed with analysis based on this information."
    -   Include a proof of reading: "Document content preview: [first 50 chars]".
3.  **GENERATE CODE**:
    -   Verify EACH component (A, B, C, MM, QQ, S) against the `read_code_generation_file` content.
    -   Use the current date (YY[D]) if not specified (Year: 26).
    -   Prioritize material > alphabetical/numerical order.
4.  **SAVE & FINISH**:
    -   Use `save_procurement_code` to save the valid code.
    -   Print the generated code on a separate line at the end.

RULES:
-   **CITATIONS**: When using `query_rag_system` (ONLY for citations, NOT info gathering), include inline citations [citation:id] immediately after the fact.
-   **NO GUESSING**: If a component isn't in the knowledge base, ask the user. Do not invent codes.
-   **CONFLICTS**: `read_code_generation_file` content always overrides `query_rag_system`.
""" + CITATION_SYSTEM_PROMPT

# Instantiate the Agent
agent = Agent(
    'openai:deepseek-chat', # PydanticAI model name for DeepSeek via OpenAI compatible interface
    deps_type=StateDeps[ProcurementState],
    tools=[read_code_generation_file, query_rag_system, reset_conversation, save_procurement_code],
)

@agent.system_prompt
def system_prompt_factory(ctx: RunContext[StateDeps[ProcurementState]]) -> str:
    """
    Dynamically generate the system prompt.
    """
    return STATIC_SYSTEM_PROMPT
