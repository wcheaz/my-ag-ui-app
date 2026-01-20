import os

from llama_index.core import Settings
from llama_index.llms.deepseek import DeepSeek
from llama_index.embeddings.huggingface import HuggingFaceEmbedding


def load_env_file(env_path):
    """Manually load environment variables from .env file"""
    if not os.path.exists(env_path):
        return False
    
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()
                # Remove quotes if present
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                os.environ[key] = value
    return True


def init_settings():
    # Check for OpenAI API key in environment to be used as DeepSeek Key
    if os.getenv("OPENAI_API_KEY") is None:
        # Try to load from .env file in current directory
        current_dir = os.getcwd()
        env_file = os.path.join(current_dir, '.env')
        
        if not os.path.exists(env_file):
            # Try project root
            # Assuming agent/src/rag/settings.py, so root is ../../../
            project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            env_file = os.path.join(project_root, '.env')
            
            # Additional check for my-ag-ui-app root if running from agent subdir
            if not os.path.exists(env_file):
                 project_root = os.path.dirname(project_root)
                 env_file = os.path.join(project_root, '.env')

        
        if os.path.exists(env_file):
            # Manually load the .env file
            if load_env_file(env_file):
                if os.getenv("OPENAI_API_KEY") is None:
                    raise RuntimeError(f"OPENAI_API_KEY (for DeepSeek) is missing in environment variables after loading {env_file}")
            else:
                pass 
        else:
             pass 

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
