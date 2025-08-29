package models

import (
	"time"

	"gorm.io/gorm"
)

// AccessRequest represents a user's request for platform access
type AccessRequest struct {
	ID                 uint           `json:"id" gorm:"primaryKey"`
	FirstName          string         `json:"firstName" gorm:"not null"`
	LastName           string         `json:"lastName" gorm:"not null"`
	Email              string         `json:"email" gorm:"uniqueIndex;not null"`
	Phone              string         `json:"phone" gorm:"not null"`
	Company            string         `json:"company" gorm:"not null"`
	Address            string         `json:"address" gorm:"not null"`
	City               string         `json:"city" gorm:"not null"`
	Country            string         `json:"country" gorm:"not null"`
	BusinessReason     string         `json:"businessReason" gorm:"type:text;not null"`
	ProjectDescription string         `json:"projectDescription" gorm:"type:text"`
	Status             string         `json:"status" gorm:"default:'pending'"` // pending, approved, rejected
	ReviewedAt         *time.Time     `json:"reviewedAt"`
	ReviewedBy         string         `json:"reviewedBy"`
	ReviewNotes        string         `json:"reviewNotes" gorm:"type:text"`
	UserID             *uint          `json:"userId"` // Set when user account is created
	CreatedAt          time.Time      `json:"createdAt"`
	UpdatedAt          time.Time      `json:"updatedAt"`
	DeletedAt          gorm.DeletedAt `json:"-" gorm:"index"`
}

// TableName specifies the table name for AccessRequest
func (AccessRequest) TableName() string {
	return "access_requests"
}
