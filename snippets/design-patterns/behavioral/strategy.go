// --- Strategy Pattern ---
// Use Case: Define a family of algorithms and make them interchangeable.
// Example: Payment processing methods, sorting algorithms, or logging strategies.
// Description: The Strategy Pattern defines a family of algorithms, encapsulates each one, and makes them interchangeable.

package main

import "fmt"

type Strategy interface {
	Execute(a, b int) int
}

type AddStrategy struct{}

func (s *AddStrategy) Execute(a, b int) int {
	return a + b
}

type MultiplyStrategy struct{}

func (s *MultiplyStrategy) Execute(a, b int) int {
	return a * b
}

type Context struct {
	strategy Strategy
}

func (c *Context) SetStrategy(strategy Strategy) {
	c.strategy = strategy
}

func (c *Context) ExecuteStrategy(a, b int) int {
	return c.strategy.Execute(a, b)
}

func main() {
	context := &Context{}
	context.SetStrategy(&AddStrategy{})
	fmt.Println("Add:", context.ExecuteStrategy(3, 4)) // Output: Add: 7

	context.SetStrategy(&MultiplyStrategy{})
	fmt.Println("Multiply:", context.ExecuteStrategy(3, 4)) // Output: Multiply: 12
}
