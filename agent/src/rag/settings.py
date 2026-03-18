import os

from dotenv import load_dotenv
from llama_index.core import Settings
from llama_index.llms.deepseek import DeepSeek
from llama_index.embeddings.huggingface import HuggingFaceEmbedding


def init_settings():
    # Load environment variables from .env file
    load_dotenv()

    # Check for OpenAI API key in environment to be used as DeepSeek Key
    if os.getenv("OPENAI_API_KEY") is None:
        raise RuntimeError(
            "OPENAI_API_KEY (for DeepSeek) is missing in environment variables"
        )

    # Initialize DeepSeek LLM
    # We use OPENAI_API_KEY because that is what is present in the .env file
    # for the DeepSeek key (per the user's setup).
    Settings.llm = DeepSeek(
        model=os.getenv("OPENAI_MODEL") or "deepseek-chat",
        api_key=os.getenv("OPENAI_API_KEY"),
        api_base=os.getenv("OPENAI_BASE_URL") or "https://api.deepseek.com",
        max_tokens=int(os.getenv("LLM_MAX_TOKENS") or 8192),
        context_window=int(os.getenv("LLM_CONTEXT_WINDOW") or 128000),
    )

    # Manually set context window
    Settings.context_window = int(os.getenv("LLM_CONTEXT_WINDOW") or 128000)

    # Initialize HuggingFace embeddings
    Settings.embed_model = HuggingFaceEmbedding(
        model_name=os.getenv("EMBEDDING_MODEL") or "BAAI/bge-large-en-v1.5"
    )
