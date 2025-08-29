package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/gokulupadhyayguragain/addtocloud/backend/internal/models"
)

type AccessRequestHandler struct {
	db *gorm.DB
}

func NewAccessRequestHandler(db *gorm.DB) *AccessRequestHandler {
	return &AccessRequestHandler{db: db}
}

// SubmitAccessRequest handles new access requests
func (h *AccessRequestHandler) SubmitAccessRequest(c *gin.Context) {
	var req models.AccessRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request data",
			"details": err.Error(),
		})
		return
	}

	// Validate required fields
	if req.FirstName == "" || req.LastName == "" || req.Email == "" ||
		req.Phone == "" || req.Company == "" || req.Address == "" ||
		req.City == "" || req.Country == "" || req.BusinessReason == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "All required fields must be provided",
		})
		return
	}

	// Check if email already has a pending or approved request
	var existingRequest models.AccessRequest
	if err := h.db.Where("email = ? AND status IN ?", req.Email, []string{"pending", "approved"}).First(&existingRequest).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{
			"error":  "An access request with this email already exists",
			"status": existingRequest.Status,
		})
		return
	}

	// Set default status
	req.Status = "pending"

	// Create the access request
	if err := h.db.Create(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to submit access request",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":   "Access request submitted successfully",
		"requestId": req.ID,
		"status":    "pending",
	})
}

// GetAccessRequests returns all access requests (admin only)
func (h *AccessRequestHandler) GetAccessRequests(c *gin.Context) {
	var requests []models.AccessRequest

	if err := h.db.Find(&requests).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch access requests",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"requests": requests,
		"total":    len(requests),
	})
}

// ApproveAccessRequest approves an access request and creates user account
func (h *AccessRequestHandler) ApproveAccessRequest(c *gin.Context) {
	requestID := c.Param("id")

	var accessReq models.AccessRequest
	if err := h.db.First(&accessReq, requestID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Access request not found",
		})
		return
	}

	if accessReq.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":         "Access request is not pending",
			"currentStatus": accessReq.Status,
		})
		return
	}

	// Generate auto password (you'll need to implement this)
	autoPassword := generateSecurePassword()

	// Create user account
	user := models.User{
		FirstName: accessReq.FirstName,
		LastName:  accessReq.LastName,
		Email:     accessReq.Email,
		Phone:     accessReq.Phone,
		Company:   accessReq.Company,
		Address:   accessReq.Address,
		IsActive:  true,
	}

	// Set the auto-generated password (you'll need to hash it)
	if err := user.SetPassword(autoPassword); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to set user password",
		})
		return
	}

	// Start transaction
	tx := h.db.Begin()

	// Create user
	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to create user account",
		})
		return
	}

	// Update access request
	now := time.Now()
	accessReq.Status = "approved"
	accessReq.ReviewedAt = &now
	accessReq.UserID = &user.ID
	accessReq.ReviewNotes = "Account created and credentials generated"

	if err := tx.Save(&accessReq).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to update access request",
		})
		return
	}

	tx.Commit()

	c.JSON(http.StatusOK, gin.H{
		"message":           "Access request approved and user account created",
		"userId":            user.ID,
		"email":             user.Email,
		"temporaryPassword": autoPassword, // You should email this instead of returning it
	})
}

// RejectAccessRequest rejects an access request
func (h *AccessRequestHandler) RejectAccessRequest(c *gin.Context) {
	requestID := c.Param("id")

	var accessReq models.AccessRequest
	if err := h.db.First(&accessReq, requestID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Access request not found",
		})
		return
	}

	if accessReq.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":         "Access request is not pending",
			"currentStatus": accessReq.Status,
		})
		return
	}

	var requestBody struct {
		ReviewNotes string `json:"reviewNotes"`
	}

	if err := c.ShouldBindJSON(&requestBody); err == nil {
		accessReq.ReviewNotes = requestBody.ReviewNotes
	}

	now := time.Now()
	accessReq.Status = "rejected"
	accessReq.ReviewedAt = &now

	if err := h.db.Save(&accessReq).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to reject access request",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Access request rejected",
		"requestId": accessReq.ID,
	})
}

// Helper function to generate secure password
func generateSecurePassword() string {
	// Generate a secure random password
	// This is a simple implementation - you might want to use a more sophisticated approach
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	const length = 16

	password := make([]byte, length)
	for i := range password {
		password[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}

	return string(password)
}
