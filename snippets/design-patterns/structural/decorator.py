'''
--- Decorator Pattern ---
Use Case: When you need to add functionality to objects dynamically.
Example: Logging, authentication, or caching.
'''

def decorator(func):
    def wrapper(*args, **kwargs):
        print(f"Function {func.__name__} is being called")
        result = func(*args, **kwargs)
        print(f"Function {func.__name__} returned {result}")
        return result
    return wrapper

@decorator
def add(a, b):
    return a + b

# Example Usage
print(add(5, 3))
# Output:
# Function add is being called
# Function add returned 8
# 8