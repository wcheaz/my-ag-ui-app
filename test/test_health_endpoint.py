#!/usr/bin/env python3
"""
Test script to verify the health endpoint functionality.
This test verifies that the /api/health endpoint works correctly for deployment monitoring.
"""

import json
import sys
import time
import requests
import argparse
from urllib.parse import urljoin


def test_health_endpoint_200(base_url="http://localhost:3000"):
    """Test that health endpoint returns HTTP 200 with JSON status."""
    print("Testing health endpoint returns HTTP 200 with JSON status...")

    try:
        health_url = urljoin(base_url, "/api/health")
        response = requests.get(health_url, timeout=5)

        if response.status_code == 200:
            print("✓ Health endpoint returned HTTP 200")

            try:
                data = response.json()
                if "status" in data and data["status"] == "healthy":
                    print("✓ Response contains correct status: 'healthy'")

                    if "timestamp" in data:
                        print("✓ Response contains timestamp")
                        return True
                    else:
                        print("✗ Response missing timestamp")
                        return False
                else:
                    print(
                        f"✗ Response contains incorrect status: {data.get('status', 'missing')}"
                    )
                    return False
            except json.JSONDecodeError:
                print("✗ Response is not valid JSON")
                return False
        else:
            print(f"✗ Health endpoint returned HTTP {response.status_code}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to connect to health endpoint: {e}")
        return False


def test_health_endpoint_response_time(base_url="http://localhost:3000"):
    """Test that health endpoint responds within 1 second."""
    print("\nTesting health endpoint response time...")

    try:
        health_url = urljoin(base_url, "/api/health")

        # Measure response time
        start_time = time.time()
        response = requests.get(health_url, timeout=5)
        end_time = time.time()

        response_time = (end_time - start_time) * 1000  # Convert to milliseconds

        if response_time < 1000:
            print(f"✓ Health endpoint responded in {response_time:.2f}ms (< 1000ms)")
            return True
        else:
            print(f"✗ Health endpoint took {response_time:.2f}ms (>= 1000ms)")
            return False

    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to connect to health endpoint: {e}")
        return False


def test_health_endpoint_no_auth(base_url="http://localhost:3000"):
    """Test that health endpoint is accessible without authentication."""
    print("\nTesting health endpoint accessibility without authentication...")

    try:
        health_url = urljoin(base_url, "/api/health")

        # Make request without any authentication headers
        response = requests.get(health_url, timeout=5)

        if response.status_code == 200:
            print("✓ Health endpoint accessible without authentication")
            return True
        else:
            print(
                f"✗ Health endpoint requires authentication or returned {response.status_code}"
            )
            return False

    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to connect to health endpoint: {e}")
        return False


def test_health_endpoint_failure_scenario(base_url="http://localhost:3000"):
    """Test health endpoint failure scenario with ?fail=true parameter."""
    print("\nTesting health endpoint failure scenario...")

    try:
        health_url = urljoin(base_url, "/api/health?fail=true")
        response = requests.get(health_url, timeout=5)

        if response.status_code == 500:
            print("✓ Health endpoint returned HTTP 500 for failure scenario")

            try:
                data = response.json()
                if "status" in data and data["status"] == "unhealthy":
                    print("✓ Failure response contains correct status: 'unhealthy'")

                    if "error" in data:
                        print("✓ Failure response contains error message")
                        return True
                    else:
                        print("✗ Failure response missing error message")
                        return False
                else:
                    print(
                        f"✗ Failure response contains incorrect status: {data.get('status', 'missing')}"
                    )
                    return False
            except json.JSONDecodeError:
                print("✗ Failure response is not valid JSON")
                return False
        else:
            print(
                f"✗ Health endpoint returned HTTP {response.status_code} instead of 500 for failure scenario"
            )
            return False

    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to connect to health endpoint: {e}")
        return False


def test_health_endpoint_content_type(base_url="http://localhost:3000"):
    """Test that health endpoint returns correct content-type."""
    print("\nTesting health endpoint content-type...")

    try:
        health_url = urljoin(base_url, "/api/health")
        response = requests.get(health_url, timeout=5)

        content_type = response.headers.get("content-type", "")

        if "application/json" in content_type:
            print(f"✓ Health endpoint returned correct content-type: {content_type}")
            return True
        else:
            print(f"✗ Health endpoint returned incorrect content-type: {content_type}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"✗ Failed to connect to health endpoint: {e}")
        return False


def main():
    """Main test runner."""
    parser = argparse.ArgumentParser(description="Test health endpoint functionality")
    parser.add_argument(
        "--url",
        default="http://localhost:3000",
        help="Base URL of the application (default: http://localhost:3000)",
    )

    args = parser.parse_args()
    base_url = args.url

    print("=" * 60)
    print("Testing Health Endpoint Functionality")
    print("=" * 60)
    print(f"Base URL: {base_url}")
    print("=" * 60)

    tests = [
        ("HTTP 200 Response", test_health_endpoint_200),
        ("Response Time < 1s", test_health_endpoint_response_time),
        ("No Authentication Required", test_health_endpoint_no_auth),
        ("Failure Scenario", test_health_endpoint_failure_scenario),
        ("Correct Content-Type", test_health_endpoint_content_type),
    ]

    results = []

    for test_name, test_func in tests:
        try:
            result = test_func(base_url)
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
        print("\n🎉 ALL TESTS PASSED - Health endpoint is working correctly!")
        print("✓ Endpoint returns HTTP 200 with JSON status")
        print("✓ Endpoint responds within 1 second")
        print("✓ Endpoint is accessible without authentication")
        print("✓ Endpoint handles failure scenarios correctly")
        print("✓ Endpoint returns correct content-type")
        return True
    else:
        print(f"\n⚠ {total - passed} test(s) failed - Health endpoint may have issues")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
