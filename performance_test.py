#!/usr/bin/env python3
"""
Script to measure agent startup time performance.
This helps verify no performance degradation when switching to python-dotenv.
"""

import time
import sys
import os
import statistics
from pathlib import Path

# Add agent source directory to Python path
agent_src_path = Path(__file__).parent / "agent" / "src"
sys.path.insert(0, str(agent_src_path))


def measure_agent_startup_time(num_runs=5):
    """
    Measure agent startup time multiple times and return statistics.
    """
    startup_times = []

    print(f"Measuring agent startup time over {num_runs} runs...")

    for i in range(num_runs):
        print(f"Run {i + 1}/{num_runs}...")

        # Clear any imported modules to ensure clean startup
        modules_to_remove = [
            mod for mod in sys.modules.keys() if mod.startswith("agent")
        ]
        for mod in modules_to_remove:
            if mod in sys.modules:
                del sys.modules[mod]

        # Measure startup time
        start_time = time.time()

        try:
            # Import the agent module (this triggers startup)
            import agent

            # Access the main agent class if it exists
            if hasattr(agent, "Agent"):
                # Try to instantiate if there's a no-arg constructor
                try:
                    agent.Agent()
                except:
                    # If instantiation fails, just importing is enough
                    pass
        except Exception as e:
            print(f"Error importing agent: {e}")
            continue

        end_time = time.time()
        startup_time = end_time - start_time
        startup_times.append(startup_time)

        print(f"  Startup time: {startup_time:.3f}s")

    if startup_times:
        avg_time = statistics.mean(startup_times)
        min_time = min(startup_times)
        max_time = max(startup_times)

        print("\n=== Startup Time Performance Results ===")
        print(f"Average startup time: {avg_time:.3f}s")
        print(f"Minimum startup time: {min_time:.3f}s")
        print(f"Maximum startup time: {max_time:.3f}s")
        print(f"All measurements: {[f'{t:.3f}s' for t in startup_times]}")

        # Calculate performance threshold (e.g., 10% higher than average)
        performance_threshold = avg_time * 1.1

        # Check for significant variance
        significant_variance = max_time > performance_threshold

        print(f"\nPerformance Analysis:")
        print(f"Performance threshold (10% above avg): {performance_threshold:.3f}s")
        print(
            f"Significant variance detected: {'Yes' if significant_variance else 'No'}"
        )

        return {
            "average": avg_time,
            "minimum": min_time,
            "maximum": max_time,
            "all_times": startup_times,
            "significant_variance": significant_variance,
        }
    else:
        print("No successful measurements recorded.")
        return None


if __name__ == "__main__":
    # Change to the correct directory
    project_root = Path(__file__).parent
    os.chdir(project_root)

    # Run the performance test
    results = measure_agent_startup_time()

    if results:
        # Write results to a file for later reference
        with open("startup_performance_results.txt", "w") as f:
            f.write("Agent Startup Time Performance Results\n")
            f.write("=" * 40 + "\n")
            f.write(f"Average startup time: {results['average']:.3f}s\n")
            f.write(f"Minimum startup time: {results['minimum']:.3f}s\n")
            f.write(f"Maximum startup time: {results['maximum']:.3f}s\n")
            f.write(
                f"All measurements: {[f'{t:.3f}s' for t in results['all_times']]}\n"
            )
            f.write(
                f"Significant variance: {'Yes' if results['significant_variance'] else 'No'}\n"
            )

        print(f"\nResults saved to startup_performance_results.txt")
