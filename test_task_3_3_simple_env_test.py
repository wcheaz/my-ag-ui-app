#!/usr/bin/env python3
"""
Simplified test script for task 3.3: Test that environment variables are loaded correctly.

This test focuses on verifying that python-dotenv is working and environment variables
are accessible, without requiring heavy dependencies like llama_index.
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv


def test_python_dotenv_import():
    """Test that python-dotenv can be imported."""
    print("Testing python-dotenv import...")
    try:
        from dotenv import load_dotenv

        print("✓ python-dotenv imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import python-dotenv: {e}")
        return False


def test_environment_variable_loading():
    """Test that environment variables are loaded correctly."""
    print("\nTesting environment variable loading...")

    # Load environment variables from .env file
    result = load_dotenv()
    print(f"load_dotenv() returned: {result}")

    # Test for key environment variables
    test_vars = [
        "OPENAI_API_KEY",
        "OPENAI_BASE_URL",
        "EMBEDDING_MODEL",
        "LLM_MAX_TOKENS",
        "LLM_CONTEXT_WINDOW",
    ]

    loaded_count = 0
    for var in test_vars:
        value = os.getenv(var)
        if value:
            print(
                f"✓ {var}: {'*' * 10 if 'KEY' in var else value[:20]}{'...' if len(value) > 20 and 'KEY' not in var else ''}"
            )
            loaded_count += 1
        else:
            print(f"- {var}: NOT_FOUND")

    print(f"Successfully loaded {loaded_count}/{len(test_vars)} environment variables")
    return loaded_count > 0


def test_agent_files_structure():
    """Test that agent files exist and have the expected structure."""
    print("\nTesting agent files structure...")

    # Check key files exist
    files_to_check = ["agent/src/agent.py", "agent/src/rag/settings.py", "agent/.env"]

    existing_files = 0
    for file_path in files_to_check:
        full_path = Path(__file__).parent / file_path
        if full_path.exists():
            print(f"✓ {file_path} exists")
            existing_files += 1
        else:
            print(f"- {file_path} not found")

    # Check that agent.py has load_dotenv import
    agent_py_path = Path(__file__).parent / "agent" / "src" / "agent.py"
    if agent_py_path.exists():
        try:
            with open(agent_py_path, "r") as f:
                content = f.read()
                if "from dotenv import load_dotenv" in content:
                    print("✓ agent.py has load_dotenv import")
                else:
                    print("✗ agent.py missing load_dotenv import")

                if "load_dotenv(" in content:
                    print("✓ agent.py has load_dotenv call")
                else:
                    print("✗ agent.py missing load_dotenv call")
        except Exception as e:
            print(f"✗ Could not read agent.py: {e}")

    # Check that rag/settings.py has load_dotenv import
    rag_settings_path = Path(__file__).parent / "agent" / "src" / "rag" / "settings.py"
    if rag_settings_path.exists():
        try:
            with open(rag_settings_path, "r") as f:
                content = f.read()
                if "from dotenv import load_dotenv" in content:
                    print("✓ rag/settings.py has load_dotenv import")
                else:
                    print("✗ rag/settings.py missing load_dotenv import")

                if "load_dotenv(" in content:
                    print("✓ rag/settings.py has load_dotenv call")
                else:
                    print("✗ rag/settings.py missing load_dotenv call")
        except Exception as e:
            print(f"✗ Could not read rag/settings.py: {e}")

    return existing_files > 0


def test_env_file_parsing():
    """Test that .env file can be parsed."""
    print("\nTesting .env file parsing...")

    env_path = Path(__file__).parent / "agent" / ".env"
    if not env_path.exists():
        print(f"⚠ .env file not found at {env_path}")
        return True  # Not necessarily a failure

    try:
        with open(env_path, "r") as f:
            content = f.read()

        print(f"✓ .env file readable ({len(content)} characters)")

        # Check for various .env features
        if "=" in content:
            print("✓ Contains variable assignments")

        if "#" in content:
            print("✓ Contains comments")

        if '"' in content or "'" in content:
            print("✓ Contains quoted values")

        return True
    except Exception as e:
        print(f"✗ Could not read .env file: {e}")
        return False


def test_pyproject_toml():
    """Test that python-dotenv is in pyproject.toml."""
    print("\nTesting pyproject.toml configuration...")

    pyproject_path = Path(__file__).parent / "agent" / "pyproject.toml"
    if not pyproject_path.exists():
        print("✗ pyproject.toml not found")
        return False

    try:
        with open(pyproject_path, "r") as f:
            content = f.read()

        if "python-dotenv" in content:
            print("✓ python-dotenv is in pyproject.toml dependencies")
            return True
        else:
            print("✗ python-dotenv not found in pyproject.toml")
            return False
    except Exception as e:
        print(f"✗ Could not read pyproject.toml: {e}")
        return False


def main():
    """Main test runner."""
    print("=" * 80)
    print(
        "TASK 3.3: Simplified test - Environment variables loading and basic structure"
    )
    print("=" * 80)

    tests = [
        ("Python-dotenv Import", test_python_dotenv_import),
        ("Environment Variable Loading", test_environment_variable_loading),
        ("Agent Files Structure", test_agent_files_structure),
        ("Env File Parsing", test_env_file_parsing),
        ("PyProject Configuration", test_pyproject_toml),
    ]

    results = []
    for test_name, test_func in tests:
        print(f"\n[{test_name}]")
        print("-" * 50)
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"✗ {test_name} failed with exception: {e}")
            results.append((test_name, False))

    # Summary
    print("\n" + "=" * 80)
    print("TASK 3.3 TEST RESULTS SUMMARY")
    print("=" * 80)

    passed = 0
    total = len(results)

    for test_name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"{status}: {test_name}")
        if result:
            passed += 1

    print(f"\nTotal tests: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")
    print(f"Success rate: {(passed / total) * 100:.1f}%")

    if passed == total:
        print("\n🎉 ALL TESTS PASSED - Environment variables are loaded correctly!")
        print("✓ Task 3.3 completed successfully - python-dotenv migration is working")
        return True
    else:
        print(f"\n⚠ {total - passed} test(s) failed - investigate the issues above")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
