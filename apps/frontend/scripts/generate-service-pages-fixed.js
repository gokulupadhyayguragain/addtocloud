// Enterprise Service Catalog Generator
// This script generates 360+ service pages for AddToCloud platform

const fs = require('fs');
const path = require('path');

// Define comprehensive service categories
const serviceCategories = {
  // Compute Services (50+ pages)
  compute: [
    'virtual-machines', 'container-instances', 'kubernetes-engine', 'app-service', 
    'functions', 'batch-computing', 'spot-instances', 'dedicated-hosts',
    'auto-scaling', 'load-balancers', 'edge-computing', 'serverless-computing',
    'gpu-instances', 'hpc-clusters', 'container-registry', 'service-mesh',
    'microservices', 'orchestration', 'workflow-automation', 'task-scheduling',
    'elastic-computing', 'burst-computing', 'parallel-processing', 'distributed-computing',
    'cloud-workstations', 'virtual-desktops', 'remote-development', 'code-execution',
    'runtime-environments', 'development-environments', 'testing-environments', 'staging-environments',
    'production-environments', 'disaster-recovery', 'backup-restoration', 'high-availability',
    'fault-tolerance', 'redundancy', 'clustering', 'sharding',
    'caching-services', 'cdn-acceleration', 'edge-caching', 'global-distribution',
    'performance-optimization', 'resource-monitoring', 'capacity-planning', 'cost-optimization',
    'usage-analytics', 'performance-metrics', 'health-monitoring', 'alerting-systems'
  ],

  // Storage Services (40+ pages)
  storage: [
    'object-storage', 'block-storage', 'file-storage', 'archive-storage',
    'backup-storage', 'snapshot-storage', 'data-lakes', 'data-warehousing',
    'distributed-storage', 'encrypted-storage', 'compliance-storage', 'geo-redundant-storage',
    'hot-storage', 'cold-storage', 'glacier-storage', 'intelligent-tiering',
    'storage-gateways', 'hybrid-storage', 'edge-storage', 'mobile-storage',
    'database-storage', 'log-storage', 'media-storage', 'content-delivery',
    'version-control', 'data-synchronization', 'data-replication', 'data-migration',
    'storage-analytics', 'capacity-management', 'lifecycle-policies', 'retention-policies',
    'access-controls', 'encryption-keys', 'data-classification', 'compliance-auditing',
    'storage-optimization', 'cost-analysis', 'usage-reporting', 'performance-tuning',
    'throughput-optimization', 'latency-reduction', 'bandwidth-management', 'transfer-acceleration'
  ],

  // Database Services (45+ pages)
  database: [
    'relational-databases', 'nosql-databases', 'graph-databases', 'time-series-databases',
    'in-memory-databases', 'distributed-databases', 'multi-model-databases', 'document-databases',
    'key-value-stores', 'column-family', 'search-databases', 'analytics-databases',
    'data-warehouses', 'data-marts', 'oltp-databases', 'olap-databases',
    'postgresql-service', 'mysql-service', 'mongodb-service', 'redis-service',
    'elasticsearch-service', 'cassandra-service', 'dynamodb-service', 'cosmosdb-service',
    'database-migration', 'schema-management', 'backup-restore', 'point-in-time-recovery',
    'high-availability', 'read-replicas', 'master-slave', 'cluster-management',
    'sharding-strategies', 'partitioning', 'indexing-optimization', 'query-optimization',
    'performance-tuning', 'monitoring-alerts', 'security-hardening', 'encryption-at-rest',
    'encryption-in-transit', 'access-controls', 'audit-logging', 'compliance-reporting',
    'automated-backups', 'disaster-recovery', 'geo-replication', 'cross-region-sync',
    'database-proxy', 'connection-pooling', 'load-balancing'
  ],

  // Networking Services (35+ pages)
  networking: [
    'virtual-networks', 'subnets', 'security-groups', 'network-acls',
    'load-balancers', 'api-gateways', 'vpn-connections', 'direct-connect',
    'content-delivery', 'dns-management', 'domain-registration', 'ssl-certificates',
    'firewall-services', 'ddos-protection', 'web-application-firewall', 'network-monitoring',
    'traffic-analytics', 'bandwidth-monitoring', 'latency-optimization', 'global-load-balancing',
    'anycast-routing', 'bgp-routing', 'peering-connections', 'transit-gateways',
    'nat-gateways', 'internet-gateways', 'vpn-gateways', 'express-routes',
    'private-endpoints', 'service-endpoints', 'network-isolation', 'micro-segmentation',
    'zero-trust-networking', 'software-defined-networking', 'network-virtualization'
  ],

  // Security Services (40+ pages)
  security: [
    'identity-management', 'access-management', 'multi-factor-authentication', 'single-sign-on',
    'certificate-management', 'key-management', 'secrets-management', 'encryption-services',
    'security-monitoring', 'threat-detection', 'vulnerability-scanning', 'compliance-auditing',
    'security-policies', 'governance-controls', 'risk-assessment', 'incident-response',
    'forensic-analysis', 'security-analytics', 'behavior-monitoring', 'anomaly-detection',
    'intrusion-detection', 'intrusion-prevention', 'endpoint-protection', 'mobile-security',
    'application-security', 'code-scanning', 'dependency-scanning', 'container-security',
    'kubernetes-security', 'infrastructure-security', 'network-security', 'data-security',
    'privacy-protection', 'gdpr-compliance', 'hipaa-compliance', 'sox-compliance',
    'pci-compliance', 'iso-certification', 'security-training', 'awareness-programs'
  ],

  // AI/ML Services (35+ pages)
  aiml: [
    'machine-learning', 'deep-learning', 'neural-networks', 'computer-vision',
    'natural-language-processing', 'speech-recognition', 'text-to-speech', 'translation-services',
    'chatbots', 'virtual-assistants', 'recommendation-engines', 'predictive-analytics',
    'anomaly-detection', 'fraud-detection', 'sentiment-analysis', 'image-recognition',
    'object-detection', 'facial-recognition', 'document-analysis', 'ocr-services',
    'automated-machine-learning', 'model-training', 'model-deployment', 'model-monitoring',
    'feature-engineering', 'data-labeling', 'synthetic-data', 'transfer-learning',
    'federated-learning', 'edge-ai', 'ai-accelerators', 'gpu-computing',
    'quantum-computing', 'ai-ethics', 'responsible-ai'
  ],

  // Analytics Services (30+ pages)
  analytics: [
    'business-intelligence', 'data-visualization', 'real-time-analytics', 'batch-analytics',
    'stream-processing', 'event-processing', 'log-analytics', 'metrics-analytics',
    'performance-analytics', 'user-analytics', 'marketing-analytics', 'sales-analytics',
    'financial-analytics', 'operational-analytics', 'predictive-modeling', 'statistical-analysis',
    'data-mining', 'pattern-recognition', 'trend-analysis', 'forecasting',
    'reporting-dashboards', 'executive-dashboards', 'operational-dashboards', 'custom-reports',
    'automated-reporting', 'scheduled-reports', 'alert-notifications', 'data-export',
    'api-analytics', 'mobile-analytics'
  ],

  // DevOps Services (35+ pages)
  devops: [
    'continuous-integration', 'continuous-deployment', 'pipeline-automation', 'build-automation',
    'test-automation', 'deployment-automation', 'infrastructure-as-code', 'configuration-management',
    'container-orchestration', 'service-mesh', 'api-management', 'version-control',
    'artifact-management', 'dependency-management', 'secret-management', 'environment-management',
    'monitoring-observability', 'logging-aggregation', 'metrics-collection', 'distributed-tracing',
    'performance-monitoring', 'error-tracking', 'uptime-monitoring', 'synthetic-monitoring',
    'chaos-engineering', 'disaster-recovery', 'backup-automation', 'scaling-automation',
    'cost-optimization', 'resource-management', 'capacity-planning', 'change-management',
    'release-management', 'rollback-strategies', 'blue-green-deployment', 'canary-deployment'
  ],

  // Integration Services (25+ pages)
  integration: [
    'api-integration', 'webhook-integration', 'message-queues', 'event-streaming',
    'data-integration', 'etl-services', 'data-pipelines', 'workflow-orchestration',
    'business-process-automation', 'enterprise-service-bus', 'middleware-services', 'protocol-translation',
    'data-transformation', 'format-conversion', 'schema-mapping', 'connector-services',
    'third-party-integrations', 'saas-integrations', 'legacy-system-integration', 'hybrid-integration',
    'real-time-integration', 'batch-integration', 'event-driven-architecture', 'microservices-integration',
    'b2b-integration'
  ],

  // IoT Services (20+ pages)
  iot: [
    'device-management', 'sensor-data', 'telemetry-processing', 'edge-computing',
    'industrial-iot', 'smart-cities', 'connected-vehicles', 'smart-buildings',
    'asset-tracking', 'predictive-maintenance', 'remote-monitoring', 'device-provisioning',
    'firmware-updates', 'security-management', 'data-analytics', 'visualization-dashboards',
    'alert-notifications', 'rule-engines', 'protocol-support', 'connectivity-management'
  ],

  // Blockchain Services (15+ pages)
  blockchain: [
    'smart-contracts', 'cryptocurrency', 'digital-assets', 'nft-services',
    'decentralized-identity', 'supply-chain', 'digital-certificates', 'consensus-mechanisms',
    'blockchain-analytics', 'wallet-services', 'trading-platforms', 'defi-services',
    'tokenization', 'cross-chain', 'interoperability'
  ]
};

// Generate page template
function generatePageTemplate(category, service, title, description) {
  const componentName = service.split('-').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join('');

  return `import React from 'react';
import Head from 'next/head';
import Navigation from '../../components/layout/Navigation';

export default function ${componentName}Page() {
  return (
    <>
      <Head>
        <title>${title} - AddToCloud Enterprise</title>
        <meta name="description" content="${description}" />
        <meta name="keywords" content="cloud, ${category}, ${service}, enterprise, nepal, addtocloud" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        {/* Hero Section */}
        <section className="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto text-center">
            <h1 className="text-4xl md:text-6xl font-bold text-white mb-6">
              ${title}
            </h1>
            <p className="text-xl text-blue-200 mb-8 max-w-3xl mx-auto">
              ${description}
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-3 rounded-lg font-semibold transition-colors">
                Start Free Trial
              </button>
              <button className="border border-blue-400 text-blue-400 hover:bg-blue-400 hover:text-white px-8 py-3 rounded-lg font-semibold transition-colors">
                Learn More
              </button>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="py-16 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto">
            <h2 className="text-3xl font-bold text-white text-center mb-12">
              Key Features
            </h2>
            <div className="grid md:grid-cols-3 gap-8">
              <div className="bg-slate-800/50 p-6 rounded-lg">
                <h3 className="text-xl font-semibold text-white mb-4">Enterprise Grade</h3>
                <p className="text-slate-300">
                  Built for enterprise scale with 99.99% uptime SLA and 24/7 support.
                </p>
              </div>
              <div className="bg-slate-800/50 p-6 rounded-lg">
                <h3 className="text-xl font-semibold text-white mb-4">Global Infrastructure</h3>
                <p className="text-slate-300">
                  Multi-cloud deployment across Azure, AWS, and GCP for maximum reliability.
                </p>
              </div>
              <div className="bg-slate-800/50 p-6 rounded-lg">
                <h3 className="text-xl font-semibold text-white mb-4">Nepal Optimized</h3>
                <p className="text-slate-300">
                  Specially optimized for Nepal market with local support and payment options.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Pricing Section */}
        <section className="py-16 px-4 sm:px-6 lg:px-8 bg-slate-800/30">
          <div className="max-w-7xl mx-auto text-center">
            <h2 className="text-3xl font-bold text-white mb-12">
              Flexible Pricing
            </h2>
            <div className="grid md:grid-cols-3 gap-8">
              <div className="bg-slate-800/50 p-8 rounded-lg border border-slate-700">
                <h3 className="text-2xl font-bold text-white mb-4">Starter</h3>
                <div className="text-4xl font-bold text-blue-400 mb-6">$99/mo</div>
                <ul className="text-slate-300 space-y-3 mb-8">
                  <li>✓ Basic ${service} features</li>
                  <li>✓ 24/7 support</li>
                  <li>✓ 99.9% uptime SLA</li>
                  <li>✓ Nepal billing support</li>
                </ul>
                <button className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-semibold transition-colors">
                  Get Started
                </button>
              </div>
              <div className="bg-gradient-to-br from-blue-600 to-purple-600 p-8 rounded-lg transform scale-105">
                <h3 className="text-2xl font-bold text-white mb-4">Professional</h3>
                <div className="text-4xl font-bold text-white mb-6">$299/mo</div>
                <ul className="text-blue-100 space-y-3 mb-8">
                  <li>✓ Advanced ${service} features</li>
                  <li>✓ Priority support</li>
                  <li>✓ 99.99% uptime SLA</li>
                  <li>✓ Multi-region deployment</li>
                </ul>
                <button className="w-full bg-white text-blue-600 py-3 rounded-lg font-semibold hover:bg-blue-50 transition-colors">
                  Most Popular
                </button>
              </div>
              <div className="bg-slate-800/50 p-8 rounded-lg border border-slate-700">
                <h3 className="text-2xl font-bold text-white mb-4">Enterprise</h3>
                <div className="text-4xl font-bold text-blue-400 mb-6">Custom</div>
                <ul className="text-slate-300 space-y-3 mb-8">
                  <li>✓ Full ${service} suite</li>
                  <li>✓ Dedicated support</li>
                  <li>✓ Custom SLA</li>
                  <li>✓ On-premises options</li>
                </ul>
                <button className="w-full border border-blue-400 text-blue-400 hover:bg-blue-400 hover:text-white py-3 rounded-lg font-semibold transition-colors">
                  Contact Sales
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-16 px-4 sm:px-6 lg:px-8">
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-3xl font-bold text-white mb-6">
              Ready to Get Started?
            </h2>
            <p className="text-xl text-slate-300 mb-8">
              Join thousands of companies already using AddToCloud for their ${category} needs.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <button className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-3 rounded-lg font-semibold transition-colors">
                Start Free Trial
              </button>
              <button className="border border-slate-400 text-slate-400 hover:bg-slate-400 hover:text-slate-900 px-8 py-3 rounded-lg font-semibold transition-colors">
                Schedule Demo
              </button>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="bg-slate-900 py-8 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto text-center">
            <p className="text-slate-400">
              © 2025 AddToCloud. Built with ❤️ for the cloud-native future.
            </p>
          </div>
        </footer>
      </div>
    </>
  );
}`;
}

// Service descriptions
const serviceDescriptions = {
  'virtual-machines': 'High-performance virtual machines with flexible configurations for enterprise workloads',
  'container-instances': 'Serverless container deployment with automatic scaling and management',
  'kubernetes-engine': 'Managed Kubernetes service for containerized application orchestration',
  'object-storage': 'Scalable object storage with 99.999999999% durability and global accessibility',
  'relational-databases': 'Fully managed relational database service with automated backups and scaling',
  'virtual-networks': 'Secure, isolated virtual networks with advanced routing and security features',
  'identity-management': 'Comprehensive identity and access management with enterprise-grade security',
  'machine-learning': 'End-to-end machine learning platform with automated model training and deployment',
  'business-intelligence': 'Advanced analytics and visualization tools for data-driven insights',
  'continuous-integration': 'Automated CI/CD pipelines for faster, more reliable software delivery'
};

// Generate service titles
function generateServiceTitle(service) {
  return service.split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

// Create directories and pages
function generateAllPages() {
  let totalPages = 0;
  
  Object.entries(serviceCategories).forEach(([category, services]) => {
    // Create category directory
    const categoryDir = path.join(__dirname, '..', 'pages', category);
    if (!fs.existsSync(categoryDir)) {
      fs.mkdirSync(categoryDir, { recursive: true });
    }
    
    // Generate pages for each service
    services.forEach(service => {
      const title = generateServiceTitle(service);
      const description = serviceDescriptions[service] || 
        `Professional ${title} service with enterprise-grade security, scalability, and Nepal market optimization`;
      
      const pageContent = generatePageTemplate(category, service, title, description);
      const filePath = path.join(categoryDir, `${service}.js`);
      
      fs.writeFileSync(filePath, pageContent);
      totalPages++;
      console.log(`Generated: ${category}/${service}.js`);
    });
  });
  
  // Generate category index pages
  Object.entries(serviceCategories).forEach(([category, services]) => {
    const categoryIndexContent = generateCategoryIndex(category, services);
    const filePath = path.join(__dirname, '..', 'pages', category, 'index.js');
    fs.writeFileSync(filePath, categoryIndexContent);
    totalPages++;
  });
  
  console.log(`\n🎉 Generated ${totalPages} service pages!`);
  console.log(`📊 Categories: ${Object.keys(serviceCategories).length}`);
  console.log(`🔧 Services: ${Object.values(serviceCategories).flat().length}`);
}

function generateCategoryIndex(category, services) {
  return `import React from 'react';
import Head from 'next/head';
import Link from 'next/link';
import Navigation from '../../components/layout/Navigation';

export default function ${category.charAt(0).toUpperCase() + category.slice(1)}Index() {
  const services = ${JSON.stringify(services, null, 2)};

  return (
    <>
      <Head>
        <title>${category.charAt(0).toUpperCase() + category.slice(1)} Services - AddToCloud Enterprise</title>
        <meta name="description" content="Comprehensive ${category} services for enterprise cloud infrastructure" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <section className="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto">
            <h1 className="text-4xl md:text-6xl font-bold text-white mb-6 text-center">
              ${category.charAt(0).toUpperCase() + category.slice(1)} Services
            </h1>
            <p className="text-xl text-blue-200 mb-12 text-center max-w-3xl mx-auto">
              Enterprise-grade ${category} solutions optimized for performance, security, and scalability
            </p>
            
            <div className="grid md:grid-cols-3 lg:grid-cols-4 gap-6">
              {services.map(service => (
                <Link key={service} href={\`/${category}/\${service}\`}>
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

// Run the generator
if (require.main === module) {
  generateAllPages();
}

module.exports = { generateAllPages, serviceCategories };
