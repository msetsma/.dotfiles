'''
--- Strategy Pattern ---
Use Case: When you want to define a family of algorithms and make them interchangeable.
Example: Sorting algorithms, payment methods, or compression strategies.
'''
from typing import Callable

class Strategy:
    def __init__(self, func: Callable):
        self._func = func

    def execute(self, *args, **kwargs):
        return self._func(*args, **kwargs)

# Example strategies
def strategy_add(a, b):
    return a + b

def strategy_multiply(a, b):
    return a * b

# Example Usage
add_strategy = Strategy(strategy_add)
multiply_strategy = Strategy(strategy_multiply)

print(add_strategy.execute(2, 3))  # Output: 5
print(multiply_strategy.execute(2, 3))  # Output: 6
