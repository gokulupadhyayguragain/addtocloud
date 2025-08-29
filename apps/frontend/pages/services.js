import Head from 'next/head'
import Navigation from '../components/layout/Navigation'

export default function Services() {
  const serviceCategories = [
    {
      name: 'Compute',
      icon: '⚡',
      description: 'Virtual machines, containers, and serverless computing',
      services: ['EC2 Instances', 'Container Service', 'Lambda Functions', 'Kubernetes']
    },
    {
      name: 'Storage',
      icon: '💾',
      description: 'Scalable object storage, block storage, and file systems',
      services: ['Object Storage', 'Block Storage', 'File Systems', 'Backup Service']
    },
    {
      name: 'Database',
      icon: '🗄️',
      description: 'Managed relational and NoSQL database services',
      services: ['PostgreSQL', 'MongoDB', 'Redis Cache', 'Analytics DB']
    },
    {
      name: 'Networking',
      icon: '🌐',
      description: 'Content delivery, load balancing, and VPN services',
      services: ['Load Balancer', 'CDN', 'VPN Gateway', 'DNS Service']
    },
    {
      name: 'Security',
      icon: '🔒',
      description: 'Identity management, encryption, and threat protection',
      services: ['IAM', 'SSL Certificates', 'WAF', 'Security Monitor']
    },
    {
      name: 'AI/ML',
      icon: '🤖',
      description: 'Machine learning models and artificial intelligence',
      services: ['ML Training', 'Model Serving', 'Auto ML', 'NLP Service']
    }
  ]

  return (
    <>
      <Head>
        <title>Services - AddToCloud</title>
        <meta name="description" content="Comprehensive cloud services for modern applications" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <div className="pt-24 pb-16 px-4">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <div className="text-center mb-16">
              <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
                Cloud Services
              </h1>
              <p className="text-xl text-slate-400 max-w-3xl mx-auto">
                Comprehensive suite of enterprise-grade cloud services to power your applications
              </p>
            </div>

            {/* Service Categories Grid */}
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
              {serviceCategories.map((category, index) => (
                <div key={index} className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20 hover:scale-105 transition-transform duration-200">
                  <div className="text-center mb-6">
                    <div className="text-5xl mb-4">{category.icon}</div>
                    <h3 className="text-2xl font-bold text-white mb-2">{category.name}</h3>
                    <p className="text-slate-400">{category.description}</p>
                  </div>
                  
                  <div className="space-y-3">
                    {category.services.map((service, serviceIndex) => (
                      <div key={serviceIndex} className="flex items-center justify-between p-3 bg-slate-700/30 rounded-lg">
                        <span className="text-white">{service}</span>
                        <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                      </div>
                    ))}
                  </div>
                  
                  <div className="mt-6">
                    <button className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors duration-200">
                      Explore {category.name}
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* CTA Section */}
            <div className="mt-20 text-center">
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-8 border border-white/20 max-w-4xl mx-auto">
                <h2 className="text-3xl font-bold text-white mb-4">Ready to Get Started?</h2>
                <p className="text-slate-400 mb-8">
                  Deploy your first service in minutes with our intuitive dashboard.
                </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <button className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors duration-200">
                    Start Free Trial
                  </button>
                  <button className="px-6 py-3 bg-transparent border border-white/30 text-white hover:bg-white/10 font-medium rounded-lg transition-colors duration-200">
                    View Documentation
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
