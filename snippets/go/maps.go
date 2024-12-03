package main

import "fmt"

func main() {
	// Creating a map
	ages := map[string]int{"Alice": 25, "Bob": 30}

	// Adding an entry
	ages["Charlie"] = 35

	// Accessing and checking existence
	if age, exists := ages["Alice"]; exists {
		fmt.Println("Alice's age:", age)
	} else {
		fmt.Println("Alice not found")
	}

	// Iterating over a map
	for name, age := range ages {
		fmt.Printf("%s is %d years old\n", name, age)
	}

	// Deleting an entry
	delete(ages, "Bob")
	fmt.Println("After deletion:", ages)
}
