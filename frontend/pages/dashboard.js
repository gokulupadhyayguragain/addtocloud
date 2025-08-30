import { useState, useEffect } from 'react';
import Head from 'next/head';
import Link from 'next/link';

const API_BASE_URL = 'https://api.addtocloud.tech';

export default function Dashboard() {
  const [metrics, setMetrics] = useState({
    totalServices: 0,
    activeDeployments: 0,
    healthyNodes: 0,
    cpuUsage: 0,
    memoryUsage: 0,
    networkTraffic: 0
  });
  
  const [services, setServices] = useState([
    { name: 'API Gateway', status: 'healthy', uptime: '99.9%', location: 'AWS EKS' },
    { name: 'User Service', status: 'healthy', uptime: '99.8%', location: 'Azure AKS' },
    { name: 'Cloud Service', status: 'warning', uptime: '98.5%', location: 'GCP GKE' },
    { name: 'Database', status: 'healthy', uptime: '99.9%', location: 'Multi-Cloud' },
    { name: 'Monitoring', status: 'healthy', uptime: '99.7%', location: 'AWS EKS' },
    { name: 'Load Balancer', status: 'healthy', uptime: '99.9%', location: 'CloudFlare' }
  ]);

  const [deployments, setDeployments] = useState([
    { name: 'addtocloud-api-simple', replicas: '2/2', status: 'Running', cluster: 'AWS EKS' },
    { name: 'addtocloud-frontend', replicas: '3/3', status: 'Running', cluster: 'CloudFlare' },
    { name: 'postgresql-primary', replicas: '1/1', status: 'Running', cluster: 'AWS EKS' },
    { name: 'prometheus-server', replicas: '1/1', status: 'Running', cluster: 'AWS EKS' },
    { name: 'grafana', replicas: '1/1', status: 'Running', cluster: 'AWS EKS' },
    { name: 'istio-gateway', replicas: '2/2', status: 'Running', cluster: 'AWS EKS' }
  ]);

  useEffect(() => {
    // Simulate real-time metrics
    const interval = setInterval(() => {
      setMetrics({
        totalServices: 12,
        activeDeployments: 6,
        healthyNodes: 8,
        cpuUsage: Math.floor(Math.random() * 30) + 20,
        memoryUsage: Math.floor(Math.random() * 25) + 45,
        networkTraffic: Math.floor(Math.random() * 50) + 100
      });
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status) => {
    switch (status) {
      case 'healthy':
      case 'Running':
        return 'text-green-400 bg-green-500/20 border-green-500/30';
      case 'warning':
        return 'text-yellow-400 bg-yellow-500/20 border-yellow-500/30';
      case 'error':
        return 'text-red-400 bg-red-500/20 border-red-500/30';
      default:
        return 'text-gray-400 bg-gray-500/20 border-gray-500/30';
    }
  };

  return (
    <>
      <Head>
        <title>Dashboard - AddToCloud Enterprise Platform</title>
        <meta name="description" content="Cloud infrastructure dashboard and monitoring" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-blue-900 via-purple-900 to-indigo-900">
        {/* Header */}
        <header className="bg-black/30 backdrop-blur-sm border-b border-white/10">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between h-16">
              <div className="flex items-center">
                <Link href="/" className="text-2xl font-bold text-white">AddToCloud</Link>
              </div>
              <nav className="flex space-x-8">
                <Link href="/services" className="text-gray-300 hover:text-white transition-colors">
                  Services
                </Link>
                <Link href="/dashboard" className="text-white font-semibold">
                  Dashboard
                </Link>
                <Link href="/monitoring" className="text-gray-300 hover:text-white transition-colors">
                  Monitoring
                </Link>
              </nav>
            </div>
          </div>
        </header>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Page Title */}
          <div className="mb-8">
            <h1 className="text-4xl font-bold text-white mb-2">Infrastructure Dashboard</h1>
            <p className="text-gray-300">Real-time monitoring of your cloud infrastructure</p>
          </div>

          {/* Metrics Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-300 text-sm">Total Services</p>
                  <p className="text-3xl font-bold text-white">{metrics.totalServices}</p>
                </div>
                <div className="text-4xl">🏗️</div>
              </div>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-300 text-sm">Active Deployments</p>
                  <p className="text-3xl font-bold text-white">{metrics.activeDeployments}</p>
                </div>
                <div className="text-4xl">🚀</div>
              </div>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-300 text-sm">Healthy Nodes</p>
                  <p className="text-3xl font-bold text-white">{metrics.healthyNodes}</p>
                </div>
                <div className="text-4xl">💚</div>
              </div>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-300 text-sm">CPU Usage</p>
                  <p className="text-3xl font-bold text-white">{metrics.cpuUsage}%</p>
                </div>
                <div className="text-4xl">⚡</div>
              </div>
              <div className="mt-3 bg-gray-700 rounded-full h-2">
                <div 
                  className="bg-blue-500 h-2 rounded-full transition-all duration-500"
                  style={{ width: `${metrics.cpuUsage}%` }}
                ></div>
              </div>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-300 text-sm">Memory Usage</p>
                  <p className="text-3xl font-bold text-white">{metrics.memoryUsage}%</p>
                </div>
                <div className="text-4xl">🧠</div>
              </div>
              <div className="mt-3 bg-gray-700 rounded-full h-2">
                <div 
                  className="bg-purple-500 h-2 rounded-full transition-all duration-500"
                  style={{ width: `${metrics.memoryUsage}%` }}
                ></div>
              </div>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-gray-300 text-sm">Network (MB/s)</p>
                  <p className="text-3xl font-bold text-white">{metrics.networkTraffic}</p>
                </div>
                <div className="text-4xl">🌐</div>
              </div>
            </div>
          </div>

          {/* Services Status */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-6">Service Health</h2>
              <div className="space-y-4">
                {services.map((service, index) => (
                  <div key={index} className="flex items-center justify-between p-4 bg-white/5 rounded-lg">
                    <div className="flex items-center space-x-4">
                      <div className={`w-3 h-3 rounded-full ${
                        service.status === 'healthy' ? 'bg-green-500' : 
                        service.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                      }`}></div>
                      <div>
                        <p className="text-white font-medium">{service.name}</p>
                        <p className="text-gray-400 text-sm">{service.location}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className={`text-sm px-3 py-1 rounded-full border ${getStatusColor(service.status)}`}>
                        {service.status}
                      </p>
                      <p className="text-gray-400 text-sm mt-1">{service.uptime}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Deployments */}
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-6">Active Deployments</h2>
              <div className="space-y-4">
                {deployments.map((deployment, index) => (
                  <div key={index} className="flex items-center justify-between p-4 bg-white/5 rounded-lg">
                    <div>
                      <p className="text-white font-medium">{deployment.name}</p>
                      <p className="text-gray-400 text-sm">{deployment.cluster}</p>
                    </div>
                    <div className="text-right">
                      <p className={`text-sm px-3 py-1 rounded-full border ${getStatusColor(deployment.status)}`}>
                        {deployment.status}
                      </p>
                      <p className="text-gray-400 text-sm mt-1">{deployment.replicas}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
            <h2 className="text-2xl font-bold text-white mb-6">Quick Actions</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Link href="/monitoring" className="bg-blue-500/20 hover:bg-blue-500/30 border border-blue-500/30 rounded-lg p-4 text-center transition-colors">
                <div className="text-3xl mb-2">📊</div>
                <p className="text-white font-medium">View Monitoring</p>
                <p className="text-gray-300 text-sm">Grafana & Prometheus</p>
              </Link>
              
              <button className="bg-green-500/20 hover:bg-green-500/30 border border-green-500/30 rounded-lg p-4 text-center transition-colors">
                <div className="text-3xl mb-2">🔄</div>
                <p className="text-white font-medium">Scale Services</p>
                <p className="text-gray-300 text-sm">Auto-scaling controls</p>
              </button>
              
              <button className="bg-purple-500/20 hover:bg-purple-500/30 border border-purple-500/30 rounded-lg p-4 text-center transition-colors">
                <div className="text-3xl mb-2">🚀</div>
                <p className="text-white font-medium">Deploy App</p>
                <p className="text-gray-300 text-sm">GitOps deployment</p>
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
