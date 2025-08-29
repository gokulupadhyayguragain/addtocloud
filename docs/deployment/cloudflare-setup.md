# Cloudflare Pages Setup Guide

## Prerequisites
1. Install Wrangler CLI: `npm install -g wrangler`
2. Login to Cloudflare: `wrangler login`

## Create Cloudflare Pages Project

### Option 1: Using Wrangler CLI
```bash
# Navigate to frontend directory
cd apps/frontend

# Create the Pages project
wrangler pages project create addtocloud-tech

# Deploy manually (first time)
npm run build
wrangler pages deploy out --project-name=addtocloud-tech
```

### Option 2: Using Cloudflare Dashboard
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to Pages
3. Click "Create a project"
4. Connect to your GitHub repository: `gokulupadhyayguragain/addtocloud`
5. Configure build settings:
   - **Build command**: `cd apps/frontend && npm run build`
   - **Build output directory**: `apps/frontend/out`
   - **Node.js version**: `18`

## Environment Variables
Set these in Cloudflare Pages settings:
- `NEXT_PUBLIC_API_URL`: `https://api.addtocloud.tech`

## Custom Domain Setup
1. Add custom domain: `addtocloud.tech`
2. Configure DNS records in Cloudflare DNS:
   - `CNAME www addtocloud-tech.pages.dev`
   - `A @ 192.0.2.1` (or use CNAME flattening)

## GitHub Actions Integration
Once the project is created, update `.github/workflows/deploy.yml`:
1. Uncomment the Cloudflare Pages deployment section
2. Add these secrets to GitHub repository:
   - `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token
   - `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID

## Testing Deployment
```bash
# Test local build
npm run build

# Test local preview
wrangler pages dev out
```
