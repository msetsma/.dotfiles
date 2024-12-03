// --- Dependency Injection Pattern ---
// Use Case: Decouple components by passing dependencies at runtime.
// Example: Pass services (e.g., logger, database) to structs.
// Description: Dependency Injection allows an object to receive its dependencies
// from an external source, improving testability and flexibility.

package main

import "fmt"

type Logger interface {
	Log(message string)
}

type ConsoleLogger struct{}

func (cl ConsoleLogger) Log(message string) {
	fmt.Println("Console log:", message)
}

type Service struct {
	logger Logger
}

func NewService(logger Logger) *Service {
	return &Service{logger: logger}
}

func (s *Service) Process() {
	s.logger.Log("Processing data")
}

func main() {
	logger := ConsoleLogger{}
	service := NewService(logger)
	service.Process() // Output: Console log: Processing data
}
