// --- Middleware Pattern ---
// Use Case: Chain handlers for pre/post-processing.
// Example: HTTP request handling.
// Description: The Middleware Pattern processes requests and responses
// through a chain of handlers, each adding functionality before passing to the next.

package main

import (
	"fmt"
	"net/http"
)

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("Request received:", r.URL.Path)
		next.ServeHTTP(w, r)
	})
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello, World!")
}

func main() {
	mux := http.NewServeMux()
	mux.Handle("/", loggingMiddleware(http.HandlerFunc(helloHandler)))

	http.ListenAndServe(":8080", mux)
}
