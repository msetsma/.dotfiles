package main

import (
	"encoding/json"
	"fmt"
)

type Person struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

func main() {
	// Encoding to JSON
	person := Person{Name: "Alice", Age: 25}
	jsonData, err := json.Marshal(person)
	if err != nil {
		fmt.Println("Error encoding JSON:", err)
		return
	}
	fmt.Println("JSON:", string(jsonData))

	// Decoding from JSON
	jsonString := `{"name": "Bob", "age": 30}`
	var decodedPerson Person
	if err := json.Unmarshal([]byte(jsonString), &decodedPerson); err != nil {
		fmt.Println("Error decoding JSON:", err)
		return
	}
	fmt.Printf("Decoded Person: %+v\n", decodedPerson)
}
