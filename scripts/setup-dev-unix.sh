#!/bin/bash

# =============================================================================
# AddToCloud Development Environment Setup (Linux/macOS)
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    error "Unsupported OS: $OSTYPE"
fi

log "Setting up AddToCloud development environment for $OS..."

# Install package managers
install_package_managers() {
    if [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            log "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            log "✓ Homebrew already installed"
        fi
    elif [[ "$OS" == "linux" ]]; then
        log "✓ Using system package manager"
    fi
}

# Install Node.js and npm
install_nodejs() {
    if ! command -v node &> /dev/null; then
        log "Installing Node.js..."
        if [[ "$OS" == "macos" ]]; then
            brew install node
        elif [[ "$OS" == "linux" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    else
        log "✓ Node.js already installed ($(node --version))"
    fi
}

# Install Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        if [[ "$OS" == "macos" ]]; then
            brew install --cask docker
            warn "Please start Docker Desktop manually"
        elif [[ "$OS" == "linux" ]]; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            sudo usermod -aG docker $USER
            warn "Please log out and back in for Docker permissions to take effect"
        fi
    else
        log "✓ Docker already installed"
    fi
}

# Install Kubernetes tools
install_kubernetes_tools() {
    # kubectl
    if ! command -v kubectl &> /dev/null; then
        log "Installing kubectl..."
        if [[ "$OS" == "macos" ]]; then
            brew install kubectl
        elif [[ "$OS" == "linux" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
        fi
    else
        log "✓ kubectl already installed"
    fi

    # Helm
    if ! command -v helm &> /dev/null; then
        log "Installing Helm..."
        if [[ "$OS" == "macos" ]]; then
            brew install helm
        elif [[ "$OS" == "linux" ]]; then
            curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
            sudo apt-get update && sudo apt-get install helm
        fi
    else
        log "✓ Helm already installed"
    fi
}

# Install Terraform
install_terraform() {
    if ! command -v terraform &> /dev/null; then
        log "Installing Terraform..."
        if [[ "$OS" == "macos" ]]; then
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        elif [[ "$OS" == "linux" ]]; then
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install terraform
        fi
    else
        log "✓ Terraform already installed"
    fi
}

# Install Go
install_go() {
    if ! command -v go &> /dev/null; then
        log "Installing Go..."
        if [[ "$OS" == "macos" ]]; then
            brew install go
        elif [[ "$OS" == "linux" ]]; then
            GO_VERSION="1.21.0"
            wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
            sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
            rm "go${GO_VERSION}.linux-amd64.tar.gz"
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
        fi
    else
        log "✓ Go already installed ($(go version))"
    fi
}

# Install Wrangler (Cloudflare CLI)
install_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        log "Installing Wrangler..."
        npm install -g wrangler
    else
        log "✓ Wrangler already installed"
    fi
}

# Install cloud CLI tools
install_cloud_tools() {
    # Azure CLI
    if ! command -v az &> /dev/null; then
        log "Installing Azure CLI..."
        if [[ "$OS" == "macos" ]]; then
            brew install azure-cli
        elif [[ "$OS" == "linux" ]]; then
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        fi
    else
        log "✓ Azure CLI already installed"
    fi

    # AWS CLI
    if ! command -v aws &> /dev/null; then
        log "Installing AWS CLI..."
        if [[ "$OS" == "macos" ]]; then
            brew install awscli
        elif [[ "$OS" == "linux" ]]; then
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        fi
    else
        log "✓ AWS CLI already installed"
    fi

    # Google Cloud CLI
    if ! command -v gcloud &> /dev/null; then
        log "Installing Google Cloud CLI..."
        if [[ "$OS" == "macos" ]]; then
            brew install --cask google-cloud-sdk
        elif [[ "$OS" == "linux" ]]; then
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
        fi
    else
        log "✓ Google Cloud CLI already installed"
    fi
}

# Setup project dependencies
setup_project() {
    log "Setting up project dependencies..."
    
    # Install root dependencies
    npm install
    
    # Install frontend dependencies
    cd frontend && npm install && cd ..
    
    # Install Go dependencies
    cd backend && go mod download && cd ..
    
    log "✓ Project dependencies installed"
}

# Create environment files
setup_environment() {
    log "Setting up environment files..."
    
    if [[ ! -f .env ]]; then
        cp .env.example .env 2>/dev/null || true
        warn "Please update .env file with your actual values"
    fi
    
    if [[ ! -f infrastructure/terraform/terraform.tfvars ]]; then
        cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars 2>/dev/null || true
        warn "Please update terraform.tfvars with your cloud credentials"
    fi
    
    log "✓ Environment files created"
}

# Main installation
main() {
    log "🚀 Starting AddToCloud development environment setup..."
    
    install_package_managers
    install_nodejs
    install_docker
    install_kubernetes_tools
    install_terraform
    install_go
    install_wrangler
    install_cloud_tools
    setup_project
    setup_environment
    
    log "🎉 Development environment setup complete!"
    
    echo ""
    log "📋 Next steps:"
    echo "1. Update .env file with your configuration"
    echo "2. Update infrastructure/terraform/terraform.tfvars with cloud credentials"
    echo "3. Run 'npm run dev' to start development servers"
    echo "4. Run 'npm run deploy' to deploy to production"
    
    echo ""
    log "🔧 Useful commands:"
    echo "  npm run dev                    # Start development servers"
    echo "  npm run build                  # Build for production"
    echo "  npm run deploy                 # Deploy everything"
    echo "  npm run deploy:frontend        # Deploy only frontend"
    echo "  npm run cloudflare:setup       # Setup Cloudflare Pages"
    
    if [[ "$OS" == "linux" ]]; then
        warn "Please log out and back in for Docker permissions to take effect"
    fi
}

main "$@"
