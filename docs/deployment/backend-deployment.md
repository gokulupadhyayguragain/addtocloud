# 🚀 Backend Deployment Guide

## Quick Start - Deploy Backend API

Your AddToCloud backend needs to be deployed to make the website functional. Choose one of these deployment options:

## Option 1: AWS ECS (Recommended)
**Requirements**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ACCOUNT_ID`

1. Go to [GitHub Secrets](https://github.com/gokulupadhyayguragain/addtocloud/settings/secrets/actions)
2. Add the required AWS secrets
3. Trigger deployment: 
   ```bash
   gh workflow run deploy-backend-aws.yml
   ```

**Features**:
- ✅ Auto-scaling with AWS Fargate
- ✅ Managed infrastructure
- ✅ Health checks
- ✅ Production-ready

## Option 2: Azure Container Instances
**Requirements**: `AZURE_CREDENTIALS`

1. Create Azure service principal:
   ```bash
   az ad sp create-for-rbac --name "addtocloud-deployment" --role contributor \
     --scopes /subscriptions/{subscription-id} --sdk-auth
   ```
2. Add the JSON output to GitHub secret `AZURE_CREDENTIALS`
3. Run: `gh workflow run deploy-backend-azure.yml`

## Option 3: Google Cloud Run
**Requirements**: `GCP_PROJECT_ID`, `GCP_SA_KEY`

1. Create GCP service account with Cloud Run permissions
2. Download service account key (JSON)
3. Add to GitHub secrets
4. Run: `gh workflow run deploy-backend-gcp.yml`

## Option 4: Railway (Fastest)
**Requirements**: `RAILWAY_TOKEN`

1. Sign up at [Railway](https://railway.app)
2. Get API token from dashboard
3. Add to GitHub secrets as `RAILWAY_TOKEN`
4. Run: `gh workflow run deploy-backend-railway.yml`

## Manual Quick Deploy (2 minutes)

If you want to deploy immediately:

```bash
# 1. Install Railway CLI
npm install -g @railway/cli

# 2. Login and deploy
cd apps/backend
railway login
railway deploy

# 3. Get URL
railway domain
```

## After Deployment

Once your backend is deployed, you'll get an API endpoint like:
- AWS: `http://[task-ip]:8080`
- Azure: `http://addtocloud-api-[hash].eastus.azurecontainer.io:8080`  
- GCP: `https://addtocloud-api-[hash].a.run.app`
- Railway: `https://[project].railway.app`

## Update Frontend Configuration

1. Update the API endpoint in your deployment workflow:
   ```yaml
   env:
     NEXT_PUBLIC_API_URL: [YOUR_BACKEND_URL]
   ```

2. Redeploy frontend to Cloudflare Pages

## Test Your API

```bash
# Health check
curl [YOUR_BACKEND_URL]/health

# Get services
curl [YOUR_BACKEND_URL]/api/v1/cloud/services

# Test auth
curl -X POST [YOUR_BACKEND_URL]/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## Which Option Should You Choose?

- **Railway**: Fastest setup (1-2 minutes)
- **AWS**: Most production-ready, best for scaling
- **Azure**: Good enterprise integration
- **GCP**: Great for containers, global deployment

**Recommendation**: Start with Railway for immediate testing, then move to AWS for production.
