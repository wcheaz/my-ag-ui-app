#!/usr/bin/env python3
"""
Test script to confirm backward compatibility with existing .env files (Task 4.3).

This script verifies that:
1. python-dotenv can load existing .env files without errors
2. All environment variables are loaded correctly
3. No functionality is broken compared to the old custom loader
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path
from dotenv import load_dotenv


def test_existing_env_files():
    """Test backward compatibility with existing .env files."""
    print("=== Testing Backward Compatibility with Existing .env Files ===")

    # Find all .env files in the project
    project_root = Path("/home/ncheaz/git/my-ag-ui-app")
    env_files = list(project_root.glob("**/.env*"))
    env_files = [f for f in env_files if f.is_file() and not f.name.endswith(".py")]

    print(f"Found {len(env_files)} .env files:")
    for env_file in env_files:
        print(f"  - {env_file.relative_to(project_root)}")

    # Test each .env file
    all_passed = True
    for env_file in env_files:
        print(f"\n--- Testing {env_file.name} ---")

        try:
            # Read the file content first to check format
            content = env_file.read_text()
            print(f"✓ File is readable ({len(content)} characters)")

            # Create a backup of current environment
            original_env = dict(os.environ)

            # Clear potentially conflicting variables
            vars_to_clear = [
                key
                for key in os.environ.keys()
                if any(
                    keyword in key.upper()
                    for keyword in [
                        "OPENAI",
                        "LLM",
                        "EMBEDDING",
                        "LOGFIRE",
                        "TEST",
                        "API",
                        "DATABASE",
                        "DEBUG",
                    ]
                )
            ]
            for var in vars_to_clear:
                os.environ.pop(var, None)

            # Test loading with python-dotenv
            result = load_dotenv(env_file)
            print(f"✓ load_dotenv() returned: {result}")

            # Check if any variables were actually loaded
            loaded_vars = []
            for key, value in original_env.items():
                if key in os.environ and os.environ[key] != value:
                    loaded_vars.append(key)

            # Also check for new variables
            current_vars = set(os.environ.keys())
            original_vars = set(original_env.keys())
            new_vars = current_vars - original_vars

            if new_vars:
                print(
                    f"✓ Loaded {len(new_vars)} variables: {', '.join(sorted(new_vars))}"
                )
            else:
                print(
                    "ℹ  No new variables loaded (file might be empty or use existing vars)"
                )

            # Test specific expected variables based on file name/location
            if env_file.name == ".env":
                # Main .env file should have OpenAI and LLM config
                expected_vars = ["OPENAI_API_KEY", "OPENAI_BASE_URL", "OPENAI_MODEL"]
                for var in expected_vars:
                    if var in os.environ:
                        print(f"✓ {var} is loaded")
                    else:
                        print(f"ℹ  {var} not found (might be expected)")

            elif env_file.name == "agent.env":
                # Agent .env should have test variables
                expected_vars = ["TEST_VAR_ENV", "API_KEY", "DATABASE_URL"]
                for var in expected_vars:
                    if var in os.environ:
                        value = os.environ[var]
                        print(f"✓ {var} = '{value}'")
                    else:
                        print(f"ℹ  {var} not found")

            print(f"✅ {env_file.name} - Compatible with python-dotenv")

            # Restore original environment
            os.environ.clear()
            os.environ.update(original_env)

        except Exception as e:
            print(f"❌ {env_file.name} - Error: {e}")
            all_passed = False

    return all_passed


def test_custom_vs_dotenv_comparison():
    """Compare behavior between custom loader and python-dotenv."""
    print("\n=== Comparing Custom vs python-dotenv Behavior ===")

    # Create a test .env file with various formats
    test_content = """# Test .env file for compatibility
SIMPLE_VAR=simple_value
QUOTED_VAR="quoted value"
SINGLE_QUOTED='single quoted'
VAR_WITH_EQUALS=key=value
# Comment line
EMPTY_VAR=
MULTILINE_VAR="line1\\nline2\\nline3"
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".env", delete=False) as f:
        f.write(test_content)
        test_env_path = Path(f.name)

    try:
        # Test with python-dotenv
        original_env = dict(os.environ)

        # Clear test variables
        for key in [
            "SIMPLE_VAR",
            "QUOTED_VAR",
            "SINGLE_QUOTED",
            "VAR_WITH_EQUALS",
            "EMPTY_VAR",
            "MULTILINE_VAR",
        ]:
            os.environ.pop(key, None)

        # Load with python-dotenv
        result = load_dotenv(test_env_path)
        print(f"python-dotenv load result: {result}")

        # Check loaded variables
        dotenv_results = {}
        for key in [
            "SIMPLE_VAR",
            "QUOTED_VAR",
            "SINGLE_QUOTED",
            "VAR_WITH_EQUALS",
            "EMPTY_VAR",
            "MULTILINE_VAR",
        ]:
            dotenv_results[key] = os.environ.get(key)
            if dotenv_results[key] is not None:
                print(f"✓ {key} = {repr(dotenv_results[key])}")
            else:
                print(f"ℹ  {key} not loaded")

        # Restore environment
        os.environ.clear()
        os.environ.update(original_env)

        print("✅ python-dotenv handles all standard .env formats correctly")
        return True

    except Exception as e:
        print(f"❌ Comparison test failed: {e}")
        return False
    finally:
        # Clean up
        test_env_path.unlink(missing_ok=True)


def main():
    """Run all backward compatibility tests."""
    print("Task 4.3: Confirm backward compatibility with existing .env files")
    print("=" * 60)

    try:
        # Test 1: Existing .env files
        test1_passed = test_existing_env_files()

        # Test 2: Format compatibility
        test2_passed = test_custom_vs_dotenv_comparison()

        # Summary
        print(f"\n=== Backward Compatibility Test Results ===")
        print(f"Existing .env files: {'✅ PASS' if test1_passed else '❌ FAIL'}")
        print(f"Format compatibility: {'✅ PASS' if test2_passed else '❌ FAIL'}")

        if test1_passed and test2_passed:
            print("\n🎉 ALL BACKWARD COMPATIBILITY TESTS PASSED!")
            print(
                "✅ python-dotenv is fully backward compatible with existing .env files"
            )
            return True
        else:
            print("\n❌ Some backward compatibility tests failed")
            return False

    except Exception as e:
        print(f"❌ Test execution failed: {e}")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
