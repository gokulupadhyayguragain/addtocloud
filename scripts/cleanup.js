#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🧹 Cleaning up AddToCloud project...');

// Remove unnecessary files
const filesToRemove = [
  'frontend/.eslintrc.json',
  'frontend/.eslintrc.js', 
  'frontend/.eslintignore',
  'backend/cmd/main.exe',
  'backend/cmd/main-simple.go',
  'backend/cmd/main-simple-v2.go',
  'backend/cmd/main-stable.go'
];

filesToRemove.forEach(file => {
  const filePath = path.join(__dirname, '..', file);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
    console.log(`✅ Removed: ${file}`);
  }
});

// Create necessary directories
const dirsToCreate = [
  'frontend/components/ui',
  'frontend/lib',
  'frontend/utils',
  'frontend/hooks',
  'frontend/types',
  'frontend/tests',
  'backend/logs',
  'docs/api',
  'docs/deployment'
];

dirsToCreate.forEach(dir => {
  const dirPath = path.join(__dirname, '..', dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`✅ Created directory: ${dir}`);
  }
});

console.log('✨ Project cleanup completed!');
console.log('📋 Next steps:');
console.log('  1. cd frontend && npm install');
console.log('  2. npm run dev (frontend)');
console.log('  3. cd ../backend/cmd && go run main.go (backend)');
console.log('  4. Open http://localhost:3000');
