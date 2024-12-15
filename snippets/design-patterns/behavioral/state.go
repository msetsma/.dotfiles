// --- State Pattern ---
// Use Case: Change an object’s behavior dynamically based on its state.
// Example: Implementing workflows, game states, or finite state machines.
// Description: The State Pattern allows an object to alter its behavior when its internal state changes.

package main

import "fmt"

type State interface {
	Handle(context *Context)
}

type Context struct {
	state State
}

func (c *Context) SetState(state State) {
	c.state = state
}

func (c *Context) Request() {
	c.state.Handle(c)
}

type ConcreteStateA struct{}

func (s *ConcreteStateA) Handle(context *Context) {
	fmt.Println("State A handling request")
	context.SetState(&ConcreteStateB{})
}

type ConcreteStateB struct{}

func (s *ConcreteStateB) Handle(context *Context) {
	fmt.Println("State B handling request")
	context.SetState(&ConcreteStateA{})
}

func main() {
	context := &Context{state: &ConcreteStateA{}}
	context.Request() // Output: State A handling request
	context.Request() // Output: State B handling request
}
