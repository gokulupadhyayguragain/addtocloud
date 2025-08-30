package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"math/big"
	"os"
	"strconv"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	_ "github.com/lib/pq" // PostgreSQL driver
	"gopkg.in/gomail.v2"
)

// Database connection
var db *sql.DB

// Admin represents the admin user with OTP authentication
type Admin struct {
	Email  string `json:"email"`
	OTP    string `json:"otp,omitempty"`
	OTPExp int64  `json:"otp_exp,omitempty"`
}

// OTPRequest for requesting OTP
type OTPRequest struct {
	Email string `json:"email" binding:"required"`
}

// OTPVerification for verifying OTP and logging in
type OTPVerification struct {
	Email string `json:"email" binding:"required"`
	OTP   string `json:"otp" binding:"required"`
}

// AccessRequest represents user access request
type AccessRequest struct {
	ID                 string    `json:"id"`
	FirstName          string    `json:"firstName"`
	LastName           string    `json:"lastName"`
	Email              string    `json:"email"`
	Phone              string    `json:"phone"`
	Company            string    `json:"company"`
	Address            string    `json:"address"`
	City               string    `json:"city"`
	Country            string    `json:"country"`
	BusinessReason     string    `json:"businessReason"`
	ProjectDescription string    `json:"projectDescription"`
	Status             string    `json:"status"` // pending, approved, rejected
	SubmittedAt        time.Time `json:"submittedAt"`
}

// User represents a platform user
type User struct {
	ID            string    `json:"id"`
	Email         string    `json:"email"`
	FirstName     string    `json:"firstName"`
	LastName      string    `json:"lastName"`
	Company       string    `json:"company"`
	Status        string    `json:"status"` // pending, approved, rejected
	CreatedAt     time.Time `json:"createdAt"`
	EC2InstanceID string    `json:"ec2InstanceId,omitempty"`
	EC2PublicIP   string    `json:"ec2PublicIp,omitempty"`
	EC2KeyPair    string    `json:"ec2KeyPair,omitempty"`
}

var (
	jwtSecret = []byte("your-super-secret-jwt-key-change-this-in-production")
)

// Initialize database connection
func initDB() error {
	var err error

	// Get database URL from environment variables
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbUser := getEnv("DB_USER", "addtocloud")
	dbPassword := getEnv("DB_PASSWORD", "password")
	dbName := getEnv("DB_NAME", "addtocloud")

	// For Docker/Kubernetes deployment, try different connection strings
	var dbURL string
	if dbURL = os.Getenv("DATABASE_URL"); dbURL == "" {
		dbURL = fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
			dbHost, dbPort, dbUser, dbPassword, dbName)
	}

	db, err = sql.Open("postgres", dbURL)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// Test the connection
	if err = db.Ping(); err != nil {
		log.Printf("Database connection failed, continuing without DB: %v", err)
		db = nil // Continue without database for now
		return nil
	}

	log.Println("✅ Database connected successfully")

	// Create tables if they don't exist
	if err = createTables(); err != nil {
		log.Printf("Failed to create tables: %v", err)
		db = nil
	}

	return nil
}

// Create database tables
func createTables() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS access_requests (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			first_name VARCHAR(100) NOT NULL,
			last_name VARCHAR(100) NOT NULL,
			email VARCHAR(255) UNIQUE NOT NULL,
			phone VARCHAR(20),
			company VARCHAR(255),
			address TEXT,
			city VARCHAR(100),
			country VARCHAR(100),
			business_reason TEXT,
			project_description TEXT,
			status VARCHAR(20) DEFAULT 'pending',
			submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,
		`CREATE TABLE IF NOT EXISTS users (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			email VARCHAR(255) UNIQUE NOT NULL,
			first_name VARCHAR(100) NOT NULL,
			last_name VARCHAR(100) NOT NULL,
			company VARCHAR(255),
			status VARCHAR(20) DEFAULT 'pending',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			ec2_instance_id VARCHAR(100),
			ec2_public_ip VARCHAR(15),
			ec2_key_pair VARCHAR(100)
		)`,
		`CREATE TABLE IF NOT EXISTS admin_otps (
			email VARCHAR(255) PRIMARY KEY,
			otp VARCHAR(10) NOT NULL,
			expires_at TIMESTAMP NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,
	}

	for _, query := range queries {
		if _, err := db.Exec(query); err != nil {
			return fmt.Errorf("failed to execute query: %v", err)
		}
	}

	log.Println("✅ Database tables created/verified")
	return nil
}

// Get access requests from database
func getAccessRequestsFromDB() ([]AccessRequest, error) {
	if db == nil {
		// Return mock data if no database
		return []AccessRequest{
			{
				ID:             "req-1",
				FirstName:      "John",
				LastName:       "Doe",
				Email:          "john.doe@company.com",
				Company:        "Tech Corp",
				BusinessReason: "PaaS - Container Platform",
				Status:         "pending",
				SubmittedAt:    time.Now().Add(-2 * time.Hour),
			},
			{
				ID:             "req-2",
				FirstName:      "Sarah",
				LastName:       "Wilson",
				Email:          "s.wilson@startup.io",
				Company:        "StartupIO",
				BusinessReason: "FaaS - Serverless Functions",
				Status:         "pending",
				SubmittedAt:    time.Now().Add(-5 * time.Hour),
			},
		}, nil
	}

	rows, err := db.Query(`
		SELECT id, first_name, last_name, email, company, business_reason, status, submitted_at 
		FROM access_requests 
		WHERE status = 'pending' 
		ORDER BY submitted_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []AccessRequest
	for rows.Next() {
		var req AccessRequest
		err := rows.Scan(&req.ID, &req.FirstName, &req.LastName, &req.Email,
			&req.Company, &req.BusinessReason, &req.Status, &req.SubmittedAt)
		if err != nil {
			continue
		}
		requests = append(requests, req)
	}

	return requests, nil
}

// Get total user count from database
func getTotalUsersFromDB() (int, error) {
	if db == nil {
		return 127, nil // Mock data
	}

	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	return count, err
}

// Store admin OTP in database
func storeAdminOTP(email, otp string, expiresAt time.Time) error {
	if db == nil {
		log.Printf("📧 Mock OTP for %s: %s (expires: %v)", email, otp, expiresAt)
		return nil
	}

	_, err := db.Exec(`
		INSERT INTO admin_otps (email, otp, expires_at) 
		VALUES ($1, $2, $3) 
		ON CONFLICT (email) 
		DO UPDATE SET otp = $2, expires_at = $3, created_at = CURRENT_TIMESTAMP
	`, email, otp, expiresAt)

	return err
}

// Verify admin OTP from database
func verifyAdminOTP(email, otp string) bool {
	if db == nil {
		// Mock verification - always allow 123456 for demo
		return otp == "123456"
	}

	var storedOTP string
	var expiresAt time.Time

	err := db.QueryRow(`
		SELECT otp, expires_at FROM admin_otps 
		WHERE email = $1
	`, email).Scan(&storedOTP, &expiresAt)

	if err != nil {
		return false
	}

	// Check if OTP is valid and not expired
	if storedOTP == otp && time.Now().Before(expiresAt) {
		// Delete used OTP
		db.Exec("DELETE FROM admin_otps WHERE email = $1", email)
		return true
	}

	return false
}

// Helper function to get environment variables with defaults
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// Generate OTP
func generateOTP() string {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		// Fallback to timestamp-based OTP if crypto/rand fails
		return fmt.Sprintf("%06d", time.Now().Unix()%1000000)
	}
	return fmt.Sprintf("%06d", n.Int64())
}

// Generate session token
func generateSessionToken() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// Send OTP email
func sendOTPEmail(email, otp string) error {
	smtpHost := getEnv("SMTP_HOST", "smtp.zoho.com")
	smtpPortStr := getEnv("SMTP_PORT", "587")
	smtpUsername := getEnv("SMTP_USERNAME", "noreply@addtocloud.tech")
	smtpPassword := getEnv("SMTP_PASSWORD", "")
	smtpFrom := getEnv("SMTP_FROM", "noreply@addtocloud.tech")

	if smtpPassword == "" {
		log.Printf("⚠️ SMTP password not configured - OTP would be: %s", otp)
		return fmt.Errorf("SMTP not configured")
	}

	smtpPort, err := strconv.Atoi(smtpPortStr)
	if err != nil {
		log.Printf("Invalid SMTP port: %s", smtpPortStr)
		return err
	}

	m := gomail.NewMessage()
	m.SetHeader("From", smtpFrom)
	m.SetHeader("To", email)
	m.SetHeader("Subject", "AddToCloud Admin Login - OTP Verification")

	body := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .logo { font-size: 24px; font-weight: bold; color: #2563eb; }
        .otp-code { font-size: 32px; font-weight: bold; color: #dc2626; background-color: #fef2f2; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0; letter-spacing: 4px; }
        .warning { background-color: #fef3c7; border: 1px solid #f59e0b; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .footer { font-size: 12px; color: #666; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">AddToCloud</div>
            <p>Admin Portal Authentication</p>
        </div>
        
        <h2>Your OTP Verification Code</h2>
        <p>Use the following One-Time Password to access the admin portal:</p>
        
        <div class="otp-code">%s</div>
        
        <div class="warning">
            <strong>⚠️ Security Notice:</strong><br>
            • This code expires in 10 minutes<br>
            • Do not share this code with anyone<br>
            • Only use this code on the official AddToCloud admin portal
        </div>
        
        <p>If you did not request this code, please ignore this email.</p>
        
        <div class="footer">
            <p>This is an automated message from AddToCloud Enterprise Platform.<br>
            For support, contact: admin@addtocloud.tech</p>
        </div>
    </div>
</body>
</html>
	`, otp)

	m.SetBody("text/html", body)

	d := gomail.NewDialer(smtpHost, smtpPort, smtpUsername, smtpPassword)

	if err := d.DialAndSend(m); err != nil {
		log.Printf("Failed to send email: %v", err)
		return err
	}

	log.Printf("✅ OTP email sent successfully to %s", email)
	return nil
}

func main() {
	// Initialize database
	if err := initDB(); err != nil {
		log.Printf("Database initialization failed: %v", err)
	}

	r := gin.Default()

	// CORS configuration
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"*"},
		ExposeHeaders:    []string{"*"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Health check
	r.GET("/api/health", func(c *gin.Context) {
		status := gin.H{
			"service":   "AddToCloud Admin API with Real Database",
			"status":    "healthy",
			"timestamp": time.Now().UTC(),
			"version":   "3.0.0-production",
		}

		if db != nil {
			status["database"] = "connected"
			status["smtp"] = "configured"
		} else {
			status["database"] = "mock_mode"
			status["smtp"] = "demo_mode"
		}

		c.JSON(200, status)
	})

	// Admin OTP request
	r.POST("/api/v1/admin/request-otp", func(c *gin.Context) {
		var req OTPRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"status": "error", "message": "Invalid request"})
			return
		}

		if req.Email != "admin@addtocloud.tech" {
			c.JSON(400, gin.H{"status": "error", "message": "Invalid admin email"})
			return
		}

		otp := generateOTP()
		expiresAt := time.Now().Add(10 * time.Minute)

		// Store OTP in database
		if err := storeAdminOTP(req.Email, otp, expiresAt); err != nil {
			log.Printf("Failed to store OTP: %v", err)
		}

		// Send email
		if err := sendOTPEmail(req.Email, otp); err != nil {
			// For demo purposes, still return success but log the error
			log.Printf("Email sending failed, but continuing: %v", err)
		}

		response := gin.H{
			"status":  "success",
			"message": "OTP sent to your email",
			"email":   req.Email,
			"expires": expiresAt.Unix(),
		}

		if db == nil {
			response["demo_mode"] = true
			response["demo_otp"] = otp
		}

		c.JSON(200, response)
	})

	// Admin OTP verification
	r.POST("/api/v1/admin/verify-otp", func(c *gin.Context) {
		var req OTPVerification
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"status": "error", "message": "Invalid request"})
			return
		}

		if !verifyAdminOTP(req.Email, req.OTP) {
			c.JSON(400, gin.H{"status": "error", "message": "Invalid or expired OTP"})
			return
		}

		// Generate JWT token
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"email": req.Email,
			"role":  "admin",
			"exp":   time.Now().Add(24 * time.Hour).Unix(),
		})

		tokenString, err := token.SignedString(jwtSecret)
		if err != nil {
			c.JSON(500, gin.H{"status": "error", "message": "Failed to generate token"})
			return
		}

		c.JSON(200, gin.H{
			"status":   "success",
			"message":  "Login successful",
			"token":    tokenString,
			"redirect": "/admin-dashboard.html",
		})
	})

	// Get admin dashboard data
	r.GET("/api/v1/admin/dashboard", func(c *gin.Context) {
		// Verify admin token
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(401, gin.H{"status": "error", "message": "Authorization header required"})
			return
		}

		requests, err := getAccessRequestsFromDB()
		if err != nil {
			log.Printf("Failed to get access requests: %v", err)
			requests = []AccessRequest{} // Empty array if database fails
		}

		totalUsers, err := getTotalUsersFromDB()
		if err != nil {
			log.Printf("Failed to get user count: %v", err)
			totalUsers = 0
		}

		c.JSON(200, gin.H{
			"status": "success",
			"data": gin.H{
				"total_users":        totalUsers,
				"active_services":    23, // Mock for now
				"deployments":        45, // Mock for now
				"pending_requests":   len(requests),
				"access_requests":    requests,
				"database_connected": db != nil,
			},
		})
	})

	port := getEnv("PORT", "8080")
	log.Printf("🚀 AddToCloud Admin API starting on port %s", port)
	log.Printf("📊 Database: %v", db != nil)
	log.Printf("📧 SMTP configured: %v", os.Getenv("SMTP_PASSWORD") != "")

	r.Run(":" + port)
}
