"""
--- Middleware Pattern ---
Use Case: Chain handlers for pre- and post-processing of requests or data.
Example: HTTP request handling, validation, logging, or authentication.
Description: The Middleware Pattern passes a request through a chain of middleware functions,
each of which can process the request and either pass it on or return a response directly.
"""

class Middleware:
    def __init__(self, next_handler=None):
        self.next_handler = next_handler

    def handle(self, request):
        """Process the request and optionally pass it to the next handler."""
        if self.next_handler:
            return self.next_handler.handle(request)
        return request

class LoggingMiddleware(Middleware):
    def handle(self, request):
        print(f"Logging request: {request}")
        return super().handle(request)

class AuthenticationMiddleware(Middleware):
    def handle(self, request):
        if "user" in request:
            print(f"Authenticated user: {request['user']}")
            return super().handle(request)
        print("Authentication failed!")
        return {"error": "Unauthorized"}

class ValidationMiddleware(Middleware):
    def handle(self, request):
        if "data" in request and isinstance(request["data"], dict):
            print("Validation passed")
            return super().handle(request)
        print("Validation failed!")
        return {"error": "Invalid data"}

class FinalHandler(Middleware):
    def handle(self, request):
        print("Final handler processing request")
        return {"status": "success", "data": request}

# Example usage
def main():
    # Chain middleware
    pipeline = LoggingMiddleware(
        AuthenticationMiddleware(
            ValidationMiddleware(
                FinalHandler()
            )
        )
    )

    # Valid request
    request = {"user": "Alice", "data": {"key": "value"}}
    response = pipeline.handle(request)
    print("Response:", response)

    # Invalid request (missing user)
    request = {"data": {"key": "value"}}
    response = pipeline.handle(request)
    print("Response:", response)

if __name__ == "__main__":
    main()

# Output
# Logging request: {'user': 'Alice', 'data': {'key': 'value'}}
# Authenticated user: Alice
# Validation passed
# Final handler processing request
# Response: {'status': 'success', 'data': {'user': 'Alice', 'data': {'key': 'value'}}}

# Logging request: {'data': {'key': 'value'}}
# Authentication failed!
# Response: {'error': 'Unauthorized'}