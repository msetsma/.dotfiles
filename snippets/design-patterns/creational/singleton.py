'''
--- Singleton Pattern ---
Use Case: When you need to ensure a class has only one instance.
Example: configuration manager, logger, or a shared resource.
'''

class Singleton:
    _instance = None
    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super().__new__(cls, *args, **kwargs)
        return cls._instance
    

# Example Usage
singleton1 = Singleton()
singleton2 = Singleton()
assert singleton1 is singleton2  # True
