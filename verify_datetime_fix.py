#!/usr/bin/env python3
"""
Simple verification script to check that datetime is imported at the top of the file
and that the read_code_generation_file function can access it.
"""


def verify_datetime_import():
    """Verify that datetime is imported at the top of agent.py"""

    print("Verifying datetime import fix...")

    agent_file = "/home/ncheaz/git/my-ag-ui-app/agent/src/agent.py"

    try:
        with open(agent_file, "r") as f:
            content = f.read()
            lines = content.split("\n")

        # Check if datetime is imported at the top (within first 10 lines)
        datetime_import_found = False
        datetime_import_line = None

        for i, line in enumerate(lines[:10], 1):
            if line.strip().startswith("import datetime"):
                datetime_import_found = True
                datetime_import_line = i
                print(f"✓ Found datetime import at line {i}: {line.strip()}")
                break

        if not datetime_import_found:
            print("✗ No datetime import found in first 10 lines")
            return False

        # Check if read_code_generation_file function uses datetime
        function_found = False
        datetime_usage_found = False
        datetime_usage_line = None

        in_function = False
        for i, line in enumerate(lines, 1):
            if "def read_code_generation_file(" in line:
                in_function = True
                function_found = True
                print(f"✓ Found read_code_generation_file function at line {i}")

            if in_function and "datetime.datetime.now()" in line:
                datetime_usage_found = True
                datetime_usage_line = i
                print(
                    f"✓ Found datetime.datetime.now() usage at line {i}: {line.strip()}"
                )
                break

            if (
                in_function
                and line.strip()
                and not line.startswith(" ")
                and not line.startswith("\t")
            ):
                # Function ended
                break

        if not function_found:
            print("✗ read_code_generation_file function not found")
            return False

        if not datetime_usage_found:
            print(
                "✗ datetime.datetime.now() usage not found in read_code_generation_file"
            )
            return False

        # Verify that import comes before usage
        if datetime_import_line > datetime_usage_line:
            print(
                f"✗ Import line {datetime_import_line} comes after usage line {datetime_usage_line}"
            )
            return False

        print(
            f"✓ Import (line {datetime_import_line}) comes before usage (line {datetime_usage_line})"
        )
        print("✓ Verification passed: datetime import fix is correct")
        return True

    except Exception as e:
        print(f"✗ Verification failed: {e}")
        return False


if __name__ == "__main__":
    success = verify_datetime_import()
    exit(0 if success else 1)
