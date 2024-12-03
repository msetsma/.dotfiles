'''
--- State Pattern ---
Use Case: Change an object's behavior based on its internal state.
Example: Finite state machines, workflows, or game states.
'''

class State:
    def handle(self, context):
        pass

class Context:
    def __init__(self, state: State):
        self.state = state

    def set_state(self, state: State):
        self.state = state

    def request(self):
        self.state.handle(self)

class ConcreteStateA(State):
    def handle(self, context: Context):
        print("State A handling request")
        context.set_state(ConcreteStateB())

class ConcreteStateB(State):
    def handle(self, context: Context):
        print("State B handling request")
        context.set_state(ConcreteStateA())

# Example Usage
context = Context(ConcreteStateA())
context.request()  # Output: State A handling request
context.request()  # Output: State B handling request
