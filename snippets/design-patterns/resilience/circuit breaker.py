"""
--- Circuit Breaker Pattern ---
Use Case: Prevent cascading failures by stopping requests to a failing service.
Example: Protecting downstream services in a distributed system.
Description: The Circuit Breaker monitors the success or failure of a service call.
If the number of failures exceeds a threshold, the circuit breaker opens to prevent further calls.
After a timeout period, it transitions to a "half-open" state to test if the service has recovered.
"""

import time
from typing import Callable, Any
import random

class CircuitBreaker:
    def __init__(self, max_failures: int, reset_timeout: int):
        self.max_failures = max_failures
        self.reset_timeout = reset_timeout
        self.failure_count = 0
        self.last_failure_time = 0
        self.state = "CLOSED"  # Possible states: "CLOSED", "OPEN", "HALF_OPEN"

    def call(self, func: Callable, *args, **kwargs) -> Any:
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.reset_timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception("Circuit breaker is OPEN. Calls are temporarily blocked.")

        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        self.failure_count = 0
        self.state = "CLOSED"

    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.max_failures:
            self.state = "OPEN"
            print("Circuit breaker is now OPEN due to repeated failures.")

# Simulated service that fails randomly
def unreliable_service() -> str:
    if random.random() < 0.5:
        raise Exception("Service failure!")
    return "Service success!"

# Example usage
def main():
    breaker = CircuitBreaker(max_failures=3, reset_timeout=5)

    for i in range(10):
        try:
            result = breaker.call(unreliable_service)
            print(f"Call {i + 1}: {result}")
        except Exception as e:
            print(f"Call {i + 1}: {e}")

        time.sleep(1)

if __name__ == "__main__":
    main()

# Output 
# Call 1: Service success!
# Call 2: Service failure!
# Call 3: Service failure!
# Call 4: Service failure!
# Circuit breaker is now OPEN due to repeated failures.
# Call 5: Circuit breaker is OPEN. Calls are temporarily blocked.
# Call 6: Circuit breaker is OPEN. Calls are temporarily blocked.
# Call 7: Circuit breaker is OPEN. Calls are temporarily blocked.
# Call 8: Service success!
# Call 9: Service success!
# Call 10: Service success!