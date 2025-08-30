import Head from 'next/head'
import Link from 'next/link'
import { useEffect } from 'react'
import { useRouter } from 'next/router'
import Navigation from '../components/layout/Navigation'
import { useAuth } from '../context/AuthContext'

export default function Home() {
  const { isAuthenticated, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // Redirect authenticated users to dashboard
    if (!loading && isAuthenticated()) {
      router.push('/dashboard');
    }
  }, [isAuthenticated, loading, router]);

  // Show loading while checking auth
  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-slate-300 text-lg">Loading AddToCloud...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      <Head>
        <title>AddToCloud - Enterprise Cloud Platform</title>
        <meta name="description" content="Next-generation enterprise cloud platform with professional services" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />

        {/* Hero Section */}
        <section className="pt-24 pb-16 px-4">
          <div className="max-w-7xl mx-auto text-center">
            {/* Main Heading */}
            <h1 className="text-5xl md:text-7xl font-bold mb-6">
              <span className="text-white">Add</span>
              <span className="text-gradient">To</span>
              <span className="text-white">Cloud</span>
            </h1>
            
            {/* Subtitle */}
            <p className="text-2xl md:text-3xl text-slate-300 mb-8 max-w-4xl mx-auto">
              Enterprise Cloud Platform for Modern Businesses
            </p>
            
            {/* Description */}
            <p className="text-lg text-slate-400 mb-12 max-w-3xl mx-auto leading-relaxed">
              Deploy, manage, and scale your applications with our comprehensive cloud infrastructure. 
              Built for enterprise needs with industry-leading security and performance.
            </p>
            
            {/* Authentication-aware CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-6 justify-center mb-16">
              <Link href="/request-access" className="btn-primary text-lg py-4 px-8 shadow-2xl hover:shadow-blue-500/25 transform hover:scale-105 transition-all duration-300">
                🚀 Request Platform Access
              </Link>
              <Link href="/login" className="btn-secondary text-lg py-4 px-8 shadow-2xl hover:shadow-slate-500/25 transform hover:scale-105 transition-all duration-300">
                🔐 Sign In to Your Account
              </Link>
            </div>

            {/* Secondary CTA for Admin */}
            <div className="mb-8">
              <Link href="/admin-login" className="inline-flex items-center gap-2 text-slate-400 hover:text-blue-400 transition-colors text-sm">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 6h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
                Admin Login
              </Link>
            </div>
            
            {/* Access Note */}
            <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-xl p-6 mb-16 max-w-4xl mx-auto">
              <div className="flex items-start gap-4">
                <div className="w-8 h-8 bg-yellow-500/20 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                  <svg className="w-4 h-4 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-yellow-300 mb-2">🔐 Exclusive Platform Access</h3>
                  <p className="text-yellow-100 text-sm leading-relaxed">
                    AddToCloud is an <strong>invite-only enterprise platform</strong> with manual approval by our admin team. 
                    Upon approval, each user receives a <strong>dedicated free-tier EC2 instance</strong> pre-configured with 
                    AWS CLI, Azure CLI, GCP CLI, and other cloud-native tools. Apply now to join our exclusive cloud community.
                  </p>
                </div>
              </div>
            </div>
            
            {/* Feature Cards */}
            <div className="grid md:grid-cols-3 gap-8 mt-20">
              <div className="card text-center">
                <div className="w-16 h-16 bg-primary-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-white mb-3">High Performance</h3>
                <p className="text-slate-400">Lightning-fast infrastructure with 99.9% uptime guarantee</p>
              </div>
              
              <div className="card text-center">
                <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-white mb-3">Enterprise Security</h3>
                <p className="text-slate-400">Bank-level security with advanced threat protection</p>
              </div>
              
              <div className="card text-center">
                <div className="w-16 h-16 bg-purple-500 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-white mb-3">Easy Deployment</h3>
                <p className="text-slate-400">Deploy applications with one-click across multiple clouds</p>
              </div>
            </div>
          </div>
        </section>
        
        {/* Services Preview */}
        <section className="py-16 px-4 bg-slate-800/30">
          <div className="max-w-7xl mx-auto text-center">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-8">
              Comprehensive Cloud Services
            </h2>
            <p className="text-lg text-slate-400 mb-12 max-w-3xl mx-auto">
              Everything you need to build, deploy, and scale modern applications
            </p>
            
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              {[
                { name: 'Compute', icon: '⚡', desc: 'Virtual machines and containers' },
                { name: 'Storage', icon: '💾', desc: 'Scalable object and block storage' },
                { name: 'Database', icon: '🗄️', desc: 'Managed database services' },
                { name: 'Networking', icon: '🌐', desc: 'Global CDN and load balancing' },
              ].map((service, index) => (
                <div key={index} className="glass p-6 text-center hover:scale-105 transition-transform duration-200">
                  <div className="text-4xl mb-4">{service.icon}</div>
                  <h3 className="text-lg font-semibold text-white mb-2">{service.name}</h3>
                  <p className="text-sm text-slate-400">{service.desc}</p>
                </div>
              ))}
            </div>
            
            <div className="mt-12">
              <Link href="/services" className="btn-primary">
                Explore All Services
              </Link>
            </div>
          </div>
        </section>
      </div>
    </>
  )
}
