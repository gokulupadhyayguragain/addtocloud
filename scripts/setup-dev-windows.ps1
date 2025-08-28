# =============================================================================
# AddToCloud Development Environment Setup (Windows PowerShell)
# =============================================================================

param(
    [switch]$SkipChocolatey,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Colors
$Colors = @{
    Red = "Red"
    Green = "Green" 
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
}

function Write-Log { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor $Colors.Green }
function Write-Warning { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor $Colors.Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red; exit 1 }

function Show-Help {
    Write-Host "AddToCloud Development Environment Setup (Windows)" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\setup-dev-windows.ps1 [OPTIONS]" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "Options:" -ForegroundColor $Colors.Blue
    Write-Host "  -SkipChocolatey    Skip Chocolatey installation"
    Write-Host "  -Help              Show this help message"
    exit 0
}

function Test-CommandExists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Install-Chocolatey {
    if ($SkipChocolatey) {
        Write-Log "Skipping Chocolatey installation"
        return
    }
    
    if (-not (Test-CommandExists "choco")) {
        Write-Log "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        refreshenv
    } else {
        Write-Log "✓ Chocolatey already installed"
    }
}

function Install-Tools {
    Write-Log "Installing development tools..."
    
    $tools = @(
        "nodejs",
        "docker-desktop", 
        "kubernetes-cli",
        "terraform",
        "golang",
        "azure-cli",
        "awscli",
        "gcloudsdk",
        "git",
        "vscode"
    )
    
    foreach ($tool in $tools) {
        if ($tool -eq "nodejs") {
            if (-not (Test-CommandExists "node")) {
                Write-Log "Installing Node.js..."
                choco install nodejs -y
            } else {
                Write-Log "✓ Node.js already installed"
            }
        }
        elseif ($tool -eq "docker-desktop") {
            if (-not (Test-CommandExists "docker")) {
                Write-Log "Installing Docker Desktop..."
                choco install docker-desktop -y
                Write-Warning "Please start Docker Desktop manually"
            } else {
                Write-Log "✓ Docker already installed"
            }
        }
        elseif ($tool -eq "kubernetes-cli") {
            if (-not (Test-CommandExists "kubectl")) {
                Write-Log "Installing kubectl..."
                choco install kubernetes-cli -y
            } else {
                Write-Log "✓ kubectl already installed"
            }
        }
        elseif ($tool -eq "terraform") {
            if (-not (Test-CommandExists "terraform")) {
                Write-Log "Installing Terraform..."
                choco install terraform -y
            } else {
                Write-Log "✓ Terraform already installed"
            }
        }
        elseif ($tool -eq "golang") {
            if (-not (Test-CommandExists "go")) {
                Write-Log "Installing Go..."
                choco install golang -y
            } else {
                Write-Log "✓ Go already installed"
            }
        }
        elseif ($tool -eq "azure-cli") {
            if (-not (Test-CommandExists "az")) {
                Write-Log "Installing Azure CLI..."
                choco install azure-cli -y
            } else {
                Write-Log "✓ Azure CLI already installed"
            }
        }
        elseif ($tool -eq "awscli") {
            if (-not (Test-CommandExists "aws")) {
                Write-Log "Installing AWS CLI..."
                choco install awscli -y
            } else {
                Write-Log "✓ AWS CLI already installed"
            }
        }
        elseif ($tool -eq "gcloudsdk") {
            if (-not (Test-CommandExists "gcloud")) {
                Write-Log "Installing Google Cloud SDK..."
                choco install gcloudsdk -y
            } else {
                Write-Log "✓ Google Cloud SDK already installed"
            }
        }
        elseif ($tool -eq "git") {
            if (-not (Test-CommandExists "git")) {
                Write-Log "Installing Git..."
                choco install git -y
            } else {
                Write-Log "✓ Git already installed"
            }
        }
        elseif ($tool -eq "vscode") {
            if (-not (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe")) {
                Write-Log "Installing Visual Studio Code..."
                choco install vscode -y
            } else {
                Write-Log "✓ Visual Studio Code already installed"
            }
        }
    }
    
    # Refresh environment variables
    refreshenv
}

function Install-Wrangler {
    if (-not (Test-CommandExists "wrangler")) {
        Write-Log "Installing Wrangler (Cloudflare CLI)..."
        npm install -g wrangler
    } else {
        Write-Log "✓ Wrangler already installed"
    }
}

function Install-Helm {
    if (-not (Test-CommandExists "helm")) {
        Write-Log "Installing Helm..."
        choco install kubernetes-helm -y
    } else {
        Write-Log "✓ Helm already installed"
    }
}

function Setup-Project {
    Write-Log "Setting up project dependencies..."
    
    try {
        # Install root dependencies
        Write-Log "Installing root dependencies..."
        npm install
        
        # Install frontend dependencies
        Write-Log "Installing frontend dependencies..."
        Push-Location "frontend"
        npm install
        Pop-Location
        
        # Install Go dependencies
        Write-Log "Installing Go dependencies..."
        Push-Location "backend"
        go mod download
        Pop-Location
        
        Write-Log "✓ Project dependencies installed"
    } catch {
        Write-ErrorMsg "Failed to install project dependencies: $($_.Exception.Message)"
    }
}

function Setup-Environment {
    Write-Log "Setting up environment files..."
    
    # Copy .env file if it doesn't exist
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Warning "Please update .env file with your actual values"
        }
    }
    
    # Copy terraform.tfvars if it doesn't exist
    $tfvarsPath = "infrastructure\terraform\terraform.tfvars"
    $tfvarsExamplePath = "infrastructure\terraform\terraform.tfvars.example"
    
    if (-not (Test-Path $tfvarsPath)) {
        if (Test-Path $tfvarsExamplePath) {
            Copy-Item $tfvarsExamplePath $tfvarsPath
            Write-Warning "Please update terraform.tfvars with your cloud credentials"
        }
    }
    
    Write-Log "✓ Environment files created"
}

function Test-Installation {
    Write-Log "Verifying installation..."
    
    $tools = @("node", "npm", "docker", "kubectl", "terraform", "go", "wrangler", "az", "aws", "gcloud")
    $missing = @()
    
    foreach ($tool in $tools) {
        if (Test-CommandExists $tool) {
            Write-Log "✓ $tool is available"
        } else {
            $missing += $tool
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Warning "Missing tools: $($missing -join ', ')"
        Write-Warning "You may need to restart your terminal or computer for some tools to be available"
    } else {
        Write-Log "✓ All tools installed successfully"
    }
}

function Main {
    if ($Help) {
        Show-Help
    }
    
    Write-Log "🚀 Starting AddToCloud development environment setup for Windows..."
    
    try {
        Install-Chocolatey
        Install-Tools
        Install-Wrangler
        Install-Helm
        Setup-Project
        Setup-Environment
        Test-Installation
        
        Write-Log "🎉 Development environment setup complete!"
        
        Write-Host ""
        Write-Log "📋 Next steps:"
        Write-Host "1. Update .env file with your configuration"
        Write-Host "2. Update infrastructure\terraform\terraform.tfvars with cloud credentials"
        Write-Host "3. Restart your terminal to ensure all tools are available"
        Write-Host "4. Run 'npm run dev' to start development servers"
        Write-Host "5. Run 'npm run deploy' to deploy to production"
        
        Write-Host ""
        Write-Log "🔧 Useful commands:"
        Write-Host "  npm run dev                    # Start development servers"
        Write-Host "  npm run build                  # Build for production"
        Write-Host "  npm run deploy                 # Deploy everything"
        Write-Host "  .\scripts\deploy-cloudflare.ps1 # Manual deployment script"
        Write-Host "  npm run cloudflare:setup       # Setup Cloudflare Pages"
        
        Write-Host ""
        Write-Warning "Important:"
        Write-Host "- Start Docker Desktop manually"
        Write-Host "- Restart your terminal for environment variables to take effect"
        Write-Host "- Configure cloud provider authentication before deploying"
        
    } catch {
        Write-ErrorMsg "Setup failed: $($_.Exception.Message)"
    }
}

# Run main function
Main
