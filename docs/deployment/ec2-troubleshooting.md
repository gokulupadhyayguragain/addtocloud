# EC2 Deployment Troubleshooting Guide

## Overview
This guide helps resolve common issues when deploying EC2 instances for the AddToCloud platform.

## Common Issues and Solutions

### 1. "cannot deploy ec2 instances" Error

#### Possible Causes:
- **AWS Credentials**: Missing or incorrect AWS credentials
- **Permissions**: Insufficient IAM permissions
- **Resource Limits**: AWS account limits reached
- **Region Issues**: Selected region doesn't support instance types
- **SSH Key**: Missing or invalid SSH public key

#### Solutions:

##### Check AWS Credentials
```powershell
# Verify AWS credentials are configured
aws sts get-caller-identity

# If not configured, run:
aws configure
```

##### Verify IAM Permissions
Your AWS user/role needs these permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "vpc:*",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:PassRole",
                "elasticloadbalancing:*"
            ],
            "Resource": "*"
        }
    ]
}
```

##### Check Account Limits
```bash
# Check EC2 instance limits
aws ec2 describe-account-attributes --attribute-names supported-platforms
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
```

##### Generate SSH Key Pair
```powershell
# Create SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/addtocloud-production-key

# Get public key content
Get-Content ~/.ssh/addtocloud-production-key.pub
```

### 2. Terraform Errors

#### "No declaration found for variable"
- **Cause**: Missing variable definitions
- **Solution**: Ensure all variables are defined in `variables.tf`

#### "Resource already exists"
- **Cause**: Resources from previous deployment still exist
- **Solution**: Either import existing resources or destroy them first

#### "Invalid CIDR block"
- **Cause**: Overlapping or invalid CIDR ranges
- **Solution**: Use non-overlapping private IP ranges

### 3. Instance Launch Failures

#### "Insufficient capacity"
- **Cause**: AWS doesn't have available capacity in the selected AZ
- **Solution**: Try different availability zones or instance types

#### "InvalidKeyPair.NotFound"
- **Cause**: SSH key pair not found in AWS
- **Solution**: Verify the key pair exists in the correct region

#### "UnauthorizedOperation"
- **Cause**: Insufficient permissions
- **Solution**: Check IAM policies and permissions

### 4. Network Issues

#### "Cannot reach instance"
- **Cause**: Security group blocking access
- **Solution**: Verify security group rules allow required ports

#### "Connection refused"
- **Cause**: Application not running or wrong port
- **Solution**: Check application status and port configuration

## Deployment Steps

### Step 1: Prerequisites
1. Install required tools:
   ```powershell
   # Install Terraform
   choco install terraform
   
   # Install AWS CLI
   choco install awscli
   ```

2. Configure AWS credentials:
   ```powershell
   aws configure
   ```

3. Generate SSH key pair:
   ```powershell
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/addtocloud-production-key
   ```

### Step 2: Configure Terraform Variables
1. Copy the example variables file:
   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and add your SSH public key:
   ```hcl
   ec2_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-public-key-content"
   ```

### Step 3: Deploy Infrastructure
1. Initialize Terraform:
   ```powershell
   terraform init
   ```

2. Plan the deployment:
   ```powershell
   terraform plan -var-file="terraform.tfvars"
   ```

3. Apply the configuration:
   ```powershell
   terraform apply -var-file="terraform.tfvars"
   ```

### Step 4: Deploy Application
1. SSH into the frontend instance:
   ```bash
   ssh -i ~/.ssh/addtocloud-production-key ec2-user@<frontend-ip>
   ```

2. Run the deployment script:
   ```bash
   ./deploy-addtocloud.sh
   ```

## Automated Deployment Script

Use the provided PowerShell script for automated deployment:

```powershell
# Plan deployment
.\scripts\deploy-ec2.ps1 -Action plan

# Deploy infrastructure
.\scripts\deploy-ec2.ps1 -Action apply

# Destroy infrastructure (when needed)
.\scripts\deploy-ec2.ps1 -Action destroy
```

## Monitoring and Logs

### Check Instance Status
```bash
# On EC2 instance
sudo systemctl status addtocloud-frontend
sudo systemctl status addtocloud-backend
sudo journalctl -u addtocloud-frontend -f
```

### CloudWatch Logs
- Navigate to CloudWatch in AWS Console
- Check logs under `/aws/ec2/addtocloud/`

### Application Logs
```bash
# Frontend logs
tail -f /opt/addtocloud/frontend/logs/app.log

# Backend logs
tail -f /opt/addtocloud/backend/logs/app.log
```

## Cost Optimization

### Instance Types by Use Case:
- **Development**: t3.micro ($0.0104/hour)
- **Staging**: t3.small ($0.0208/hour)
- **Production**: t3.medium ($0.0416/hour)

### Estimated Monthly Costs:
- Frontend (t3.small): ~$15/month
- Backend (t3.medium): ~$30/month
- Database (t3.medium): ~$30/month
- **Total**: ~$75/month

## Security Best Practices

1. **SSH Keys**: Use strong SSH keys and rotate regularly
2. **Security Groups**: Restrict access to necessary ports only
3. **Updates**: Keep instances updated with latest security patches
4. **Monitoring**: Enable CloudWatch monitoring and alerts
5. **Backup**: Regular EBS snapshots for data protection

## Support

If you continue to experience issues:

1. Check AWS Service Health Dashboard
2. Review Terraform logs for detailed error messages
3. Verify all prerequisites are met
4. Consider using AWS Support if available

## Quick Fixes

### Reset Terraform State
```powershell
# If Terraform state is corrupted
terraform init -reconfigure
terraform refresh
```

### Force Recreation
```powershell
# Force recreate specific resource
terraform taint aws_instance.frontend
terraform apply
```

### Emergency Access
```bash
# Use AWS Systems Manager Session Manager if SSH fails
aws ssm start-session --target <instance-id>
```
