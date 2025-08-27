package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gokulupadhyayguragain/addtocloud/backend/internal/services"
)

type CloudHandler struct {
	cloudService *services.CloudService
}

func NewCloudHandler(cloudService *services.CloudService) *CloudHandler {
	return &CloudHandler{
		cloudService: cloudService,
	}
}

func (h *CloudHandler) ListInstances(c *gin.Context) {
	// TODO: Extract user ID from JWT token
	userID := c.GetHeader("X-User-ID") // Temporary for testing
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	instances, err := h.cloudService.ListInstances(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"instances": instances,
		"total":     len(instances),
	})
}

func (h *CloudHandler) CreateInstance(c *gin.Context) {
	// TODO: Extract user ID from JWT token
	userID := c.GetHeader("X-User-ID") // Temporary for testing
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req services.CreateInstanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	req.UserID = userID
	instance, err := h.cloudService.CreateInstance(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":  "Instance created successfully",
		"instance": instance,
	})
}

func (h *CloudHandler) DeleteInstance(c *gin.Context) {
	// TODO: Extract user ID from JWT token
	userID := c.GetHeader("X-User-ID") // Temporary for testing
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	instanceID := c.Param("id")
	if instanceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Instance ID is required"})
		return
	}

	err := h.cloudService.DeleteInstance(instanceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Instance deleted successfully",
	})
}

func (h *CloudHandler) ListServices(c *gin.Context) {
	services, err := h.cloudService.ListServices()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"services": services,
		"total":    len(services),
	})
}
