from typing import Any, List, Optional

from llama_index.core import QueryBundle
from llama_index.core.postprocessor.types import BaseNodePostprocessor
from llama_index.core.prompts import PromptTemplate
from llama_index.core.query_engine.retriever_query_engine import RetrieverQueryEngine
from llama_index.core.response_synthesizers import Accumulate
from llama_index.core.schema import NodeWithScore
from llama_index.core.tools.query_engine import QueryEngineTool


# Used as a prompt for synthesizer
# Override this prompt by setting the `CITATION_PROMPT` environment variable
CITATION_PROMPT = """
Context information is below.
------------------
{context_str}
------------------
The context are multiple text chunks, each text chunk has its own citation_id at the beginning.
Use the citation_id for citation construction.

Answer the following query with citations:
------------------
{query_str}
------------------

## Citation format

[id]

Where:
- `id` is the `citation_id` provided in the context or previous response.

Example:
```
    The Technology industry uses code T [1]. 
    For manufacturing methods, Assembly uses code A [2]. 
    Material type for steel is 01 [3].
```

CRITICAL: Each piece of information MUST have its citation immediately after it, not at the end of the paragraph.

## Requirements:
1. ONLY cite sources that contain information you actually use in your response. 
2. If a chunk doesn't contain relevant information for the query, do NOT cite it.
3. Make sure that the citation_id is correct with the context, don't mix up the citation_id with other information.
4. CRITICAL: Include in-line citations [id] immediately after each piece of information in your response text. Do NOT just list citations at the end.

Now, you answer the query with citations:
"""


class NodeCitationProcessor(BaseNodePostprocessor):
    """
    Add a new field `citation_id` to the metadata of the node by copying the id from the node.
    Useful for citation construction.
    """

    def _postprocess_nodes(
        self,
        nodes: List[NodeWithScore],
        query_bundle: Optional[QueryBundle] = None,
    ) -> List[NodeWithScore]:
        for idx, node_score in enumerate(nodes, start=1):
            # DEBUG: Log metadata to hidden/METADATAOUTPUT.md
            try:
                import os
                import json
                log_path = os.path.join(os.getcwd(), "hidden", "METADATAOUTPUT.md")
                os.makedirs(os.path.dirname(log_path), exist_ok=True)
                with open(log_path, "a", encoding="utf-8") as f:
                    f.write(f"\n--- Processing Node {node_score.node.node_id} ---\n")
                    f.write(json.dumps(node_score.node.metadata, indent=2))
                    f.write("\n")
                    f.write(f"Content Preview: {node_score.node.get_content()[:200]}...\n")
            except Exception as e:
                print(f"Failed to log metadata: {e}")

            # Use sequential numbering for human-readable citations
            citation_id = str(idx)
            node_score.node.metadata["citation_id"] = citation_id
            
            # Prepend source label with filename if available
            original_text = node_score.node.get_content()
            file_name = node_score.node.metadata.get("file_name", "Unknown Source")
            node_score.node.text = f"Source {idx} ({file_name}):\n{original_text}\n"
            
        return nodes


class CitationSynthesizer(Accumulate):
    """
    Overload the Accumulate synthesizer to:
    1. Update prepare node metadata for citation id
    2. Update text_qa_template to include citations
    """

    def __init__(self, **kwargs: Any) -> None:
        text_qa_template = kwargs.pop("text_qa_template", None)
        if text_qa_template is None:
            text_qa_template = PromptTemplate(template=CITATION_PROMPT)
        super().__init__(text_qa_template=text_qa_template, **kwargs)


# Add this prompt to your agent system prompt
CITATION_SYSTEM_PROMPT = (
    "\nWhen using the query tool (RAG system), answer the user question using ONLY the response from the query tool. "
    "It's important to respect the citation information in the response. "
    "Don't mix up the citation_id, keep them at the correct fact. "
    "The query tool provides citations in the format [id] for each chunk of information. "
    "CRITICAL: You MUST include these in-line citations [id] in your actual response text, immediately after each piece of information you reference. "
    "Do NOT just list citations at the end - they must be embedded within your response text. "
    "EXAMPLE: Write 'The Technology industry uses code T [1]' not 'The Technology industry uses code T. Sources: [1]'. "
    "If the query tool returns no relevant information, respond with 'I cannot find information about this topic in the provided knowledge base.'"
)


def enable_citation(query_engine_tool: QueryEngineTool) -> QueryEngineTool:
    """
    Enable citation for a query engine tool by using CitationSynthesizer and NodePostprocessor.
    Note: This function will override the response synthesizer of your query engine.
    """
    query_engine = query_engine_tool.query_engine
    if not isinstance(query_engine, RetrieverQueryEngine):
        raise ValueError(
            "Citation feature requires a RetrieverQueryEngine. Your tool's query engine is a "
            f"{type(query_engine)}."
        )
    # Update the response synthesizer and node postprocessors
    query_engine._response_synthesizer = CitationSynthesizer()
    query_engine._node_postprocessors += [NodeCitationProcessor()]
    query_engine_tool._query_engine = query_engine

    # Update tool metadata
    query_engine_tool.metadata.description += "\nThe output will include citations with the format [id] for each chunk of information in the knowledge base."
    return query_engine_tool
