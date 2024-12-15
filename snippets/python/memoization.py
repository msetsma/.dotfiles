'''
--- Memoization ---
A technique used to cache the results of expensive 
function calls and reuse them when the same inputs 
occur again.
'''

from functools import lru_cache

@lru_cache(maxsize=None)
def fib(n):
    if n < 2:
        return n
    return fib(n-1) + fib(n-2)

print(fib(10))  # Output: 55