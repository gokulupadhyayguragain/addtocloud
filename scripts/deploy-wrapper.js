#!/usr/bin/env node

/**
 * AddToCloud Deployment Wrapper
 * Cross-platform deployment script that calls appropriate shell scripts
 */

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');

// Configuration
const ENVIRONMENT = process.env.ENVIRONMENT || 'production';
const DEPLOY_FRONTEND = process.env.DEPLOY_FRONTEND !== 'false';
const DEPLOY_BACKEND = process.env.DEPLOY_BACKEND !== 'false';
const SKIP_AZURE = process.env.SKIP_AZURE === 'true';
const SKIP_AWS = process.env.SKIP_AWS === 'true';
const SKIP_GCP = process.env.SKIP_GCP === 'true';

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m'
};

function log(message, color = colors.green) {
    console.log(`${color}[${new Date().toISOString()}]${colors.reset} ${message}`);
}

function error(message) {
    console.error(`${colors.red}[ERROR]${colors.reset} ${message}`);
    process.exit(1);
}

function info(message) {
    console.log(`${colors.blue}[INFO]${colors.reset} ${message}`);
}

function warn(message) {
    console.log(`${colors.yellow}[WARNING]${colors.reset} ${message}`);
}

function success(message) {
    console.log(`${colors.cyan}[SUCCESS]${colors.reset} ${message}`);
}

// Determine the correct script to run based on the platform
function getDeploymentScript() {
    const isWindows = os.platform() === 'win32';
    const scriptsDir = path.join(__dirname, '..');
    
    if (isWindows) {
        return {
            command: 'powershell',
            args: [
                '-ExecutionPolicy', 'Bypass',
                '-File', path.join(scriptsDir, 'scripts', 'deploy-cloudflare.ps1')
            ]
        };
    } else {
        return {
            command: 'bash',
            args: [path.join(scriptsDir, 'scripts', 'deploy-cloudflare.sh')]
        };
    }
}

// Build command line arguments
function buildArguments() {
    const args = [];
    
    if (!DEPLOY_FRONTEND && DEPLOY_BACKEND) {
        args.push(os.platform() === 'win32' ? '-BackendOnly' : '--backend-only');
    } else if (DEPLOY_FRONTEND && !DEPLOY_BACKEND) {
        args.push(os.platform() === 'win32' ? '-FrontendOnly' : '--frontend-only');
    }
    
    if (SKIP_AZURE) {
        args.push(os.platform() === 'win32' ? '-SkipAzure' : '--skip-azure');
    }
    
    if (SKIP_AWS) {
        args.push(os.platform() === 'win32' ? '-SkipAWS' : '--skip-aws');
    }
    
    if (SKIP_GCP) {
        args.push(os.platform() === 'win32' ? '-SkipGCP' : '--skip-gcp');
    }
    
    if (ENVIRONMENT !== 'production') {
        if (os.platform() === 'win32') {
            args.push('-Environment', ENVIRONMENT);
        } else {
            args.push('--environment', ENVIRONMENT);
        }
    }
    
    return args;
}

// Execute the deployment script
function executeDeployment() {
    log('🚀 Starting AddToCloud deployment...');
    info(`Platform: ${os.platform()}`);
    info(`Environment: ${ENVIRONMENT}`);
    info(`Frontend: ${DEPLOY_FRONTEND}`);
    info(`Backend: ${DEPLOY_BACKEND}`);
    
    const script = getDeploymentScript();
    const args = [...script.args, ...buildArguments()];
    
    info(`Executing: ${script.command} ${args.join(' ')}`);
    
    const child = spawn(script.command, args, {
        stdio: 'inherit',
        shell: true,
        env: {
            ...process.env,
            ENVIRONMENT,
            DEPLOY_FRONTEND: DEPLOY_FRONTEND.toString(),
            DEPLOY_BACKEND: DEPLOY_BACKEND.toString(),
            DEPLOY_AZURE: (!SKIP_AZURE).toString(),
            DEPLOY_AWS: (!SKIP_AWS).toString(),
            DEPLOY_GCP: (!SKIP_GCP).toString()
        }
    });
    
    child.on('close', (code) => {
        if (code === 0) {
            success('🎉 Deployment completed successfully!');
            
            // Show useful information
            console.log('\n' + colors.bright + '📋 Next Steps:' + colors.reset);
            console.log('1. Check your domain DNS settings');
            console.log('2. Verify SSL certificates');
            console.log('3. Test all application endpoints');
            console.log('4. Monitor deployment health');
            
            console.log('\n' + colors.bright + '🔧 Useful Commands:' + colors.reset);
            console.log('  kubectl get all -n addtocloud');
            console.log('  kubectl logs -f deployment/addtocloud-backend -n addtocloud');
            console.log('  wrangler pages deployment list --project-name addtocloud-frontend');
            
            console.log('\n' + colors.bright + '🌐 URLs:' + colors.reset);
            switch (ENVIRONMENT) {
                case 'production':
                    console.log('  Frontend: https://addtocloud.tech');
                    console.log('  API: https://api.addtocloud.tech');
                    break;
                case 'staging':
                    console.log('  Frontend: https://staging.addtocloud.tech');
                    console.log('  API: https://staging-api.addtocloud.tech');
                    break;
                default:
                    console.log('  Check Cloudflare Pages dashboard for URLs');
                    break;
            }
        } else {
            error(`Deployment failed with exit code ${code}`);
        }
    });
    
    child.on('error', (err) => {
        error(`Failed to start deployment script: ${err.message}`);
    });
}

// Handle command line arguments for help
if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log('AddToCloud Deployment Wrapper\n');
    console.log('Environment Variables:');
    console.log('  ENVIRONMENT        - Deployment environment (development|staging|production)');
    console.log('  DEPLOY_FRONTEND    - Deploy frontend to Cloudflare (true|false)');
    console.log('  DEPLOY_BACKEND     - Deploy backend to clouds (true|false)');
    console.log('  SKIP_AZURE         - Skip Azure deployment (true|false)');
    console.log('  SKIP_AWS           - Skip AWS deployment (true|false)');
    console.log('  SKIP_GCP           - Skip GCP deployment (true|false)');
    console.log('\nExamples:');
    console.log('  npm run deploy                                    # Deploy everything to production');
    console.log('  ENVIRONMENT=staging npm run deploy                # Deploy to staging');
    console.log('  DEPLOY_FRONTEND=true DEPLOY_BACKEND=false npm run deploy  # Frontend only');
    console.log('  SKIP_AZURE=true npm run deploy                    # Skip Azure deployment');
    process.exit(0);
}

// Check for required tools
function checkPrerequisites() {
    const requiredTools = ['node', 'npm'];
    
    if (DEPLOY_FRONTEND) {
        requiredTools.push('wrangler');
    }
    
    if (DEPLOY_BACKEND) {
        requiredTools.push('kubectl', 'terraform', 'docker');
    }
    
    const missingTools = [];
    
    for (const tool of requiredTools) {
        try {
            require('child_process').execSync(`${tool} --version`, { stdio: 'ignore' });
        } catch (err) {
            missingTools.push(tool);
        }
    }
    
    if (missingTools.length > 0) {
        error(`Missing required tools: ${missingTools.join(', ')}`);
    }
}

// Main execution
try {
    checkPrerequisites();
    executeDeployment();
} catch (err) {
    error(err.message);
}
