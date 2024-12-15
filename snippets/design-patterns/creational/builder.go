// --- Builder Pattern ---
// Use Case: Construct complex objects step by step.
// Example: Building objects with many optional parameters.
// Description: The Builder Pattern separates the construction of a complex object
// from its representation, allowing the same construction process to create different representations.

package main

import "fmt"

type Car struct {
	Make  string
	Model string
	Color string
}

type CarBuilder struct {
	make  string
	model string
	color string
}

func (cb *CarBuilder) SetMake(make string) *CarBuilder {
	cb.make = make
	return cb
}

func (cb *CarBuilder) SetModel(model string) *CarBuilder {
	cb.model = model
	return cb
}

func (cb *CarBuilder) SetColor(color string) *CarBuilder {
	cb.color = color
	return cb
}

func (cb *CarBuilder) Build() Car {
	return Car{
		Make:  cb.make,
		Model: cb.model,
		Color: cb.color,
	}
}

func main() {
	car := (&CarBuilder{}).SetMake("Tesla").SetModel("Model S").SetColor("Red").Build()
	fmt.Printf("Car: %+v\n", car) // Output: Car: {Make:Tesla Model:Model S Color:Red}
}
