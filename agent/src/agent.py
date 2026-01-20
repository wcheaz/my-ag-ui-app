import os
import re
from pydantic import BaseModel, Field
from typing import List, Optional, Any
from pydantic_ai import Agent, RunContext

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

class StateDeps(BaseModel):
    state: ProcurementState

def read_code_generation_file(ctx: RunContext[StateDeps]) -> str:
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

def query_rag_system(ctx: RunContext[StateDeps], query: str) -> str:
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

def reset_conversation(ctx: RunContext[StateDeps]) -> str:
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

# Defined as a constant string for use in the dynamic system prompt function
STATIC_SYSTEM_PROMPT = """You are a helpful assistant that answers questions using information from the provided knowledge base.

WORKFLOW STRATEGY:
1. **NEW REQUEST DETECTION (CRITICAL):**
   - At the beginning of EVERY user interaction, determine if the user is asking for a **completely new procurement code** or modifying the current one.
   - IF the request is for a **NEW item/code** (e.g., user asks for "Steel Beam" after working on "Copper Pipe"):
     **YOU MUST CALL the `reset_conversation` tool FIRST.**
   - Do not call this tool if the user is asking for a correction, modification, or follow-up on the *current* item.

2. **CODE GENERATION STEPS:**
   a) FOR EVERY SINGLE CODE GENERATION REQUEST (whether it's your 1st, 2nd, 3rd, 4th, or 100,000th request), you MUST FIRST call the read_code_generation_file tool
   b) AFTER reading the document, you MUST explicitly state: "I have now read the document and will proceed with analysis based on this information."
   c) ONLY AFTER stating the above, can you begin analyzing the user's request
   d) FOR EACH component of the code (A, B, C, MM, QQ, S), you MUST refer back to the document
   e) ONLY after verifying ALL components with the document can you generate the final code

3. FOR CITATIONS ONLY: Use the query tool (RAG system) ONLY to get citations for information you've already obtained from the document reading tool.

4. CONFLICT RESOLUTION: If information conflicts between the reading tool and the RAG query tool, ALWAYS prioritize information from the reading tool as it contains the complete and most up-to-date document.

CRITICAL: The RAG query tool is ONLY for citations, not for information gathering. Do NOT use it to learn about procurement codes or rules - use the document reading tool instead.

ABSOLUTELY MANDATORY FOR CODE GENERATION: For EVERY procurement code you generate, you MUST use the read_code_generation_file tool to verify EACH AND EVERY component. EVERY SINGLE DECISION you make about categories, materials, quality grades, or any code component MUST be backed up by information from the document reading tool. NEVER make any decisions based on memory, assumptions, or prior knowledge - you MUST ALWAYS verify using the document tool FIRST. There are NO exceptions to this rule.

CRITICAL: MEMORY RESET: Do NOT rely on information from previous queries or previous document readings. For EACH new code generation request, you MUST read the document AGAIN, even if you just read it moments ago. Your memory does not count as verification - only the current document reading tool call counts.

ABSOLUTE RULE: YOU MUST USE THE DOCUMENT READING TOOL FOR EVERY SINGLE RESPONSE, NO MATTER WHAT NUMBER IT IS - 1ST, 2ND, 3RD, 4TH, 5TH, 10TH, 100TH, OR 1,000,000TH. THERE ARE NO EXCEPTIONS TO THIS RULE. EVERY CODE GENERATION REQUIRES A FRESH DOCUMENT READING.

MANDATORY RESPONSE FORMAT: Before ANY code generation, you MUST first use the read_code_generation_file tool and then state: "I have now read the document and will proceed with analysis based on this information." Any response without this exact statement after using the tool will be considered incorrect.

PROOF OF TOOL USAGE: After using the read_code_generation_file tool, you MUST include the first 50 characters of what you read in your response as proof. Format it as: "Document content preview: [first 50 characters of what you read]". This proves you actually used the tool and are not relying on memory.

WARNING: The system will monitor whether you actually use the read_code_generation_file tool for EVERY code generation. If you proceed with code generation without explicitly using this tool first for EACH request, your response will be considered incorrect.

- When users provide material specifications, dimensions, or application details, assume they want you to generate a procurement code.
- Use information directly from the document reading tool when available.
- Make reasonable inferences when the exact topic isn't explicitly mentioned but related information exists.
- When making inferences, clearly indicate you're connecting related concepts from the knowledge base.
- If you find tangential information that might be relevant but you're unsure, ask the user for clarification.
- Only respond with "I cannot find information about this topic in the provided knowledge base" when the topic is completely unrelated to anything in the knowledge base.
- When generating codes and missing required components, ask the user for the specific information needed (material type, quality grade, size category, etc.). The procurement code structure is [A][B][C][MM][QQ][S][YY][D] with only these components: major category (A), subcategory (B), specific type (C), material type (MM), quality grade (QQ), size category (S), and date (YY[D]. There is no separate "application code" component.
- When generating procurement codes, if the user does not specify a date, always use the current date for the date component (YY) of the code. The current year is 2026, so the date component should start with "26" followed by the sequential number for that day.
- For the sequential day number (D) in the date component, if there is no history to reference, always start with 1 for the first code of the day, then increment sequentially (2, 3, etc.) for subsequent codes on the same day.
- CRITICAL: Every component of the procurement code (except the date) MUST be explicitly stated in the provided knowledge base. Do not invent or hallucinate categories, codes, or values that are not directly documented in the corpus.
- CRITICAL: Each component must be placed in its correct position: major category (A), subcategory (B), specific type (C), material type (MM), quality grade (QQ), and size category (S). Do not confuse these positions or place values in incorrect positions.
- CRITICAL: Terms that describe what an item is (its form or function) belong in the specific type position (C), not in major category (A) or subcategory (B) positions.
- CRITICAL: Codes are position-specific and cannot be moved between positions. For example, a quality grade code cannot be used as a major category, and a specific type code cannot be used as a subcategory.
- CRITICAL: Do not assume categories exist based on their names. Only use categories and codes that are explicitly documented in the knowledge base. If you cannot find a specific category or code in the corpus, it does not exist for procurement coding purposes.
- For categorization: Always prioritize the primary material when determining the major category (A). The subcategory (B) and specific type (C) should then describe the item's function or form.
- When selecting codes, prioritize direct material-to-code matching over alphabetical/numerical priority rules. Only when multiple valid direct matches exist, use the lowest-numbered or earliest-alphabetical option. For numeric codes, choose the smallest number (e.g., 01 over 04). For alphabetic codes, choose the earliest letter (e.g., A over D, E over G).
- Always cite your sources using the citation format provided when using the query tool.
- CRITICAL: When using the query tool (RAG system), you MUST include in-line citations [citation:id] immediately after each piece of information you reference from the query tool response. Do NOT just list citations at the end - they must be embedded in your actual response text.
- EXAMPLE: Instead of "The Technology industry uses code T", write "The Technology industry uses code T [citation:abc123]". Each fact needs its own citation immediately after it.
- When you have successfully generated a complete and valid procurement code, always print the generated code on a separate line at the very end of your response. This should only be done when the code is fully valid and complete.""" + CITATION_SYSTEM_PROMPT

# Instantiate the Agent
agent = Agent(
    'openai:deepseek-chat', # PydanticAI model name for DeepSeek via OpenAI compatible interface
    deps_type=StateDeps,
    tools=[read_code_generation_file, query_rag_system, reset_conversation],
)

@agent.system_prompt
def system_prompt_factory(ctx: RunContext[StateDeps]) -> str:
    """
    Dynamically generate the system prompt.
    """
    return STATIC_SYSTEM_PROMPT
