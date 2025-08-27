package services

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
	"go.mongodb.org/mongo-driver/mongo"
)

type UserService struct {
	db    *sql.DB
	mongo *mongo.Client
	redis *redis.Client
}

type User struct {
	ID        string    `json:"id"`
	Email     string    `json:"email"`
	Username  string    `json:"username"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type CreateUserRequest struct {
	Email    string `json:"email"`
	Username string `json:"username"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func NewUserService(db *sql.DB, mongo *mongo.Client, redis *redis.Client) *UserService {
	return &UserService{
		db:    db,
		mongo: mongo,
		redis: redis,
	}
}

func (s *UserService) CreateUser(req CreateUserRequest) (*User, error) {
	// TODO: Hash password
	// TODO: Validate input
	// TODO: Check if user exists
	
	user := &User{
		ID:        generateID(),
		Email:     req.Email,
		Username:  req.Username,
		Name:      req.Name,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Insert into PostgreSQL
	query := `
		INSERT INTO users (id, email, username, name, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := s.db.Exec(query, user.ID, user.Email, user.Username, user.Name, user.CreatedAt, user.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

func (s *UserService) GetUserByID(id string) (*User, error) {
	// Try cache first
	cached, err := s.redis.Get(s.redis.Context(), fmt.Sprintf("user:%s", id)).Result()
	if err == nil {
		var user User
		if err := json.Unmarshal([]byte(cached), &user); err == nil {
			return &user, nil
		}
	}

	// Get from database
	query := `
		SELECT id, email, username, name, created_at, updated_at
		FROM users WHERE id = $1
	`
	
	user := &User{}
	err = s.db.QueryRow(query, id).Scan(
		&user.ID, &user.Email, &user.Username, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Cache the result
	userJSON, _ := json.Marshal(user)
	s.redis.Set(s.redis.Context(), fmt.Sprintf("user:%s", id), userJSON, 30*time.Minute)

	return user, nil
}

func (s *UserService) Login(req LoginRequest) (*User, error) {
	// TODO: Implement proper authentication
	// TODO: Verify password hash
	// TODO: Generate JWT token
	
	query := `
		SELECT id, email, username, name, created_at, updated_at
		FROM users WHERE email = $1
	`
	
	user := &User{}
	err := s.db.QueryRow(query, req.Email).Scan(
		&user.ID, &user.Email, &user.Username, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("invalid credentials")
		}
		return nil, fmt.Errorf("failed to login: %w", err)
	}

	return user, nil
}

func generateID() string {
	return fmt.Sprintf("user_%d", time.Now().UnixNano())
}
