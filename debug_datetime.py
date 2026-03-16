#!/usr/bin/env python3
"""
Detailed verification script to check datetime import and usage.
"""


def debug_function_content():
    """Debug the function content to see exact lines"""

    print("Debugging function content...")

    agent_file = "/home/ncheaz/git/my-ag-ui-app/agent/src/agent.py"

    try:
        with open(agent_file, "r") as f:
            lines = f.readlines()

        # Find the function and print its content
        in_function = False
        function_lines = []

        for i, line in enumerate(lines, 1):
            if "def read_code_generation_file(" in line:
                in_function = True
                print(f"Function starts at line {i}")
                continue

            if in_function:
                if (
                    line.strip()
                    and not line.startswith(" ")
                    and not line.startswith("\t")
                    and "def " in line
                ):
                    # Next function started
                    break
                function_lines.append((i, line.rstrip()))

        print("Function content:")
        for line_num, line_content in function_lines:
            has_datetime = "datetime" in line_content
            marker = " <-- DATETIME" if has_datetime else ""
            print(f"  {line_num}: {line_content}{marker}")

        # Check for datetime usage
        datetime_lines = [
            (num, content) for num, content in function_lines if "datetime" in content
        ]

        if datetime_lines:
            print(
                f"\n✓ Found datetime usage at lines: {[num for num, _ in datetime_lines]}"
            )
            return True
        else:
            print("\n✗ No datetime usage found in function")
            return False

    except Exception as e:
        print(f"✗ Debug failed: {e}")
        return False


if __name__ == "__main__":
    success = debug_function_content()
    exit(0 if success else 1)
