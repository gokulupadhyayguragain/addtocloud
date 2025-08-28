#!/usr/bin/env python3
"""
AddToCloud Platform - Advanced Deployment Automation
Python script for complex deployment scenarios and monitoring
Author: GitHub Copilot for gokulupadhyayguragain
Version: 2.0.0
"""

import os
import sys
import json
import yaml
import time
import logging
import argparse
import subprocess
import requests
from typing import Dict, List, Optional
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor, as_completed

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('deployment.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class CloudProvider:
    name: str
    cluster_name: str
    region: str
    context: str
    endpoint: Optional[str] = None

@dataclass
class DeploymentStatus:
    provider: str
    status: str
    message: str
    timestamp: str
    pods_running: int
    pods_total: int

class DeploymentManager:
    def __init__(self, config_file: str = "deployment-config.yaml"):
        self.config_file = config_file
        self.load_config()
        self.namespace = "addtocloud-prod"
        
    def load_config(self):
        """Load deployment configuration"""
        try:
            with open(self.config_file, 'r') as f:
                self.config = yaml.safe_load(f)
        except FileNotFoundError:
            logger.warning(f"Config file {self.config_file} not found, using defaults")
            self.config = self.get_default_config()
            self.save_config()
    
    def get_default_config(self) -> Dict:
        """Get default configuration"""
        return {
            'providers': {
                'aws': {
                    'cluster_name': 'addtocloud-eks',
                    'region': 'us-east-1',
                    'context': 'arn:aws:eks:us-east-1:ACCOUNT:cluster/addtocloud-eks'
                },
                'azure': {
                    'cluster_name': 'addtocloud-aks',
                    'region': 'eastus',
                    'context': 'addtocloud-aks',
                    'resource_group': 'addtocloud-rg'
                },
                'gcp': {
                    'cluster_name': 'addtocloud-gke',
                    'region': 'us-central1-a',
                    'context': 'gke_PROJECT_us-central1-a_addtocloud-gke',
                    'project_id': 'your-project-id'
                }
            },
            'deployment': {
                'namespace': 'addtocloud-prod',
                'replicas': {
                    'frontend': 3,
                    'backend': 3
                },
                'resources': {
                    'frontend': {
                        'requests': {'memory': '256Mi', 'cpu': '250m'},
                        'limits': {'memory': '512Mi', 'cpu': '500m'}
                    },
                    'backend': {
                        'requests': {'memory': '512Mi', 'cpu': '500m'},
                        'limits': {'memory': '1Gi', 'cpu': '1000m'}
                    }
                }
            },
            'monitoring': {
                'prometheus_enabled': True,
                'grafana_enabled': True,
                'alerts_enabled': True,
                'slack_webhook': os.getenv('SLACK_WEBHOOK_URL', '')
            }
        }
    
    def save_config(self):
        """Save current configuration"""
        with open(self.config_file, 'w') as f:
            yaml.dump(self.config, f, default_flow_style=False)
    
    def run_command(self, command: List[str], cwd: str = None) -> subprocess.CompletedProcess:
        """Run shell command with error handling"""
        try:
            logger.info(f"Running command: {' '.join(command)}")
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                cwd=cwd,
                check=True
            )
            return result
        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {e}")
            logger.error(f"stdout: {e.stdout}")
            logger.error(f"stderr: {e.stderr}")
            raise
    
    def check_prerequisites(self) -> bool:
        """Check if all required tools are installed"""
        required_tools = ['kubectl', 'docker', 'helm']
        
        for tool in required_tools:
            try:
                self.run_command(['which', tool])
                logger.info(f"✓ {tool} is available")
            except subprocess.CalledProcessError:
                logger.error(f"✗ {tool} is not installed")
                return False
        
        return True
    
    def setup_kubeconfig(self, provider: str):
        """Setup kubectl context for specific cloud provider"""
        config = self.config['providers'][provider]
        
        if provider == 'aws':
            cmd = [
                'aws', 'eks', 'update-kubeconfig',
                '--region', config['region'],
                '--name', config['cluster_name']
            ]
        elif provider == 'azure':
            cmd = [
                'az', 'aks', 'get-credentials',
                '--resource-group', config['resource_group'],
                '--name', config['cluster_name']
            ]
        elif provider == 'gcp':
            cmd = [
                'gcloud', 'container', 'clusters', 'get-credentials',
                config['cluster_name'],
                '--zone', config['region'],
                '--project', config['project_id']
            ]
        else:
            raise ValueError(f"Unsupported provider: {provider}")
        
        self.run_command(cmd)
        logger.info(f"Kubeconfig updated for {provider}")
    
    def deploy_to_provider(self, provider: str) -> DeploymentStatus:
        """Deploy application to specific cloud provider"""
        try:
            logger.info(f"Starting deployment to {provider}")
            
            # Setup kubeconfig
            self.setup_kubeconfig(provider)
            
            # Create namespace
            self.run_command([
                'kubectl', 'create', 'namespace', self.namespace,
                '--dry-run=client', '-o', 'yaml'
            ])
            self.run_command(['kubectl', 'apply', '-f', '-'], input=f'''
apiVersion: v1
kind: Namespace
metadata:
  name: {self.namespace}
  labels:
    istio-injection: enabled
''')
            
            # Apply deployments
            self.run_command([
                'kubectl', 'apply', '-f', 'infrastructure/kubernetes/deployments/',
                '-n', self.namespace
            ])
            
            # Apply services
            self.run_command([
                'kubectl', 'apply', '-f', 'infrastructure/kubernetes/services/',
                '-n', self.namespace
            ])
            
            # Wait for rollout
            deployments = ['frontend', 'backend']
            for deployment in deployments:
                self.run_command([
                    'kubectl', 'rollout', 'status',
                    f'deployment/{deployment}',
                    '-n', self.namespace,
                    '--timeout=300s'
                ])
            
            # Get deployment status
            status = self.get_deployment_status(provider)
            logger.info(f"Successfully deployed to {provider}")
            
            return status
            
        except Exception as e:
            logger.error(f"Deployment to {provider} failed: {e}")
            return DeploymentStatus(
                provider=provider,
                status="failed",
                message=str(e),
                timestamp=time.strftime("%Y-%m-%d %H:%M:%S"),
                pods_running=0,
                pods_total=0
            )
    
    def get_deployment_status(self, provider: str) -> DeploymentStatus:
        """Get current deployment status"""
        try:
            # Get pod status
            result = self.run_command([
                'kubectl', 'get', 'pods',
                '-n', self.namespace,
                '-o', 'json'
            ])
            
            pods_data = json.loads(result.stdout)
            pods_total = len(pods_data['items'])
            pods_running = sum(1 for pod in pods_data['items'] 
                             if pod['status']['phase'] == 'Running')
            
            status = "healthy" if pods_running == pods_total else "degraded"
            
            return DeploymentStatus(
                provider=provider,
                status=status,
                message=f"{pods_running}/{pods_total} pods running",
                timestamp=time.strftime("%Y-%m-%d %H:%M:%S"),
                pods_running=pods_running,
                pods_total=pods_total
            )
            
        except Exception as e:
            return DeploymentStatus(
                provider=provider,
                status="unknown",
                message=f"Failed to get status: {e}",
                timestamp=time.strftime("%Y-%m-%d %H:%M:%S"),
                pods_running=0,
                pods_total=0
            )
    
    def deploy_all_providers(self) -> List[DeploymentStatus]:
        """Deploy to all configured cloud providers in parallel"""
        providers = list(self.config['providers'].keys())
        results = []
        
        with ThreadPoolExecutor(max_workers=3) as executor:
            future_to_provider = {
                executor.submit(self.deploy_to_provider, provider): provider
                for provider in providers
            }
            
            for future in as_completed(future_to_provider):
                provider = future_to_provider[future]
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    logger.error(f"Deployment to {provider} failed: {e}")
                    results.append(DeploymentStatus(
                        provider=provider,
                        status="failed",
                        message=str(e),
                        timestamp=time.strftime("%Y-%m-%d %H:%M:%S"),
                        pods_running=0,
                        pods_total=0
                    ))
        
        return results
    
    def health_check(self, provider: str) -> bool:
        """Perform health check on deployed services"""
        try:
            # Port forward to test locally
            frontend_port = "3000"
            backend_port = "8080"
            
            # Test frontend
            response = requests.get(f"http://localhost:{frontend_port}", timeout=10)
            if response.status_code != 200:
                return False
            
            # Test backend health endpoint
            response = requests.get(f"http://localhost:{backend_port}/health", timeout=10)
            if response.status_code != 200:
                return False
            
            # Test API endpoints
            response = requests.get(f"http://localhost:{backend_port}/api/v1/services", timeout=10)
            if response.status_code != 200:
                return False
            
            logger.info(f"Health check passed for {provider}")
            return True
            
        except Exception as e:
            logger.error(f"Health check failed for {provider}: {e}")
            return False
    
    def setup_monitoring(self):
        """Setup monitoring stack"""
        logger.info("Setting up monitoring...")
        
        # Apply Prometheus configuration
        self.run_command([
            'kubectl', 'apply', '-f', 'infrastructure/monitoring/prometheus/',
            '-n', self.namespace
        ])
        
        # Apply Grafana configuration
        self.run_command([
            'kubectl', 'apply', '-f', 'infrastructure/monitoring/grafana/',
            '-n', self.namespace
        ])
        
        logger.info("Monitoring setup completed")
    
    def generate_deployment_report(self, results: List[DeploymentStatus]) -> str:
        """Generate deployment report"""
        report = ["AddToCloud Platform Deployment Report"]
        report.append("=" * 50)
        report.append(f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        for result in results:
            report.append(f"Provider: {result.provider.upper()}")
            report.append(f"Status: {result.status}")
            report.append(f"Message: {result.message}")
            report.append(f"Pods: {result.pods_running}/{result.pods_total}")
            report.append(f"Timestamp: {result.timestamp}")
            report.append("-" * 30)
        
        # Overall status
        successful = sum(1 for r in results if r.status in ["healthy", "success"])
        total = len(results)
        
        report.append(f"Overall Success Rate: {successful}/{total} ({(successful/total)*100:.1f}%)")
        
        return "\n".join(report)
    
    def send_slack_notification(self, message: str):
        """Send notification to Slack"""
        webhook_url = self.config['monitoring'].get('slack_webhook')
        if not webhook_url:
            logger.warning("Slack webhook not configured")
            return
        
        payload = {
            "text": f"AddToCloud Deployment Update",
            "attachments": [{
                "color": "good" if "successful" in message.lower() else "danger",
                "text": message
            }]
        }
        
        try:
            response = requests.post(webhook_url, json=payload)
            response.raise_for_status()
            logger.info("Slack notification sent")
        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}")

def main():
    parser = argparse.ArgumentParser(description="AddToCloud Deployment Manager")
    parser.add_argument("command", choices=[
        "deploy", "status", "health", "monitor", "report", "config"
    ], help="Command to execute")
    parser.add_argument("--provider", choices=["aws", "azure", "gcp", "all"],
                       default="all", help="Cloud provider to target")
    parser.add_argument("--config", default="deployment-config.yaml",
                       help="Configuration file path")
    parser.add_argument("--dry-run", action="store_true",
                       help="Show what would be done without executing")
    
    args = parser.parse_args()
    
    manager = DeploymentManager(args.config)
    
    if not manager.check_prerequisites():
        logger.error("Prerequisites not met. Please install required tools.")
        sys.exit(1)
    
    if args.command == "deploy":
        if args.provider == "all":
            results = manager.deploy_all_providers()
        else:
            result = manager.deploy_to_provider(args.provider)
            results = [result]
        
        # Generate and display report
        report = manager.generate_deployment_report(results)
        print(report)
        
        # Send notification
        manager.send_slack_notification(report)
        
        # Save report
        with open(f"deployment-report-{int(time.time())}.txt", "w") as f:
            f.write(report)
    
    elif args.command == "status":
        providers = [args.provider] if args.provider != "all" else ["aws", "azure", "gcp"]
        
        for provider in providers:
            try:
                status = manager.get_deployment_status(provider)
                print(f"{provider.upper()}: {status.status} - {status.message}")
            except Exception as e:
                print(f"{provider.upper()}: Error - {e}")
    
    elif args.command == "health":
        providers = [args.provider] if args.provider != "all" else ["aws", "azure", "gcp"]
        
        for provider in providers:
            is_healthy = manager.health_check(provider)
            status = "HEALTHY" if is_healthy else "UNHEALTHY"
            print(f"{provider.upper()}: {status}")
    
    elif args.command == "monitor":
        manager.setup_monitoring()
        print("Monitoring stack deployed successfully")
    
    elif args.command == "config":
        print("Current configuration:")
        print(yaml.dump(manager.config, default_flow_style=False))

if __name__ == "__main__":
    main()
