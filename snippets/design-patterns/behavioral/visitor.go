// --- Visitor Pattern ---
// Use Case: Separate algorithms from objects they operate on.
// Example: Traversing complex data structures like trees or applying operations on collections.
// Description: The Visitor Pattern lets you add new operations to objects without modifying their structures.

package main

import "fmt"

type Visitor interface {
	VisitElementA(element *ElementA)
	VisitElementB(element *ElementB)
}

type Element interface {
	Accept(visitor Visitor)
}

type ElementA struct {
	Name string
}

func (e *ElementA) Accept(visitor Visitor) {
	visitor.VisitElementA(e)
}

type ElementB struct {
	Value int
}

func (e *ElementB) Accept(visitor Visitor) {
	visitor.VisitElementB(e)
}

type ConcreteVisitor struct{}

func (v *ConcreteVisitor) VisitElementA(element *ElementA) {
	fmt.Println("Visiting ElementA:", element.Name)
}

func (v *ConcreteVisitor) VisitElementB(element *ElementB) {
	fmt.Println("Visiting ElementB with value:", element.Value)
}

func main() {
	elements := []Element{
		&ElementA{Name: "Element A1"},
		&ElementB{Value: 42},
	}

	visitor := &ConcreteVisitor{}
	for _, element := range elements {
		element.Accept(visitor)
	}
	// Output:
	// Visiting ElementA: Element A1
	// Visiting ElementB with value: 42
}
