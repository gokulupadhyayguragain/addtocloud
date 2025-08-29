// Generate just category index pages
const fs = require('fs');
const path = require('path');

const serviceCategories = {
  compute: ['virtual-machines', 'container-instances', 'kubernetes-engine', 'app-service', 'functions'],
  storage: ['object-storage', 'block-storage', 'file-storage', 'archive-storage', 'backup-storage'],
  database: ['relational-databases', 'nosql-databases', 'graph-databases', 'time-series-databases', 'in-memory-databases'],
  networking: ['virtual-networks', 'subnets', 'security-groups', 'network-acls', 'load-balancers'],
  security: ['identity-management', 'access-management', 'multi-factor-authentication', 'single-sign-on', 'certificate-management'],
  aiml: ['machine-learning', 'deep-learning', 'neural-networks', 'computer-vision', 'natural-language-processing'],
  analytics: ['business-intelligence', 'data-visualization', 'real-time-analytics', 'batch-analytics', 'stream-processing'],
  devops: ['continuous-integration', 'continuous-deployment', 'pipeline-automation', 'build-automation', 'test-automation'],
  integration: ['api-integration', 'webhook-integration', 'message-queues', 'event-streaming', 'data-integration'],
  iot: ['device-management', 'sensor-data', 'telemetry-processing', 'edge-computing', 'industrial-iot'],
  blockchain: ['smart-contracts', 'cryptocurrency', 'digital-assets', 'nft-services', 'decentralized-identity']
};

function generateCategoryIndex(categoryName, services) {
  const title = categoryName.charAt(0).toUpperCase() + categoryName.slice(1);
  
  return `import React from 'react';
import Head from 'next/head';
import Link from 'next/link';
import Navigation from '../../components/layout/Navigation';

export default function ${title}Index() {
  const services = [${services.map(s => `"${s}"`).join(', ')}];

  return (
    <>
      <Head>
        <title>${title} Services - AddToCloud Enterprise</title>
        <meta name="description" content="Comprehensive ${categoryName} services for enterprise cloud infrastructure" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <section className="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto">
            <h1 className="text-4xl md:text-6xl font-bold text-white mb-6 text-center">
              ${title} Services
            </h1>
            <p className="text-xl text-blue-200 mb-12 text-center max-w-3xl mx-auto">
              Enterprise-grade ${categoryName} solutions optimized for performance, security, and scalability
            </p>
            
            <div className="grid md:grid-cols-3 lg:grid-cols-4 gap-6">
              {services.map(service => (
                <Link key={service} href={\`/${categoryName}/\${service}\`}>
                  <div className="bg-slate-800/50 hover:bg-slate-700/50 p-6 rounded-lg border border-slate-700 hover:border-blue-500 transition-all cursor-pointer">
                    <h3 className="text-lg font-semibold text-white mb-2">
                      {service.split('-').map(word => 
                        word.charAt(0).toUpperCase() + word.slice(1)
                      ).join(' ')}
                    </h3>
                    <p className="text-slate-400 text-sm">
                      Professional {service.replace(/-/g, ' ')} service
                    </p>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      </div>
    </>
  );
}`;
}

// Generate category index pages
Object.entries(serviceCategories).forEach(([category, services]) => {
  const categoryIndexContent = generateCategoryIndex(category, services);
  const filePath = path.join(__dirname, '..', 'pages', category, 'index.js');
  fs.writeFileSync(filePath, categoryIndexContent);
  console.log(`Generated: ${category}/index.js`);
});

console.log('Category index pages generated successfully!');
