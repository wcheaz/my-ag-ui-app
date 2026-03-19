#!/usr/bin/env python3
"""
Script to measure environment variable loading performance.
This helps verify no performance degradation when switching to python-dotenv.
"""

import time
import os
import statistics
from pathlib import Path
import tempfile


# Test the new python-dotenv approach
def test_dotenv_performance(num_runs=10):
    """Test performance of python-dotenv library."""
    from dotenv import load_dotenv

    # Create a temporary .env file with typical content
    env_content = """# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_USER=myuser
DB_PASS=mypass

# API settings
API_KEY=secret-api-key-12345
API_URL=https://api.example.com

# Feature flags
FEATURE_A_ENABLED=true
FEATURE_B_ENABLED=false

# Timeout settings
TIMEOUT=30
MAX_RETRIES=3
"""

    startup_times = []

    # Create temporary file
    with tempfile.NamedTemporaryFile(mode="w", suffix=".env", delete=False) as temp_env:
        temp_env.write(env_content)
        temp_env_path = temp_env.name

    try:
        print(f"Testing python-dotenv performance over {num_runs} runs...")

        for i in range(num_runs):
            print(f"Run {i + 1}/{num_runs}...")

            # Clear environment variables to ensure clean test
            for key in [
                "DB_HOST",
                "DB_PORT",
                "DB_USER",
                "DB_PASS",
                "API_KEY",
                "API_URL",
                "FEATURE_A_ENABLED",
                "FEATURE_B_ENABLED",
                "TIMEOUT",
                "MAX_RETRIES",
            ]:
                if key in os.environ:
                    del os.environ[key]

            # Measure loading time
            start_time = time.time()

            # Load environment variables
            load_dotenv(temp_env_path)

            end_time = time.time()
            startup_time = end_time - start_time
            startup_times.append(startup_time)

            print(f"  Load time: {startup_time:.6f}s")

        return startup_times

    finally:
        # Clean up
        os.unlink(temp_env_path)

        # Clear environment variables again
        for key in [
            "DB_HOST",
            "DB_PORT",
            "DB_USER",
            "DB_PASS",
            "API_KEY",
            "API_URL",
            "FEATURE_A_ENABLED",
            "FEATURE_B_ENABLED",
            "TIMEOUT",
            "MAX_RETRIES",
        ]:
            if key in os.environ:
                del os.environ[key]


def test_custom_env_loading(num_runs=10):
    """Test performance of custom environment loading (simulating the old approach)."""

    # Create a temporary .env file with typical content
    env_content = """# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_USER=myuser
DB_PASS=mypass

# API settings
API_KEY=secret-api-key-12345
API_URL=https://api.example.com

# Feature flags
FEATURE_A_ENABLED=true
FEATURE_B_ENABLED=false

# Timeout settings
TIMEOUT=30
MAX_RETRIES=3
"""

    startup_times = []

    # Create temporary file
    with tempfile.NamedTemporaryFile(mode="w", suffix=".env", delete=False) as temp_env:
        temp_env.write(env_content)
        temp_env_path = temp_env.name

    try:
        print(f"Testing custom env loading performance over {num_runs} runs...")

        for i in range(num_runs):
            print(f"Run {i + 1}/{num_runs}...")

            # Clear environment variables to ensure clean test
            for key in [
                "DB_HOST",
                "DB_PORT",
                "DB_USER",
                "DB_PASS",
                "API_KEY",
                "API_URL",
                "FEATURE_A_ENABLED",
                "FEATURE_B_ENABLED",
                "TIMEOUT",
                "MAX_RETRIES",
            ]:
                if key in os.environ:
                    del os.environ[key]

            # Measure loading time
            start_time = time.time()

            # Custom loading logic (simulating the old approach)
            with open(temp_env_path, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        key, value = line.split("=", 1)
                        os.environ[key] = value

            end_time = time.time()
            startup_time = end_time - start_time
            startup_times.append(startup_time)

            print(f"  Load time: {startup_time:.6f}s")

        return startup_times

    finally:
        # Clean up
        os.unlink(temp_env_path)

        # Clear environment variables again
        for key in [
            "DB_HOST",
            "DB_PORT",
            "DB_USER",
            "DB_PASS",
            "API_KEY",
            "API_URL",
            "FEATURE_A_ENABLED",
            "FEATURE_B_ENABLED",
            "TIMEOUT",
            "MAX_RETRIES",
        ]:
            if key in os.environ:
                del os.environ[key]


def compare_performance(num_runs=10):
    """Compare performance between python-dotenv and custom loading."""

    # Test python-dotenv
    dotenv_times = test_dotenv_performance(num_runs)
    if not dotenv_times:
        print("Failed to measure python-dotenv performance")
        return

    # Test custom loading
    custom_times = test_custom_env_loading(num_runs)
    if not custom_times:
        print("Failed to measure custom loading performance")
        return

    # Calculate statistics
    dotenv_avg = statistics.mean(dotenv_times)
    dotenv_min = min(dotenv_times)
    dotenv_max = max(dotenv_times)

    custom_avg = statistics.mean(custom_times)
    custom_min = min(custom_times)
    custom_max = max(custom_times)

    print("\n" + "=" * 60)
    print("ENVIRONMENT VARIABLE LOADING PERFORMANCE COMPARISON")
    print("=" * 60)

    print(f"\npython-dotenv Performance:")
    print(f"  Average load time: {dotenv_avg:.6f}s")
    print(f"  Minimum load time: {dotenv_min:.6f}s")
    print(f"  Maximum load time: {dotenv_max:.6f}s")

    print(f"\nCustom Loading Performance:")
    print(f"  Average load time: {custom_avg:.6f}s")
    print(f"  Minimum load time: {custom_min:.6f}s")
    print(f"  Maximum load time: {custom_max:.6f}s")

    # Compare performance
    perf_diff = dotenv_avg - custom_avg
    perf_percent = (perf_diff / custom_avg) * 100 if custom_avg > 0 else 0

    print(f"\nPerformance Comparison:")
    print(f"  Average difference: {perf_diff:.6f}s")
    print(f"  Performance difference: {perf_percent:+.2f}%")

    # Determine if performance is acceptable
    is_degraded = perf_diff > 0.0001  # 0.1ms threshold
    is_significantly_degraded = perf_percent > 10  # 10% threshold

    print(f"\nPerformance Assessment:")
    print(f"  Performance degraded: {'Yes' if is_degraded else 'No'}")
    print(
        f"  Significantly degraded (>10%): {'Yes' if is_significantly_degraded else 'No'}"
    )

    # Save results to file
    with open("env_loading_performance_results.txt", "w") as f:
        f.write("ENVIRONMENT VARIABLE LOADING PERFORMANCE COMPARISON\n")
        f.write("=" * 60 + "\n\n")

        f.write("python-dotenv Performance:\n")
        f.write(f"  Average load time: {dotenv_avg:.6f}s\n")
        f.write(f"  Minimum load time: {dotenv_min:.6f}s\n")
        f.write(f"  Maximum load time: {dotenv_max:.6f}s\n\n")

        f.write("Custom Loading Performance:\n")
        f.write(f"  Average load time: {custom_avg:.6f}s\n")
        f.write(f"  Minimum load time: {custom_min:.6f}s\n")
        f.write(f"  Maximum load time: {custom_max:.6f}s\n\n")

        f.write("Performance Comparison:\n")
        f.write(f"  Average difference: {perf_diff:.6f}s\n")
        f.write(f"  Performance difference: {perf_percent:+.2f}%\n\n")

        f.write("Performance Assessment:\n")
        f.write(f"  Performance degraded: {'Yes' if is_degraded else 'No'}\n")
        f.write(
            f"  Significantly degraded (>10%): {'Yes' if is_significantly_degraded else 'No'}\n"
        )

    print(f"\nResults saved to env_loading_performance_results.txt")

    return {
        "dotenv_avg": dotenv_avg,
        "custom_avg": custom_avg,
        "perf_diff": perf_diff,
        "perf_percent": perf_percent,
        "is_degraded": is_degraded,
        "is_significantly_degraded": is_significantly_degraded,
    }


if __name__ == "__main__":
    # Change to the project root directory
    project_root = Path(__file__).parent
    os.chdir(project_root)

    # Run the performance comparison
    results = compare_performance()

    if results:
        # Exit with appropriate code
        exit_code = 1 if results["is_significantly_degraded"] else 0
        print(f"\nPerformance test completed with exit code: {exit_code}")
        exit(exit_code)
    else:
        print("\nPerformance test failed")
        exit(1)
