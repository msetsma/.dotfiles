// --- Singleton Pattern ---
// Use Case: Ensure a single instance of a struct exists across your application.
// Example: Configuration manager, database connection, or logger.
// Description: The Singleton Pattern restricts a struct to having only one instance
// and provides a global point of access to that instance.

package main

import (
	"fmt"
	"sync"
)

type Singleton struct {
	value string
}

var instance *Singleton
var once sync.Once

func GetInstance() *Singleton {
	once.Do(func() {
		instance = &Singleton{value: "I am the singleton instance"}
	})
	return instance
}

func main() {
	s1 := GetInstance()
	s2 := GetInstance()
	fmt.Println(s1 == s2) // Output: true
}
