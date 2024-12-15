// --- Pipeline Pattern ---
// Use Case: Chain multiple stages of data processing.
// Example: Streaming data through a sequence of operations.
// Description: The Pipeline Pattern splits data processing into stages,
// where each stage transforms the data and passes it to the next stage.

package main

import "fmt"

func generator(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		for _, n := range nums {
			out <- n
		}
		close(out)
	}()
	return out
}

func square(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		for n := range in {
			out <- n * n
		}
		close(out)
	}()
	return out
}

func main() {
	numbers := generator(1, 2, 3, 4)
	squares := square(numbers)

	for sq := range squares {
		fmt.Println(sq) // Output: 1, 4, 9, 16
	}
}
