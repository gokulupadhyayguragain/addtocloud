import { useState, useEffect } from 'react';
import Head from 'next/head';
import Link from 'next/link';

const API_BASE_URL = 'http://a89adf16af24048fdb948d1bfc77ec57-490099404.us-west-2.elb.amazonaws.com';

export default function Services() {
  const [accessRequest, setAccessRequest] = useState({
    service: '',
    plan: '',
    company: '',
    email: '',
    requirements: ''
  });
  const [requestStatus, setRequestStatus] = useState('');

  const services = [
    {
      name: 'Platform as a Service (PaaS)',
      icon: '🏗️',
      description: 'Deploy applications without infrastructure management',
      features: ['Auto-scaling', 'CI/CD Integration', 'Multi-cloud deployment', 'Container orchestration'],
      plans: ['Starter', 'Professional', 'Enterprise']
    },
    {
      name: 'Function as a Service (FaaS)',
      icon: '⚡',
      description: 'Serverless computing for event-driven applications',
      features: ['Event triggers', 'Auto-scaling', 'Pay-per-execution', 'Multiple runtimes'],
      plans: ['Basic', 'Premium', 'Enterprise']
    },
    {
      name: 'Infrastructure as a Service (IaaS)',
      icon: '🖥️',
      description: 'Virtual machines and networking resources',
      features: ['Virtual machines', 'Load balancers', 'Storage solutions', 'Network security'],
      plans: ['Small', 'Medium', 'Large', 'Custom']
    },
    {
      name: 'Software as a Service (SaaS)',
      icon: '☁️',
      description: 'Ready-to-use software applications',
      features: ['Web applications', 'API access', 'Data analytics', 'Collaboration tools'],
      plans: ['Starter', 'Business', 'Enterprise']
    }
  ];

  const handleSubmit = async (e) => {
    e.preventDefault();
    setRequestStatus('sending');

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/access-request`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://addtocloud.tech'
        },
        body: JSON.stringify(accessRequest)
      });

      if (response.ok) {
        setRequestStatus('success');
        setAccessRequest({
          service: '',
          plan: '',
          company: '',
          email: '',
          requirements: ''
        });
      } else {
        setRequestStatus('error');
      }
    } catch (error) {
      console.error('Access request error:', error);
      setRequestStatus('error');
    }
  };

  const handleChange = (e) => {
    setAccessRequest({
      ...accessRequest,
      [e.target.name]: e.target.value
    });
  };

  return (
    <>
      <Head>
        <title>Services - AddToCloud Enterprise Platform</title>
        <meta name="description" content="Enterprise cloud services: PaaS, FaaS, IaaS, SaaS" />
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
                <Link href="/services" className="text-white font-semibold">
                  Services
                </Link>
                <Link href="/dashboard" className="text-gray-300 hover:text-white transition-colors">
                  Dashboard
                </Link>
                <Link href="/monitoring" className="text-gray-300 hover:text-white transition-colors">
                  Monitoring
                </Link>
              </nav>
            </div>
          </div>
        </header>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Title */}
          <div className="text-center mb-16">
            <h1 className="text-5xl font-bold text-white mb-6">
              Our <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-purple-400">Services</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Comprehensive cloud solutions deployed across Azure AKS, AWS EKS, and GCP GKE
            </p>
          </div>

          {/* Services Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-16">
            {services.map((service, index) => (
              <div key={index} className="bg-white/10 backdrop-blur-sm rounded-lg p-8 border border-white/20">
                <div className="flex items-center mb-6">
                  <span className="text-4xl mr-4">{service.icon}</span>
                  <h2 className="text-2xl font-bold text-white">{service.name}</h2>
                </div>
                
                <p className="text-gray-300 mb-6">{service.description}</p>
                
                <div className="mb-6">
                  <h3 className="text-lg font-semibold text-white mb-3">Features:</h3>
                  <ul className="space-y-2">
                    {service.features.map((feature, idx) => (
                      <li key={idx} className="text-gray-300 flex items-center">
                        <span className="text-green-400 mr-2">✓</span>
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>
                
                <div>
                  <h3 className="text-lg font-semibold text-white mb-3">Plans:</h3>
                  <div className="flex flex-wrap gap-2">
                    {service.plans.map((plan, idx) => (
                      <span key={idx} className="bg-blue-500/20 text-blue-300 px-3 py-1 rounded-full text-sm border border-blue-500/30">
                        {plan}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Access Request Form */}
          <div className="max-w-2xl mx-auto">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-8 border border-white/20">
              <h2 className="text-3xl font-bold text-white mb-6 text-center">Request Access</h2>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <select
                    name="service"
                    value={accessRequest.service}
                    onChange={handleChange}
                    required
                    className="px-4 py-3 rounded-lg bg-white/10 border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="" className="bg-gray-800">Select Service</option>
                    <option value="paas" className="bg-gray-800">PaaS</option>
                    <option value="faas" className="bg-gray-800">FaaS</option>
                    <option value="iaas" className="bg-gray-800">IaaS</option>
                    <option value="saas" className="bg-gray-800">SaaS</option>
                  </select>
                  
                  <select
                    name="plan"
                    value={accessRequest.plan}
                    onChange={handleChange}
                    required
                    className="px-4 py-3 rounded-lg bg-white/10 border border-white/20 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="" className="bg-gray-800">Select Plan</option>
                    <option value="starter" className="bg-gray-800">Starter</option>
                    <option value="professional" className="bg-gray-800">Professional</option>
                    <option value="enterprise" className="bg-gray-800">Enterprise</option>
                  </select>
                </div>
                
                <input
                  type="text"
                  name="company"
                  placeholder="Company Name"
                  value={accessRequest.company}
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                
                <input
                  type="email"
                  name="email"
                  placeholder="Business Email"
                  value={accessRequest.email}
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                
                <textarea
                  name="requirements"
                  placeholder="Describe your requirements..."
                  value={accessRequest.requirements}
                  onChange={handleChange}
                  required
                  rows={4}
                  className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                />
                
                <button
                  type="submit"
                  disabled={requestStatus === 'sending'}
                  className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-3 px-6 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {requestStatus === 'sending' ? 'Submitting...' : 'Request Access'}
                </button>
              </form>
              
              {requestStatus === 'success' && (
                <div className="mt-6 p-4 bg-green-500/20 border border-green-500/30 rounded-lg text-green-300">
                  Access request submitted successfully! We'll contact you within 24 hours.
                </div>
              )}
              
              {requestStatus === 'error' && (
                <div className="mt-6 p-4 bg-red-500/20 border border-red-500/30 rounded-lg text-red-300">
                  Failed to submit request. Please try again or contact support.
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
