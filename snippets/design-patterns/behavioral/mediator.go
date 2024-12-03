// --- Mediator Pattern ---
// Use Case: Simplify communication between objects by centralizing it in a mediator.
// Example: Chat applications, event buses, or service orchestration.
// Description: The Mediator Pattern defines an object that encapsulates how a set of objects interact,
// promoting loose coupling by preventing direct interactions between components.

package main

import "fmt"

type Mediator interface {
	Notify(sender string, event string)
}

type ConcreteMediator struct {
	component1 *Component1
	component2 *Component2
}

func (m *ConcreteMediator) Notify(sender string, event string) {
	if event == "A" {
		fmt.Println("Mediator reacts to A and triggers Component2")
		m.component2.DoC()
	} else if event == "B" {
		fmt.Println("Mediator reacts to B and triggers Component1")
		m.component1.DoA()
	}
}

type Component1 struct {
	mediator Mediator
}

func (c *Component1) DoA() {
	fmt.Println("Component1 does A")
	c.mediator.Notify("Component1", "A")
}

type Component2 struct {
	mediator Mediator
}

func (c *Component2) DoC() {
	fmt.Println("Component2 does C")
	c.mediator.Notify("Component2", "B")
}

func main() {
	mediator := &ConcreteMediator{}
	component1 := &Component1{mediator: mediator}
	component2 := &Component2{mediator: mediator}
	mediator.component1 = component1
	mediator.component2 = component2

	component1.DoA()
	// Output:
	// Component1 does A
	// Mediator reacts to A and triggers Component2
	// Component2 does C
}
