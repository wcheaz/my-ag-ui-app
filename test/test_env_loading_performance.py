#!/usr/bin/env python3
"""
Performance test to compare startup time between custom load_env function
and python-dotenv library for loading .env files.
"""

import os
import sys
import time
import tempfile
from dotenv import load_dotenv


def old_load_env():
    """
    Recreate the old custom load_env function for performance comparison.
    Based on the description in design.md, this function:
    - Searches multiple directory paths for .env file
    - Reads file line by line
    - Splits on first = character
    - Strips quotes from values
    - Only sets environment variables if they don't already exist
    """
    # Search paths from original implementation (design.md lines 95-99)
    paths_to_check = [
        os.path.join(os.getcwd(), ".env"),
        os.path.join(os.getcwd(), "..", ".env"),
        os.path.join(os.path.dirname(__file__), "..", ".env"),
        os.path.join(os.path.dirname(__file__), "..", "..", ".env"),
    ]

    env_file_path = None
    for path in paths_to_check:
        if os.path.exists(path):
            env_file_path = path
            break

    if not env_file_path:
        return False

    try:
        with open(env_file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if not line or line.startswith("#"):
                    continue

                # Split on first = character
                if "=" in line:
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip()

                    # Strip quotes from value
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]

                    # Only set if environment variable doesn't already exist
                    if key not in os.environ:
                        os.environ[key] = value

        return True
    except Exception:
        return False


def create_test_env_file():
    """Create a temporary .env file with test data."""
    env_content = """# Test environment file
TEST_VAR_ENV=hello_from_dotenv
API_KEY=test_api_key_12345
DATABASE_URL=postgresql://localhost:5432/testdb
DEBUG_MODE=true
MULTILINE_VAR="This is a multi-line\\nenvironment variable value"
QUOTED_SINGLE='single quoted value'
NORMAL_VALUE=no_quotes_here
EMPTY_VALUE=
COMMENT_AFTER_VALUE=value # this is a comment
"""

    # Create temporary file
    temp_env = tempfile.NamedTemporaryFile(mode="w", suffix=".env", delete=False)
    temp_env.write(env_content)
    temp_env.close()

    return temp_env.name


def benchmark_function(func, func_name, env_file_path, iterations=100):
    """Benchmark a function and return average execution time."""
    # Clean environment before each test
    env_vars_to_remove = [
        "TEST_VAR_ENV",
        "API_KEY",
        "DATABASE_URL",
        "DEBUG_MODE",
        "MULTILINE_VAR",
        "QUOTED_SINGLE",
        "NORMAL_VALUE",
        "EMPTY_VALUE",
        "COMMENT_AFTER_VALUE",
    ]

    # Store original values to restore later
    original_values = {}
    for var in env_vars_to_remove:
        original_values[var] = os.environ.get(var)
        if var in os.environ:
            del os.environ[var]

    # Set the .env file path to current directory for testing
    original_cwd = os.getcwd()
    test_dir = os.path.dirname(env_file_path)
    os.chdir(test_dir)

    try:
        # Copy the temp file to .env in current directory
        env_file_in_cwd = os.path.join(test_dir, ".env")

        # Copy file content
        with open(env_file_path, "r") as src:
            with open(env_file_in_cwd, "w") as dst:
                dst.write(src.read())

        # Warm up
        for _ in range(10):
            # Clear environment variables for each run
            for var in env_vars_to_remove:
                if var in os.environ:
                    del os.environ[var]
            func()

        # Benchmark
        times = []
        for _ in range(iterations):
            # Clear environment variables for each run
            for var in env_vars_to_remove:
                if var in os.environ:
                    del os.environ[var]

            start_time = time.perf_counter()
            result = func()
            end_time = time.perf_counter()

            times.append(end_time - start_time)

            # Verify the function worked
            if not result:
                print(f"❌ {func_name} failed to load environment variables")
                return None

        # Clean up test .env file
        if os.path.exists(env_file_in_cwd):
            os.remove(env_file_in_cwd)

        # Calculate statistics
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)

        return {"avg": avg_time, "min": min_time, "max": max_time, "all_times": times}

    finally:
        # Restore original directory
        os.chdir(original_cwd)

        # Restore original environment variables
        for var, value in original_values.items():
            if value is not None:
                os.environ[var] = value
            elif var in os.environ:
                del os.environ[var]


def main():
    """Main performance comparison function."""
    print("🔍 Performance Test: Custom load_env vs python-dotenv")
    print("=" * 60)

    # Create test environment file
    env_file_path = create_test_env_file()

    iterations = 100
    print(f"Running {iterations} iterations for each method...")

    try:
        # Benchmark old custom load_env function
        print("\n📊 Testing custom load_env function...")
        old_results = benchmark_function(
            old_load_env, "Custom load_env", env_file_path, iterations
        )

        if old_results is None:
            print("❌ Custom load_env test failed")
            return 1

        # Benchmark python-dotenv
        print("\n📊 Testing python-dotenv library...")
        new_results = benchmark_function(
            lambda: load_dotenv(), "python-dotenv", env_file_path, iterations
        )

        if new_results is None:
            print("❌ python-dotenv test failed")
            return 1

        # Compare results
        print("\n📈 Results Summary:")
        print("-" * 40)
        print(
            f"{'Metric':<20} {'Custom (ms)':<15} {'python-dotenv (ms)':<20} {'Difference':<15}"
        )
        print("-" * 40)

        avg_old_ms = old_results["avg"] * 1000
        avg_new_ms = new_results["avg"] * 1000
        avg_diff_pct = ((avg_new_ms - avg_old_ms) / avg_old_ms) * 100

        min_old_ms = old_results["min"] * 1000
        min_new_ms = new_results["min"] * 1000
        min_diff_pct = ((min_new_ms - min_old_ms) / min_old_ms) * 100

        max_old_ms = old_results["max"] * 1000
        max_new_ms = new_results["max"] * 1000
        max_diff_pct = ((max_new_ms - max_old_ms) / max_old_ms) * 100

        print(
            f"{'Average':<20} {avg_old_ms:<15.3f} {avg_new_ms:<20.3f} {avg_diff_pct:+.1f}%"
        )
        print(
            f"{'Minimum':<20} {min_old_ms:<15.3f} {min_new_ms:<20.3f} {min_diff_pct:+.1f}%"
        )
        print(
            f"{'Maximum':<20} {max_old_ms:<15.3f} {max_new_ms:<20.3f} {max_diff_pct:+.1f}%"
        )

        # Performance assessment
        print("\n🎯 Performance Assessment:")
        print("-" * 40)

        # Define performance degradation threshold (5%)
        degradation_threshold = 5.0

        if avg_diff_pct <= degradation_threshold:
            print(
                f"✅ PASS: python-dotenv is {avg_diff_pct:+.1f}% different from custom implementation"
            )
            print(f"   (within acceptable threshold of ±{degradation_threshold}%)")

            if avg_diff_pct < 0:
                print(
                    f"   🚀 python-dotenv is actually {abs(avg_diff_pct):.1f}% FASTER!"
                )
        else:
            print(
                f"❌ FAIL: python-dotenv is {avg_diff_pct:+.1f}% slower than custom implementation"
            )
            print(f"   (exceeds acceptable threshold of ±{degradation_threshold}%)")

        # Memory efficiency note
        print(f"\n📝 Additional Notes:")
        print(f"   - Custom implementation: ~20 lines of manual parsing code")
        print(f"   - python-dotenv: Industry-standard library with robust parsing")
        print(
            f"   - Maintenance benefit: Reduced code complexity and improved reliability"
        )

        # Overall verdict
        if avg_diff_pct <= degradation_threshold:
            print(f"\n🎉 CONCLUSION: No significant performance degradation detected.")
            print(f"   The migration to python-dotenv is performance-acceptable.")
            return 0
        else:
            print(f"\n⚠️  CONCLUSION: Performance degradation detected.")
            print(
                f"   Consider optimizing the python-dotenv usage or investigating further."
            )
            return 1

    finally:
        # Clean up temp file
        try:
            os.unlink(env_file_path)
        except:
            pass


if __name__ == "__main__":
    sys.exit(main())
