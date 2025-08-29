#!/bin/bash
# Cloudflare Pages build script for AddToCloud

echo "🚀 Starting AddToCloud Frontend Build for Cloudflare Pages..."

# Change to frontend directory
cd frontend

echo "📦 Installing dependencies..."
npm ci

echo "🏗️ Building Next.js application..."
npm run build

echo "✅ Build completed! Static files are ready in frontend/out/"
echo "📁 Contents of out directory:"
ls -la out/

echo "🌐 Ready for Cloudflare Pages deployment!"
