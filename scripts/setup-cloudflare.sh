#!/bin/bash

# Create Cloudflare Pages project script
echo "🚀 Setting up Cloudflare Pages project for AddToCloud Enterprise Platform"

# Check if wrangler is available
if ! command -v wrangler &> /dev/null; then
    echo "Installing wrangler CLI..."
    npm install -g wrangler
fi

# Create project if it doesn't exist
echo "Creating Cloudflare Pages project: addtocloud-enterprise"

# Create the project
wrangler pages project create addtocloud-enterprise \
    --production-branch main \
    --build-command "npm run build" \
    --build-output-directory "out" \
    --root-dir "frontend"

echo "✅ Cloudflare Pages project created successfully!"
echo "📋 Project Details:"
echo "   - Name: addtocloud-enterprise"
echo "   - Production Branch: main"
echo "   - Build Command: npm run build"
echo "   - Output Directory: out"
echo "   - Root Directory: frontend"

# Set environment variables
echo "🔧 Setting environment variables..."
wrangler pages secret put NEXT_PUBLIC_API_URL --env production
wrangler pages secret put NODE_ENV --env production

echo ""
echo "🌍 Your platform will be available at:"
echo "   https://addtocloud-enterprise.pages.dev"
echo ""
echo "🔗 Custom domain setup:"
echo "   1. Go to Cloudflare Dashboard"
echo "   2. Navigate to Pages > addtocloud-enterprise"
echo "   3. Click 'Custom domains'"
echo "   4. Add: addtocloud.tech"
echo ""
echo "✨ Setup complete! Ready for deployment."
