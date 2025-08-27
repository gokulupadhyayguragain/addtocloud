package main

import (
    "context"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/gokulupadhyayguragain/addtocloud/backend/internal/handlers"
    "github.com/gokulupadhyayguragain/addtocloud/backend/internal/services"
    "github.com/gokulupadhyayguragain/addtocloud/backend/pkg/database"
    "github.com/gokulupadhyayguragain/addtocloud/backend/pkg/logger"
)

func main() {
    // Initialize logger
    logger.Init()
    
    // Initialize database connections
    db, err := database.InitPostgreSQL()
    if err != nil {
        log.Fatalf("Failed to connect to PostgreSQL: %v", err)
    }
    defer db.Close()
    
    mongodb, err := database.InitMongoDB()
    if err != nil {
        log.Fatalf("Failed to connect to MongoDB: %v", err)
    }
    defer mongodb.Disconnect(context.Background())
    
    redis, err := database.InitRedis()
    if err != nil {
        log.Fatalf("Failed to connect to Redis: %v", err)
    }
    defer redis.Close()
    
    // Initialize services
    userService := services.NewUserService(db, mongodb, redis)
    cloudService := services.NewCloudService(db, mongodb)
    
    // Initialize handlers
    userHandler := handlers.NewUserHandler(userService)
    cloudHandler := handlers.NewCloudHandler(cloudService)
    
    // Set up Gin router
    router := gin.Default()
    
    // Middleware
    router.Use(gin.Logger())
    router.Use(gin.Recovery())
    router.Use(corsMiddleware())
    
    // Health check endpoint
    router.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "status": "healthy",
            "timestamp": time.Now().UTC(),
            "version": "1.0.0",
        })
    })
    
    // API routes
    v1 := router.Group("/api/v1")
    {
        // User routes
        users := v1.Group("/users")
        {
            users.POST("/register", userHandler.Register)
            users.POST("/login", userHandler.Login)
            users.GET("/profile", userHandler.GetProfile)
            users.PUT("/profile", userHandler.UpdateProfile)
        }
        
        // Cloud service routes
        cloud := v1.Group("/cloud")
        {
            cloud.GET("/instances", cloudHandler.ListInstances)
            cloud.POST("/instances", cloudHandler.CreateInstance)
            cloud.DELETE("/instances/:id", cloudHandler.DeleteInstance)
            cloud.GET("/services", cloudHandler.ListServices)
        }
    }
    
    // Start server
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    
    srv := &http.Server{
        Addr:    ":" + port,
        Handler: router,
    }
    
    // Graceful shutdown
    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()
    
    log.Printf("Server started on port %s", port)
    
    // Wait for interrupt signal to gracefully shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    log.Println("Shutting down server...")
    
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }
    
    log.Println("Server exited")
}

func corsMiddleware() gin.HandlerFunc {
    return gin.HandlerFunc(func(c *gin.Context) {
        c.Header("Access-Control-Allow-Origin", "*")
        c.Header("Access-Control-Allow-Credentials", "true")
        c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
        c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")
        
        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        
        c.Next()
    })
}
