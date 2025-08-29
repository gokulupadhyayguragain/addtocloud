package services

import (
	"database/sql"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
)

type CloudService struct {
	db    *sql.DB
	mongo *mongo.Client
}

type Instance struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Type        string    `json:"type"`
	Status      string    `json:"status"`
	Provider    string    `json:"provider"`
	Region      string    `json:"region"`
	CPU         int       `json:"cpu"`
	Memory      int       `json:"memory"`
	Storage     int       `json:"storage"`
	UserID      string    `json:"user_id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type CreateInstanceRequest struct {
	Name     string `json:"name"`
	Type     string `json:"type"`
	Provider string `json:"provider"`
	Region   string `json:"region"`
	CPU      int    `json:"cpu"`
	Memory   int    `json:"memory"`
	Storage  int    `json:"storage"`
	UserID   string `json:"user_id"`
}

type Service struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Type        string    `json:"type"`
	Status      string    `json:"status"`
	Description string    `json:"description"`
	Category    string    `json:"category"`
	CreatedAt   time.Time `json:"created_at"`
}

func NewCloudService(db *sql.DB, mongo *mongo.Client) *CloudService {
	return &CloudService{
		db:    db,
		mongo: mongo,
	}
}

func (s *CloudService) CreateInstance(req CreateInstanceRequest) (*Instance, error) {
	instance := &Instance{
		ID:        generateInstanceID(),
		Name:      req.Name,
		Type:      req.Type,
		Status:    "creating",
		Provider:  req.Provider,
		Region:    req.Region,
		CPU:       req.CPU,
		Memory:    req.Memory,
		Storage:   req.Storage,
		UserID:    req.UserID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	query := `
		INSERT INTO instances (id, name, type, status, provider, region, cpu, memory, storage, user_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	
	_, err := s.db.Exec(query, instance.ID, instance.Name, instance.Type, instance.Status,
		instance.Provider, instance.Region, instance.CPU, instance.Memory, instance.Storage,
		instance.UserID, instance.CreatedAt, instance.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create instance: %w", err)
	}

	// TODO: Actually provision the instance in the cloud provider
	go s.provisionInstance(instance)

	return instance, nil
}

func (s *CloudService) ListInstances(userID string) ([]*Instance, error) {
	query := `
		SELECT id, name, type, status, provider, region, cpu, memory, storage, user_id, created_at, updated_at
		FROM instances WHERE user_id = $1 ORDER BY created_at DESC
	`
	
	rows, err := s.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list instances: %w", err)
	}
	defer rows.Close()

	var instances []*Instance
	for rows.Next() {
		instance := &Instance{}
		err := rows.Scan(&instance.ID, &instance.Name, &instance.Type, &instance.Status,
			&instance.Provider, &instance.Region, &instance.CPU, &instance.Memory,
			&instance.Storage, &instance.UserID, &instance.CreatedAt, &instance.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan instance: %w", err)
		}
		instances = append(instances, instance)
	}

	return instances, nil
}

func (s *CloudService) DeleteInstance(id string, userID string) error {
	query := `DELETE FROM instances WHERE id = $1 AND user_id = $2`
	result, err := s.db.Exec(query, id, userID)
	if err != nil {
		return fmt.Errorf("failed to delete instance: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("instance not found or unauthorized")
	}

	// TODO: Actually delete the instance from the cloud provider
	go s.destroyInstance(id)

	return nil
}

func (s *CloudService) ListServices() ([]*Service, error) {
	services := []*Service{
		{
			ID:          "paas",
			Name:        "Platform as a Service",
			Type:        "PaaS",
			Status:      "active",
			Description: "Deploy applications without managing infrastructure",
			Category:    "platform",
			CreatedAt:   time.Now(),
		},
		{
			ID:          "faas",
			Name:        "Function as a Service",
			Type:        "FaaS",
			Status:      "active",
			Description: "Serverless function execution platform",
			Category:    "compute",
			CreatedAt:   time.Now(),
		},
		{
			ID:          "iaas",
			Name:        "Infrastructure as a Service",
			Type:        "IaaS",
			Status:      "active",
			Description: "Virtual machines and networking resources",
			Category:    "infrastructure",
			CreatedAt:   time.Now(),
		},
		{
			ID:          "saas",
			Name:        "Software as a Service",
			Type:        "SaaS",
			Status:      "active",
			Description: "Ready-to-use business applications",
			Category:    "software",
			CreatedAt:   time.Now(),
		},
	}

	return services, nil
}

func (s *CloudService) provisionInstance(instance *Instance) {
	// Simulate provisioning delay
	time.Sleep(30 * time.Second)
	
	// Update status to running
	query := `UPDATE instances SET status = 'running', updated_at = $1 WHERE id = $2`
	s.db.Exec(query, time.Now(), instance.ID)
}

func (s *CloudService) destroyInstance(instanceID string) {
	// Simulate destruction delay
	time.Sleep(10 * time.Second)
	
	// Instance should already be deleted from database
	// This would handle cloud provider cleanup
}

func generateInstanceID() string {
	return fmt.Sprintf("inst_%d", time.Now().UnixNano())
}
