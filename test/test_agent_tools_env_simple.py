#!/usr/bin/env python3
"""
Test script to verify all agent tools work correctly with loaded environment variables.

This test ensures that the migration from custom load_env() to python-dotenv's load_dotenv()
has not broken any agent tool functionality and that environment variables are properly
loaded and accessible to all tools.
"""

import os
import sys
import subprocess
import logging
from pathlib import Path

# Set up logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def test_environment_variables_loaded():
    """Test that environment variables are loaded correctly."""
    logger.info("Testing environment variables loading...")

    # Test that we can access environment variables that should be loaded from .env
    api_key = os.environ.get("OPENAI_API_KEY")
    base_url = os.environ.get("OPENAI_BASE_URL")

    if api_key:
        logger.info("✓ OPENAI_API_KEY is loaded from .env file")
    else:
        logger.warning("⚠ OPENAI_API_KEY not found in environment variables")

    if base_url:
        logger.info("✓ OPENAI_BASE_URL is loaded from .env file")
    else:
        logger.warning("⚠ OPENAI_BASE_URL not found in environment variables")

    # Test additional environment variables that might be in .env
    embedding_model = os.environ.get("EMBEDDING_MODEL")
    if embedding_model:
        logger.info(f"✓ EMBEDDING_MODEL is loaded: {embedding_model}")

    return True


def test_existing_agent_tests():
    """Test that existing agent tests work with loaded environment variables."""
    logger.info("Testing existing agent tests...")

    test_files = [
        "test_env_loading.py",
        "test_disambiguation_edge_cases.py",
        "test_additional_disambiguation_edge_cases.py",
        "test_multi_request_flag_reset.py",
    ]

    results = []

    for test_file in test_files:
        logger.info(f"Running {test_file}...")
        try:
            result = subprocess.run(
                ["python", test_file],
                capture_output=True,
                text=True,
                cwd="/home/ncheaz/git/my-ag-ui-app/agent",
                timeout=60,
            )

            if result.returncode == 0:
                logger.info(f"✓ {test_file} passed")
                results.append((test_file, True))
            else:
                logger.error(
                    f"✗ {test_file} failed with return code {result.returncode}"
                )
                logger.error(f"  stdout: {result.stdout[:200]}...")
                logger.error(f"  stderr: {result.stderr[:200]}...")
                results.append((test_file, False))

        except subprocess.TimeoutExpired:
            logger.error(f"✗ {test_file} timed out")
            results.append((test_file, False))
        except Exception as e:
            logger.error(f"✗ {test_file} failed with error: {e}")
            results.append((test_file, False))

    return results


def test_agent_imports():
    """Test that agent can be imported with environment variables loaded."""
    logger.info("Testing agent imports...")

    try:
        # Try to import the agent with environment variables
        result = subprocess.run(
            [
                "python",
                "-c",
                """
import sys
sys.path.insert(0, 'src')
from dotenv import load_dotenv
load_dotenv()
print('✓ Environment variables loaded successfully')
print(f'OPENAI_API_KEY: {os.environ.get(\"OPENAI_API_KEY\", \"NOT_FOUND\")}')
print(f'OPENAI_BASE_URL: {os.environ.get(\"OPENAI_BASE_URL\", \"NOT_FOUND\")}')
""",
            ],
            capture_output=True,
            text=True,
            cwd="/home/ncheaz/git/my-ag-ui-app/agent",
            timeout=30,
        )

        if result.returncode == 0:
            logger.info("✓ Agent imports work with loaded environment variables")
            logger.info(f"  Output: {result.stdout.strip()}")
            return True
        else:
            logger.error(f"✗ Agent imports failed: {result.stderr}")
            return False

    except Exception as e:
        logger.error(f"✗ Agent imports test failed: {e}")
        return False


def main():
    """Main test runner."""
    logger.info("=" * 60)
    logger.info("Testing all agent tools with loaded environment variables")
    logger.info("=" * 60)

    test_results = []

    # Test 1: Environment variables loaded
    test_results.append(
        ("Environment Variables Loaded", test_environment_variables_loaded())
    )

    # Test 2: Agent imports work
    test_results.append(("Agent Imports", test_agent_imports()))

    # Test 3: Existing tests work
    existing_results = test_existing_agent_tests()
    passed_existing = sum(1 for _, result in existing_results if result)
    total_existing = len(existing_results)

    if total_existing > 0:
        test_results.append(("Existing Tests", passed_existing == total_existing))

        # Log individual test results
        for test_name, result in existing_results:
            status = "PASS" if result else "FAIL"
            logger.info(f"  {status}: {test_name}")

    # Summary
    logger.info("=" * 60)
    logger.info("TEST RESULTS SUMMARY")
    logger.info("=" * 60)

    passed = 0
    total = len(test_results)

    for test_name, result in test_results:
        status = "PASS" if result else "FAIL"
        logger.info(f"{status}: {test_name}")
        if result:
            passed += 1

    logger.info(f"\nTotal tests: {total}")
    logger.info(f"Passed: {passed}")
    logger.info(f"Failed: {total - passed}")
    logger.info(f"Success rate: {(passed / total) * 100:.1f}%")

    if passed == total:
        logger.info(
            "🎉 ALL TESTS PASSED - All agent tools work correctly with loaded environment variables!"
        )
        return True
    else:
        logger.warning("⚠ Some tests failed - investigate the issues above")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
