import React from 'react';
import Head from 'next/head';
import Navigation from '../../components/layout/Navigation';

export default function ThroughputOptimizationPage() {
  return (
    <>
      <Head>
        <title>Throughput Optimization - AddToCloud Enterprise</title>
        <meta name="description" content="Professional Throughput Optimization service with enterprise-grade security, scalability, and Nepal market optimization" />
        <meta name="keywords" content="cloud, storage, throughput-optimization, enterprise, nepal, addtocloud" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        {/* Hero Section */}
        <section className="pt-24 pb-12 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto text-center">
            <h1 className="text-4xl md:text-6xl font-bold text-white mb-6">
              Throughput Optimization
            </h1>
            <p className="text-xl text-blue-200 mb-8 max-w-3xl mx-auto">
              Professional Throughput Optimization service with enterprise-grade security, scalability, and Nepal market optimization
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
                  <li>✓ Basic throughput-optimization features</li>
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
                  <li>✓ Advanced throughput-optimization features</li>
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
                  <li>✓ Full throughput-optimization suite</li>
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
              Join thousands of companies already using AddToCloud for their storage needs.
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
}