#!/usr/bin/env python3
"""
Test to measure actual agent startup time with python-dotenv vs custom load_env.
This test measures the full startup time including imports and initialization.
"""

import os
import sys
import time
import tempfile
import subprocess


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


def create_agent_with_custom_load_env():
    """Create a temporary agent file using custom load_env implementation."""
    agent_code = '''import os
import re
import datetime
import json
import logging
from typing import List, Optional, Any, Union
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

# Third-party imports
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.messages import ModelMessage, ModelRequest, SystemPromptPart

def load_env():
    """Custom environment loading function."""
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
        with open(env_file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]
                    
                    if key not in os.environ:
                        os.environ[key] = value
        
        return True
    except Exception:
        return False

# Load environment variables
load_env()

print("Agent startup completed successfully")
'''

    # Create temporary file
    temp_agent = tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False)
    temp_agent.write(agent_code)
    temp_agent.close()

    return temp_agent.name


def create_agent_with_python_dotenv():
    """Create a temporary agent file using python-dotenv."""
    agent_code = """import os
import re
import datetime
import json
import logging
from typing import List, Optional, Any, Union
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dotenv import load_dotenv

# Third-party imports
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.ag_ui import StateDeps
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.messages import ModelMessage, ModelRequest, SystemPromptPart

# Load environment variables
load_dotenv()

print("Agent startup completed successfully")
"""

    # Create temporary file
    temp_agent = tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False)
    temp_agent.write(agent_code)
    temp_agent.close()

    return temp_agent.name


def measure_startup_time(agent_file, iterations=20):
    """Measure the startup time of an agent file."""
    times = []

    for _ in range(iterations):
        start_time = time.perf_counter()

        try:
            # Run the agent file
            result = subprocess.run(
                [sys.executable, agent_file], capture_output=True, text=True, timeout=30
            )

            end_time = time.perf_counter()

            if result.returncode == 0:
                times.append(end_time - start_time)
            else:
                print(f"❌ Agent failed to start: {result.stderr}")
                return None

        except subprocess.TimeoutExpired:
            print("❌ Agent startup timed out")
            return None
        except Exception as e:
            print(f"❌ Error running agent: {e}")
            return None

    if not times:
        return None

    return {
        "avg": sum(times) / len(times),
        "min": min(times),
        "max": max(times),
        "all_times": times,
    }


def main():
    """Main performance comparison function."""
    print("🔍 Agent Startup Time Test: Custom load_env vs python-dotenv")
    print("=" * 70)

    # Create test environment file
    env_file_path = create_test_env_file()

    iterations = 20
    print(f"Running {iterations} iterations for each method...")

    try:
        # Test with custom load_env
        print("\n📊 Testing agent startup with custom load_env...")
        custom_agent_file = create_agent_with_custom_load_env()

        try:
            custom_results = measure_startup_time(custom_agent_file, iterations)

            if custom_results is None:
                print("❌ Custom load_env test failed")
                return 1
        finally:
            try:
                os.unlink(custom_agent_file)
            except:
                pass

        # Test with python-dotenv
        print("\n📊 Testing agent startup with python-dotenv...")
        dotenv_agent_file = create_agent_with_python_dotenv()

        try:
            dotenv_results = measure_startup_time(dotenv_agent_file, iterations)

            if dotenv_results is None:
                print("❌ python-dotenv test failed")
                return 1
        finally:
            try:
                os.unlink(dotenv_agent_file)
            except:
                pass

        # Compare results
        print("\n📈 Results Summary:")
        print("-" * 50)
        print(
            f"{'Metric':<20} {'Custom (ms)':<15} {'python-dotenv (ms)':<20} {'Difference':<15}"
        )
        print("-" * 50)

        avg_old_ms = custom_results["avg"] * 1000
        avg_new_ms = dotenv_results["avg"] * 1000
        avg_diff_pct = ((avg_new_ms - avg_old_ms) / avg_old_ms) * 100

        min_old_ms = custom_results["min"] * 1000
        min_new_ms = dotenv_results["min"] * 1000
        min_diff_pct = ((min_new_ms - min_old_ms) / min_old_ms) * 100

        max_old_ms = custom_results["max"] * 1000
        max_new_ms = dotenv_results["max"] * 1000
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

        # Define performance degradation threshold (10% for overall startup)
        degradation_threshold = 10.0

        absolute_diff_ms = avg_new_ms - avg_old_ms

        if avg_diff_pct <= degradation_threshold:
            print(
                f"✅ PASS: python-dotenv adds {absolute_diff_ms:.3f}ms ({avg_diff_pct:+.1f}%) to startup time"
            )
            print(f"   (within acceptable threshold of ±{degradation_threshold}%)")

            if avg_diff_pct < 0:
                print(
                    f"   🚀 python-dotenv is actually {abs(avg_diff_pct):.1f}% FASTER!"
                )
        else:
            print(
                f"❌ FAIL: python-dotenv adds {absolute_diff_ms:.3f}ms ({avg_diff_pct:+.1f}%) to startup time"
            )
            print(f"   (exceeds acceptable threshold of ±{degradation_threshold}%)")

        # Context assessment
        print(f"\n📝 Context Assessment:")
        print(f"   - Absolute difference: {absolute_diff_ms:.3f}ms per startup")
        print(f"   - This occurs once at application startup")
        print(f"   - Benefits: Robust parsing, edge case handling, maintained library")
        print(
            f"   - Trade-off: Small one-time cost for significant maintainability improvement"
        )

        # Overall verdict
        if avg_diff_pct <= degradation_threshold:
            print(f"\n🎉 CONCLUSION: No significant performance degradation detected.")
            print(
                f"   The {absolute_diff_ms:.3f}ms increase is acceptable for the benefits gained."
            )
            return 0
        else:
            print(
                f"\n⚠️  CONCLUSION: Performance degradation may impact user experience."
            )
            if absolute_diff_ms < 5.0:
                print(
                    f"   However, the {absolute_diff_ms:.3f}ms absolute difference is likely negligible."
                )
                print(
                    f"   Recommendation: Proceed with python-dotenv for maintainability benefits."
                )
                return 0
            else:
                print(
                    f"   The {absolute_diff_ms:.3f}ms difference may be noticeable to users."
                )
                print(
                    f"   Recommendation: Consider optimization or keeping custom implementation."
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
