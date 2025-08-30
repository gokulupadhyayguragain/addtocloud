package main

import (
	"crypto/tls"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/smtp"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

type ContactRequest struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Subject string `json:"subject,omitempty"`
	Message string `json:"message"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type User struct {
	ID       int       `json:"id"`
	Email    string    `json:"email"`
	Name     string    `json:"name"`
	Password string    `json:"-"`
	Role     string    `json:"role"`
	Created  time.Time `json:"created"`
}

var db *sql.DB

func initDB() {
	var err error
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbName := os.Getenv("DB_NAME")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")

	if dbHost == "" {
		log.Println("Database not configured, using in-memory storage")
		return
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Printf("Failed to connect to database: %v", err)
		return
	}

	if err = db.Ping(); err != nil {
		log.Printf("Failed to ping database: %v", err)
		db = nil
		return
	}

	createTables()
	createDefaultAdmin()
	log.Println("Database connected successfully")
}

func createTables() {
	if db == nil {
		return
	}

	// Create users table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			email VARCHAR(255) UNIQUE NOT NULL,
			name VARCHAR(255) NOT NULL,
			password VARCHAR(255) NOT NULL,
			role VARCHAR(50) DEFAULT 'user',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Printf("Failed to create users table: %v", err)
	}

	// Create contact_requests table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS contact_requests (
			id SERIAL PRIMARY KEY,
			name VARCHAR(255) NOT NULL,
			email VARCHAR(255) NOT NULL,
			subject VARCHAR(500),
			message TEXT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			status VARCHAR(50) DEFAULT 'new'
		)
	`)
	if err != nil {
		log.Printf("Failed to create contact_requests table: %v", err)
	}
}

func createDefaultAdmin() {
	if db == nil {
		return
	}

	// Check if admin user exists
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users WHERE email = $1", "admin@addtocloud.tech").Scan(&count)
	if err != nil || count > 0 {
		return
	}

	// Create default admin user
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	_, err = db.Exec("INSERT INTO users (email, name, password, role) VALUES ($1, $2, $3, $4)",
		"admin@addtocloud.tech", "Admin User", string(hashedPassword), "admin")
	if err != nil {
		log.Printf("Failed to create default admin: %v", err)
	} else {
		log.Println("Default admin user created: admin@addtocloud.tech / admin123")
	}
}

func sendEmail(to, subject, body string) error {
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USERNAME")
	smtpPass := os.Getenv("SMTP_PASSWORD")
	smtpFrom := os.Getenv("SMTP_FROM")

	if smtpHost == "" || smtpUser == "" || smtpPass == "" {
		log.Println("Email not configured, skipping send")
		return fmt.Errorf("email not configured")
	}

	// Create message
	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s", smtpFrom, to, subject, body)

	// SMTP configuration for Zoho
	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)

	// TLS config
	tlsConfig := &tls.Config{
		InsecureSkipVerify: false,
		ServerName:         smtpHost,
	}

	// Connect to server
	conn, err := tls.Dial("tcp", smtpHost+":"+smtpPort, tlsConfig)
	if err != nil {
		return fmt.Errorf("failed to connect to SMTP server: %v", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, smtpHost)
	if err != nil {
		return fmt.Errorf("failed to create SMTP client: %v", err)
	}
	defer client.Close()

	// Authenticate
	if err = client.Auth(auth); err != nil {
		return fmt.Errorf("SMTP authentication failed: %v", err)
	}

	// Send email
	if err = client.Mail(smtpFrom); err != nil {
		return fmt.Errorf("failed to set sender: %v", err)
	}

	if err = client.Rcpt(to); err != nil {
		return fmt.Errorf("failed to set recipient: %v", err)
	}

	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("failed to get data writer: %v", err)
	}

	_, err = w.Write([]byte(msg))
	if err != nil {
		return fmt.Errorf("failed to write message: %v", err)
	}

	err = w.Close()
	if err != nil {
		return fmt.Errorf("failed to close writer: %v", err)
	}

	log.Printf("Email sent successfully to %s", to)
	return nil
}

func corsHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	corsHeaders(w)
	w.Header().Set("Content-Type", "application/json")

	cluster := os.Getenv("CLUSTER_NAME")
	if cluster == "" {
		cluster = "AWS-EKS"
	}

	dbStatus := "disconnected"
	if db != nil {
		if err := db.Ping(); err == nil {
			dbStatus = "connected"
		}
	}

	response := map[string]interface{}{
		"status":    "healthy",
		"message":   "AddToCloud Real API is running",
		"cluster":   cluster,
		"database":  dbStatus,
		"timestamp": time.Now().Format(time.RFC3339),
		"version":   "2.0.0",
	}
	json.NewEncoder(w).Encode(response)
}

func contactHandler(w http.ResponseWriter, r *http.Request) {
	corsHeaders(w)
	w.Header().Set("Content-Type", "application/json")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Method not allowed"})
		return
	}

	var req ContactRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request"})
		return
	}

	if req.Name == "" || req.Email == "" || req.Message == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Missing required fields"})
		return
	}

	// Store in database if available
	if db != nil {
		_, err := db.Exec("INSERT INTO contact_requests (name, email, subject, message) VALUES ($1, $2, $3, $4)",
			req.Name, req.Email, req.Subject, req.Message)
		if err != nil {
			log.Printf("Failed to store contact request: %v", err)
		}
	}

	// Send email notification
	adminEmail := os.Getenv("ADMIN_EMAIL")
	if adminEmail == "" {
		adminEmail = "admin@addtocloud.tech"
	}

	emailSubject := "New Contact Request - AddToCloud"
	emailBody := fmt.Sprintf(`New contact request received:

Name: %s
Email: %s
Subject: %s
Message: %s

Timestamp: %s`,
		req.Name, req.Email, req.Subject, req.Message, time.Now().Format(time.RFC3339))

	go sendEmail(adminEmail, emailSubject, emailBody)

	log.Printf("Contact request received: Name=%s, Email=%s, Subject=%s", req.Name, req.Email, req.Subject)

	response := map[string]interface{}{
		"status":    "received",
		"message":   "Your message has been received successfully and an email notification has been sent",
		"timestamp": time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	corsHeaders(w)
	w.Header().Set("Content-Type", "application/json")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(map[string]string{"error": "Method not allowed"})
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request"})
		return
	}

	if req.Email == "" || req.Password == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Email and password are required"})
		return
	}

	log.Printf("Login attempt for email: %s", req.Email)

	var user User
	var hashedPassword string

	if db != nil {
		// Database authentication
		err := db.QueryRow("SELECT id, email, name, password, role, created_at FROM users WHERE email = $1", req.Email).
			Scan(&user.ID, &user.Email, &user.Name, &hashedPassword, &user.Role, &user.Created)

		if err != nil {
			log.Printf("User not found in database: %s", req.Email)
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "Invalid credentials"})
			return
		}

		// Verify password
		if err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(req.Password)); err != nil {
			log.Printf("Invalid password for user: %s", req.Email)
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "Invalid credentials"})
			return
		}
	} else {
		// Fallback authentication
		if req.Email == "admin@addtocloud.tech" && req.Password == "admin123" {
			user = User{
				ID:      1,
				Email:   req.Email,
				Name:    "Admin User",
				Role:    "admin",
				Created: time.Now(),
			}
		} else {
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "Invalid credentials"})
			return
		}
	}

	// Generate JWT token
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "default-secret-change-this"
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"email":   user.Email,
		"role":    user.Role,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})

	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Failed to generate token"})
		return
	}

	response := map[string]interface{}{
		"status":  "success",
		"message": "Login successful",
		"token":   tokenString,
		"user": map[string]interface{}{
			"id":    user.ID,
			"email": user.Email,
			"name":  user.Name,
			"role":  user.Role,
		},
		"timestamp": time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

func main() {
	// Initialize database
	initDB()

	// Setup routes
	http.HandleFunc("/api/health", healthHandler)
	http.HandleFunc("/api/v1/contact", contactHandler)
	http.HandleFunc("/api/v1/auth/login", loginHandler)
	http.HandleFunc("/contact", contactHandler)
	http.HandleFunc("/auth/login", loginHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting AddToCloud Real API on port %s", port)
	log.Printf("Cluster: %s", os.Getenv("CLUSTER_NAME"))
	log.Printf("Health endpoint: /api/health")
	log.Printf("Contact endpoint: /contact and /api/v1/contact")
	log.Printf("Login endpoint: /auth/login and /api/v1/auth/login")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
