// --- Decorator Pattern ---
// Use Case: Dynamically add behavior to objects without modifying their code.
// Example: Middleware in web frameworks, logging, or caching.
// Description: The Decorator Pattern attaches additional responsibilities to an object dynamically,
// allowing behavior to be added or modified at runtime.

package main

import "fmt"

type Component interface {
	Operation() string
}

type ConcreteComponent struct{}

func (c *ConcreteComponent) Operation() string {
	return "ConcreteComponent"
}

type Decorator struct {
	component Component
}

func (d *Decorator) Operation() string {
	return fmt.Sprintf("%s + Decorator", d.component.Operation())
}

func main() {
	component := &ConcreteComponent{}
	decorator := &Decorator{component: component}

	fmt.Println(decorator.Operation()) // Output: ConcreteComponent + Decorator
}
