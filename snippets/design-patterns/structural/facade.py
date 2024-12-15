'''
--- Facade Pattern ---
Use Case: Provide a simplified interface to a complex system.
Example: Wrapping a subsystem (e.g., a payment processor or third-party API).
'''

class SubsystemA:
    def operation_a(self):
        return "SubsystemA: Ready"

class SubsystemB:
    def operation_b(self):
        return "SubsystemB: Go"

class Facade:
    def __init__(self):
        self.subsystem_a = SubsystemA()
        self.subsystem_b = SubsystemB()

    def simple_operation(self):
        results = []
        results.append(self.subsystem_a.operation_a())
        results.append(self.subsystem_b.operation_b())
        return " | ".join(results)

# Example Usage
facade = Facade()
print(facade.simple_operation())
# Output: SubsystemA: Ready | SubsystemB: Go
