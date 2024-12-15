// --- Worker Pool Pattern ---
// Use Case: Efficiently handle concurrent tasks.
// Example: Processing jobs from a queue.
// Description: The Worker Pool Pattern uses a fixed number of workers to process
// tasks concurrently, reducing overhead and improving throughput.
// Note: Worker Pool is about controlled, continuous concurrency, while Fan-Out, 
//	Fan-In maximizes throughput for a fixed set of tasks.

package main

import (
	"fmt"
	"time"
)

func worker(id int, jobs <-chan int, results chan<- int) {
	for job := range jobs {
		fmt.Printf("Worker %d processing job %d\n", id, job)
		time.Sleep(time.Second)
		results <- job * 2
	}
}

func main() {
	jobs := make(chan int, 5)
	results := make(chan int, 5)

	for i := 1; i <= 3; i++ {
		go worker(i, jobs, results)
	}

	for j := 1; j <= 5; j++ {
		jobs <- j
	}
	close(jobs)

	for i := 1; i <= 5; i++ {
		fmt.Printf("Result: %d\n", <-results)
	}
}
