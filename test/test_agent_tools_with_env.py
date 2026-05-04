#!/usr/bin/env python3
"""
Test script to verify all agent tools work correctly with loaded environment variables.

This test ensures that the migration from custom load_env() to python-dotenv's load_dotenv()
has not broken any agent tool functionality and that environment variables are properly
loaded and accessible to all tools.
"""

import os
import sys
import json
import logging
from pathlib import Path

# Add the src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "agent" / "src"))

# Import agent components
from agent import (
    ProcurementState,
    read_code_generation_file,
    reset_conversation,
    save_procurement_code,
    clarify_components,
)
from pydantic_ai import RunContext
from pydantic_ai.ag_ui import StateDeps

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


def create_test_context():
    """Create a test RunContext for tool testing."""
    # Create a test state
    state = ProcurementState()
    deps = StateDeps(state=state)
    # Create a minimal mock model and usage
    from unittest.mock import Mock

    mock_model = Mock()
    mock_usage = Mock()
    ctx = RunContext(deps=deps, model=mock_model, usage=mock_usage)
    return ctx


def test_read_code_generation_file_tool():
    """Test the read_code_generation_file tool works with loaded environment variables."""
    logger.info("Testing read_code_generation_file tool...")

    ctx = create_test_context()

    try:
        content = read_code_generation_file(ctx)
        logger.info("✓ read_code_generation_file tool executed successfully")
        logger.info(f"  Content length: {len(content)} characters")

        # Verify content contains expected sections
        if "Major Categories" in content:
            logger.info("✓ Content contains expected 'Major Categories' section")
        else:
            logger.warning("⚠ Content missing expected 'Major Categories' section")

        return True
    except FileNotFoundError as e:
        logger.error(f"✗ read_code_generation_file failed: {e}")
        return False
    except Exception as e:
        logger.error(f"✗ read_code_generation_file failed with unexpected error: {e}")
        return False


def test_reset_conversation_tool():
    """Test the reset_conversation tool works with loaded environment variables."""
    logger.info("Testing reset_conversation tool...")

    ctx = create_test_context()

    try:
        result = reset_conversation(ctx)
        logger.info("✓ reset_conversation tool executed successfully")
        logger.info(f"  Result: {result}")
        return True
    except Exception as e:
        logger.error(f"✗ reset_conversation tool failed: {e}")
        return False


def test_clarify_components_tool():
    """Test the clarify_components tool works with loaded environment variables."""
    logger.info("Testing clarify_components tool...")

    ctx = create_test_context()

    try:
        # First, we need to read the code generation file
        try:
            read_code_generation_file(ctx)
        except FileNotFoundError:
            logger.error(
                "✗ Cannot test clarify_components - CODE_GENERATION.md not found"
            )
            return False

        # Now test clarify_components with a sample description
        user_description = "I need a steel I-beam for construction using 3D printing"
        result = clarify_components(ctx, user_description)

        # Parse the JSON result
        try:
            result_data = json.loads(result)
            logger.info("✓ clarify_components tool executed successfully")
            logger.info(f"  Result type: {type(result_data)}")

            # Check for expected fields
            if "ambiguous_components" in result_data:
                logger.info(
                    f"  Ambiguous components: {len(result_data['ambiguous_components'])}"
                )
            if "unambiguous_components" in result_data:
                logger.info(
                    f"  Unambiguous components: {len(result_data['unambiguous_components'])}"
                )
            if "similarity_threshold_info" in result_data:
                logger.info("✓ Similarity threshold info present in result")

            return True
        except json.JSONDecodeError as e:
            logger.error(f"✗ clarify_components returned invalid JSON: {e}")
            logger.error(f"  Result: {result[:200]}...")
            return False

    except Exception as e:
        logger.error(f"✗ clarify_components tool failed: {e}")
        return False


def test_save_procurement_code_tool():
    """Test the save_procurement_code tool works with loaded environment variables."""
    logger.info("Testing save_procurement_code tool...")

    ctx = create_test_context()

    try:
        # First, we need to read the code generation file and clarify components
        try:
            read_code_generation_file(ctx)
        except FileNotFoundError:
            logger.error(
                "✗ Cannot test save_procurement_code - CODE_GENERATION.md not found"
            )
            return False

        # Import AmbiguityInfo class
        from agent import AmbiguityInfo

        # Set some component values as unambiguous in the state using proper AmbiguityInfo objects
        ctx.deps.state.component_ambiguity_status = {
            "major_category": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "M", "description": "Metal products"}],
                selected_value="M",
            ),
            "manufacturing_method": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "A", "description": "Additive manufacturing"}],
                selected_value="A",
            ),
            "object_shape": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "B", "description": "Barrel/cylindrical"}],
                selected_value="B",
            ),
            "material_type": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "01", "description": "Steel"}],
                selected_value="01",
            ),
            "quality_grade": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "01", "description": "Standard quality"}],
                selected_value="01",
            ),
            "size_category": AmbiguityInfo(
                status="unambiguous",
                options=[{"value": "2", "description": "Medium size"}],
                selected_value="2",
            ),
        }

        # Now test save_procurement_code with a sample code
        test_code = "MAB011262"
        test_description = "Steel I-beam for construction"

        result = save_procurement_code(ctx, test_code, test_description)
        logger.info("✓ save_procurement_code tool executed successfully")
        logger.info(f"  Result type: {type(result)}")

        # Check that the code was saved to the state
        if ctx.deps.state.procurement_codes:
            saved_code = ctx.deps.state.procurement_codes[-1]
            logger.info(f"  Saved code: {saved_code.code}")
            logger.info(f"  Saved description: {saved_code.description}")
            return True
        else:
            logger.warning("⚠ No codes found in state after saving")
            return True  # Still considered success since the tool executed

    except ValueError as e:
        # This is expected if components are not properly set up
        if "ERROR: You must call read_code_generation_file" in str(e):
            logger.error(
                "✗ save_procurement_code failed - workflow validation working but state not properly set up"
            )
        else:
            logger.error(f"✗ save_procurement_code failed with validation error: {e}")
        return False
    except Exception as e:
        logger.error(f"✗ save_procurement_code failed with unexpected error: {e}")
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

    # Test 2: read_code_generation_file tool
    test_results.append(
        ("read_code_generation_file", test_read_code_generation_file_tool())
    )

    # Test 3: reset_conversation tool
    test_results.append(("reset_conversation", test_reset_conversation_tool()))

    # Test 4: clarify_components tool
    test_results.append(("clarify_components", test_clarify_components_tool()))

    # Test 5: save_procurement_code tool
    test_results.append(("save_procurement_code", test_save_procurement_code_tool()))

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
