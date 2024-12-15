def greet(**kwargs):
    return f"Hello, {kwargs.get('name', 'Guest')}!"

print(greet(name="Alice"))  # Output: Hello, Alice!