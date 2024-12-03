'''
--- Chain of Responsibility Pattern ---
Use Case: Pass a request along a chain of handlers until one processes it.
Example: Logging pipelines, HTTP middleware, or validation chains.
'''

class Handler:
    def __init__(self, successor=None):
        self.successor = successor

    def handle(self, request):
        if self.successor:
            return self.successor.handle(request)
        return None

class ConcreteHandlerA(Handler):
    def handle(self, request):
        if request == "A":
            return f"Handler A processed {request}"
        return super().handle(request)

class ConcreteHandlerB(Handler):
    def handle(self, request):
        if request == "B":
            return f"Handler B processed {request}"
        return super().handle(request)

# Example Usage
handler_chain = ConcreteHandlerA(ConcreteHandlerB())

print(handler_chain.handle("A"))  # Output: Handler A processed A
print(handler_chain.handle("B"))  # Output: Handler B processed B
print(handler_chain.handle("C"))  # Output: None
