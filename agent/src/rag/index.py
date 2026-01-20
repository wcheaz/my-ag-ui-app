import logging
import os

from llama_index.core.indices import load_index_from_storage
from llama_index.core.storage import StorageContext

logger = logging.getLogger("uvicorn")

def get_storage_dir():
    paths_to_check = [
        os.path.join(os.getcwd(), "agent", "data", "storage"),  # From project root
        os.path.join(os.getcwd(), "data", "storage"),           # From agent dir
        os.path.join(os.path.dirname(__file__), "..", "..", "data", "storage"), # Relative to file
    ]
    
    for path in paths_to_check:
        if os.path.exists(path) and os.path.exists(os.path.join(path, "docstore.json")):
             return path
    return None

def get_index():
    storage_dir = get_storage_dir()
    
    # check if storage already exists
    if not storage_dir:
        logger.warning(f"RAG Storage directory not found in checked paths.")
        return None
        
    # load the existing index
    logger.info(f"Loading index from {storage_dir}...")
    try:
        storage_context = StorageContext.from_defaults(persist_dir=storage_dir)
        index = load_index_from_storage(storage_context)
        logger.info(f"Finished loading index from {storage_dir}")
        return index
    except Exception as e:
        logger.error(f"Failed to load index from {storage_dir}: {e}")
        return None
