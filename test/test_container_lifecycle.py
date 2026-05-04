#!/usr/bin/env python3
"""
Test script to verify container lifecycle management.
This test verifies that the container stays running in production mode and handles graceful shutdown.
"""

import json
import sys
import time
import requests
import argparse
import subprocess
import signal
import threading
from urllib.parse import urljoin


def test_container_stays_running(docker_image="my-ag-ui-app:latest"):
    """Test that container stays running after startup."""
    print("Testing container stays running after startup...")

    try:
        # Start container in background
        container_name = f"test-lifecycle-{int(time.time())}"

        # Remove existing container if it exists
        subprocess.run(
            ["docker", "rm", "-f", container_name], capture_output=True, text=True
        )

        # Run container
        run_cmd = [
            "docker",
            "run",
            "-d",
            "--name",
            container_name,
            "-p",
            "3001:3000",  # Use port 3001 to avoid conflicts with running app
            docker_image,
        ]

        result = subprocess.run(run_cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"✗ Failed to start container: {result.stderr}")
            return False

        container_id = result.stdout.strip()
        print(f"✓ Container started with ID: {container_id}")

        # Wait a bit for container to start
        time.sleep(5)

        # Check if container is still running
        inspect_cmd = [
            "docker",
            "inspect",
            "--format",
            "{{.State.Status}}",
            container_name,
        ]
        inspect_result = subprocess.run(inspect_cmd, capture_output=True, text=True)

        if inspect_result.returncode == 0:
            status = inspect_result.stdout.strip()
            if status == "running":
                print("✓ Container is still running after startup")

                # Clean up
                subprocess.run(["docker", "stop", container_name], capture_output=True)
                subprocess.run(["docker", "rm", container_name], capture_output=True)
                return True
            else:
                print(f"✗ Container is not running (status: {status})")

                # Check exit code
                exit_code_cmd = [
                    "docker",
                    "inspect",
                    "--format",
                    "{{.State.ExitCode}}",
                    container_name,
                ]
                exit_code_result = subprocess.run(
                    exit_code_cmd, capture_output=True, text=True
                )

                if exit_code_result.returncode == 0:
                    exit_code = exit_code_result.stdout.strip()
                    if exit_code == "0":
                        print(
                            f"✗ Container exited with code 0 - indicates premature shutdown"
                        )
                    else:
                        print(f"✗ Container exited with code {exit_code}")

                # Clean up
                subprocess.run(["docker", "rm", container_name], capture_output=True)
                return False
        else:
            print(f"✗ Failed to inspect container: {inspect_result.stderr}")
            return False

    except Exception as e:
        print(f"✗ Test failed with exception: {e}")
        return False


def test_container_not_exit_code_zero(docker_image="my-ag-ui-app:latest"):
    """Test that container does not exit with code 0 in production mode."""
    print("\nTesting container does not exit with code 0...")

    try:
        container_name = f"test-exit-code-{int(time.time())}"

        # Remove existing container if it exists
        subprocess.run(
            ["docker", "rm", "-f", container_name], capture_output=True, text=True
        )

        # Run container with timeout to collect exit code
        run_cmd = [
            "docker",
            "run",
            "--rm",
            "--name",
            container_name,
            "-p",
            "3002:3000",  # Use port 3002 to avoid conflicts
            docker_image,
        ]

        # Start container and wait for it to exit or timeout
        try:
            result = subprocess.run(run_cmd, capture_output=True, text=True, timeout=30)

            if result.returncode == 0:
                print("✗ Container exited with code 0 - should stay running")
                return False
            else:
                print(
                    f"✓ Container did not exit with code 0 (exit code: {result.returncode})"
                )
                return True

        except subprocess.TimeoutExpired:
            # Container is still running (good)
            print("✓ Container did not exit within 30 second timeout (stays running)")

            # Clean up
            subprocess.run(["docker", "stop", container_name], capture_output=True)
            return True

    except Exception as e:
        print(f"✗ Test failed with exception: {e}")
        return False


def test_server_listens_on_port(docker_image="my-ag-ui-app:latest"):
    """Test that server listens on configured port."""
    print("\nTesting server listens on port 3000...")

    try:
        container_name = f"test-listen-{int(time.time())}"

        # Remove existing container if it exists
        subprocess.run(
            ["docker", "rm", "-f", container_name], capture_output=True, text=True
        )

        # Run container
        run_cmd = [
            "docker",
            "run",
            "-d",
            "--name",
            container_name,
            "-p",
            "3003:3000",  # Use port 3003 to avoid conflicts
            docker_image,
        ]

        result = subprocess.run(run_cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"✗ Failed to start container: {result.stderr}")
            return False

        # Wait for container to start
        time.sleep(10)

        # Test if server is responding on the port
        try:
            response = requests.get("http://localhost:3003/api/health", timeout=5)
            if response.status_code == 200:
                print("✓ Server is listening and responding on port 3000")

                # Clean up
                subprocess.run(["docker", "stop", container_name], capture_output=True)
                subprocess.run(["docker", "rm", container_name], capture_output=True)
                return True
            else:
                print(f"✗ Server responded with HTTP {response.status_code}")

                # Clean up
                subprocess.run(["docker", "stop", container_name], capture_output=True)
                subprocess.run(["docker", "rm", container_name], capture_output=True)
                return False

        except requests.exceptions.ConnectionError:
            print("✗ Could not connect to server on port 3000")

            # Check container logs
            logs_result = subprocess.run(
                ["docker", "logs", container_name], capture_output=True, text=True
            )

            if logs_result.returncode == 0 and logs_result.stdout:
                print("Container logs:")
                print(logs_result.stdout)

            # Clean up
            subprocess.run(["docker", "stop", container_name], capture_output=True)
            subprocess.run(["docker", "rm", container_name], capture_output=True)
            return False

    except Exception as e:
        print(f"✗ Test failed with exception: {e}")
        return False


def test_graceful_shutdown(docker_image="my-ag-ui-app:latest"):
    """Test that container handles graceful shutdown signals."""
    print("\nTesting graceful shutdown on SIGTERM...")

    try:
        container_name = f"test-shutdown-{int(time.time())}"

        # Remove existing container if it exists
        subprocess.run(
            ["docker", "rm", "-f", container_name], capture_output=True, text=True
        )

        # Run container
        run_cmd = [
            "docker",
            "run",
            "-d",
            "--name",
            container_name,
            "-p",
            "3004:3000",  # Use port 3004 to avoid conflicts
            docker_image,
        ]

        result = subprocess.run(run_cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"✗ Failed to start container: {result.stderr}")
            return False

        # Wait for container to start
        time.sleep(10)

        # Verify container is running and responding
        try:
            response = requests.get("http://localhost:3004/api/health", timeout=5)
            if response.status_code != 200:
                print("✗ Container not responding before shutdown test")
                subprocess.run(["docker", "stop", container_name], capture_output=True)
                subprocess.run(["docker", "rm", container_name], capture_output=True)
                return False
        except requests.exceptions.ConnectionError:
            print("✗ Could not connect to container before shutdown test")
            subprocess.run(["docker", "stop", container_name], capture_output=True)
            subprocess.run(["docker", "rm", container_name], capture_output=True)
            return False

        print("✓ Container is running and responding")

        # Send SIGTERM signal
        stop_result = subprocess.run(
            ["docker", "stop", container_name], capture_output=True, text=True
        )

        if stop_result.returncode == 0:
            print("✓ Container stopped gracefully on SIGTERM")

            # Check exit code (should be 0 for graceful shutdown)
            inspect_cmd = [
                "docker",
                "inspect",
                "--format",
                "{{.State.ExitCode}}",
                container_name,
            ]
            inspect_result = subprocess.run(inspect_cmd, capture_output=True, text=True)

            if inspect_result.returncode == 0:
                exit_code = inspect_result.stdout.strip()
                if exit_code == "0":
                    print(f"✓ Container exited gracefully with code 0")

                    # Clean up
                    subprocess.run(
                        ["docker", "rm", container_name], capture_output=True
                    )
                    return True
                else:
                    print(f"✗ Container exited with code {exit_code} (expected 0)")

                    # Clean up
                    subprocess.run(
                        ["docker", "rm", container_name], capture_output=True
                    )
                    return False
            else:
                print(f"✗ Failed to get container exit code: {inspect_result.stderr}")

                # Clean up
                subprocess.run(["docker", "rm", container_name], capture_output=True)
                return False
        else:
            print(f"✗ Failed to stop container: {stop_result.stderr}")
            return False

    except Exception as e:
        print(f"✗ Test failed with exception: {e}")
        return False


def main():
    """Main test runner."""
    parser = argparse.ArgumentParser(
        description="Test container lifecycle verification"
    )
    parser.add_argument(
        "--image",
        default="my-ag-ui-app:latest",
        help="Docker image to test (default: my-ag-ui-app:latest)",
    )

    args = parser.parse_args()
    docker_image = args.image

    print("=" * 60)
    print("Testing Container Lifecycle Verification")
    print("=" * 60)
    print(f"Docker image: {docker_image}")
    print("=" * 60)

    tests = [
        ("Container Stays Running", test_container_stays_running),
        ("Container Not Exit Code 0", test_container_not_exit_code_zero),
        ("Server Listens on Port 3000", test_server_listens_on_port),
        ("Graceful Shutdown", test_graceful_shutdown),
    ]

    results = []

    for test_name, test_func in tests:
        try:
            print(f"\n--- Running: {test_name} ---")
            result = test_func(docker_image)
            results.append((test_name, result))
        except Exception as e:
            print(f"✗ {test_name} failed with exception: {e}")
            results.append((test_name, False))

    # Summary
    print("\n" + "=" * 60)
    print("TEST RESULTS SUMMARY")
    print("=" * 60)

    passed = 0
    total = len(results)

    for test_name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"{status}: {test_name}")
        if result:
            passed += 1

    print(f"\nTotal tests: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")
    print(f"Success rate: {(passed / total) * 100:.1f}%")

    if passed == total:
        print("\n🎉 ALL TESTS PASSED - Container lifecycle is working correctly!")
        print("✓ Container stays running after startup")
        print("✓ Container does not exit with code 0 in production mode")
        print("✓ Server listens on port 3000")
        print("✓ Container handles graceful shutdown signals")
        return True
    else:
        print(
            f"\n⚠ {total - passed} test(s) failed - Container lifecycle may have issues"
        )
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
