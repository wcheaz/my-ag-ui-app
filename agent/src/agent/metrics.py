import os
import logging


logging.basicConfig(level=logging.INFO)
disambiguation_logger = logging.getLogger("disambiguation_events")
disambiguation_logger.setLevel(logging.INFO)

try:
    os.makedirs(os.path.join(os.getcwd(), "logs"), exist_ok=True)
    file_handler = logging.FileHandler(
        os.path.join(os.getcwd(), "logs", "disambiguation_events.log")
    )
    file_handler.setLevel(logging.INFO)

    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    file_handler.setFormatter(formatter)

    disambiguation_logger.addHandler(file_handler)
except Exception as e:
    print(f"Warning: Could not set up disambiguation logging: {e}")


class DisambiguationMetrics:
    """
    DISAMBIGUATION METRICS SYSTEM:
    Tracks and calculates disambiguation success rate and related metrics.

    This class implements the metrics collection system for monitoring the
    effectiveness of the disambiguation workflow. It tracks key performance
    indicators including success rate, clarification patterns, and component
    resolution statistics.

    METRICS TRACKED:
    - Total disambiguation attempts
    - Successful disambiguations (all components resolved)
    - Failed disambiguations (components still ambiguous)
    - Average clarification rounds per request
    - Component resolution statistics (ambiguous, unambiguous, guessed)
    - Success rate calculation

    USAGE:
    - Metrics are automatically collected during disambiguation workflow
    - Call get_success_rate() to calculate current success rate
    - Call log_metrics_summary() to output comprehensive metrics report
    - Call reset_metrics() to clear all metrics (for testing or periodic reset)

    INTEGRATION:
    - Integrated with detect_component_ambiguity for component-level metrics
    - Integrated with clarify_components for round-level metrics
    - Integrated with save_procurement_code for completion metrics
    - Metrics are logged to both file and console for monitoring
    """

    def __init__(self):
        """Initialize metrics tracking with default values."""
        self.total_disambiguation_attempts = 0
        self.successful_disambiguations = 0
        self.failed_disambiguations = 0
        self.total_clarification_rounds = 0
        self.components_analyzed = 0
        self.components_ambiguous = 0
        self.components_unambiguous = 0
        self.components_guessed = 0
        self.components_no_match = 0

    def record_disambiguation_attempt(self):
        """Record a new disambiguation attempt."""
        self.total_disambiguation_attempts += 1
        disambiguation_logger.info(
            f"Metrics: New disambiguation attempt recorded. Total attempts: {self.total_disambiguation_attempts}"
        )

    def record_successful_disambiguation(self, clarification_rounds: int = 0):
        """
        Record a successful disambiguation where all components were resolved.

        Args:
            clarification_rounds: Number of clarification rounds required
        """
        self.successful_disambiguations += 1
        self.total_clarification_rounds += clarification_rounds
        disambiguation_logger.info(
            f"Metrics: Successful disambiguation recorded. "
            f"Total successful: {self.successful_disambiguations}, "
            f"Rounds for this attempt: {clarification_rounds}"
        )

    def record_failed_disambiguation(self, clarification_rounds: int = 0):
        """
        Record a failed disambiguation where components remain ambiguous.

        Args:
            clarification_rounds: Number of clarification rounds attempted
        """
        self.failed_disambiguations += 1
        self.total_clarification_rounds += clarification_rounds
        disambiguation_logger.info(
            f"Metrics: Failed disambiguation recorded. "
            f"Total failed: {self.failed_disambiguations}, "
            f"Rounds for this attempt: {clarification_rounds}"
        )

    def record_component_analysis(
        self,
        ambiguous: int = 0,
        unambiguous: int = 0,
        guessed: int = 0,
        no_match: int = 0,
    ):
        """
        Record component-level analysis statistics.

        Args:
            ambiguous: Number of components marked as ambiguous
            unambiguous: Number of components marked as unambiguous
            guessed: Number of components marked as guessed
            no_match: Number of components with no matches
        """
        total_this_batch = ambiguous + unambiguous + guessed + no_match
        self.components_analyzed += total_this_batch
        self.components_ambiguous += ambiguous
        self.components_unambiguous += unambiguous
        self.components_guessed += guessed
        self.components_no_match += no_match

        disambiguation_logger.info(
            f"Metrics: Component analysis recorded. "
            f"This batch - Ambiguous: {ambiguous}, Unambiguous: {unambiguous}, "
            f"Guessed: {guessed}, No match: {no_match}"
        )

    def get_success_rate(self) -> float:
        """
        Calculate the disambiguation success rate.

        Returns:
            Success rate as a percentage (0.0 to 100.0)
            Returns 0.0 if no attempts have been made
        """
        if self.total_disambiguation_attempts == 0:
            return 0.0

        success_rate = (
            self.successful_disambiguations / self.total_disambiguation_attempts
        ) * 100.0
        return round(success_rate, 2)

    def get_average_clarification_rounds(self) -> float:
        """
        Calculate average number of clarification rounds per disambiguation attempt.

        Returns:
            Average rounds as float, or 0.0 if no attempts
        """
        if self.total_disambiguation_attempts == 0:
            return 0.0

        return round(
            self.total_clarification_rounds / self.total_disambiguation_attempts, 2
        )

    def get_component_resolution_rates(self) -> dict:
        """
        Calculate component resolution statistics.

        Returns:
            Dictionary with resolution rates for each component type
        """
        if self.components_analyzed == 0:
            return {
                "ambiguous_rate": 0.0,
                "unambiguous_rate": 0.0,
                "guessed_rate": 0.0,
                "no_match_rate": 0.0,
            }

        return {
            "ambiguous_rate": round(
                (self.components_ambiguous / self.components_analyzed) * 100.0, 2
            ),
            "unambiguous_rate": round(
                (self.components_unambiguous / self.components_analyzed) * 100.0, 2
            ),
            "guessed_rate": round(
                (self.components_guessed / self.components_analyzed) * 100.0, 2
            ),
            "no_match_rate": round(
                (self.components_no_match / self.components_analyzed) * 100.0, 2
            ),
        }

    def log_metrics_summary(self):
        """Log a comprehensive summary of all disambiguation metrics."""
        success_rate = self.get_success_rate()
        avg_rounds = self.get_average_clarification_rounds()
        resolution_rates = self.get_component_resolution_rates()

        summary_lines = [
            "=== DISAMBIGUATION METRICS SUMMARY ===",
            f"Total disambiguation attempts: {self.total_disambiguation_attempts}",
            f"Successful disambiguations: {self.successful_disambiguations}",
            f"Failed disambiguations: {self.failed_disambiguations}",
            f"Success rate: {success_rate}%",
            f"Average clarification rounds per attempt: {avg_rounds}",
            f"Total clarification rounds: {self.total_clarification_rounds}",
            "",
            "=== COMPONENT ANALYSIS ===",
            f"Total components analyzed: {self.components_analyzed}",
            f"Components ambiguous: {self.components_ambiguous} ({resolution_rates['ambiguous_rate']}%)",
            f"Components unambiguous: {self.components_unambiguous} ({resolution_rates['unambiguous_rate']}%)",
            f"Components guessed: {self.components_guessed} ({resolution_rates['guessed_rate']}%)",
            f"Components no match: {self.components_no_match} ({resolution_rates['no_match_rate']}%)",
            "=====================================",
        ]

        summary = "\n".join(summary_lines)
        disambiguation_logger.info(summary)
        print(summary)

        return summary

    def reset_metrics(self):
        """Reset all metrics to zero (for testing or periodic reset)."""
        self.total_disambiguation_attempts = 0
        self.successful_disambiguations = 0
        self.failed_disambiguations = 0
        self.total_clarification_rounds = 0
        self.components_analyzed = 0
        self.components_ambiguous = 0
        self.components_unambiguous = 0
        self.components_guessed = 0
        self.components_no_match = 0

        disambiguation_logger.info(
            "Metrics: All disambiguation metrics have been reset."
        )
        print("Disambiguation metrics have been reset.")


disambiguation_metrics = DisambiguationMetrics()


def get_disambiguation_metrics() -> dict:
    """
    Get current disambiguation metrics including success rate and statistics.

    This function provides comprehensive access to the current disambiguation
    metrics, including success rate calculation, component resolution statistics,
    and clarification round analysis. It's designed for monitoring and reporting
    purposes.

    Returns:
        Dictionary containing all current disambiguation metrics:
        - success_rate: Current success rate as percentage
        - total_attempts: Total disambiguation attempts
        - successful_disambiguations: Number of successful completions
        - failed_disambiguations: Number of failed attempts
        - average_clarification_rounds: Average rounds per attempt
        - component_resolution_rates: Breakdown by component type
        - total_components_analyzed: Total components processed
    """
    success_rate = disambiguation_metrics.get_success_rate()
    avg_rounds = disambiguation_metrics.get_average_clarification_rounds()
    resolution_rates = disambiguation_metrics.get_component_resolution_rates()

    return {
        "success_rate": success_rate,
        "total_attempts": disambiguation_metrics.total_disambiguation_attempts,
        "successful_disambiguations": disambiguation_metrics.successful_disambiguations,
        "failed_disambiguations": disambiguation_metrics.failed_disambiguations,
        "average_clarification_rounds": avg_rounds,
        "total_clarification_rounds": disambiguation_metrics.total_clarification_rounds,
        "component_resolution_rates": resolution_rates,
        "total_components_analyzed": disambiguation_metrics.components_analyzed,
        "components_breakdown": {
            "ambiguous": disambiguation_metrics.components_ambiguous,
            "unambiguous": disambiguation_metrics.components_unambiguous,
            "guessed": disambiguation_metrics.components_guessed,
            "no_match": disambiguation_metrics.components_no_match,
        },
    }


def log_disambiguation_metrics_summary():
    """
    Log a comprehensive summary of disambiguation metrics.

    This function logs a detailed summary of all current disambiguation metrics,
    including success rate, component analysis, and clarification statistics.
    The summary is both logged to file and printed to console for immediate visibility.
    """
    return disambiguation_metrics.log_metrics_summary()
