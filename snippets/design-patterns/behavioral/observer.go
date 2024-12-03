// --- Observer Pattern ---
// Use Case: Notify multiple listeners when a state changes.
// Example: Event handling or real-time updates.
// Description: The Observer Pattern defines a one-to-many dependency, where
// multiple observers are notified of changes in the subject's state.

package main

import "fmt"

type Observer interface {
	Update(message string)
}

type Subject struct {
	observers []Observer
}

func (s *Subject) Attach(o Observer) {
	s.observers = append(s.observers, o)
}

func (s *Subject) Notify(message string) {
	for _, o := range s.observers {
		o.Update(message)
	}
}

type ConcreteObserver struct {
	id int
}

func (co *ConcreteObserver) Update(message string) {
	fmt.Printf("Observer %d received: %s\n", co.id, message)
}

func main() {
	subject := &Subject{}

	o1 := &ConcreteObserver{id: 1}
	o2 := &ConcreteObserver{id: 2}

	subject.Attach(o1)
	subject.Attach(o2)

	subject.Notify("Event occurred")
	// Output:
	// Observer 1 received: Event occurred
	// Observer 2 received: Event occurred
}
