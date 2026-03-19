#!/usr/bin/env python3
"""
Test for average clarification rounds per request metric (Task 12.3).

This test verifies that the average clarification rounds per request metric
is correctly calculated and tracked through the disambiguation workflow.
"""

import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock

# Add the agent src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "agent", "src"))

# We need to mock the RAG imports since they might not be available
with patch.dict(
    "sys.modules",
    {
        "src.rag.index": MagicMock(),
        "src.rag.settings": MagicMock(),
        "src.rag.citation": MagicMock(),
        "src.rag.query": MagicMock(),
        "llama_index.core": MagicMock(),
        "llama_index.embeddings.huggingface": MagicMock(),
    },
):
    from agent import (
        read_code_generation_file,
        clarify_components,
        save_procurement_code,
        ProcurementState,
        AmbiguityInfo,
        disambiguation_metrics,
        get_disambiguation_metrics,
        log_disambiguation_metrics_summary,
    )
    from pydantic_ai import RunContext
    from pydantic_ai.ag_ui import StateDeps
    from ag_ui.core import EventType, StateSnapshotEvent


class TestAverageClarificationRoundsMetric(unittest.TestCase):
    """Test for average clarification rounds per request metric."""

    def setUp(self):
        """Set up test fixtures."""
        # Reset metrics to ensure clean test state
        disambiguation_metrics.reset_metrics()

        # Create a mock ProcurementState
        self.state = ProcurementState()

        # Create a mock RunContext
        self.mock_ctx = Mock(spec=RunContext)
        self.mock_ctx.deps = StateDeps(state=self.state)

        # Complete CODE_GENERATION.md content for realistic testing
        self.complete_code_generation_content = """
### First Letter - Major Categories
| Code | Industry Focus | Description |
|------|----------------|-------------|
| A | Agricultural products | Products derived from agriculture and farming |
| C | Chemical products | Chemical and pharmaceutical products |
| F | Food and beverage | Food items and beverages |
| M | Metal products | Metal-based products and components |
| T | Textile products | Textiles and clothing items |

### Second Letter - Manufacturing Method
| Code | Manufacturing Method | Description |
|------|---------------------|-------------|
| A | Additive manufacturing | 3D printing and additive processes |
| B | Blow molding | Plastic molding processes |
| C | Casting | Metal casting processes |
| F | Forging | Metal forging processes |
| M | Machining | CNC and traditional machining |
| W | Welding | Welding and joining processes |

### Third Letter - Object Shape/Form
| Code | Object Shape/Form | Description |
|------|------------------|-------------|
| A | Angular | Sharp-cornered shapes |
| B | Barrel/cylindrical | Rounded cylindrical shapes |
| C | Cubic | Cube or box-like shapes |
| F | Flat/sheet | Flat or sheet-like objects |
| R | Round/spherical | Spherical or rounded objects |
| T | Tubular | Hollow tube-like shapes |

### Material Type
| Code | Material Type | Examples |
|------|---------------|----------|
| 01 | Steel | Carbon steel, alloy steel, stainless steel |
| 02 | Aluminum | Aluminum alloys, pure aluminum |
| 03 | Plastic | Various plastic polymers |

### Quality Grade
| Code | Quality Grade | Description |
|------|---------------|-------------|
| 01 | Standard | Standard commercial quality |
| 02 | Premium | High-quality commercial |
| 03 | Industrial | Heavy-duty industrial use |

### Size Category
| Code | Size Category | Description |
|------|--------------|-------------|
| 1 | Small | Small items under 10cm |
| 2 | Medium | Medium items 10-50cm |
| 3 | Large | Large items 50-100cm |
"""

    async def test_average_clarification_rounds_single_request(self):
        """Test average clarification rounds calculation for a single request."""

        print("=== Testing Average Clarification Rounds - Single Request ===")

        # Initial metrics should be zero
        initial_metrics = get_disambiguation_metrics()
        self.assertEqual(initial_metrics["total_attempts"], 0)
        self.assertEqual(initial_metrics["average_clarification_rounds"], 0.0)

        # === First Request ===
        # Simulate a request that requires 2 clarification rounds
        print("\n--- Processing first request (2 rounds expected) ---")

        # Read the file
        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            content = read_code_generation_file(self.mock_ctx)
            self.assertTrue(self.state.rules_loaded_this_turn)

            # Initial clarification (detects ambiguity)
            result = clarify_components(self.mock_ctx, "industrial metal component")

            # Simulate 2 clarification rounds by setting the counter
            self.state.clarification_rounds = 2

            # Save the code (records successful disambiguation)
            generated_code = "MMA013261"
            code_description = "Industrial angular machined metal component"

            result = await save_procurement_code(
                self.mock_ctx, generated_code, code_description
            )

            # Verify save was successful
            self.assertIsInstance(result, StateSnapshotEvent)

        # Check metrics after first request
        metrics_after_first = get_disambiguation_metrics()

        print(
            f"Total attempts after first request: {metrics_after_first['total_attempts']}"
        )
        print(
            f"Average rounds after first request: {metrics_after_first['average_clarification_rounds']}"
        )

        # Should have 1 attempt and average of 2 rounds
        self.assertEqual(metrics_after_first["total_attempts"], 1)
        self.assertEqual(metrics_after_first["average_clarification_rounds"], 2.0)
        self.assertEqual(metrics_after_first["total_clarification_rounds"], 2)

    async def test_average_clarification_rounds_multiple_requests(self):
        """Test average clarification rounds calculation across multiple requests."""

        print("\n=== Testing Average Clarification Rounds - Multiple Requests ===")

        # Reset metrics for clean test
        disambiguation_metrics.reset_metrics()

        # === Request 1: 1 round ===
        print("\n--- Request 1: 1 clarification round ---")

        # Create new state for first request
        state1 = ProcurementState()
        ctx1 = Mock(spec=RunContext)
        ctx1.deps = StateDeps(state=state1)

        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            # Read file and get clarification
            read_code_generation_file(ctx1)
            clarify_components(ctx1, "steel small component")  # Should be unambiguous

            # Set 1 clarification round and save
            state1.clarification_rounds = 1
            result = await save_procurement_code(
                ctx1, "A0101261", "Small steel component"
            )
            self.assertIsInstance(result, StateSnapshotEvent)

        # === Request 2: 3 rounds ===
        print("\n--- Request 2: 3 clarification rounds ---")

        # Create new state for second request
        state2 = ProcurementState()
        ctx2 = Mock(spec=RunContext)
        ctx2.deps = StateDeps(state=state2)

        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            # Read file and get clarification
            read_code_generation_file(ctx2)
            clarify_components(
                ctx2, "industrial shaped manufactured component"
            )  # Ambiguous

            # Set 3 clarification rounds and save
            state2.clarification_rounds = 3
            result = await save_procurement_code(
                ctx2, "MMA033261", "Industrial angular machined component"
            )
            self.assertIsInstance(result, StateSnapshotEvent)

        # === Request 3: 2 rounds ===
        print("\n--- Request 3: 2 clarification rounds ---")

        # Create new state for third request
        state3 = ProcurementState()
        ctx3 = Mock(spec=RunContext)
        ctx3.deps = StateDeps(state=state3)

        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            # Read file and get clarification
            read_code_generation_file(ctx3)
            clarify_components(ctx3, "medium quality component")  # Somewhat ambiguous

            # Set 2 clarification rounds and save
            state3.clarification_rounds = 2
            result = await save_procurement_code(
                ctx3, "A022261", "Medium quality component"
            )
            self.assertIsInstance(result, StateSnapshotEvent)

        # Check final metrics
        final_metrics = get_disambiguation_metrics()

        print(f"\nFinal Metrics Summary:")
        print(f"Total attempts: {final_metrics['total_attempts']}")
        print(
            f"Total clarification rounds: {final_metrics['total_clarification_rounds']}"
        )
        print(
            f"Average rounds per request: {final_metrics['average_clarification_rounds']}"
        )

        # Should have 3 attempts with total of 6 rounds (1 + 3 + 2)
        self.assertEqual(final_metrics["total_attempts"], 3)
        self.assertEqual(final_metrics["total_clarification_rounds"], 6)
        self.assertEqual(
            final_metrics["average_clarification_rounds"], 2.0
        )  # 6 / 3 = 2.0

    async def test_average_clarification_rounds_with_failures(self):
        """Test average clarification rounds calculation including failed attempts."""

        print("\n=== Testing Average Clarification Rounds - With Failures ===")

        # Reset metrics for clean test
        disambiguation_metrics.reset_metrics()

        # === Successful Request: 2 rounds ===
        print("\n--- Successful request: 2 rounds ---")

        state1 = ProcurementState()
        ctx1 = Mock(spec=RunContext)
        ctx1.deps = StateDeps(state=state1)

        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            read_code_generation_file(ctx1)
            clarify_components(ctx1, "industrial component")

            state1.clarification_rounds = 2
            result = await save_procurement_code(
                ctx1, "M0103261", "Industrial component"
            )
            self.assertIsInstance(result, StateSnapshotEvent)

        # === Failed Request: 1 round (user abandoned) ===
        print("\n--- Failed request: 1 round (abandoned) ---")

        state2 = ProcurementState()
        ctx2 = Mock(spec=RunContext)
        ctx2.deps = StateDeps(state=state2)

        with patch("builtins.open", create=True) as mock_open:
            mock_open.return_value.__enter__.return_value.read.return_value = (
                self.complete_code_generation_content
            )

            read_code_generation_file(ctx2)
            clarify_components(ctx2, "complex shaped item")  # Very ambiguous

            # User abandoned after 1 round (failed disambiguation)
            state2.clarification_rounds = 1

            # Manually record failed disambiguation (normally would be done by workflow)
            disambiguation_metrics.record_failed_disambiguation(clarification_rounds=1)

        # Check metrics including failures
        metrics_with_failures = get_disambiguation_metrics()

        print(f"\nMetrics with Failures:")
        print(f"Total attempts: {metrics_with_failures['total_attempts']}")
        print(
            f"Successful disambiguations: {metrics_with_failures['successful_disambiguations']}"
        )
        print(
            f"Failed disambiguations: {metrics_with_failures['failed_disambiguations']}"
        )
        print(
            f"Total clarification rounds: {metrics_with_failures['total_clarification_rounds']}"
        )
        print(
            f"Average rounds per request: {metrics_with_failures['average_clarification_rounds']}"
        )

        # Should have 2 attempts (1 successful, 1 failed) with 3 total rounds
        self.assertEqual(metrics_with_failures["total_attempts"], 2)
        self.assertEqual(metrics_with_failures["successful_disambiguations"], 1)
        self.assertEqual(metrics_with_failures["failed_disambiguations"], 1)
        self.assertEqual(metrics_with_failures["total_clarification_rounds"], 3)
        self.assertEqual(
            metrics_with_failures["average_clarification_rounds"], 1.5
        )  # 3 / 2 = 1.5

    def test_metrics_summary_logging(self):
        """Test that metrics summary includes average clarification rounds."""

        print("\n=== Testing Metrics Summary Logging ===")

        # Add some test data
        disambiguation_metrics.reset_metrics()
        disambiguation_metrics.record_disambiguation_attempt()
        disambiguation_metrics.record_successful_disambiguation(clarification_rounds=2)
        disambiguation_metrics.record_disambiguation_attempt()
        disambiguation_metrics.record_successful_disambiguation(clarification_rounds=4)

        # Log the metrics summary
        summary = log_disambiguation_metrics_summary()

        # Verify the summary contains average rounds information
        self.assertIn("Average clarification rounds per attempt", summary)
        self.assertIn("3.0", summary)  # (2 + 4) / 2 = 3.0
        self.assertIn("Total clarification rounds", summary)

        print(f"Metrics summary logged successfully:")
        print(summary)

    def test_get_average_clarification_rounds_directly(self):
        """Test the get_average_clarification_rounds method directly."""

        print("\n=== Testing get_average_clarification_rounds Method ===")

        # Reset metrics
        disambiguation_metrics.reset_metrics()

        # Initially should be 0.0
        avg_rounds = disambiguation_metrics.get_average_clarification_rounds()
        self.assertEqual(avg_rounds, 0.0)

        # Add some test data
        disambiguation_metrics.record_disambiguation_attempt()
        disambiguation_metrics.record_successful_disambiguation(clarification_rounds=3)

        # Should now be 3.0
        avg_rounds = disambiguation_metrics.get_average_clarification_rounds()
        self.assertEqual(avg_rounds, 3.0)

        # Add more data
        disambiguation_metrics.record_disambiguation_attempt()
        disambiguation_metrics.record_successful_disambiguation(clarification_rounds=1)

        # Should now be 2.0 ( (3 + 1) / 2 )
        avg_rounds = disambiguation_metrics.get_average_clarification_rounds()
        self.assertEqual(avg_rounds, 2.0)

        print(f"✓ Average clarification rounds calculated correctly: {avg_rounds}")


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
