'''
--- Flyweight Pattern ---
Use Case: Minimize memory usage by sharing objects with similar properties.
Example: Caching icons, fonts, or large sets of similar objects.
'''

class Flyweight:
    def __init__(self, shared_state):
        self.shared_state = shared_state

    def operation(self, unique_state):
        print(f"Shared: {self.shared_state}, Unique: {unique_state}")

class FlyweightFactory:
    _flyweights = {}

    @staticmethod
    def get_flyweight(shared_state):
        if shared_state not in FlyweightFactory._flyweights:
            FlyweightFactory._flyweights[shared_state] = Flyweight(shared_state)
        return FlyweightFactory._flyweights[shared_state]

# Example Usage
factory = FlyweightFactory()
flyweight1 = factory.get_flyweight("shared1")
flyweight2 = factory.get_flyweight("shared1")

flyweight1.operation("uniqueA")
flyweight2.operation("uniqueB")
# Output:
# Shared: shared1, Unique: uniqueA
# Shared: shared1, Unique: uniqueB
