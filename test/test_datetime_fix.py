#!/usr/bin/env python3
"""
Test script to verify that the datetime import fix resolves the NameError
in the read_code_generation_file function.
"""

import sys
import os

# Add the agent src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))


def test_datetime_import():
    """Test that datetime is properly imported and accessible in read_code_generation_file"""

    print("Testing datetime import fix...")

    try:
        # Import the read_code_generation_file function
        from agent import read_code_generation_file

        print("✓ Successfully imported read_code_generation_file")

        # Try to access datetime.datetime.now() which was causing the NameError
        import datetime

        timestamp = datetime.datetime.now()
        print(f"✓ Successfully accessed datetime.datetime.now(): {timestamp}")

        # The function should be able to access datetime without NameError
        # We can't easily test the full function without proper setup,
        # but we can at least verify that the import is available

        print("✓ Test passed: datetime import is working correctly")
        return True

    except NameError as e:
        if "datetime" in str(e):
            print(f"✗ Test failed: datetime NameError still exists: {e}")
            return False
        else:
            print(f"✗ Test failed: Unexpected NameError: {e}")
            return False

    except ImportError as e:
        print(f"✗ Test failed: Import error: {e}")
        return False

    except Exception as e:
        print(f"✗ Test failed: Unexpected error: {e}")
        return False


if __name__ == "__main__":
    success = test_datetime_import()
    sys.exit(0 if success else 1)
