#!/bin/bash
# Manual Cloudflare Pages Deployment Script

echo "🚀 Starting manual Cloudflare Pages deployment..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this from the frontend directory."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm ci

# Build the project
echo "🔨 Building the project..."
export NEXT_PUBLIC_API_BASE_URL="https://api.addtocloud.tech"
export NEXT_PUBLIC_EKS_API="https://eks-api.addtocloud.tech"
export NEXT_PUBLIC_AKS_API="https://aks-api.addtocloud.tech"
export NEXT_PUBLIC_GKE_API="https://gke-api.addtocloud.tech"
export NEXT_PUBLIC_MONITORING_URL="https://addtocloud.tech/monitoring"
export NEXT_PUBLIC_GRAFANA_URL="https://addtocloud.tech/grafana"

npm run build

# Check if build was successful
if [ ! -d "out" ]; then
    echo "❌ Build failed - out directory not created"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 Output directory: $(pwd)/out"
echo "📋 Files in output:"
ls -la out/

# Deploy using Wrangler
echo "🌐 Deploying to Cloudflare Pages..."
npx wrangler pages deploy out --project-name addtocloud

echo "🎉 Deployment completed!"
echo "🔗 Site: https://addtocloud.tech"
