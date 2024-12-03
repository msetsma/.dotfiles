// --- Factory Pattern ---
// Use Case: Create objects without exposing the creation logic.
// Example: Building structs with different configurations.
// Description: The Factory Pattern provides an interface for creating objects,
// allowing the creation logic to be abstracted and centralized.

package main

import "fmt"

type Shape interface {
	Draw() string
}

type Circle struct{}

func (c Circle) Draw() string { return "Drawing Circle" }

type Square struct{}

func (s Square) Draw() string { return "Drawing Square" }

func ShapeFactory(shapeType string) Shape {
	switch shapeType {
	case "circle":
		return Circle{}
	case "square":
		return Square{}
	default:
		return nil
	}
}

func main() {
	shape := ShapeFactory("circle")
	fmt.Println(shape.Draw()) // Output: Drawing Circle
}
