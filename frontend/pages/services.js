import { useState, useEffect } from 'react';
import Head from 'next/head';
import Link from 'next/link';
import { getAllServices } from '../lib/services';
import { useAuth } from '../context/AuthContext';
import ProtectedRoute from '../components/ProtectedRoute';

const API_BASE_URL = 'https://addtocloud-api-proxy.gocools.workers.dev';

function ServicesContent() {
  const { user, logout } = useAuth();
  const [services, setServices] = useState([]);
  const [filteredServices, setFilteredServices] = useState([]);
  const [selectedProvider, setSelectedProvider] = useState('all');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedService, setSelectedService] = useState(null);
  const [deploymentConfig, setDeploymentConfig] = useState({});
  const [isDeploying, setIsDeploying] = useState(false);

  useEffect(() => {
    const allServices = getAllServices();
    setServices(allServices);
    setFilteredServices(allServices);
  }, []);

  useEffect(() => {
    let filtered = services;

    if (selectedProvider !== 'all') {
      filtered = filtered.filter(service => service.provider.toLowerCase() === selectedProvider);
    }

    if (selectedCategory !== 'all') {
      filtered = filtered.filter(service => service.category === selectedCategory);
    }

    if (searchTerm) {
      filtered = filtered.filter(service => 
        service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        service.description.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredServices(filtered);
  }, [services, selectedProvider, selectedCategory, searchTerm]);

  const handleServiceSelect = (service) => {
    setSelectedService(service);
    setDeploymentConfig({
      name: '',
      region: 'us-west-2',
      instanceType: 't3.micro',
      environment: 'development'
    });
  };

  const handleDeploy = async () => {
    if (!selectedService) return;

    setIsDeploying(true);
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/deploy`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          service: selectedService,
          config: deploymentConfig
        })
      });

      if (response.ok) {
        const result = await response.json();
        alert(`✅ ${selectedService.name} deployed successfully!\nDeployment ID: ${result.deploymentId}`);
      } else {
        throw new Error('Deployment failed');
      }
    } catch (error) {
      console.error('Deployment error:', error);
      alert(`❌ Deployment failed: ${error.message}`);
    } finally {
      setIsDeploying(false);
    }
  };

  const providers = ['all', 'aws', 'azure', 'gcp', 'cloudflare', 'digitalocean', 'linode', 'vultr'];
  const categories = ['all', 'compute', 'storage', 'database', 'networking', 'ai', 'security', 'analytics'];

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <Head>
        <title>360+ Cloud Services | AddToCloud</title>
        <meta name="description" content="Deploy and manage 360+ cloud services across AWS, Azure, GCP, and more" />
      </Head>

      <nav className="bg-gray-800 p-4">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold text-blue-400">
            AddToCloud
          </Link>
          <div className="space-x-6">
            <Link href="/services" className="text-blue-400">Services</Link>
            <Link href="/dashboard" className="hover:text-blue-400">Dashboard</Link>
            <Link href="/monitoring" className="hover:text-blue-400">Monitoring</Link>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto p-6">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">🌐 360+ Cloud Services</h1>
          <p className="text-gray-300 text-lg">Deploy any cloud service with one-click automation across multiple providers</p>
        </div>

        {/* Filters */}
        <div className="bg-gray-800 p-6 rounded-lg mb-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Search Services</label>
              <input
                type="text"
                placeholder="Search services..."
                className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Provider</label>
              <select
                className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                value={selectedProvider}
                onChange={(e) => setSelectedProvider(e.target.value)}
              >
                {providers.map(provider => (
                  <option key={provider} value={provider}>
                    {provider === 'all' ? 'All Providers' : provider.toUpperCase()}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Category</label>
              <select
                className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
              >
                {categories.map(category => (
                  <option key={category} value={category}>
                    {category === 'all' ? 'All Categories' : category.charAt(0).toUpperCase() + category.slice(1)}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex items-end">
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-400">{filteredServices.length}</div>
                <div className="text-sm text-gray-400">Services Available</div>
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Services List */}
          <div className="lg:col-span-2">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredServices.map((service) => (
                <div
                  key={service.serviceId}
                  className={`bg-gray-800 p-4 rounded-lg border cursor-pointer transition-all ${
                    selectedService?.serviceId === service.serviceId 
                      ? 'border-blue-400 bg-blue-900/20' 
                      : 'border-gray-700 hover:border-gray-600'
                  }`}
                  onClick={() => handleServiceSelect(service)}
                >
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="font-semibold text-lg">{service.name}</h3>
                    <span className="text-xs bg-blue-600 px-2 py-1 rounded">
                      {service.provider}
                    </span>
                  </div>
                  <p className="text-gray-400 text-sm mb-2">{service.description}</p>
                  <div className="flex justify-between items-center">
                    <span className="text-green-400 font-medium">{service.price}</span>
                    <span className="text-xs text-gray-500 capitalize">{service.category}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Deployment Panel */}
          <div className="bg-gray-800 p-6 rounded-lg h-fit sticky top-6">
            {selectedService ? (
              <>
                <h3 className="text-xl font-bold mb-4">Deploy {selectedService.name}</h3>
                
                <div className="space-y-4 mb-6">
                  <div>
                    <label className="block text-sm font-medium mb-2">Service Name</label>
                    <input
                      type="text"
                      placeholder="my-service"
                      className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                      value={deploymentConfig.name}
                      onChange={(e) => setDeploymentConfig({...deploymentConfig, name: e.target.value})}
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-2">Region</label>
                    <select
                      className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                      value={deploymentConfig.region}
                      onChange={(e) => setDeploymentConfig({...deploymentConfig, region: e.target.value})}
                    >
                      <option value="us-west-2">US West 2</option>
                      <option value="us-east-1">US East 1</option>
                      <option value="eu-west-1">EU West 1</option>
                      <option value="ap-southeast-1">Asia Pacific 1</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-2">Instance Type</label>
                    <select
                      className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                      value={deploymentConfig.instanceType}
                      onChange={(e) => setDeploymentConfig({...deploymentConfig, instanceType: e.target.value})}
                    >
                      <option value="t3.micro">t3.micro (1 vCPU, 1GB RAM)</option>
                      <option value="t3.small">t3.small (2 vCPU, 2GB RAM)</option>
                      <option value="t3.medium">t3.medium (2 vCPU, 4GB RAM)</option>
                      <option value="t3.large">t3.large (2 vCPU, 8GB RAM)</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-2">Environment</label>
                    <select
                      className="w-full p-2 bg-gray-700 rounded border border-gray-600"
                      value={deploymentConfig.environment}
                      onChange={(e) => setDeploymentConfig({...deploymentConfig, environment: e.target.value})}
                    >
                      <option value="development">Development</option>
                      <option value="staging">Staging</option>
                      <option value="production">Production</option>
                    </select>
                  </div>
                </div>

                <button
                  onClick={handleDeploy}
                  disabled={isDeploying || !deploymentConfig.name}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 px-4 py-2 rounded font-medium transition-colors"
                >
                  {isDeploying ? '🚀 Deploying...' : '🚀 Deploy Service'}
                </button>

                <div className="mt-6">
                  <h4 className="font-medium mb-2">Generated Script</h4>
                  <pre className="bg-gray-900 p-3 rounded text-xs overflow-x-auto">
                    <code>{selectedService.codeTemplate}</code>
                  </pre>
                </div>

                <div className="mt-4">
                  <h4 className="font-medium mb-2">Setup Steps</h4>
                  <ol className="text-sm space-y-1">
                    {selectedService.setupSteps.map((step, index) => (
                      <li key={index} className="flex">
                        <span className="text-blue-400 mr-2">{index + 1}.</span>
                        <span>{step}</span>
                      </li>
                    ))}
                  </ol>
                </div>
              </>
            ) : (
              <div className="text-center text-gray-400">
                <div className="text-4xl mb-4">🎯</div>
                <h3 className="text-lg font-medium mb-2">Select a Service</h3>
                <p className="text-sm">Choose any service from the list to configure and deploy</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Services() {
  return (
    <ProtectedRoute>
      <ServicesContent />
    </ProtectedRoute>
  );
}
