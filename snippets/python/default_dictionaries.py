from collections import defaultdict

freq = defaultdict(int)
items = ["apple", "banana", "apple"]
for item in items:
    freq[item] += 1
    
print(freq)  # Output: defaultdict(<class 'int'>, {'apple': 2, 'banana': 1})
