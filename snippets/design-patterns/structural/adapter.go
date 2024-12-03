// --- Adapter Pattern ---
// Use Case: Allow incompatible interfaces to work together.
// Example: Wrapping a legacy API to conform to a new standard or integrating third-party libraries.
// Description: The Adapter Pattern acts as a bridge between two incompatible interfaces,
// allowing them to work together without modifying their existing code.

package main

import "fmt"

type LegacyPrinter struct{}

func (lp *LegacyPrinter) PrintLegacyMessage() {
	fmt.Println("Printing from LegacyPrinter")
}

type ModernPrinter interface {
	PrintMessage()
}

type Adapter struct {
	legacyPrinter *LegacyPrinter
}

func (a *Adapter) PrintMessage() {
	a.legacyPrinter.PrintLegacyMessage()
}

func main() {
	legacy := &LegacyPrinter{}
	adapter := &Adapter{legacyPrinter: legacy}

	adapter.PrintMessage() // Output: Printing from LegacyPrinter
}
