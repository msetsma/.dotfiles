'''
--- Mediator Pattern ---
Use Case: Simplify communication between objects by centralizing it in a mediator.
Example: Chat applications, event buses, or service orchestration.
'''

class Mediator:
    def notify(self, sender, event):
        pass

class ConcreteMediator(Mediator):
    def __init__(self, component1, component2):
        self.component1 = component1
        self.component2 = component2

    def notify(self, sender, event):
        if event == "A":
            print("Mediator reacts to A and triggers component2")
            self.component2.do_c()
        elif event == "B":
            print("Mediator reacts to B and triggers component1")
            self.component1.do_a()

class BaseComponent:
    def __init__(self, mediator: Mediator = None):
        self.mediator = mediator

    def set_mediator(self, mediator: Mediator):
        self.mediator = mediator

class Component1(BaseComponent):
    def do_a(self):
        print("Component1 does A")
        self.mediator.notify(self, "A")

class Component2(BaseComponent):
    def do_c(self):
        print("Component2 does C")
        self.mediator.notify(self, "B")

# Example Usage
component1 = Component1()
component2 = Component2()
mediator = ConcreteMediator(component1, component2)
component1.set_mediator(mediator)
component2.set_mediator(mediator)

component1.do_a()
# Output:
# Component1 does A
# Mediator reacts to A and triggers component2
# Component2 does C
