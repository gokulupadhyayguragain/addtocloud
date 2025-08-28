#!/bin/bash

# AddToCloud Platform - Development Environment Setup Script
# Linux/WSL2 compatible setup script
# Author: GitHub Copilot for gokulupadhyayguragain

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version; then
            OS="wsl"
            log_info "Detected WSL2 environment"
        else
            OS="linux"
            log_info "Detected Linux environment"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS environment"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

install_prerequisites() {
    log_info "Installing prerequisites..."
    
    case $OS in
        "linux"|"wsl")
            # Update package manager
            sudo apt-get update
            
            # Install basic tools
            sudo apt-get install -y curl wget git unzip build-essential
            
            # Install Node.js 18
            if ! command -v node &> /dev/null; then
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
                log_success "Node.js installed"
            else
                log_success "Node.js already installed: $(node --version)"
            fi
            
            # Install Go 1.21
            if ! command -v go &> /dev/null; then
                wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
                sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
                echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
                export PATH=$PATH:/usr/local/go/bin
                rm go1.21.5.linux-amd64.tar.gz
                log_success "Go installed"
            else
                log_success "Go already installed: $(go version)"
            fi
            
            # Install Docker
            if ! command -v docker &> /dev/null; then
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
                log_success "Docker installed"
                log_warning "Please logout and login again for Docker group changes to take effect"
            else
                log_success "Docker already installed: $(docker --version)"
            fi
            ;;
        "macos")
            # Check if Homebrew is installed
            if ! command -v brew &> /dev/null; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Install packages
            brew install node go docker kubectl helm
            ;;
    esac
}

install_cloud_tools() {
    log_info "Installing cloud provider tools..."
    
    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        log_success "kubectl installed"
    else
        log_success "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'kubectl available')"
    fi
    
    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        log_success "Helm installed"
    else
        log_success "Helm already installed: $(helm version --short)"
    fi
    
    # Install AWS CLI
    if ! command -v aws &> /dev/null; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        log_success "AWS CLI installed"
    else
        log_success "AWS CLI already installed: $(aws --version)"
    fi
    
    # Install Azure CLI
    if ! command -v az &> /dev/null; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        log_success "Azure CLI installed"
    else
        log_success "Azure CLI already installed: $(az --version | head -n1)"
    fi
    
    # Install Google Cloud SDK
    if ! command -v gcloud &> /dev/null; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        sudo apt-get update && sudo apt-get install google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin
        log_success "Google Cloud SDK installed"
    else
        log_success "Google Cloud SDK already installed: $(gcloud --version | head -n1)"
    fi
}

setup_environment() {
    log_info "Setting up development environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env
        log_success "Created .env file from template"
        log_warning "Please update .env file with your actual credentials"
    else
        log_success ".env file already exists"
    fi
    
    # Setup Git hooks (if .git exists)
    if [ -d .git ]; then
        # Create pre-commit hook
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# AddToCloud pre-commit hook

echo "Running pre-commit checks..."

# Check for secrets in staged files
if git diff --cached --name-only | xargs grep -l "sk-\|pk_\|api_key\|secret_key\|password\|token" 2>/dev/null; then
    echo "ERROR: Potential secrets found in staged files!"
    echo "Please remove secrets before committing."
    exit 1
fi

# Run backend tests
if [ -d "backend" ]; then
    cd backend
    go test ./... -v
    if [ $? -ne 0 ]; then
        echo "Backend tests failed!"
        exit 1
    fi
    cd ..
fi

# Run frontend tests
if [ -d "frontend" ]; then
    cd frontend
    npm test -- --watchAll=false
    if [ $? -ne 0 ]; then
        echo "Frontend tests failed!"
        exit 1
    fi
    cd ..
fi

echo "All pre-commit checks passed!"
EOF
        chmod +x .git/hooks/pre-commit
        log_success "Git pre-commit hook installed"
    fi
}

install_dependencies() {
    log_info "Installing project dependencies..."
    
    # Backend dependencies
    if [ -d "backend" ]; then
        cd backend
        go mod tidy
        go mod download
        log_success "Backend dependencies installed"
        cd ..
    fi
    
    # Frontend dependencies
    if [ -d "frontend" ]; then
        cd frontend
        npm install
        log_success "Frontend dependencies installed"
        cd ..
    fi
}

build_project() {
    log_info "Building project..."
    
    # Build backend
    if [ -d "backend" ]; then
        cd backend/cmd
        go build -o ../addtocloud main.go
        log_success "Backend built successfully"
        cd ../..
    fi
    
    # Build frontend
    if [ -d "frontend" ]; then
        cd frontend
        npm run build
        log_success "Frontend built successfully"
        cd ..
    fi
}

start_services() {
    log_info "Starting development services..."
    
    # Start backend
    if [ -d "backend" ]; then
        cd backend/cmd
        echo "Starting backend on port 8080..."
        go run main.go &
        BACKEND_PID=$!
        echo $BACKEND_PID > ../../backend.pid
        cd ../..
        log_success "Backend started (PID: $BACKEND_PID)"
    fi
    
    # Wait a moment for backend to start
    sleep 2
    
    # Start frontend
    if [ -d "frontend" ]; then
        cd frontend
        echo "Starting frontend on port 3000..."
        npm run dev &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > ../frontend.pid
        cd ..
        log_success "Frontend started (PID: $FRONTEND_PID)"
    fi
    
    log_success "Development environment is ready!"
    log_info "Frontend: http://localhost:3000"
    log_info "Backend API: http://localhost:8080"
    log_info "Health Check: http://localhost:8080/health"
    
    echo ""
    log_info "To stop services, run: ./scripts/stop-dev.sh"
}

show_help() {
    echo "AddToCloud Development Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install    Install all prerequisites and dependencies"
    echo "  build      Build the project"
    echo "  start      Start development services"
    echo "  full       Run complete setup (install + build + start)"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 full      Complete development setup"
    echo "  $0 install   Install dependencies only"
    echo "  $0 start     Start services only"
}

main() {
    case "${1:-full}" in
        "install")
            detect_os
            install_prerequisites
            install_cloud_tools
            setup_environment
            install_dependencies
            ;;
        "build")
            build_project
            ;;
        "start")
            start_services
            ;;
        "full")
            detect_os
            install_prerequisites
            install_cloud_tools
            setup_environment
            install_dependencies
            build_project
            start_services
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"
