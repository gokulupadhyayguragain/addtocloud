package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
	"gopkg.in/gomail.v2"
)

// User represents a platform user
type User struct {
	ID            string    `json:"id"`
	Email         string    `json:"email"`
	Password      string    `json:"password"`
	FirstName     string    `json:"firstName"`
	LastName      string    `json:"lastName"`
	Company       string    `json:"company"`
	Status        string    `json:"status"` // pending, approved, rejected
	CreatedAt     time.Time `json:"createdAt"`
	EC2InstanceID string    `json:"ec2InstanceId,omitempty"`
	EC2PublicIP   string    `json:"ec2PublicIp,omitempty"`
}

// AccessRequest represents a user's access request
type AccessRequest struct {
	ID                 string     `json:"id"`
	FirstName          string     `json:"firstName"`
	LastName           string     `json:"lastName"`
	Email              string     `json:"email"`
	Phone              string     `json:"phone"`
	Company            string     `json:"company"`
	Address            string     `json:"address"`
	City               string     `json:"city"`
	Country            string     `json:"country"`
	BusinessReason     string     `json:"businessReason"`
	ProjectDescription string     `json:"projectDescription"`
	Status             string     `json:"status"` // pending, approved, rejected
	SubmittedAt        time.Time  `json:"submittedAt"`
	ReviewedAt         *time.Time `json:"reviewedAt,omitempty"`
}

// LoginRequest for authentication
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// EC2ProvisionRequest for creating user infrastructure
type EC2ProvisionRequest struct {
	UserID       string `json:"userId"`
	Email        string `json:"email"`
	InstanceName string `json:"instanceName"`
}

// EC2ProvisionResponse with instance details
type EC2ProvisionResponse struct {
	InstanceID      string `json:"instanceId"`
	PublicIP        string `json:"publicIp"`
	PrivateIP       string `json:"privateIp"`
	InstanceType    string `json:"instanceType"`
	KeyPairName     string `json:"keyPairName"`
	SecurityGroupID string `json:"securityGroupId"`
	Status          string `json:"status"`
}

// In-memory storage (replace with database in production)
var users = make(map[string]*User)
var accessRequests = make(map[string]*AccessRequest)
var jwtSecret []byte

func init() {
	// Initialize JWT secret
	jwtSecret = []byte(os.Getenv("JWT_SECRET"))
	if len(jwtSecret) == 0 {
		jwtSecret = []byte("addtocloud-admin-secret-2025")
	}
}

func main() {
	// Initialize Gin
	r := gin.Default()

	// CORS configuration
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"https://addtocloud.pages.dev", "http://localhost:3000"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	r.Use(cors.New(config))

	// Health check
	r.GET("/api/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "healthy",
			"service":   "AddToCloud Admin API",
			"version":   "1.0.0",
			"timestamp": time.Now().UTC(),
		})
	})

	// Public endpoints
	r.POST("/api/v1/request-access", handleRequestAccess)
	r.POST("/api/v1/auth/login", handleLogin)

	// Admin endpoints (require authentication)
	admin := r.Group("/api/admin")
	admin.Use(authMiddleware())
	{
		admin.GET("/requests", getAccessRequests)
		admin.POST("/create-user", createUserAccount)
		admin.POST("/provision-ec2", provisionEC2Instance)
		admin.POST("/send-credentials", sendCredentialsEmail)
		admin.PUT("/requests/:id/approve", approveRequest)
		admin.PUT("/requests/:id/reject", rejectRequest)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 AddToCloud Admin API starting on port %s", port)
	log.Printf("🔐 Authentication enabled with JWT")
	log.Printf("📧 SMTP configured for notifications")
	log.Printf("☁️  Auto-provisioning enabled for approved users")

	r.Run(":" + port)
}

// Handle access requests
func handleRequestAccess(c *gin.Context) {
	var request AccessRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data", "details": err.Error()})
		return
	}

	// Generate unique ID
	request.ID = generateID()
	request.Status = "pending"
	request.SubmittedAt = time.Now().UTC()

	// Store request
	accessRequests[request.ID] = &request

	// Send notification email to admin
	go sendAdminNotification(&request)

	c.JSON(200, gin.H{
		"message":   "Access request submitted successfully",
		"requestId": request.ID,
		"status":    "pending",
		"note":      "Your request will be reviewed by an administrator within 24-48 hours",
	})
}

// Handle user login
func handleLogin(c *gin.Context) {
	var login LoginRequest
	if err := c.ShouldBindJSON(&login); err != nil {
		c.JSON(400, gin.H{"error": "Invalid login data"})
		return
	}

	// Check admin credentials
	if login.Email == "admin@addtocloud.tech" && login.Password == "admin123" {
		token := generateJWT("admin", "admin@addtocloud.tech")
		c.JSON(200, gin.H{
			"token": token,
			"user": gin.H{
				"id":        "admin",
				"email":     "admin@addtocloud.tech",
				"firstName": "Admin",
				"lastName":  "User",
				"role":      "admin",
			},
		})
		return
	}

	// Check regular user credentials
	for _, user := range users {
		if user.Email == login.Email && user.Status == "approved" {
			err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(login.Password))
			if err == nil {
				token := generateJWT(user.ID, user.Email)
				c.JSON(200, gin.H{
					"token": token,
					"user": gin.H{
						"id":          user.ID,
						"email":       user.Email,
						"firstName":   user.FirstName,
						"lastName":    user.LastName,
						"company":     user.Company,
						"ec2Instance": user.EC2InstanceID,
						"ec2PublicIp": user.EC2PublicIP,
					},
				})
				return
			}
		}
	}

	c.JSON(401, gin.H{"error": "Invalid credentials or account not approved"})
}

// Get all access requests (admin only)
func getAccessRequests(c *gin.Context) {
	var requests []*AccessRequest
	for _, request := range accessRequests {
		requests = append(requests, request)
	}
	c.JSON(200, gin.H{"requests": requests})
}

// Create user account after approval
func createUserAccount(c *gin.Context) {
	var req struct {
		Email     string `json:"email"`
		FirstName string `json:"firstName"`
		LastName  string `json:"lastName"`
		Company   string `json:"company"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	// Generate secure password
	password := generateSecurePassword()
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(500, gin.H{"error": "Password hashing failed"})
		return
	}

	// Create user
	user := &User{
		ID:        generateID(),
		Email:     req.Email,
		Password:  string(hashedPassword),
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Company:   req.Company,
		Status:    "approved",
		CreatedAt: time.Now().UTC(),
	}

	users[user.ID] = user

	c.JSON(200, gin.H{
		"userId": user.ID,
		"credentials": gin.H{
			"email":    user.Email,
			"password": password, // Send plain password for initial email
		},
	})
}

// Provision EC2 instance for user
func provisionEC2Instance(c *gin.Context) {
	var req EC2ProvisionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	// Simulate EC2 provisioning (replace with actual AWS SDK calls)
	instanceDetails := &EC2ProvisionResponse{
		InstanceID:      fmt.Sprintf("i-%s", generateID()),
		PublicIP:        fmt.Sprintf("52.%d.%d.%d", randomInt(1, 255), randomInt(1, 255), randomInt(1, 255)),
		PrivateIP:       fmt.Sprintf("10.0.%d.%d", randomInt(1, 255), randomInt(1, 255)),
		InstanceType:    "t2.micro",
		KeyPairName:     fmt.Sprintf("%s-key", req.InstanceName),
		SecurityGroupID: fmt.Sprintf("sg-%s", generateID()),
		Status:          "running",
	}

	// Update user with EC2 details
	if user, exists := users[req.UserID]; exists {
		user.EC2InstanceID = instanceDetails.InstanceID
		user.EC2PublicIP = instanceDetails.PublicIP
	}

	// In production, this would:
	// 1. Create EC2 instance with AWS SDK
	// 2. Configure security groups
	// 3. Install AWS CLI, Azure CLI, GCP CLI
	// 4. Set up user environment

	log.Printf("🚀 Provisioned EC2 instance %s for user %s", instanceDetails.InstanceID, req.Email)

	c.JSON(200, gin.H{
		"message":         "EC2 instance provisioned successfully",
		"instanceDetails": instanceDetails,
	})
}

// Send credentials email to approved user
func sendCredentialsEmail(c *gin.Context) {
	var req struct {
		Email       string `json:"email"`
		FirstName   string `json:"firstName"`
		Credentials struct {
			Email    string `json:"email"`
			Password string `json:"password"`
		} `json:"credentials"`
		EC2Details interface{} `json:"ec2Details"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	// Send email with credentials and EC2 details
	emailBody := fmt.Sprintf(`
		<h2>Welcome to AddToCloud!</h2>
		<p>Dear %s,</p>
		<p>Your access request has been approved! Here are your login credentials:</p>
		
		<div style="background: #f4f4f4; padding: 15px; border-radius: 5px; margin: 20px 0;">
			<strong>Login Credentials:</strong><br>
			Email: %s<br>
			Password: %s
		</div>

		<p><strong>Your Dedicated Infrastructure:</strong></p>
		<p>We've provisioned a dedicated EC2 instance for your use with pre-installed cloud CLI tools:</p>
		<ul>
			<li>AWS CLI - For Amazon Web Services</li>
			<li>Azure CLI - For Microsoft Azure</li>
			<li>GCP CLI - For Google Cloud Platform</li>
		</ul>

		<p><strong>Getting Started:</strong></p>
		<ol>
			<li>Login at: <a href="https://addtocloud.pages.dev/login">https://addtocloud.pages.dev/login</a></li>
			<li>Access your dashboard to view your infrastructure</li>
			<li>Deploy applications across multiple cloud providers</li>
		</ol>

		<p>If you have any questions, please contact our support team.</p>
		<p>Best regards,<br>AddToCloud Team</p>
	`, req.FirstName, req.Credentials.Email, req.Credentials.Password)

	err := sendEmail(req.Email, "Welcome to AddToCloud - Your Account is Ready!", emailBody)
	if err != nil {
		log.Printf("Failed to send credentials email: %v", err)
		c.JSON(500, gin.H{"error": "Failed to send email"})
		return
	}

	c.JSON(200, gin.H{"message": "Credentials email sent successfully"})
}

// Approve request
func approveRequest(c *gin.Context) {
	requestID := c.Param("id")
	if request, exists := accessRequests[requestID]; exists {
		request.Status = "approved"
		now := time.Now().UTC()
		request.ReviewedAt = &now
		c.JSON(200, gin.H{"message": "Request approved"})
	} else {
		c.JSON(404, gin.H{"error": "Request not found"})
	}
}

// Reject request
func rejectRequest(c *gin.Context) {
	requestID := c.Param("id")
	if request, exists := accessRequests[requestID]; exists {
		request.Status = "rejected"
		now := time.Now().UTC()
		request.ReviewedAt = &now
		c.JSON(200, gin.H{"message": "Request rejected"})
	} else {
		c.JSON(404, gin.H{"error": "Request not found"})
	}
}

// Middleware for authentication
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(401, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		tokenString := authHeader[7:] // Remove "Bearer " prefix
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			c.JSON(401, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// Generate JWT token
func generateJWT(userID, email string) string {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"email":   email,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})

	tokenString, _ := token.SignedString(jwtSecret)
	return tokenString
}

// Generate secure random ID
func generateID() string {
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// Generate secure password
func generateSecurePassword() string {
	bytes := make([]byte, 12)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)[:16]
}

// Random integer for IP generation
func randomInt(min, max int) int {
	bytes := make([]byte, 1)
	rand.Read(bytes)
	return min + int(bytes[0])%(max-min+1)
}

// Send admin notification
func sendAdminNotification(request *AccessRequest) {
	subject := fmt.Sprintf("New Access Request: %s %s", request.FirstName, request.LastName)
	body := fmt.Sprintf(`
		<h3>New AddToCloud Access Request</h3>
		<p><strong>User:</strong> %s %s</p>
		<p><strong>Email:</strong> %s</p>
		<p><strong>Company:</strong> %s</p>
		<p><strong>Business Reason:</strong> %s</p>
		<p><strong>Project:</strong> %s</p>
		<p><strong>Submitted:</strong> %s</p>
		
		<p><a href="https://addtocloud.pages.dev/admin">Review Request</a></p>
	`, request.FirstName, request.LastName, request.Email, request.Company,
		request.BusinessReason, request.ProjectDescription, request.SubmittedAt.Format(time.RFC3339))

	sendEmail("admin@addtocloud.tech", subject, body)
}

// Send email function
func sendEmail(to, subject, body string) error {
	// SMTP configuration
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")

	if smtpHost == "" {
		smtpHost = "smtp.zoho.com"
		smtpPort = "587"
		smtpUser = "noreply@addtocloud.tech"
		smtpPass = "your-zoho-password" // Set this in environment
	}

	port, _ := strconv.Atoi(smtpPort)

	m := gomail.NewMessage()
	m.SetHeader("From", smtpUser)
	m.SetHeader("To", to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/html", body)

	d := gomail.NewDialer(smtpHost, port, smtpUser, smtpPass)

	return d.DialAndSend(m)
}
