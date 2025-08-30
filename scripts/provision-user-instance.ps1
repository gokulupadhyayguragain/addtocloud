#!/usr/bin/env powershell

# AddToCloud Auto-Provisioning Script
# This script creates a free-tier EC2 instance for each approved user

param(
    [string]$UserEmail,
    [string]$UserName,
    [string]$InstanceName,
    [switch]$DryRun
)

Write-Host "🚀 AddToCloud Auto-Provisioning System" -ForegroundColor Cyan
Write-Host "User: $UserEmail" -ForegroundColor Yellow
Write-Host "Instance: $InstanceName" -ForegroundColor Yellow

# AWS Configuration
$Region = "us-west-2"
$InstanceType = "t2.micro"  # Free tier eligible
$ImageId = "ami-0c02fb55956c7d316"  # Amazon Linux 2 AMI
$KeyPairName = "$InstanceName-key"
$SecurityGroupName = "$InstanceName-sg"

if ($DryRun) {
    Write-Host "🧪 DRY RUN MODE - No actual resources will be created" -ForegroundColor Yellow
}

try {
    # Check AWS CLI installation
    $awsVersion = aws --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI not found. Please install AWS CLI first."
    }
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green

    # Check AWS credentials
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS Account: $($identity.Account)" -ForegroundColor Green

    if (!$DryRun) {
        # 1. Create Key Pair
        Write-Host "🔑 Creating SSH key pair..." -ForegroundColor Cyan
        $keyPairResult = aws ec2 create-key-pair --key-name $KeyPairName --query 'KeyMaterial' --output text --region $Region
        if ($LASTEXITCODE -eq 0) {
            # Save private key
            $keyPath = ".\keys\$KeyPairName.pem"
            New-Item -ItemType Directory -Force -Path ".\keys" | Out-Null
            $keyPairResult | Out-File -FilePath $keyPath -Encoding ASCII
            Write-Host "✅ Key pair created: $KeyPairName" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Key pair may already exist, continuing..." -ForegroundColor Yellow
        }

        # 2. Create Security Group
        Write-Host "🛡️ Creating security group..." -ForegroundColor Cyan
        $sgResult = aws ec2 create-security-group --group-name $SecurityGroupName --description "Security group for $UserEmail AddToCloud instance" --region $Region --output json | ConvertFrom-Json
        $SecurityGroupId = $sgResult.GroupId
        Write-Host "✅ Security group created: $SecurityGroupId" -ForegroundColor Green

        # 3. Configure Security Group Rules
        Write-Host "🔧 Configuring security group rules..." -ForegroundColor Cyan
        
        # SSH access
        aws ec2 authorize-security-group-ingress --group-id $SecurityGroupId --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $Region | Out-Null
        
        # HTTP access
        aws ec2 authorize-security-group-ingress --group-id $SecurityGroupId --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $Region | Out-Null
        
        # HTTPS access
        aws ec2 authorize-security-group-ingress --group-id $SecurityGroupId --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $Region | Out-Null
        
        # Custom application ports
        aws ec2 authorize-security-group-ingress --group-id $SecurityGroupId --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region $Region | Out-Null
        aws ec2 authorize-security-group-ingress --group-id $SecurityGroupId --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region $Region | Out-Null
        
        Write-Host "✅ Security group rules configured" -ForegroundColor Green

        # 4. Create User Data Script
        $UserDataScript = @"
#!/bin/bash

# Update system
yum update -y

# Install essential packages
yum install -y git curl wget unzip python3 pip nodejs npm docker

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Azure CLI
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
yum install -y azure-cli

# Install Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l \$SHELL
source /home/ec2-user/google-cloud-sdk/path.bash.inc
source /home/ec2-user/google-cloud-sdk/completion.bash.inc

# Install Kubernetes tools
curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm.tar.gz

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.5.0_linux_amd64.zip

# Create welcome message
cat > /home/ec2-user/welcome.txt << 'EOF'
🎉 Welcome to your AddToCloud instance!

This instance has been pre-configured with:
- AWS CLI (latest)
- Azure CLI (latest)
- Google Cloud CLI (latest)
- kubectl (Kubernetes CLI)
- Helm (Kubernetes package manager)
- Terraform (Infrastructure as Code)
- Docker (containerization)

User: $UserEmail
Instance: $InstanceName
Provisioned: \$(date)

To get started:
1. Configure your cloud credentials:
   - aws configure
   - az login
   - gcloud auth login

2. Verify installations:
   - aws --version
   - az --version
   - gcloud --version
   - kubectl version --client
   - terraform --version

3. Access AddToCloud dashboard:
   https://addtocloud.pages.dev/login

Happy cloud computing! 🚀
EOF

chown ec2-user:ec2-user /home/ec2-user/welcome.txt

# Create status file
echo "Instance provisioned successfully at \$(date)" > /var/log/addtocloud-provision.log
echo "User: $UserEmail" >> /var/log/addtocloud-provision.log
echo "All CLI tools installed and ready" >> /var/log/addtocloud-provision.log
"@

        $UserDataEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserDataScript))

        # 5. Launch EC2 Instance
        Write-Host "🚀 Launching EC2 instance..." -ForegroundColor Cyan
        $instanceResult = aws ec2 run-instances `
            --image-id $ImageId `
            --count 1 `
            --instance-type $InstanceType `
            --key-name $KeyPairName `
            --security-group-ids $SecurityGroupId `
            --user-data $UserDataEncoded `
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName},{Key=User,Value=$UserEmail},{Key=Purpose,Value=AddToCloud},{Key=AutoProvisioned,Value=true}]" `
            --region $Region `
            --output json | ConvertFrom-Json

        $InstanceId = $instanceResult.Instances[0].InstanceId
        Write-Host "✅ Instance launched: $InstanceId" -ForegroundColor Green

        # 6. Wait for instance to be running
        Write-Host "⏳ Waiting for instance to be running..." -ForegroundColor Cyan
        do {
            Start-Sleep -Seconds 10
            $instanceState = aws ec2 describe-instances --instance-ids $InstanceId --query 'Reservations[0].Instances[0].State.Name' --output text --region $Region
            Write-Host "Instance state: $instanceState" -ForegroundColor Yellow
        } while ($instanceState -ne "running")

        # 7. Get instance details
        $instanceDetails = aws ec2 describe-instances --instance-ids $InstanceId --region $Region --output json | ConvertFrom-Json
        $instance = $instanceDetails.Reservations[0].Instances[0]
        $PublicIp = $instance.PublicIpAddress
        $PrivateIp = $instance.PrivateIpAddress

        Write-Host "✅ Instance is running!" -ForegroundColor Green
        Write-Host "📍 Instance Details:" -ForegroundColor Cyan
        Write-Host "   Instance ID: $InstanceId" -ForegroundColor White
        Write-Host "   Public IP: $PublicIp" -ForegroundColor White
        Write-Host "   Private IP: $PrivateIp" -ForegroundColor White
        Write-Host "   Key Pair: $KeyPairName" -ForegroundColor White
        Write-Host "   Security Group: $SecurityGroupId" -ForegroundColor White

        # 8. Create connection script
        $sshScript = @"
#!/bin/bash
# SSH Connection script for $UserEmail
# Generated: $(Get-Date)

echo "🔗 Connecting to your AddToCloud instance..."
echo "Instance: $InstanceId"
echo "Public IP: $PublicIp"
echo ""

# Set correct permissions for key file
chmod 400 keys/$KeyPairName.pem

# Connect to instance
ssh -i keys/$KeyPairName.pem ec2-user@$PublicIp
"@

        $sshScript | Out-File -FilePath ".\connect-$InstanceName.sh" -Encoding UTF8
        Write-Host "✅ SSH script created: connect-$InstanceName.sh" -ForegroundColor Green

        # 9. Return instance details
        $result = @{
            instanceId = $InstanceId
            publicIp = $PublicIp
            privateIp = $PrivateIp
            instanceType = $InstanceType
            keyPairName = $KeyPairName
            securityGroupId = $SecurityGroupId
            region = $Region
            sshCommand = "ssh -i keys/$KeyPairName.pem ec2-user@$PublicIp"
            status = "running"
        }

        Write-Host "🎉 Auto-provisioning completed successfully!" -ForegroundColor Green
        Write-Host "📧 Send these details to user: $UserEmail" -ForegroundColor Cyan
        
        return $result | ConvertTo-Json -Depth 2
    } else {
        Write-Host "🧪 DRY RUN: Would create:" -ForegroundColor Yellow
        Write-Host "   - Key pair: $KeyPairName" -ForegroundColor Gray
        Write-Host "   - Security group: $SecurityGroupName" -ForegroundColor Gray
        Write-Host "   - EC2 instance: $InstanceType in $Region" -ForegroundColor Gray
        Write-Host "   - Pre-installed: AWS CLI, Azure CLI, GCP CLI, kubectl, Helm, Terraform, Docker" -ForegroundColor Gray
    }

} catch {
    Write-Host "❌ Auto-provisioning failed: $_" -ForegroundColor Red
    throw $_
}

# Usage examples:
# .\provision-user-instance.ps1 -UserEmail "user@company.com" -UserName "John Doe" -InstanceName "addtocloud-john-doe"
# .\provision-user-instance.ps1 -UserEmail "test@example.com" -UserName "Test User" -InstanceName "addtocloud-test" -DryRun
