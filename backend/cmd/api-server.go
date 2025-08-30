package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

type HealthResponse struct {
	Status            string `json:"status"`
	Message           string `json:"message"`
	FrontendConnected bool   `json:"frontend_connected"`
	Database          string `json:"database"`
	Timestamp         string `json:"timestamp"`
}

type ContactRequest struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Message string `json:"message"`
}

type ContactResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	RequestID string `json:"request_id"`
	Timestamp string `json:"timestamp"`
}

type AccessRequest struct {
	Service      string `json:"service"`
	Plan         string `json:"plan"`
	Company      string `json:"company"`
	Email        string `json:"email"`
	Requirements string `json:"requirements"`
}

type AccessResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	Status    string `json:"status"`
	RequestID string `json:"request_id"`
	Timestamp string `json:"timestamp"`
}

type DeployRequest struct {
	Service struct {
		Name        string `json:"name"`
		Provider    string `json:"provider"`
		Category    string `json:"category"`
		Description string `json:"description"`
	} `json:"service"`
	Config struct {
		Name         string `json:"name"`
		Region       string `json:"region"`
		InstanceType string `json:"instanceType"`
		Environment  string `json:"environment"`
	} `json:"config"`
}

type DeployResponse struct {
	Success       bool   `json:"success"`
	Message       string `json:"message"`
	DeploymentID  string `json:"deploymentId"`
	Status        string `json:"status"`
	EstimatedTime string `json:"estimatedTime"`
	Timestamp     string `json:"timestamp"`
}

func enableCORS(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With")
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	response := HealthResponse{
		Status:            "healthy",
		Message:           "AddToCloud API Working",
		FrontendConnected: true,
		Database:          "ready",
		Timestamp:         time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func contactHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Method not allowed"})
		return
	}

	var contact ContactRequest
	if err := json.NewDecoder(r.Body).Decode(&contact); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid JSON"})
		return
	}

	response := ContactResponse{
		Success:   true,
		Message:   "Contact request received successfully",
		RequestID: fmt.Sprintf("contact_%d", time.Now().Unix()),
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func accessRequestHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Method not allowed"})
		return
	}

	var access AccessRequest
	if err := json.NewDecoder(r.Body).Decode(&access); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid JSON"})
		return
	}

	response := AccessResponse{
		Success:   true,
		Message:   "Access request submitted successfully",
		Status:    "pending_review",
		RequestID: fmt.Sprintf("access_%d", time.Now().Unix()),
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func deployHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Method not allowed"})
		return
	}

	var deploy DeployRequest
	if err := json.NewDecoder(r.Body).Decode(&deploy); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid JSON"})
		return
	}

	// Simulate deployment processing
	deploymentID := fmt.Sprintf("deploy_%s_%d", deploy.Service.Provider, time.Now().Unix())

	response := DeployResponse{
		Success:       true,
		Message:       fmt.Sprintf("%s %s deployment initiated successfully", deploy.Service.Provider, deploy.Service.Name),
		DeploymentID:  deploymentID,
		Status:        "provisioning",
		EstimatedTime: "3-5 minutes",
		Timestamp:     time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	response := map[string]interface{}{
		"status":    "operational",
		"message":   "AddToCloud API Ready",
		"endpoints": []string{"/api/health", "/api/v1/contact", "/api/v1/access-request"},
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/", rootHandler)
	http.HandleFunc("/api/health", healthHandler)
	http.HandleFunc("/api/v1/contact", contactHandler)
	http.HandleFunc("/api/v1/access-request", accessRequestHandler)
	http.HandleFunc("/api/v1/deploy", deployHandler)

	port := ":8080"
	log.Printf("🚀 AddToCloud API starting on port %s", port)
	log.Printf("🌐 API endpoints ready:")
	log.Printf("   GET  /api/health")
	log.Printf("   POST /api/v1/contact")
	log.Printf("   POST /api/v1/access-request")
	log.Printf("   POST /api/v1/deploy")

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("❌ Failed to start server:", err)
	}
}
