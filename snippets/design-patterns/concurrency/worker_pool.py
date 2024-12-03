"""
--- Worker Pool Pattern ---
Use Case: Efficiently handle concurrent tasks with a fixed number of workers.
Example: Processing a large number of tasks (e.g., web scraping, data processing, or file I/O).
Description: The Worker Pool Pattern uses a pool of workers to execute tasks concurrently, 
improving resource utilization and throughput.

Note: Worker Pool is about controlled, continuous concurrency, while Fan-Out, 
	Fan-In maximizes throughput for a fixed set of tasks.
"""

from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import random

def task(n: int) -> str:
    """Simulates a task by sleeping for a random time."""
    sleep_time = random.uniform(0.5, 2.0)
    time.sleep(sleep_time)
    return f"Task {n} completed after {sleep_time:.2f} seconds"

def main():
    tasks = list(range(10))  # A list of 10 tasks
    max_workers = 3  # Number of workers in the pool

    print(f"Starting worker pool with {max_workers} workers.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit tasks to the executor
        futures = {executor.submit(task, n): n for n in tasks}

        for future in as_completed(futures):
            try:
                result = future.result()
                print(result)
            except Exception as e:
                print(f"Task {futures[future]} failed with exception: {e}")

if __name__ == "__main__":
    main()
    
# Output
# Starting worker pool with 3 workers.
# Task 0 completed after 1.37 seconds
# Task 1 completed after 1.54 seconds
# Task 2 completed after 1.63 seconds
# Task 3 completed after 0.88 seconds
# Task 4 completed after 1.94 seconds
# Task 5 completed after 1.46 seconds
# Task 6 completed after 1.84 seconds
# Task 7 completed after 1.07 seconds
# Task 8 completed after 1.27 seconds
# Task 9 completed after 1.59 seconds