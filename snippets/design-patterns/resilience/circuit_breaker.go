// --- Circuit Breaker Pattern ---
// Use Case: Prevent cascading failures by stopping requests to a failing service.
// Example: Protecting downstream services in distributed systems.
// Description: The circuit breaker monitors the success or failure of a service call.
// If the number of failures exceeds a threshold, the circuit breaker opens to prevent further calls.
// After a timeout period, the circuit breaker enters a "half-open" state to test if the service has recovered.

package main

import (
	"errors"
	"fmt"
	"time"
)

type CircuitBreaker struct {
	failures      int
	maxFailures   int
	timeout       time.Duration
	lastFailure   time.Time
	state         string // "closed", "open", "half-open"
}

func NewCircuitBreaker(maxFailures int, timeout time.Duration) *CircuitBreaker {
	return &CircuitBreaker{
		maxFailures: maxFailures,
		timeout:     timeout,
		state:       "closed",
	}
}

func (cb *CircuitBreaker) Call(fn func() error) error {
	if cb.state == "open" && time.Since(cb.lastFailure) < cb.timeout {
		return errors.New("circuit breaker open")
	}

	err := fn()
	if err != nil {
		cb.failures++
		cb.lastFailure = time.Now()
		if cb.failures >= cb.maxFailures {
			cb.state = "open"
		}
		return err
	}

	cb.failures = 0
	cb.state = "closed"
	return nil
}

func main() {
	cb := NewCircuitBreaker(3, 2*time.Second)

	task := func() error {
		return errors.New("service error")
	}

	for i := 0; i < 5; i++ {
		err := cb.Call(task)
		if err != nil {
			fmt.Println("Error:", err)
		} else {
			fmt.Println("Task succeeded")
		}
		time.Sleep(500 * time.Millisecond)
	}
}
