#!/usr/bin/env python3
"""
Test script to verify that environment variables are loaded correctly from .env file
using python-dotenv library.
"""

import os
import sys
from dotenv import load_dotenv


def test_env_loading():
    """Test that environment variables are loaded correctly from .env file."""
    print("Testing environment variable loading...")

    # Load environment variables from .env file
    result = load_dotenv()
    print(f"load_dotenv() returned: {result}")

    # Expected environment variables from .env file
    expected_vars = {
        "TEST_VAR_ENV": "hello_from_dotenv",
        "API_KEY": "test_api_key_12345",
        "DATABASE_URL": "postgresql://localhost:5432/testdb",
        "DEBUG_MODE": "true",
        "MULTILINE_VAR": "This is a multi-line\nenvironment variable value",
    }

    # Check if expected variables are present
    missing_vars = []
    incorrect_vars = []

    for var_name, expected_value in expected_vars.items():
        actual_value = os.getenv(var_name)
        if actual_value is None:
            missing_vars.append(var_name)
        elif actual_value != expected_value:
            incorrect_vars.append(
                f"{var_name}: expected '{expected_value}', got '{actual_value}'"
            )
        else:
            print(f"✓ {var_name} = '{actual_value}'")

    # Report results
    if missing_vars:
        print(f"\n❌ Missing environment variables: {', '.join(missing_vars)}")
        return False

    if incorrect_vars:
        print(f"\n❌ Incorrect environment variable values:")
        for error in incorrect_vars:
            print(f"   {error}")
        return False

    print("\n✅ All environment variables loaded correctly!")
    return True


if __name__ == "__main__":
    success = test_env_loading()
    sys.exit(0 if success else 1)
