package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	// Check WEBSITES_PORT first (Azure's preference for containers)
	port := os.Getenv("WEBSITES_PORT")

	// If that's empty, check the standard PORT variable
	if port == "" {
		port = os.Getenv("PORT")
	}

	// If both are empty (Local testing), default to 8080
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "<h1>Azure App Service + App Gateway</h1>")
		fmt.Fprintf(w, "<p>Status: <b>Healthy</b></p>")
		fmt.Fprintf(w, "<hr>")

		fmt.Fprintf(w, "<h3>Request Headers:</h3><ul>")

		for name, headers := range r.Header {
			for _, h := range headers {
				fmt.Fprintf(w, "<li><b>%s:</b> %s</li>", name, h)
			}
		}
		fmt.Fprintf(w, "</ul>")
	})

	fmt.Printf("Server starting on port %s...\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Printf("Error starting server: %s\n", err)
	}

}
