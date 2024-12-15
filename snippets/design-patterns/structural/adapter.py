'''
--- Adapter Pattern ---
Use Case: When you need to make two incompatible interfaces work together.
Example: Connecting legacy code to a modern system.
'''

class OldSystem:
    def specific_request(self):
        return "Specific behavior"

class NewSystemAdapter:
    def __init__(self, old_system: OldSystem):
        self.old_system = old_system

    def request(self):
        return self.old_system.specific_request()

# Example Usage
old_system = OldSystem()
adapter = NewSystemAdapter(old_system)
print(adapter.request())  # Output: Specific behavior
