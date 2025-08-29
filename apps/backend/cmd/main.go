package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"github.com/gokulupadhyayguragain/addtocloud/backend/internal/handlers"
	"github.com/gokulupadhyayguragain/addtocloud/backend/internal/middleware"
	"github.com/gokulupadhyayguragain/addtocloud/backend/internal/models"
)

func main() {
	// Load environment variables from .env file (local development only)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found - using environment variables from system/GitHub Actions")
	}

	// Set Gin mode from environment
	ginMode := os.Getenv("GIN_MODE")
	if ginMode == "" {
		ginMode = "release"
	}
	gin.SetMode(ginMode)

	// Database connection
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		host := getEnvOrDefault("DB_HOST", "localhost")
		user := getEnvOrDefault("DB_USER", "postgres")
		password := getEnvOrDefault("POSTGRES_PASSWORD", "postgres")
		dbname := getEnvOrDefault("DB_NAME", "addtocloud")
		port := getEnvOrDefault("DB_PORT", "5432")
		sslmode := getEnvOrDefault("DB_SSLMODE", "disable")

		dsn = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
			host, user, password, dbname, port, sslmode)
	}

	// Connect to database
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Printf("Warning: Failed to connect to database: %v", err)
		log.Println("Continuing without database")
		db = nil
	} else {
		log.Println("✅ Database connected successfully")

		// Auto-migrate
		if err := db.AutoMigrate(&models.User{}); err != nil {
			log.Printf("Warning: Failed to migrate database: %v", err)
		}
	}

	// Initialize handlers
	var authHandler *handlers.AuthHandler
	if db != nil {
		authHandler = handlers.NewAuthHandler(db)
	}

	// Setup router
	r := gin.Default()

	// CORS configuration
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{
		"http://localhost:3000",
		"https://addtocloud.tech",
		"https://*.addtocloud.tech",
		"https://addtocloud.pages.dev",
	}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Authorization", "Accept", "X-Requested-With"}
	config.AllowCredentials = true
	r.Use(cors.New(config))

	// Security headers
	r.Use(func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Next()
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"version":   "2.0.0",
			"service":   "addtocloud-api",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
			"database":  db != nil,
		})
	})

	// Cloud services endpoint
	r.GET("/api/v1/cloud/services", func(c *gin.Context) {
		services := generateCloudServices()
		c.JSON(http.StatusOK, gin.H{
			"services": services,
			"total":    len(services),
			"providers": map[string]int{
				"AWS":   120,
				"Azure": 120,
				"GCP":   120,
			},
		})
	})

	// API routes
	api := r.Group("/api/v1")
	{
		// Auth routes
		if authHandler != nil {
			auth := api.Group("/auth")
			{
				auth.POST("/register", authHandler.Register)
				auth.POST("/login", authHandler.Login)
			}

			// Protected routes
			protected := api.Group("/")
			protected.Use(middleware.AuthMiddleware())
			{
				protected.GET("/user/profile", authHandler.GetProfile)
			}
		} else {
			// Fallback endpoints
			api.POST("/auth/register", func(c *gin.Context) {
				c.JSON(http.StatusServiceUnavailable, gin.H{
					"error":   "Database not available",
					"message": "Authentication requires database connection",
				})
			})
			api.POST("/auth/login", func(c *gin.Context) {
				c.JSON(http.StatusServiceUnavailable, gin.H{
					"error":   "Database not available",
					"message": "Authentication requires database connection",
				})
			})
		}

		api.GET("/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"api_version": "v1",
				"services":    []string{"auth", "cloud", "monitoring"},
				"status":      "operational",
			})
		})
	}

	// Start server
	port := getEnvOrDefault("PORT", "8080")
	log.Printf("🚀 Starting AddToCloud API v1.0.1 on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

// Helper function
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// Generate cloud services data
func generateCloudServices() []map[string]interface{} {
	services := make([]map[string]interface{}, 0, 360)

	// AWS Services
	awsServices := []map[string]string{
		{"name": "EC2", "category": "Compute", "description": "Virtual Servers in the Cloud"},
		{"name": "Lambda", "category": "Serverless", "description": "Run Code without Servers"},
		{"name": "S3", "category": "Storage", "description": "Object Storage Service"},
		{"name": "RDS", "category": "Database", "description": "Managed Relational Database"},
		{"name": "DynamoDB", "category": "Database", "description": "NoSQL Database Service"},
		{"name": "EKS", "category": "Container", "description": "Managed Kubernetes Service"},
		{"name": "CloudFront", "category": "Network", "description": "Content Delivery Network"},
		{"name": "SageMaker", "category": "AI/ML", "description": "Machine Learning Platform"},
		{"name": "Kinesis", "category": "Analytics", "description": "Real-time Data Streaming"},
		{"name": "IAM", "category": "Security", "description": "Identity and Access Management"},
	}

	// Generate AWS services
	for _, service := range awsServices {
		for j := 0; j < 12; j++ {
			services = append(services, map[string]interface{}{
				"id":          len(services) + 1,
				"name":        fmt.Sprintf("%s %s", service["name"], []string{"", "Advanced", "Pro", "Enterprise", "Premium", "Ultimate", "Standard", "Basic", "Professional", "Business", "Starter", "Plus"}[j]),
				"provider":    "AWS",
				"category":    service["category"],
				"description": service["description"],
				"status":      []string{"running", "active", "maintenance", "stopped"}[len(services)%4],
				"region":      []string{"us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"}[len(services)%4],
			})
		}
	}

	// Azure Services
	azureServices := []map[string]string{
		{"name": "Virtual Machines", "category": "Compute", "description": "Linux and Windows VMs"},
		{"name": "Functions", "category": "Serverless", "description": "Event-driven Serverless Compute"},
		{"name": "Blob Storage", "category": "Storage", "description": "Object Storage for Cloud"},
		{"name": "SQL Database", "category": "Database", "description": "Managed SQL Database Service"},
		{"name": "Cosmos DB", "category": "Database", "description": "Multi-model Database Service"},
		{"name": "AKS", "category": "Container", "description": "Azure Kubernetes Service"},
		{"name": "CDN", "category": "Network", "description": "Content Delivery Network"},
		{"name": "Machine Learning", "category": "AI/ML", "description": "Enterprise ML Service"},
		{"name": "Stream Analytics", "category": "Analytics", "description": "Real-time Analytics Service"},
		{"name": "Active Directory", "category": "Security", "description": "Identity and Access Management"},
	}

	// Generate Azure services
	for _, service := range azureServices {
		for j := 0; j < 12; j++ {
			services = append(services, map[string]interface{}{
				"id":          len(services) + 1,
				"name":        fmt.Sprintf("%s %s", service["name"], []string{"", "Standard", "Premium", "Enterprise", "Advanced", "Ultimate", "Basic", "Professional", "Business", "Starter", "Plus", "Pro"}[j]),
				"provider":    "Azure",
				"category":    service["category"],
				"description": service["description"],
				"status":      []string{"running", "active", "maintenance", "stopped"}[len(services)%4],
				"region":      []string{"East US", "West Europe", "Southeast Asia", "Central US"}[len(services)%4],
			})
		}
	}

	// GCP Services
	gcpServices := []map[string]string{
		{"name": "Compute Engine", "category": "Compute", "description": "Virtual Machine Instances"},
		{"name": "Cloud Functions", "category": "Serverless", "description": "Event-driven Functions"},
		{"name": "Cloud Storage", "category": "Storage", "description": "Object Storage and Serving"},
		{"name": "Cloud SQL", "category": "Database", "description": "Managed Relational Database"},
		{"name": "Firestore", "category": "Database", "description": "NoSQL Document Database"},
		{"name": "GKE", "category": "Container", "description": "Google Kubernetes Engine"},
		{"name": "Cloud CDN", "category": "Network", "description": "Content Delivery Network"},
		{"name": "AI Platform", "category": "AI/ML", "description": "Machine Learning Platform"},
		{"name": "BigQuery", "category": "Analytics", "description": "Serverless Data Warehouse"},
		{"name": "Cloud IAM", "category": "Security", "description": "Identity and Access Management"},
	}

	// Generate GCP services
	for _, service := range gcpServices {
		for j := 0; j < 12; j++ {
			services = append(services, map[string]interface{}{
				"id":          len(services) + 1,
				"name":        fmt.Sprintf("%s %s", service["name"], []string{"", "Standard", "Premium", "Enterprise", "Advanced", "Ultimate", "Basic", "Professional", "Business", "Starter", "Plus", "Pro"}[j]),
				"provider":    "GCP",
				"category":    service["category"],
				"description": service["description"],
				"status":      []string{"running", "active", "maintenance", "stopped"}[len(services)%4],
				"region":      []string{"us-central1", "europe-west1", "asia-southeast1", "us-east1"}[len(services)%4],
			})
		}
	}

	return services
}
