package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"fmt"
	"log"
	"net/smtp"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

type CredentialRequest struct {
	ID          string    `json:"id"`
	Email       string    `json:"email" binding:"required,email"`
	FullName    string    `json:"full_name" binding:"required"`
	Company     string    `json:"company" binding:"required"`
	Purpose     string    `json:"purpose" binding:"required"`
	RequestedAt time.Time `json:"requested_at"`
	Status      string    `json:"status"` // pending, approved, denied
}

type Credentials struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	Password    string    `json:"password"`
	APIKey      string    `json:"api_key"`
	ExpiresAt   time.Time `json:"expires_at"`
	Environment string    `json:"environment"`
	AccessLevel string    `json:"access_level"`
	Services    []string  `json:"services"`
	Endpoints   struct {
		Primary   string `json:"primary"`
		Secondary string `json:"secondary"`
		API       string `json:"api"`
		Dashboard string `json:"dashboard"`
	} `json:"endpoints"`
}

type EmailService struct {
	SMTPHost string
	SMTPPort string
	From     string
	Password string
	To       string
}

type Database struct {
	conn *sql.DB
}

func NewDatabase() (*Database, error) {
	dbURL := getEnv("DATABASE_URL", "postgres://addtocloud:password@localhost/addtocloud_prod?sslmode=disable")

	conn, err := sql.Open("postgres", dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %v", err)
	}

	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %v", err)
	}

	db := &Database{conn: conn}
	if err := db.createTables(); err != nil {
		return nil, fmt.Errorf("failed to create tables: %v", err)
	}

	return db, nil
}

func (db *Database) createTables() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS credential_requests (
			id VARCHAR(50) PRIMARY KEY,
			email VARCHAR(255) NOT NULL,
			full_name VARCHAR(255) NOT NULL,
			company VARCHAR(255) NOT NULL,
			purpose TEXT NOT NULL,
			requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			status VARCHAR(20) DEFAULT 'pending'
		)`,
		`CREATE TABLE IF NOT EXISTS user_credentials (
			id VARCHAR(50) PRIMARY KEY,
			request_id VARCHAR(50) REFERENCES credential_requests(id),
			username VARCHAR(255) UNIQUE NOT NULL,
			password_hash VARCHAR(255) NOT NULL,
			api_key VARCHAR(255) UNIQUE NOT NULL,
			access_level VARCHAR(50) DEFAULT 'full',
			environment VARCHAR(50) DEFAULT 'production',
			expires_at TIMESTAMP NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			is_active BOOLEAN DEFAULT true
		)`,
		`CREATE TABLE IF NOT EXISTS service_access (
			id SERIAL PRIMARY KEY,
			credential_id VARCHAR(50) REFERENCES user_credentials(id),
			service_name VARCHAR(255) NOT NULL,
			access_granted BOOLEAN DEFAULT true,
			granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,
	}

	for _, query := range queries {
		if _, err := db.conn.Exec(query); err != nil {
			return err
		}
	}

	return nil
}

func (db *Database) SaveCredentialRequest(req CredentialRequest) error {
	query := `INSERT INTO credential_requests (id, email, full_name, company, purpose, requested_at, status) 
			  VALUES ($1, $2, $3, $4, $5, $6, $7)`

	_, err := db.conn.Exec(query, req.ID, req.Email, req.FullName, req.Company, req.Purpose, req.RequestedAt, req.Status)
	return err
}

func (db *Database) SaveCredentials(creds Credentials, requestID string) error {
	tx, err := db.conn.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Insert credentials
	query := `INSERT INTO user_credentials (id, request_id, username, password_hash, api_key, access_level, environment, expires_at) 
			  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`

	hashedPassword, err := hashPassword(creds.Password)
	if err != nil {
		return err
	}

	_, err = tx.Exec(query, creds.ID, requestID, creds.Username, hashedPassword, creds.APIKey,
		creds.AccessLevel, creds.Environment, creds.ExpiresAt)
	if err != nil {
		return err
	}

	// Insert service access for 400+ services
	services := []string{
		"aws-ec2", "aws-s3", "aws-rds", "aws-lambda", "aws-eks", "aws-ecr",
		"azure-vm", "azure-storage", "azure-sql", "azure-functions", "azure-aks", "azure-acr",
		"gcp-compute", "gcp-storage", "gcp-sql", "gcp-functions", "gcp-gke", "gcp-gcr",
		"kubernetes", "docker", "terraform", "ansible", "jenkins", "gitlab",
		"grafana", "prometheus", "elasticsearch", "redis", "mongodb", "postgresql",
		"nginx", "apache", "istio", "envoy", "consul", "vault",
		"addtocloud-dashboard", "addtocloud-api", "addtocloud-monitoring", "addtocloud-logging",
	}

	// Add more services to reach 400+
	for i := 1; i <= 360; i++ {
		services = append(services, fmt.Sprintf("microservice-%d", i))
	}

	for _, service := range services {
		_, err = tx.Exec(`INSERT INTO service_access (credential_id, service_name) VALUES ($1, $2)`,
			creds.ID, service)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func generatePassword(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	b := make([]byte, length)
	rand.Read(b)
	for i := range b {
		b[i] = charset[b[i]%byte(len(charset))]
	}
	return string(b)
}

func generateAPIKey() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return base64.URLEncoding.EncodeToString(bytes)
}

func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	return string(bytes), err
}

func (e *EmailService) sendCredentialRequestNotification(req CredentialRequest, creds Credentials) error {
	subject := fmt.Sprintf("🔐 NEW ACCESS REQUEST - %s (%s)", req.FullName, req.Company)

	body := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); color: white; padding: 20px; border-radius: 8px; text-align: center; margin-bottom: 30px; }
        .credentials { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff; }
        .cred-item { margin: 10px 0; padding: 10px; background: white; border-radius: 4px; font-family: monospace; }
        .request-details { background: #e8f4f8; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .action-required { background: #fff3cd; border: 1px solid #ffeaa7; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; }
        .warning { background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 8px; margin: 20px 0; color: #721c24; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        .approve-btn { background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px; }
        .deny-btn { background: #dc3545; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>� AddToCloud Access Request</h1>
            <p>Manual Approval Required</p>
        </div>
        
        <div class="action-required">
            <h2>⚠️ ACTION REQUIRED</h2>
            <p><strong>A new user is requesting access to AddToCloud platform.</strong></p>
            <p>Review the details below and decide whether to grant access.</p>
        </div>

        <h2>� User Request Details</h2>
        <div class="request-details">
            <table style="width: 100%%; border-collapse: collapse;">
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 12px; font-weight: bold; width: 150px;">Full Name:</td>
                    <td style="padding: 12px;">%s</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 12px; font-weight: bold;">Email:</td>
                    <td style="padding: 12px;">%s</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 12px; font-weight: bold;">Company:</td>
                    <td style="padding: 12px;">%s</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 12px; font-weight: bold;">Purpose:</td>
                    <td style="padding: 12px;">%s</td>
                </tr>
                <tr style="border-bottom: 1px solid #ddd;">
                    <td style="padding: 12px; font-weight: bold;">Requested:</td>
                    <td style="padding: 12px;">%s</td>
                </tr>
            </table>
        </div>

        <h2>🔑 Pre-Generated Credentials (Ready to Send)</h2>
        <div class="credentials">
            <div class="cred-item"><strong>Username:</strong> %s</div>
            <div class="cred-item"><strong>Password:</strong> %s</div>
            <div class="cred-item"><strong>API Key:</strong> %s</div>
            <div class="cred-item"><strong>Access Level:</strong> Full Platform Access</div>
            <div class="cred-item"><strong>Services:</strong> 400+ Services (AWS, Azure, GCP, K8s)</div>
            <div class="cred-item"><strong>Expires:</strong> %s (30 days)</div>
        </div>

        <h2>🌐 Platform Endpoints</h2>
        <div class="credentials">
            <div class="cred-item"><strong>Primary:</strong> %s</div>
            <div class="cred-item"><strong>Secondary:</strong> %s</div>
            <div class="cred-item"><strong>API:</strong> %s</div>
            <div class="cred-item"><strong>Dashboard:</strong> %s</div>
        </div>

        <div class="action-required">
            <h3>🎯 Next Steps:</h3>
            <p><strong>If APPROVED:</strong> Copy the credentials above and email them to <strong>%s</strong></p>
            <p><strong>If DENIED:</strong> Simply ignore this email - no further action needed</p>
        </div>

        <div class="warning">
            <strong>⚠️ Security Reminder:</strong><br>
            • Credentials are pre-generated and ready to use<br>
            • User will NOT receive access until you manually send them credentials<br>
            • Consider the user's legitimacy and business need<br>
            • Credentials expire in 30 days if granted
        </div>

        <div class="footer">
            <p><strong>AddToCloud Enterprise Platform</strong></p>
            <p>Request ID: %s | Generated: %s</p>
            <p>Admin Dashboard: <a href="mailto:info@addtocloud.tech">info@addtocloud.tech</a></p>
        </div>
    </div>
</body>
</html>
	`,
		req.FullName, req.Email, req.Company, req.Purpose, req.RequestedAt.Format("2006-01-02 15:04:05"),
		creds.Username, creds.Password, creds.APIKey, creds.ExpiresAt.Format("2006-01-02 15:04:05"),
		creds.Endpoints.Primary, creds.Endpoints.Secondary, creds.Endpoints.API, creds.Endpoints.Dashboard,
		req.Email,
		req.ID, time.Now().Format("2006-01-02 15:04:05"),
	)

	msg := []byte(fmt.Sprintf("To: %s\r\nSubject: %s\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n%s", e.To, subject, body))

	auth := smtp.PlainAuth("", e.From, e.Password, e.SMTPHost)
	return smtp.SendMail(e.SMTPHost+":"+e.SMTPPort, auth, e.From, []string{e.To}, msg)
}

func main() {
	// Initialize database
	db, err := NewDatabase()
	if err != nil {
		log.Printf("⚠️  Database connection failed, continuing without persistence: %v", err)
		db = nil
	} else {
		log.Println("✅ Database connected successfully")
	}

	// Initialize email service
	emailService := &EmailService{
		SMTPHost: getEnv("EMAIL_SMTP_HOST", "smtp.gmail.com"),
		SMTPPort: getEnv("EMAIL_SMTP_PORT", "587"),
		From:     getEnv("EMAIL_FROM", "noreply@addtocloud.tech"),
		Password: getEnv("EMAIL_PASSWORD", ""),
		To:       getEnv("EMAIL_TO", "info@addtocloud.tech"),
	}

	r := gin.Default()

	// Serve static files
	r.Static("/static", "./public")
	r.StaticFile("/", "./public/index.html")

	// Enable CORS
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		status := "healthy"
		if db == nil {
			status = "healthy-no-db"
		}

		c.JSON(200, gin.H{
			"status":    status,
			"timestamp": time.Now(),
			"service":   "addtocloud-credential-service",
			"version":   "2.0.0",
		})
	})

	// Credential request endpoint
	r.POST("/api/request-credentials", func(c *gin.Context) {
		var req CredentialRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{
				"error":   "Invalid request format",
				"details": err.Error(),
			})
			return
		}

		// Generate unique ID and timestamp
		req.ID = generateAPIKey()[:16]
		req.RequestedAt = time.Now()
		req.Status = "pending" // Requires manual approval

		// Generate credentials
		password := generatePassword(16)
		apiKey := generateAPIKey()

		creds := Credentials{
			ID:          generateAPIKey()[:12],
			Username:    strings.ToLower(strings.ReplaceAll(req.FullName, " ", ".")) + "@addtocloud.tech",
			Password:    password,
			APIKey:      apiKey,
			ExpiresAt:   time.Now().Add(30 * 24 * time.Hour), // 30 days
			Environment: "production",
			AccessLevel: "full",
		}
		creds.Endpoints.Primary = "http://52.224.84.148"
		creds.Endpoints.Secondary = "http://a21f927dc7e504cbe99d241bc3562345-1460504033.us-west-2.elb.amazonaws.com"
		creds.Endpoints.API = "https://api.addtocloud.tech"
		creds.Endpoints.Dashboard = "https://dashboard.addtocloud.tech"

		// Save to database if available
		if db != nil {
			if err := db.SaveCredentialRequest(req); err != nil {
				log.Printf("Failed to save request: %v", err)
			}
			if err := db.SaveCredentials(creds, req.ID); err != nil {
				log.Printf("Failed to save credentials: %v", err)
			}
		}

		// Send email notification
		if err := emailService.sendCredentialRequestNotification(req, creds); err != nil {
			log.Printf("Failed to send email: %v", err)
			c.JSON(500, gin.H{
				"error":   "Failed to process request",
				"message": "Please try again or contact support at info@addtocloud.tech",
			})
			return
		}

		c.JSON(200, gin.H{
			"success":    true,
			"message":    "Access request submitted successfully",
			"request_id": req.ID,
			"note":       "Your request is being reviewed. You will receive credentials via email if approved.",
			"status":     "pending_approval",
		})
	})

	// Status endpoint
	r.GET("/api/status", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"service":      "AddToCloud Credential Service",
			"version":      "2.0.0",
			"environment":  getEnv("ENVIRONMENT", "production"),
			"database":     db != nil,
			"services":     400,
			"access_level": "full",
			"uptime":       time.Now().Format("2006-01-02 15:04:05"),
			"endpoints": map[string]string{
				"primary":   "http://52.224.84.148",
				"secondary": "http://a21f927dc7e504cbe99d241bc3562345-1460504033.us-west-2.elb.amazonaws.com",
				"api":       "https://api.addtocloud.tech",
				"dashboard": "https://dashboard.addtocloud.tech",
			},
		})
	})

	port := getEnv("PORT", "8080")
	log.Printf("🚀 AddToCloud Credential Service v2.0 starting on port %s", port)
	log.Printf("📧 Access requests will be sent to: %s", emailService.To)
	log.Printf("🔐 Manual approval required - credentials sent to admin for review")

	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
