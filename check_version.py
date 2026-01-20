import pydantic_ai
print(f"Pydantic AI Version: {pydantic_ai.__version__}")
try:
    import pydantic_ai.ag_ui
    print(f"AG UI file: {pydantic_ai.ag_ui.__file__}")
except ImportError:
    print("AG UI not found in pydantic_ai")
