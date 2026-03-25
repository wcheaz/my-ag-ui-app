#!/usr/bin/env python3
"""
Test script to verify that all agent tools work correctly with loaded environment variables.

This script tests:
1. Environment variables are loaded correctly from .env file
2. Agent can be instantiated successfully
3. RAG settings can be initialized successfully
4. All agent tools can be called without errors
"""

import os
import sys
import json
from pathlib import Path

# Add src to path so we can import modules
sys.path.insert(0, str(Path(__file__).parent / "src"))


def test_environment_variables():
    """Test that required environment variables are loaded."""
    print("Testing environment variables...")

    # Required environment variables
    required_vars = [
        "OPENAI_API_KEY",
        "OPENAI_MODEL",
        "OPENAI_BASE_URL",
        "LLM_MAX_TOKENS",
        "LLM_CONTEXT_WINDOW",
        "EMBEDDING_MODEL",
    ]

    missing_vars = []
    for var in required_vars:
        value = os.getenv(var)
        if value is None:
            missing_vars.append(var)
        else:
            print(f"  ✓ {var}: {value[:20]}{'...' if len(value) > 20 else ''}")

    if missing_vars:
        print(f"  ✗ Missing environment variables: {missing_vars}")
        return False

    print("  ✓ All required environment variables are loaded")
    return True


def test_rag_settings():
    """Test that RAG settings can be initialized successfully."""
    print("\nTesting RAG settings initialization...")

    try:
        from src.rag.settings import init_settings
        from llama_index.core import Settings

        # Initialize settings
        init_settings()

        # Check that LLM was initialized
        if Settings.llm is None:
            print("  ✗ LLM not initialized")
            return False

        # Check that embed model was initialized
        if Settings.embed_model is None:
            print("  ✗ Embed model not initialized")
            return False

        print("  ✓ RAG settings initialized successfully")
        print(
            f"  ✓ LLM model: {Settings.llm.model if hasattr(Settings.llm, 'model') else 'Unknown'}"
        )
        print(
            f"  ✓ Embed model: {Settings.embed_model.model_name if hasattr(Settings.embed_model, 'model_name') else 'Unknown'}"
        )
        return True

    except Exception as e:
        print(f"  ✗ RAG settings initialization failed: {e}")
        return False


def test_agent_instantiation():
    """Test that the agent can be instantiated successfully."""
    print("\nTesting agent instantiation...")

    try:
        from src.agent import agent, ProcurementState
        from pydantic_ai.ag_ui import StateDeps

        # Create a test state
        state = ProcurementState()
        deps = StateDeps(state=state)

        # Check that agent exists
        if agent is None:
            print("  ✗ Agent not instantiated")
            return False

        print("  ✓ Agent instantiated successfully")
        print(
            f"  ✓ Agent model: {agent.model.model if hasattr(agent.model, 'model') else 'Unknown'}"
        )
        return True

    except Exception as e:
        print(f"  ✗ Agent instantiation failed: {e}")
        return False


def test_agent_tools():
    """Test that all agent tools can be called without errors."""
    print("\nTesting agent tools...")

    try:
        from src.agent import (
            read_code_generation_file,
            reset_conversation,
            clarify_components,
            ProcurementState,
        )
        from pydantic_ai.ag_ui import StateDeps
        from pydantic_ai import RunContext

        # Create test state and context
        state = ProcurementState()
        deps = StateDeps(state=state)
        ctx = RunContext(deps=deps)

        # Test read_code_generation_file
        try:
            print("  Testing read_code_generation_file...")
            content = read_code_generation_file(ctx)
            if not content:
                print("    ✗ read_code_generation_file returned empty content")
                return False
            print("    ✓ read_code_generation_file works")
        except Exception as e:
            print(f"    ✗ read_code_generation_file failed: {e}")
            return False

        # Test reset_conversation
        try:
            print("  Testing reset_conversation...")
            result = reset_conversation(ctx)
            print(f"    ✓ reset_conversation works: {result}")
        except Exception as e:
            print(f"    ✗ reset_conversation failed: {e}")
            return False

        # Test clarify_components (may fail if no CODE_GENERATION.md, but should not crash)
        try:
            print("  Testing clarify_components...")
            result = clarify_components(ctx, "test description")
            # Should return JSON string
            json.loads(result)  # Verify it's valid JSON
            print("    ✓ clarify_components works")
        except FileNotFoundError:
            print(
                "    ⚠ clarify_components failed (expected - no CODE_GENERATION.md file)"
            )
        except json.JSONDecodeError:
            print("    ✗ clarify_components returned invalid JSON")
            return False
        except Exception as e:
            print(f"    ✗ clarify_components failed unexpectedly: {e}")
            return False

        return True

    except Exception as e:
        print(f"  ✗ Agent tools testing failed: {e}")
        return False


def test_rag_tools():
    """Test that RAG-related tools work correctly."""
    print("\nTesting RAG tools...")

    try:
        from src.rag.index import get_index
        from src.rag.query import get_query_engine_tool

        # Test get_index (may return None if no index exists, but should not crash)
        try:
            print("  Testing get_index...")
            index = get_index()
            print(f"    ✓ get_index works: {index is not None}")
        except Exception as e:
            print(f"    ✗ get_index failed: {e}")
            return False

        # Test get_query_engine_tool (requires index)
        try:
            print("  Testing get_query_engine_tool...")
            index = get_index()
            if index is None:
                print("    ⚠ get_query_engine_tool skipped (no index)")
            else:
                tool = get_query_engine_tool(index=index, description="test")
                print("    ✓ get_query_engine_tool works")
        except Exception as e:
            print(f"    ✗ get_query_engine_tool failed: {e}")
            return False

        return True

    except Exception as e:
        print(f"  ✗ RAG tools testing failed: {e}")
        return False


def main():
    """Main test function."""
    print("=" * 60)
    print("AGENT TOOLS ENVIRONMENT VARIABLES TEST")
    print("=" * 60)

    tests = [
        ("Environment Variables", test_environment_variables),
        ("RAG Settings", test_rag_settings),
        ("Agent Instantiation", test_agent_instantiation),
        ("Agent Tools", test_agent_tools),
        ("RAG Tools", test_rag_tools),
    ]

    results = []
    for test_name, test_func in tests:
        print(f"\n[{test_name}]")
        print("-" * 40)
        result = test_func()
        results.append((test_name, result))

    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)

    passed = 0
    failed = 0

    for test_name, result in results:
        status = "PASS" if result else "FAIL"
        icon = "✓" if result else "✗"
        print(f"{icon} {test_name}: {status}")

        if result:
            passed += 1
        else:
            failed += 1

    print(f"\nTotal: {passed + failed} tests")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")

    if failed == 0:
        print(
            "\n🎉 All tests passed! Agent tools work correctly with loaded environment variables."
        )
        return 0
    else:
        print(
            f"\n❌ {failed} test(s) failed. Please check the output above for details."
        )
        return 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
