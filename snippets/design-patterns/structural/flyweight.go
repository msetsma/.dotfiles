// --- Flyweight Pattern ---
// Use Case: Minimize memory usage by sharing objects with similar properties.
// Example: Caching repetitive data like fonts, icons, or database records.
// Description: The Flyweight Pattern uses shared objects to support large numbers of fine-grained objects efficiently.

package main

import "fmt"

type Flyweight struct {
	sharedState string
}

func (f *Flyweight) Operation(uniqueState string) {
	fmt.Printf("Shared: %s, Unique: %s\n", f.sharedState, uniqueState)
}

type FlyweightFactory struct {
	flyweights map[string]*Flyweight
}

func NewFlyweightFactory() *FlyweightFactory {
	return &FlyweightFactory{flyweights: make(map[string]*Flyweight)}
}

func (f *FlyweightFactory) GetFlyweight(sharedState string) *Flyweight {
	if _, exists := f.flyweights[sharedState]; !exists {
		f.flyweights[sharedState] = &Flyweight{sharedState: sharedState}
	}
	return f.flyweights[sharedState]
}

func main() {
	factory := NewFlyweightFactory()
	flyweight1 := factory.GetFlyweight("shared1")
	flyweight2 := factory.GetFlyweight("shared1")

	flyweight1.Operation("uniqueA") // Output: Shared: shared1, Unique: uniqueA
	flyweight2.Operation("uniqueB") // Output: Shared: shared1, Unique: uniqueB
}
