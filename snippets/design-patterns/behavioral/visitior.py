'''
--- Visitor Pattern ---
Use Case: Separate algorithms from objects they operate on.
Example: Traversing complex data structures like trees or applying operations on collections.
'''

class Visitor:
    def visit(self, element):
        pass

class ConcreteVisitor(Visitor):
    def visit(self, element):
        print(f"Visiting {element.name}")

class Element:
    def __init__(self, name):
        self.name = name

    def accept(self, visitor: Visitor):
        visitor.visit(self)

# Example Usage
element = Element("Element1")
visitor = ConcreteVisitor()

element.accept(visitor)  # Output: Visiting Element1