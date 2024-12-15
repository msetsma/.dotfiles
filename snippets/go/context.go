package main

import (
	"context"
	"fmt"
	"time"
)

func longRunningTask(ctx context.Context) {
	select {
	case <-time.After(5 * time.Second):
		fmt.Println("Task completed")
	case <-ctx.Done():
		fmt.Println("Task cancelled:", ctx.Err())
	}
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	go longRunningTask(ctx)

	time.Sleep(3 * time.Second)
	fmt.Println("Main function done")
}
