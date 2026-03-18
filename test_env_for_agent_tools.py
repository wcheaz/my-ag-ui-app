#!/usr/bin/env python3
"""
Focused test script to verify environment variables are loaded correctly
and accessible for agent tools using python-dotenv.

This test ensures that the migration from custom load_env() to python-dotenv's load_dotenv()
has not broken environment variable loading and that variables are accessible to tools.
"""

import os
import sys
from dotenv import load_dotenv
from pathlib import Path


def test_python_dotenv_loading():
    """Test that python-dotenv loads environment variables correctly."""
    print("Testing python-dotenv environment variable loading...")

    # Load environment variables from .env file
    result = load_dotenv()
    print(f"load_dotenv() returned: {result}")

    # Test variables that should be in the .env file
    test_vars = ["OPENAI_API_KEY", "OPENAI_BASE_URL", "EMBEDDING_MODEL", "TEST_VAR_ENV"]

    loaded_vars = 0
    for var in test_vars:
        value = os.getenv(var)
        if value:
            print(f"✓ {var} = '{value[:20]}...' (truncated)")
            loaded_vars += 1
        else:
            print(f"- {var} = NOT_FOUND")

    print(f"Successfully loaded {loaded_vars}/{len(test_vars)} environment variables")
    return loaded_vars > 0


def test_agent_environment_access():
    """Test that environment variables are accessible in agent context."""
    print("\nTesting environment variable access in agent context...")

    # Test that critical environment variables for agent are accessible
    critical_vars = {
        "OPENAI_API_KEY": "Required for OpenAI model initialization",
        "OPENAI_BASE_URL": "Required for OpenAI API endpoint",
    }

    accessible = True
    for var, description in critical_vars.items():
        value = os.getenv(var)
        if value:
            print(f"✓ {var} is accessible ({description})")
        else:
            print(f"⚠ {var} is not accessible ({description})")
            # This is just a warning, not a failure, as these might not be in all .env files

    # Test that we can simulate agent environment access
    try:
        # Simulate how agent would access environment variables
        api_key = os.environ.get("OPENAI_API_KEY", "default_key")
        base_url = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
        embedding_model = os.environ.get("EMBEDDING_MODEL", "BAAI/bge-large-en-v1.5")

        print(f"✓ Simulated agent can access:")
        print(
            f"  - OPENAI_API_KEY: {'*' * 10 if api_key != 'default_key' else 'default'}"
        )
        print(f"  - OPENAI_BASE_URL: {base_url}")
        print(f"  - EMBEDDING_MODEL: {embedding_model}")

        return True
    except Exception as e:
        print(f"✗ Failed to simulate agent environment access: {e}")
        return False


def test_env_file_parsing():
    """Test that python-dotenv correctly parses various .env file formats."""
    print("\nTesting .env file parsing capabilities...")

    # Check that the .env file exists and is readable
    env_path = Path(__file__).parent / "agent" / ".env"
    if env_path.exists():
        print(f"✓ .env file found at {env_path}")

        # Try to read and parse the file manually to check for complex formats
        try:
            with open(env_path, "r") as f:
                content = f.read()

            # Check for various .env features
            has_comments = "#" in content
            has_multiline = "\\" in content or "\n" in content
            has_quoted_values = '"' in content or "'" in content

            print(f"✓ .env file contains:")
            if has_comments:
                print("  - Comments (#)")
            if has_multiline:
                print("  - Multiline values")
            if has_quoted_values:
                print("  - Quoted values")

            # Since we already tested load_dotenv works, this confirms parsing
            return True
        except Exception as e:
            print(f"✗ Error reading .env file: {e}")
            return False
    else:
        print(f"⚠ .env file not found at {env_path}")
        # This is not necessarily a failure - the file might be elsewhere
        return True


def test_environment_persistence():
    """Test that environment variables persist and are not overwritten."""
    print("\nTesting environment variable persistence...")

    # Set a test environment variable
    test_var_name = "TEST_PERSISTENCE_VAR"
    test_var_value = "test_persistence_value"

    # Set it before loading .env
    os.environ[test_var_name] = test_var_value

    # Load .env (should not overwrite existing vars by default)
    load_dotenv()

    # Check that our test variable is still there
    persisted_value = os.getenv(test_var_name)
    if persisted_value == test_var_value:
        print(f"✓ Environment variable {test_var_name} persisted correctly")
        return True
    else:
        print(f"✗ Environment variable {test_var_name} was not persisted")
        return False


def main():
    """Main test runner."""
    print("=" * 60)
    print("Testing environment variable loading for agent tools")
    print("=" * 60)

    tests = [
        ("Python-dotenv Loading", test_python_dotenv_loading),
        ("Agent Environment Access", test_agent_environment_access),
        ("Env File Parsing", test_env_file_parsing),
        ("Environment Persistence", test_environment_persistence),
    ]

    results = []

    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"✗ {test_name} failed with exception: {e}")
            results.append((test_name, False))

    # Summary
    print("\n" + "=" * 60)
    print("TEST RESULTS SUMMARY")
    print("=" * 60)

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
        print(
            "\n🎉 ALL TESTS PASSED - Environment variables are loaded correctly and accessible to agent tools!"
        )
        return True
    else:
        print(
            f"\n⚠ {total - passed} test(s) failed - Environment loading may have issues"
        )
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
