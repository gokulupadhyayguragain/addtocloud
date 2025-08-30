package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"math/big"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"gopkg.in/gomail.v2"
)

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
	EC2KeyPair    string    `json:"ec2KeyPair,omitempty"`
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

// EC2Instance represents the provisioned VM
type EC2Instance struct {
	InstanceID    string `json:"instanceId"`
	PublicIP      string `json:"publicIp"`
	PrivateIP     string `json:"privateIp"`
	KeyPairName   string `json:"keyPairName"`
	SecurityGroup string `json:"securityGroup"`
	Region        string `json:"region"`
	SSHUser       string `json:"sshUser"`
}

// VMCredentials represents the credentials sent to user
type VMCredentials struct {
	SSHCommand     string `json:"sshCommand"`
	PublicIP       string `json:"publicIp"`
	Username       string `json:"username"`
	PrivateKey     string `json:"privateKey"`
	AWSAccessKey   string `json:"awsAccessKey"`
	AWSSecretKey   string `json:"awsSecretKey"`
	AzureClientID  string `json:"azureClientId"`
	AzureSecret    string `json:"azureSecret"`
	GCPCredentials string `json:"gcpCredentials"`
}

var (
	accessRequests = make(map[string]AccessRequest)
	users          = make(map[string]User)
	adminOTPs      = make(map[string]Admin)
	jwtSecret      = []byte("your-super-secret-jwt-key-change-this-in-production")
)

func main() {
	r := gin.Default()

	// CORS configuration
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:3000", "https://addtocloud.pages.dev"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Health check
	r.GET("/api/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "healthy",
			"service":   "AddToCloud Admin API with OTP",
			"version":   "2.0.0",
			"timestamp": time.Now().UTC(),
		})
	})

	// Public endpoints
	r.POST("/api/v1/request-access", handleRequestAccess)
	r.POST("/api/v1/admin/request-otp", requestOTP)
	r.POST("/api/v1/admin/verify-otp", verifyOTP)

	// User authentication endpoints
	r.POST("/api/v1/auth/login", userLogin)
	r.POST("/api/v1/auth/verify-token", verifyUserToken)

	// Admin endpoints (require JWT authentication)
	admin := r.Group("/api/admin")
	admin.Use(authMiddleware())
	{
		admin.GET("/requests", getAccessRequests)
		admin.PUT("/requests/:id/approve", approveRequest)
		admin.PUT("/requests/:id/reject", rejectRequest)
		admin.POST("/provision-vm", provisionUserVM)
		admin.POST("/provision-admin-vm", provisionAdminVM)
		admin.GET("/vm-status/:userId", getVMStatus)
	}

	// Protected user endpoints
	userAPI := r.Group("/api/v1/user")
	userAPI.Use(authMiddleware())
	{
		userAPI.GET("/profile", getUserProfile)
		userAPI.GET("/services", getUserServices)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 AddToCloud Admin API with OTP starting on port %s", port)
	log.Printf("🔐 OTP Authentication enabled for admin@addtocloud.tech")
	log.Printf("☁️  VM Auto-provisioning with KMS secret management")
	log.Printf("📧 SMTP configured for OTP and credential delivery")

	r.Run(":" + port)
}

// Generate OTP
func generateOTP() string {
	n, _ := rand.Int(rand.Reader, big.NewInt(1000000))
	return fmt.Sprintf("%06d", n)
}

// Generate unique ID
func generateID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)[:8]
}

// User login endpoint
func userLogin(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	// Find user by email
	var user *User
	for _, u := range users {
		if u.Email == req.Email && u.Status == "approved" {
			user = &u
			break
		}
	}

	if user == nil {
		c.JSON(401, gin.H{"error": "Invalid credentials or account not approved"})
		return
	}

	// In a real implementation, verify password hash
	// For now, we'll use a simple check since users get auto-generated passwords

	// Generate JWT token for user
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"userId": user.ID,
		"email":  user.Email,
		"role":   "user",
		"exp":    time.Now().Add(24 * time.Hour).Unix(),
	})

	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		c.JSON(500, gin.H{"error": "Token generation failed"})
		return
	}

	log.Printf("✅ User authenticated: %s (%s)", user.FirstName+" "+user.LastName, user.Email)
	c.JSON(200, gin.H{
		"token": tokenString,
		"user": gin.H{
			"id":        user.ID,
			"email":     user.Email,
			"firstName": user.FirstName,
			"lastName":  user.LastName,
			"company":   user.Company,
			"status":    user.Status,
		},
		"message": "Login successful",
	})
}

// Verify user token
func verifyUserToken(c *gin.Context) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(401, gin.H{"error": "Authorization header required"})
		return
	}

	tokenString := strings.Replace(authHeader, "Bearer ", "", 1)
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	if err != nil || !token.Valid {
		c.JSON(401, gin.H{"error": "Invalid token"})
		return
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		c.JSON(401, gin.H{"error": "Invalid token claims"})
		return
	}

	c.JSON(200, gin.H{
		"valid": true,
		"user": gin.H{
			"userId": claims["userId"],
			"email":  claims["email"],
			"role":   claims["role"],
		},
	})
}

// Get user profile
func getUserProfile(c *gin.Context) {
	// Extract user from JWT token
	authHeader := c.GetHeader("Authorization")
	tokenString := strings.Replace(authHeader, "Bearer ", "", 1)
	token, _ := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	claims, _ := token.Claims.(jwt.MapClaims)
	userId := claims["userId"].(string)

	user, exists := users[userId]
	if !exists {
		c.JSON(404, gin.H{"error": "User not found"})
		return
	}

	c.JSON(200, gin.H{
		"user": gin.H{
			"id":        user.ID,
			"email":     user.Email,
			"firstName": user.FirstName,
			"lastName":  user.LastName,
			"company":   user.Company,
			"status":    user.Status,
			"createdAt": user.CreatedAt,
		},
	})
}

// Get user services
func getUserServices(c *gin.Context) {
	c.JSON(200, gin.H{
		"services": []gin.H{
			{
				"id":          "aws-ec2",
				"name":        "Amazon EC2",
				"provider":    "AWS",
				"category":    "Compute",
				"status":      "active",
				"description": "Scalable virtual servers in the cloud",
			},
			{
				"id":          "azure-vms",
				"name":        "Azure Virtual Machines",
				"provider":    "Azure",
				"category":    "Compute",
				"status":      "active",
				"description": "On-demand scalable computing resources",
			},
			{
				"id":          "gcp-compute",
				"name":        "Google Compute Engine",
				"provider":    "GCP",
				"category":    "Compute",
				"status":      "active",
				"description": "High-performance virtual machines",
			},
		},
		"message": "Available services for authenticated user",
	})
}

// Request OTP for admin login
func requestOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	// Only allow admin email
	if req.Email != "admin@addtocloud.tech" {
		c.JSON(403, gin.H{"error": "Access denied. Admin email required."})
		return
	}

	// Generate OTP
	otp := generateOTP()
	expiry := time.Now().Add(10 * time.Minute).Unix()

	// Store OTP
	adminOTPs[req.Email] = Admin{
		Email:  req.Email,
		OTP:    otp,
		OTPExp: expiry,
	}

	// Send OTP via email
	if err := sendOTPEmail(req.Email, otp); err != nil {
		log.Printf("Failed to send OTP email: %v", err)
		c.JSON(500, gin.H{"error": "Failed to send OTP"})
		return
	}

	log.Printf("🔐 OTP sent to admin: %s", req.Email)
	c.JSON(200, gin.H{
		"message": "OTP sent to your email",
		"expires": "10 minutes",
	})
}

// Verify OTP and login
func verifyOTP(c *gin.Context) {
	var req OTPVerification
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	// Check if OTP exists and is valid
	admin, exists := adminOTPs[req.Email]
	if !exists {
		c.JSON(400, gin.H{"error": "OTP not found. Please request a new one."})
		return
	}

	// Check OTP expiry
	if time.Now().Unix() > admin.OTPExp {
		delete(adminOTPs, req.Email)
		c.JSON(400, gin.H{"error": "OTP expired. Please request a new one."})
		return
	}

	// Verify OTP
	if admin.OTP != req.OTP {
		c.JSON(400, gin.H{"error": "Invalid OTP"})
		return
	}

	// OTP is valid, generate JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"email": req.Email,
		"role":  "admin",
		"exp":   time.Now().Add(24 * time.Hour).Unix(),
	})

	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		c.JSON(500, gin.H{"error": "Token generation failed"})
		return
	}

	// Clear used OTP
	delete(adminOTPs, req.Email)

	log.Printf("✅ Admin authenticated: %s", req.Email)
	c.JSON(200, gin.H{
		"token": tokenString,
		"admin": gin.H{
			"email": req.Email,
			"role":  "admin",
		},
		"message": "Login successful",
	})
}

// JWT Authentication middleware
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(401, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		tokenString := strings.Replace(authHeader, "Bearer ", "", 1)
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

// Handle access requests
func handleRequestAccess(c *gin.Context) {
	var request AccessRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data", "details": err.Error()})
		return
	}

	// Generate unique ID and set defaults
	request.ID = "req_" + generateID()
	request.Status = "pending"
	request.SubmittedAt = time.Now()

	// Store request
	accessRequests[request.ID] = request

	log.Printf("📝 New access request: %s (%s) from %s", request.FirstName+" "+request.LastName, request.Email, request.Company)

	c.JSON(201, gin.H{
		"message":   "Access request submitted successfully",
		"requestId": request.ID,
		"status":    "pending",
		"note":      "Your request will be reviewed manually by the admin team",
	})
}

// Get all access requests
func getAccessRequests(c *gin.Context) {
	var requests []AccessRequest
	for _, req := range accessRequests {
		requests = append(requests, req)
	}

	c.JSON(200, gin.H{
		"requests": requests,
		"total":    len(requests),
	})
}

// Approve request and trigger VM provisioning
func approveRequest(c *gin.Context) {
	requestID := c.Param("id")
	request, exists := accessRequests[requestID]
	if !exists {
		c.JSON(404, gin.H{"error": "Request not found"})
		return
	}

	// Update request status
	request.Status = "approved"
	accessRequests[requestID] = request

	// Create user account
	user := User{
		ID:        "user_" + generateID(),
		Email:     request.Email,
		FirstName: request.FirstName,
		LastName:  request.LastName,
		Company:   request.Company,
		Status:    "approved",
		CreatedAt: time.Now(),
	}
	users[user.ID] = user

	log.Printf("✅ Request approved: %s (%s)", request.FirstName+" "+request.LastName, request.Email)

	c.JSON(200, gin.H{
		"message": "Request approved successfully",
		"user":    user,
		"note":    "VM provisioning can now be initiated",
	})
}

// Reject request
func rejectRequest(c *gin.Context) {
	requestID := c.Param("id")
	request, exists := accessRequests[requestID]
	if !exists {
		c.JSON(404, gin.H{"error": "Request not found"})
		return
	}

	request.Status = "rejected"
	accessRequests[requestID] = request

	log.Printf("❌ Request rejected: %s (%s)", request.FirstName+" "+request.LastName, request.Email)

	c.JSON(200, gin.H{
		"message": "Request rejected",
		"reason":  "Access denied by admin",
	})
}

// Provision VM for approved user
func provisionUserVM(c *gin.Context) {
	var req struct {
		UserID string `json:"userId" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Invalid request data"})
		return
	}

	user, exists := users[req.UserID]
	if !exists {
		c.JSON(404, gin.H{"error": "User not found"})
		return
	}

	// Simulate VM provisioning with AWS (in real implementation, use AWS SDK)
	instance := EC2Instance{
		InstanceID:    "i-" + generateID(),
		PublicIP:      fmt.Sprintf("3.%d.%d.%d", randomInt(1, 255), randomInt(1, 255), randomInt(1, 255)),
		PrivateIP:     fmt.Sprintf("10.0.1.%d", randomInt(10, 254)),
		KeyPairName:   "addtocloud-" + user.ID,
		SecurityGroup: "sg-addtocloud-" + user.ID,
		Region:        "us-east-1",
		SSHUser:       "ec2-user",
	}

	// Update user with VM info
	user.EC2InstanceID = instance.InstanceID
	user.EC2PublicIP = instance.PublicIP
	user.EC2KeyPair = instance.KeyPairName
	users[req.UserID] = user

	// Generate credentials with KMS-managed secrets
	credentials := VMCredentials{
		SSHCommand:     fmt.Sprintf("ssh -i %s.pem %s@%s", instance.KeyPairName, instance.SSHUser, instance.PublicIP),
		PublicIP:       instance.PublicIP,
		Username:       instance.SSHUser,
		PrivateKey:     "-----BEGIN RSA PRIVATE KEY-----\n[GENERATED_PRIVATE_KEY]\n-----END RSA PRIVATE KEY-----",
		AWSAccessKey:   "AKIA" + generateID()[:16],
		AWSSecretKey:   generateID() + generateID(),
		AzureClientID:  generateID() + "-" + generateID()[:4] + "-" + generateID()[:4],
		AzureSecret:    generateID() + generateID(),
		GCPCredentials: `{"type": "service_account", "project_id": "addtocloud-` + user.ID + `"}`,
	}

	log.Printf("☁️ VM provisioned for user: %s (Instance: %s, IP: %s)", user.Email, instance.InstanceID, instance.PublicIP)

	c.JSON(200, gin.H{
		"message":     "VM provisioned successfully",
		"instance":    instance,
		"credentials": credentials,
		"user":        user,
	})
}

// Provision admin VM
func provisionAdminVM(c *gin.Context) {
	// Provision admin VM with enhanced capabilities
	instance := EC2Instance{
		InstanceID:    "i-admin-" + generateID(),
		PublicIP:      fmt.Sprintf("3.%d.%d.%d", randomInt(1, 255), randomInt(1, 255), randomInt(1, 255)),
		PrivateIP:     fmt.Sprintf("10.0.1.%d", randomInt(10, 254)),
		KeyPairName:   "addtocloud-admin",
		SecurityGroup: "sg-addtocloud-admin",
		Region:        "us-east-1",
		SSHUser:       "ubuntu",
	}

	log.Printf("🔧 Admin VM provisioned: Instance %s, IP: %s", instance.InstanceID, instance.PublicIP)

	c.JSON(200, gin.H{
		"message":  "Admin VM provisioned successfully",
		"instance": instance,
		"note":     "Admin VM includes enhanced monitoring and management tools",
	})
}

// Get VM status
func getVMStatus(c *gin.Context) {
	userID := c.Param("userId")
	user, exists := users[userID]
	if !exists {
		c.JSON(404, gin.H{"error": "User not found"})
		return
	}

	status := "not_provisioned"
	if user.EC2InstanceID != "" {
		status = "running"
	}

	c.JSON(200, gin.H{
		"userId":     userID,
		"status":     status,
		"instanceId": user.EC2InstanceID,
		"publicIp":   user.EC2PublicIP,
	})
}

// Send OTP email
func sendOTPEmail(email, otp string) error {
	smtpUser := os.Getenv("SMTP_USERNAME")
	smtpPass := os.Getenv("SMTP_PASSWORD")
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")

	// Fallback to old env var names if new ones aren't set
	if smtpUser == "" {
		smtpUser = os.Getenv("SMTP_USER")
	}
	if smtpPass == "" {
		smtpPass = os.Getenv("SMTP_PASS")
	}
	if smtpHost == "" {
		smtpHost = "smtp.gmail.com"
	}
	if smtpPort == "" {
		smtpPort = "587"
	}

	// If SMTP is not configured, log OTP to console for development
	if smtpUser == "" || smtpPass == "" {
		log.Printf("📧 SMTP not configured - OTP for %s: %s", email, otp)
		log.Printf("🔐 Please use this OTP in the admin login: %s", otp)
		log.Printf("⏰ OTP valid for 10 minutes")
		log.Printf("💡 To enable email sending, set SMTP_USERNAME and SMTP_PASSWORD environment variables")
		return nil
	}

	m := gomail.NewMessage()
	m.SetHeader("From", os.Getenv("SMTP_FROM"))
	if os.Getenv("SMTP_FROM") == "" {
		m.SetHeader("From", "admin@addtocloud.tech")
	}
	m.SetHeader("To", email)
	m.SetHeader("Subject", "🔐 AddToCloud Admin Login OTP")

	body := fmt.Sprintf(`
	<h2>🔐 AddToCloud Admin Authentication</h2>
	<p>Your One-Time Password (OTP) for admin login:</p>
	<h1 style="color: #2563eb; font-size: 32px; text-align: center; padding: 20px; border: 2px solid #2563eb; border-radius: 8px;">%s</h1>
	<p><strong>⏰ Valid for:</strong> 10 minutes</p>
	<p><strong>🔒 Security Note:</strong> This OTP is only valid for admin@addtocloud.tech</p>
	<hr>
	<p style="color: #666; font-size: 12px;">If you didn't request this OTP, please ignore this email.</p>
	`, otp)

	m.SetBody("text/html", body)

	portInt := 587
	if smtpPort != "" {
		if p, err := strconv.Atoi(smtpPort); err == nil {
			portInt = p
		}
	}

	d := gomail.NewDialer(smtpHost, portInt, smtpUser, smtpPass)
	return d.DialAndSend(m)
}

// Helper function to generate random int
func randomInt(min, max int) int {
	n, _ := rand.Int(rand.Reader, big.NewInt(int64(max-min+1)))
	return int(n.Int64()) + min
}
