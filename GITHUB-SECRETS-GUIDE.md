# 🔐 GitHub Actions Secrets Configuration Guide

This guide explains how to configure all required secrets for the AddToCloud GitHub Actions deployment pipeline.

## 📋 Required Secrets

### 🌐 Cloudflare Configuration
```bash
# Get these from your Cloudflare dashboard
CLOUDFLARE_API_TOKEN=your-cloudflare-api-token
CLOUDFLARE_ACCOUNT_ID=your-cloudflare-account-id
CLOUDFLARE_ZONE_ID=your-domain-zone-id
```

**How to get Cloudflare credentials:**
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Create API Token with permissions:
   - Zone:Zone:Read
   - Zone:DNS:Edit
   - Account:Cloudflare Pages:Edit
3. Copy Account ID from the right sidebar of any domain
4. Copy Zone ID from the domain overview page

### ☁️ Azure Configuration
```bash
# Create Azure service principal
az ad sp create-for-rbac --name "addtocloud-github" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Use the output to set these secrets:
AZURE_CREDENTIALS='{"clientId":"xxx","clientSecret":"xxx","subscriptionId":"xxx","tenantId":"xxx"}'
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
AZURE_TENANT_ID=your-tenant-id
```

### 🟠 AWS Configuration
```bash
# Create IAM user with programmatic access
# Attach policies: PowerUserAccess or custom policy

AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
```

**Required AWS Permissions:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:*",
                "rds:*",
                "ecr:*",
                "s3:*",
                "cloudformation:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 🔴 Google Cloud Configuration
```bash
# Create service account with required roles
gcloud iam service-accounts create addtocloud-github --display-name="AddToCloud GitHub Actions"

# Grant permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:addtocloud-github@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create addtocloud-key.json \
    --iam-account=addtocloud-github@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Base64 encode the key for GitHub secret
base64 -w 0 addtocloud-key.json

# Set these secrets:
GCP_SA_KEY=base64-encoded-service-account-key
GCP_PROJECT_ID=your-gcp-project-id
GCP_REGION=us-central1
```

### 🗃️ Database Configuration
```bash
# Generate secure passwords
DATABASE_URL=postgres://addtocloud:SECURE_PASSWORD@your-db-host:5432/addtocloud
MONGODB_URI=mongodb://username:SECURE_PASSWORD@your-mongo-host:27017/addtocloud
REDIS_URL=redis://:SECURE_PASSWORD@your-redis-host:6379

# Database passwords (used by Kubernetes secrets)
POSTGRES_PASSWORD=your-secure-postgres-password
MONGODB_PASSWORD=your-secure-mongodb-password
REDIS_PASSWORD=your-secure-redis-password
```

### 🔐 Security Secrets
```bash
# Generate these with: openssl rand -hex 32
JWT_SECRET=your-super-secure-jwt-secret-64-characters-minimum
JWT_REFRESH_SECRET=your-refresh-token-secret-64-characters-minimum
SESSION_SECRET=your-session-secret-32-characters-minimum
ENCRYPTION_KEY=your-encryption-key-32-characters-minimum
API_SECRET_KEY=your-api-secret-key-32-characters-minimum

# CSRF and webhook secrets
CSRF_SECRET_KEY=your-csrf-secret-16-characters
WEBHOOK_SECRET=your-webhook-secret-32-characters
GITHUB_WEBHOOK_SECRET=your-github-webhook-secret
```

### 💳 Payment Integration
```bash
# Payoneer configuration
PAYONEER_API_KEY=your-payoneer-api-key
PAYONEER_SECRET=your-payoneer-secret
PAYONEER_ENVIRONMENT=production  # or sandbox

# Stripe configuration (if using)
STRIPE_SECRET_KEY=sk_live_your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=whsec_your-stripe-webhook-secret
```

### 📊 Monitoring and Notifications
```bash
# Slack notifications
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

# Email notifications
EMAIL_USERNAME=your-gmail-username
EMAIL_PASSWORD=your-gmail-app-password
NOTIFY_EMAIL=admin@addtocloud.tech
```

### 🐳 Container Registry Credentials
```bash
# Azure Container Registry
ACR_LOGIN_SERVER=your-registry.azurecr.io
ACR_USERNAME=your-acr-username
ACR_PASSWORD=your-acr-password

# Additional registry credentials are handled by cloud provider auth
```

## 🛠️ How to Add Secrets to GitHub

### Method 1: GitHub Web Interface
1. Go to your repository: `https://github.com/YOUR_USERNAME/addtocloud`
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add each secret name and value
5. Click **Add secret**

### Method 2: GitHub CLI
```bash
# Install GitHub CLI if not already installed
# https://cli.github.com/

# Login to GitHub
gh auth login

# Add secrets from a file
gh secret set -f secrets.env

# Add individual secrets
gh secret set CLOUDFLARE_API_TOKEN --body "your-token-here"
gh secret set AWS_ACCESS_KEY_ID --body "your-key-here"
# ... repeat for all secrets
```

### Method 3: Batch Import Script
Create a file called `secrets.env`:
```bash
CLOUDFLARE_API_TOKEN=your-token
CLOUDFLARE_ACCOUNT_ID=your-account-id
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
# ... add all your secrets
```

Then run:
```bash
# Make sure GitHub CLI is installed and authenticated
while IFS='=' read -r key value; do
    if [[ ! -z "$key" && ! "$key" =~ ^#.* ]]; then
        gh secret set "$key" --body "$value"
        echo "✓ Added secret: $key"
    fi
done < secrets.env
```

## 🎯 Environment-Specific Secrets

### Production Environment
All secrets listed above are required for production deployment.

### Staging Environment
You can use the same secrets as production, or create separate staging credentials:
- Use sandbox/test API keys for external services
- Use separate database instances
- Use different cloud projects/subscriptions

### Development Environment
For development, you can use:
- Local database URLs
- Test API keys
- Simplified authentication

## 🔒 Security Best Practices

### 1. Rotate Secrets Regularly
```bash
# Set up a schedule to rotate secrets every 90 days
# Update both GitHub secrets and actual service credentials
```

### 2. Use Least Privilege
- Grant minimum required permissions to service accounts
- Use separate credentials for different environments
- Regularly audit and remove unused permissions

### 3. Monitor Secret Usage
- Enable audit logging for secret access
- Set up alerts for failed authentication attempts
- Monitor deployment logs for credential issues

### 4. Backup and Recovery
```bash
# Keep encrypted backups of critical secrets
# Document secret recovery procedures
# Test secret rotation procedures regularly
```

## 🧪 Testing Your Configuration

### 1. Validate Secrets
```bash
# Test GitHub Actions workflow with a pull request
# Check workflow logs for authentication errors
# Verify each cloud provider connection
```

### 2. Manual Testing
```bash
# Test Cloudflare API
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_CLOUDFLARE_TOKEN"

# Test Azure authentication
az account show

# Test AWS authentication
aws sts get-caller-identity

# Test GCP authentication
gcloud auth list
```

### 3. Deployment Testing
```bash
# Run a staging deployment to verify all secrets work
# Test database connections
# Verify external service integrations
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Cloudflare Authentication Failed
- Verify API token has correct permissions
- Check token hasn't expired
- Ensure account ID and zone ID are correct

#### 2. Cloud Provider Authentication Failed
- Verify service account permissions
- Check credential format (JSON for GCP, etc.)
- Ensure subscriptions/projects are active

#### 3. Database Connection Failed
- Check database URLs and passwords
- Verify network connectivity
- Ensure databases are running and accessible

#### 4. GitHub Actions Workflow Failed
- Check secret names match exactly (case-sensitive)
- Verify all required secrets are set
- Check workflow syntax and permissions

### Getting Help
- Check GitHub Actions logs for specific error messages
- Verify cloud provider documentation for credential requirements
- Test credentials manually before adding to GitHub secrets

---

## 📋 Quick Setup Checklist

- [ ] Cloudflare API token and account/zone IDs
- [ ] Azure service principal credentials
- [ ] AWS IAM user credentials with required permissions
- [ ] GCP service account key (base64 encoded)
- [ ] Database connection strings and passwords
- [ ] JWT and encryption secrets (32+ characters each)
- [ ] Payment provider API keys
- [ ] Monitoring/notification webhooks
- [ ] All secrets added to GitHub repository settings
- [ ] Test deployment workflow with staging environment
- [ ] Verify production deployment works correctly

**🎉 Once all secrets are configured, your GitHub Actions will automatically deploy your AddToCloud platform to Cloudflare (frontend) and multi-cloud (backend) on every push to main!**
