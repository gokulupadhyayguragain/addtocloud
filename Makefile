# AddToCloud Enterprise Platform Makefile
# Professional build and deployment automation

.PHONY: help build test clean deploy dev lint format security

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_REGISTRY ?= addtocloud
VERSION ?= $(shell git describe --tags --always --dirty)
ENVIRONMENT ?= dev
CLOUD_PROVIDER ?= all

# Colors for output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
RESET := \033[0m

##@ Help
help: ## Display this help
	@echo "$(GREEN)AddToCloud Enterprise Platform$(RESET)"
	@echo "$(BLUE)Available commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development
dev: ## Start development environment
	@echo "$(GREEN)Starting development environment...$(RESET)"
	docker-compose -f infrastructure/docker/compose/docker-compose.dev.yml up -d
	@echo "$(GREEN)✅ Development environment started$(RESET)"

dev-stop: ## Stop development environment
	@echo "$(YELLOW)Stopping development environment...$(RESET)"
	docker-compose -f infrastructure/docker/compose/docker-compose.dev.yml down
	@echo "$(GREEN)✅ Development environment stopped$(RESET)"

dev-logs: ## Show development logs
	docker-compose -f infrastructure/docker/compose/docker-compose.dev.yml logs -f

##@ Build
build: build-frontend build-backend ## Build all applications
	@echo "$(GREEN)✅ All applications built successfully$(RESET)"

build-frontend: ## Build frontend application
	@echo "$(GREEN)Building frontend...$(RESET)"
	cd apps/frontend && npm ci && npm run build
	@echo "$(GREEN)✅ Frontend built$(RESET)"

build-backend: ## Build backend application
	@echo "$(GREEN)Building backend...$(RESET)"
	cd apps/backend && go mod download && go build -o bin/server ./cmd/server
	@echo "$(GREEN)✅ Backend built$(RESET)"

build-docker: ## Build Docker images
	@echo "$(GREEN)Building Docker images...$(RESET)"
	docker build -t $(DOCKER_REGISTRY)/frontend:$(VERSION) -f apps/frontend/Dockerfile apps/frontend
	docker build -t $(DOCKER_REGISTRY)/backend:$(VERSION) -f apps/backend/Dockerfile apps/backend
	@echo "$(GREEN)✅ Docker images built$(RESET)"

##@ Testing
test: test-frontend test-backend ## Run all tests
	@echo "$(GREEN)✅ All tests completed$(RESET)"

test-frontend: ## Run frontend tests
	@echo "$(GREEN)Running frontend tests...$(RESET)"
	cd apps/frontend && npm test

test-backend: ## Run backend tests
	@echo "$(GREEN)Running backend tests...$(RESET)"
	cd apps/backend && go test ./...

test-integration: ## Run integration tests
	@echo "$(GREEN)Running integration tests...$(RESET)"
	cd tests/integration && go test -v ./...

test-e2e: ## Run end-to-end tests
	@echo "$(GREEN)Running e2e tests...$(RESET)"
	cd tests/e2e && npm test

##@ Code Quality
lint: lint-frontend lint-backend ## Run all linters
	@echo "$(GREEN)✅ All linting completed$(RESET)"

lint-frontend: ## Lint frontend code
	@echo "$(GREEN)Linting frontend...$(RESET)"
	cd apps/frontend && npm run lint

lint-backend: ## Lint backend code
	@echo "$(GREEN)Linting backend...$(RESET)"
	cd apps/backend && golangci-lint run

format: format-frontend format-backend ## Format all code
	@echo "$(GREEN)✅ All code formatted$(RESET)"

format-frontend: ## Format frontend code
	@echo "$(GREEN)Formatting frontend...$(RESET)"
	cd apps/frontend && npm run format

format-backend: ## Format backend code
	@echo "$(GREEN)Formatting backend...$(RESET)"
	cd apps/backend && go fmt ./...

##@ Security
security: ## Run security scans
	@echo "$(GREEN)Running security scans...$(RESET)"
	@echo "$(YELLOW)Scanning frontend dependencies...$(RESET)"
	cd apps/frontend && npm audit
	@echo "$(YELLOW)Scanning backend dependencies...$(RESET)"
	cd apps/backend && gosec ./...
	@echo "$(YELLOW)Scanning Docker images...$(RESET)"
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $(DOCKER_REGISTRY)/frontend:$(VERSION)
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $(DOCKER_REGISTRY)/backend:$(VERSION)
	@echo "$(GREEN)✅ Security scans completed$(RESET)"

##@ Infrastructure
infra-plan: ## Plan infrastructure changes
	@echo "$(GREEN)Planning infrastructure for $(ENVIRONMENT)...$(RESET)"
	cd infrastructure/terraform/environments/$(ENVIRONMENT) && terraform plan

infra-apply: ## Apply infrastructure changes
	@echo "$(GREEN)Applying infrastructure for $(ENVIRONMENT)...$(RESET)"
	cd infrastructure/terraform/environments/$(ENVIRONMENT) && terraform apply

infra-destroy: ## Destroy infrastructure
	@echo "$(RED)Destroying infrastructure for $(ENVIRONMENT)...$(RESET)"
	cd infrastructure/terraform/environments/$(ENVIRONMENT) && terraform destroy

##@ Kubernetes
k8s-deploy: ## Deploy to Kubernetes
	@echo "$(GREEN)Deploying to $(ENVIRONMENT) environment on $(CLOUD_PROVIDER)...$(RESET)"
	kubectl apply -k infrastructure/kubernetes/environments/$(ENVIRONMENT)
	@echo "$(GREEN)✅ Deployed to Kubernetes$(RESET)"

k8s-status: ## Check Kubernetes deployment status
	@echo "$(GREEN)Checking deployment status...$(RESET)"
	kubectl get pods -n addtocloud
	kubectl get services -n addtocloud
	kubectl get ingress -n addtocloud

k8s-logs: ## View application logs
	@echo "$(GREEN)Viewing application logs...$(RESET)"
	kubectl logs -n addtocloud -l app=addtocloud-backend --tail=100 -f

##@ Cloud Deployment
deploy-aws: ## Deploy to AWS EKS
	@echo "$(GREEN)Deploying to AWS EKS...$(RESET)"
	./infrastructure/scripts/deploy/deploy-aws.sh $(ENVIRONMENT)
	@echo "$(GREEN)✅ Deployed to AWS$(RESET)"

deploy-azure: ## Deploy to Azure AKS
	@echo "$(GREEN)Deploying to Azure AKS...$(RESET)"
	./infrastructure/scripts/deploy/deploy-azure.sh $(ENVIRONMENT)
	@echo "$(GREEN)✅ Deployed to Azure$(RESET)"

deploy-gcp: ## Deploy to GCP GKE
	@echo "$(GREEN)Deploying to GCP GKE...$(RESET)"
	./infrastructure/scripts/deploy/deploy-gcp.sh $(ENVIRONMENT)
	@echo "$(GREEN)✅ Deployed to GCP$(RESET)"

deploy-all: ## Deploy to all cloud providers
	@echo "$(GREEN)Deploying to all cloud providers...$(RESET)"
	$(MAKE) deploy-aws ENVIRONMENT=$(ENVIRONMENT)
	$(MAKE) deploy-azure ENVIRONMENT=$(ENVIRONMENT)
	$(MAKE) deploy-gcp ENVIRONMENT=$(ENVIRONMENT)
	@echo "$(GREEN)✅ Deployed to all clouds$(RESET)"

##@ Monitoring
monitor-setup: ## Setup monitoring stack
	@echo "$(GREEN)Setting up monitoring...$(RESET)"
	kubectl apply -k infrastructure/kubernetes/monitoring
	@echo "$(GREEN)✅ Monitoring setup completed$(RESET)"

monitor-status: ## Check monitoring status
	@echo "$(GREEN)Checking monitoring status...$(RESET)"
	kubectl get pods -n monitoring
	kubectl get services -n monitoring

##@ Database
db-migrate: ## Run database migrations
	@echo "$(GREEN)Running database migrations...$(RESET)"
	cd apps/backend && go run cmd/migrate/main.go

db-seed: ## Seed database with test data
	@echo "$(GREEN)Seeding database...$(RESET)"
	cd apps/backend && go run cmd/seed/main.go

##@ Cleanup
clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(RESET)"
	rm -rf apps/frontend/.next
	rm -rf apps/frontend/out
	rm -rf apps/backend/bin
	docker system prune -f
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

clean-all: clean ## Clean everything including node_modules
	@echo "$(GREEN)Deep cleaning...$(RESET)"
	rm -rf apps/frontend/node_modules
	rm -rf node_modules
	@echo "$(GREEN)✅ Deep cleanup completed$(RESET)"

##@ Utilities
version: ## Show version information
	@echo "$(GREEN)Version: $(VERSION)$(RESET)"
	@echo "$(GREEN)Git Commit: $(shell git rev-parse HEAD)$(RESET)"
	@echo "$(GREEN)Build Date: $(shell date)$(RESET)"

env: ## Show environment variables
	@echo "$(GREEN)Environment Variables:$(RESET)"
	@echo "ENVIRONMENT: $(ENVIRONMENT)"
	@echo "CLOUD_PROVIDER: $(CLOUD_PROVIDER)"
	@echo "DOCKER_REGISTRY: $(DOCKER_REGISTRY)"
	@echo "VERSION: $(VERSION)"

validate: ## Validate configurations
	@echo "$(GREEN)Validating configurations...$(RESET)"
	@echo "$(YELLOW)Validating Kubernetes manifests...$(RESET)"
	kubectl apply --dry-run=client -k infrastructure/kubernetes/environments/$(ENVIRONMENT)
	@echo "$(YELLOW)Validating Terraform configurations...$(RESET)"
	cd infrastructure/terraform/environments/$(ENVIRONMENT) && terraform validate
	@echo "$(GREEN)✅ All configurations valid$(RESET)"

##@ Quick Start
setup: ## Initial project setup
	@echo "$(GREEN)Setting up AddToCloud project...$(RESET)"
	@echo "$(YELLOW)Installing frontend dependencies...$(RESET)"
	cd apps/frontend && npm install
	@echo "$(YELLOW)Installing backend dependencies...$(RESET)"
	cd apps/backend && go mod download
	@echo "$(YELLOW)Setting up pre-commit hooks...$(RESET)"
	cp tools/scripts/pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
	@echo "$(GREEN)✅ Project setup completed$(RESET)"
	@echo "$(BLUE)Next steps:$(RESET)"
	@echo "  1. Copy .env.example to .env and configure"
	@echo "  2. Run 'make dev' to start development environment"
	@echo "  3. Run 'make test' to run tests"
	@echo "  4. Run 'make deploy-all' to deploy to all clouds"
