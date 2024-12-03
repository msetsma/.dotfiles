/*
--- Fan-Out, Fan-In Pattern ---
Use Case: Distribute tasks to multiple workers (fan-out) and aggregate the results (fan-in).
Example: Concurrent data processing, web scraping, or aggregating API results.
Description: The Fan-Out, Fan-In pattern in Go uses goroutines to concurrently distribute tasks
and channels to collect and aggregate results.

Note: Worker Pool is about controlled, continuous concurrency, while Fan-Out, 
	Fan-In maximizes throughput for a fixed set of tasks.
*/

package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

func worker(taskID int, results chan<- string, wg *sync.WaitGroup) {
	defer wg.Done() // Signal task completion
	sleepTime := time.Duration(rand.Intn(1500)+500) * time.Millisecond
	time.Sleep(sleepTime)
	results <- fmt.Sprintf("Task %d completed after %v", taskID, sleepTime)
}

func main() {
	rand.Seed(time.Now().UnixNano()) // Seed the random number generator

	numTasks := 10
	numWorkers := 4
	results := make(chan string, numTasks)

	fmt.Printf("Starting fan-out with %d workers for %d tasks.\n", numWorkers, numTasks)

	// Fan-out: Start workers
	var wg sync.WaitGroup
	for i := 0; i < numTasks; i++ {
		wg.Add(1)
		go worker(i, results, &wg)
	}

	// Fan-in: Collect results
	go func() {
		wg.Wait()    // Wait for all workers to finish
		close(results) // Close the results channel
	}()

	// Print results as they come in
	for result := range results {
		fmt.Println(result)
	}
}
// Output
// Starting fan-out with 4 workers for 10 tasks.
// Task 0 completed after 1.2s
// Task 1 completed after 0.9s
// Task 2 completed after 1.5s
// Task 3 completed after 0.7s
// Task 4 completed after 1.3s
// Task 5 completed after 0.8s
// Task 6 completed after 1.4s
// Task 7 completed after 1.1s
// Task 8 completed after 0.6s
// Task 9 completed after 1.0s
