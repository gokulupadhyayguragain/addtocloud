package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

type HealthResponse struct {
	Status    string `json:"status"`
	Message   string `json:"message"`
	Cluster   string `json:"cluster"`
	Timestamp string `json:"timestamp"`
}

type ServiceResponse struct {
	Services []Service `json:"services"`
	Total    int       `json:"total"`
}

type Service struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Status      string `json:"status"`
	Provider    string `json:"provider"`
}

func main() {
	// Load environment variables
	godotenv.Load()

	// Set Gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create Gin router
	r := gin.Default()

	// CORS middleware
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	r.Use(cors.New(config))

	// Health check endpoint
	r.GET("/api/health", func(c *gin.Context) {
		cluster := os.Getenv("CLUSTER_NAME")
		if cluster == "" {
			cluster = "unknown"
		}

		c.JSON(http.StatusOK, HealthResponse{
			Status:    "healthy",
			Message:   "AddToCloud API is running",
			Cluster:   cluster,
			Timestamp: "2025-08-30T05:45:00Z",
		})
	})

	// Cloud services endpoint
	r.GET("/api/v1/cloud/services", func(c *gin.Context) {
		services := []Service{
			{
				ID:          "compute-1",
				Name:        "Virtual Machines",
				Description: "Scalable compute instances",
				Status:      "active",
				Provider:    "Multi-Cloud",
			},
			{
				ID:          "storage-1",
				Name:        "Object Storage",
				Description: "Highly available object storage",
				Status:      "active",
				Provider:    "Multi-Cloud",
			},
			{
				ID:          "database-1",
				Name:        "Managed Database",
				Description: "PostgreSQL and MongoDB hosting",
				Status:      "active",
				Provider:    "Multi-Cloud",
			},
			{
				ID:          "networking-1",
				Name:        "Global CDN",
				Description: "Content delivery network",
				Status:      "active",
				Provider:    "Multi-Cloud",
			},
		}

		c.JSON(http.StatusOK, ServiceResponse{
			Services: services,
			Total:    len(services),
		})
	})

	// User endpoints
	r.POST("/api/v1/auth/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Login endpoint - please implement authentication",
			"status":  "not_implemented",
		})
	})

	r.POST("/api/v1/auth/register", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Registration endpoint - please implement authentication",
			"status":  "not_implemented",
		})
	})

	// Contact/email endpoint
	r.POST("/api/v1/contact", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Contact form submitted successfully",
			"status":  "received",
			"note":    "Email service integration pending",
		})
	})

	// Get port from environment or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting AddToCloud API on port %s", port)
	log.Printf("Cluster: %s", os.Getenv("CLUSTER_NAME"))
	
	// Start server
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}