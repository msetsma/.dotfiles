// --- Command Pattern ---
// Use Case: Encapsulate requests or operations as objects to allow undoable actions or queuing.
// Example: Task queues, undo/redo functionality, or macro recording.
// Description: The Command Pattern encapsulates a request as an object, allowing for
// parameterization of clients, logging of requests, and support for undoable operations.

package main

import "fmt"

type Command interface {
	Execute()
}

type Light struct{}

func (l *Light) On() {
	fmt.Println("Light is ON")
}

func (l *Light) Off() {
	fmt.Println("Light is OFF")
}

type LightOnCommand struct {
	light *Light
}

func (c *LightOnCommand) Execute() {
	c.light.On()
}

type LightOffCommand struct {
	light *Light
}

func (c *LightOffCommand) Execute() {
	c.light.Off()
}

type RemoteControl struct {
	command Command
}

func (r *RemoteControl) SetCommand(command Command) {
	r.command = command
}

func (r *RemoteControl) PressButton() {
	r.command.Execute()
}

func main() {
	light := &Light{}
	onCommand := &LightOnCommand{light: light}
	offCommand := &LightOffCommand{light: light}

	remote := &RemoteControl{}
	remote.SetCommand(onCommand)
	remote.PressButton() // Output: Light is ON

	remote.SetCommand(offCommand)
	remote.PressButton() // Output: Light is OFF
}
