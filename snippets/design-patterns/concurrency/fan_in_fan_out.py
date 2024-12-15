"""
--- Fan-Out, Fan-In Pattern ---
Use Case: Distribute tasks to multiple workers (fan-out) and aggregate the results (fan-in).
Example: Concurrent data processing, web scraping, or aggregating API results.
Description: The Fan-Out, Fan-In pattern uses multiple workers to process tasks concurrently.
Tasks are distributed among workers (fan-out), and their results are collected and aggregated (fan-in).

Note: Worker Pool is about controlled, continuous concurrency, while Fan-Out, 
	Fan-In maximizes throughput for a fixed set of tasks.
"""

import concurrent.futures
import time
import random

def worker(task_id: int) -> str:
    """Simulates a worker processing a task."""
    sleep_time = random.uniform(0.5, 2.0)
    time.sleep(sleep_time)
    return f"Task {task_id} completed after {sleep_time:.2f} seconds"

def main():
    num_tasks = 10
    max_workers = 4  # Number of workers

    print(f"Starting fan-out with {max_workers} workers for {num_tasks} tasks.")

    # Fan-out: Distribute tasks to workers
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(worker, i): i for i in range(num_tasks)}

        # Fan-in: Collect and aggregate results
        for future in concurrent.futures.as_completed(futures):
            task_id = futures[future]
            try:
                result = future.result()
                print(f"Result from Task {task_id}: {result}")
            except Exception as e:
                print(f"Task {task_id} failed with exception: {e}")

if __name__ == "__main__":
    main()

# output
# Starting fan-out with 4 workers for 10 tasks.
# Result from Task 0: Task 0 completed after 1.37 seconds
# Result from Task 3: Task 3 completed after 1.54 seconds
# Result from Task 1: Task 1 completed after 1.63 seconds
# Result from Task 2: Task 2 completed after 0.88 seconds
# Result from Task 5: Task 5 completed after 1.46 seconds
# Result from Task 6: Task 6 completed after 1.84 seconds
# Result from Task 7: Task 7 completed after 1.07 seconds
# Result from Task 4: Task 4 completed after 1.94 seconds
# Result from Task 8: Task 8 completed after 1.27 seconds
# Result from Task 9: Task 9 completed after 1.59 seconds
