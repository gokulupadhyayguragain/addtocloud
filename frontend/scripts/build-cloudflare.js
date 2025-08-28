#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Building AddToCloud Frontend for Cloudflare Pages...');

// Step 1: Clean build
console.log('🧹 Cleaning previous build...');
if (fs.existsSync('out')) {
  fs.rmSync('out', { recursive: true, force: true });
}

// Step 2: Run Next.js build
console.log('⚡ Building with Next.js...');
execSync('npm run build', { stdio: 'inherit' });

// Step 3: Prepare static files for Cloudflare
console.log('📦 Preparing static files for Cloudflare...');

// Copy HTML files from server/pages to root
const serverPagesDir = path.join('out', 'server', 'pages');
if (fs.existsSync(serverPagesDir)) {
  const files = fs.readdirSync(serverPagesDir);
  files.forEach(file => {
    const srcPath = path.join(serverPagesDir, file);
    const destPath = path.join('out', file);
    fs.copyFileSync(srcPath, destPath);
  });
}

// Create _next directory and copy static assets
const nextDir = path.join('out', '_next');
if (!fs.existsSync(nextDir)) {
  fs.mkdirSync(nextDir, { recursive: true });
}

const staticDir = path.join('out', 'static');
const nextStaticDir = path.join(nextDir, 'static');
if (fs.existsSync(staticDir)) {
  fs.cpSync(staticDir, nextStaticDir, { recursive: true });
}

// Step 4: Clean up unnecessary files
console.log('🧽 Cleaning up unnecessary files...');
const filesToRemove = [
  'server',
  'standalone',
  'cache',
  'trace',
  'next-minimal-server.js.nft.json',
  'next-server.js.nft.json',
  'required-server-files.json'
];

filesToRemove.forEach(file => {
  const filePath = path.join('out', file);
  if (fs.existsSync(filePath)) {
    fs.rmSync(filePath, { recursive: true, force: true });
  }
});

console.log('✅ Build completed! Ready for Cloudflare deployment.');
console.log('📁 Static files are in the "out" directory.');
console.log('🌐 Deploy with: npx wrangler pages deploy out');
