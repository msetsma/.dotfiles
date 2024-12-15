// --- Chain of Responsibility Pattern ---
// Use Case: Pass a request along a chain of handlers until one processes it.
// Example: Logging pipelines, HTTP middleware, or validation chains.
// Description: The Chain of Responsibility Pattern decouples the sender of a request
// from its receiver, allowing multiple handlers to process the request dynamically.

package main

import "fmt"

type Handler interface {
	SetNext(handler Handler) Handler
	Handle(request string)
}

type BaseHandler struct {
	next Handler
}

func (h *BaseHandler) SetNext(handler Handler) Handler {
	h.next = handler
	return handler
}

func (h *BaseHandler) Handle(request string) {
	if h.next != nil {
		h.next.Handle(request)
	}
}

type ConcreteHandlerA struct {
	BaseHandler
}

func (h *ConcreteHandlerA) Handle(request string) {
	if request == "A" {
		fmt.Println("Handler A processed the request")
	} else {
		h.BaseHandler.Handle(request)
	}
}

type ConcreteHandlerB struct {
	BaseHandler
}

func (h *ConcreteHandlerB) Handle(request string) {
	if request == "B" {
		fmt.Println("Handler B processed the request")
	} else {
		h.BaseHandler.Handle(request)
	}
}

func main() {
	handlerA := &ConcreteHandlerA{}
	handlerB := &ConcreteHandlerB{}
	handlerA.SetNext(handlerB)

	handlerA.Handle("A") // Output: Handler A processed the request
	handlerA.Handle("B") // Output: Handler B processed the request
	handlerA.Handle("C") // No output
}
