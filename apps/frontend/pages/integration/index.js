import React from 'react';
import Head from 'next/head';
import Link from 'next/link';
import Navigation from '../../components/layout/Navigation';

export default function IntegrationIndex() {
  const services = ["api-integration", "webhook-integration", "message-queues", "event-streaming", "data-integration"];

  return (
    <>
      <Head>
        <title>Integration Services - AddToCloud Enterprise</title>
        <meta name="description" content="Comprehensive integration services for enterprise cloud infrastructure" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <section className="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto">
            <h1 className="text-4xl md:text-6xl font-bold text-white mb-6 text-center">
              Integration Services
            </h1>
            <p className="text-xl text-blue-200 mb-12 text-center max-w-3xl mx-auto">
              Enterprise-grade integration solutions optimized for performance, security, and scalability
            </p>
            
            <div className="grid md:grid-cols-3 lg:grid-cols-4 gap-6">
              {services.map(service => (
                <Link key={service} href={`/integration/${service}`}>
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
}