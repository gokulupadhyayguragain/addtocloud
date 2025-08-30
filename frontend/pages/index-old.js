import Head from 'next/head'
import Link from 'next/link'
import Navigation from '../components/layout/Navigation'
import { Canvas } from '@react-three/fiber'
import { OrbitControls, Sphere, Box, Float } from '@react-three/drei'
import { Suspense, useRef } from 'react'
import { useFrame } from '@react-three/fiber'

function CloudSphere({ position, color, scale = 1 }) {
  const ref = useRef()
  useFrame((state) => {
    ref.current.rotation.x = Math.sin(state.clock.elapsedTime) * 0.1
    ref.current.rotation.y += 0.01
  })
  
  return (
    <Float speed={2} rotationIntensity={0.5} floatIntensity={0.8}>
      <Sphere ref={ref} position={position} scale={scale}>
        <meshStandardMaterial color={color} transparent opacity={0.8} />
      </Sphere>
    </Float>
  )
}

function AnimatedCubes() {
  const ref = useRef()
  useFrame((state) => {
    ref.current.rotation.y += 0.005
    ref.current.position.y = Math.sin(state.clock.elapsedTime) * 0.1
  })
  
  return (
    <group ref={ref}>
      <CloudSphere position={[-4, 0, 0]} color="#3b82f6" scale={0.8} />
      <CloudSphere position={[4, 0, 0]} color="#8b5cf6" scale={1.2} />
      <CloudSphere position={[0, 3, -2]} color="#06b6d4" scale={0.6} />
      <CloudSphere position={[2, -2, 1]} color="#f59e0b" scale={0.9} />
      <CloudSphere position={[-3, 2, 2]} color="#ef4444" scale={0.7} />
    </group>
  )
}

function CloudScene() {
  return (
    <>
      <ambientLight intensity={0.4} />
      <pointLight position={[10, 10, 10]} intensity={1} />
      <pointLight position={[-10, -10, -10]} intensity={0.5} color="#8b5cf6" />
      <Suspense fallback={null}>
        <AnimatedCubes />
      </Suspense>
      <OrbitControls enableZoom={false} enablePan={false} autoRotate autoRotateSpeed={0.5} />
    </>
  )
}

export default function Home() {
  return (
    <>
      <Head>
        <title>AddToCloud - Next-Generation Enterprise Cloud Platform | 398 Pages, 380+ Services</title>
        <meta name="description" content="Transform your business with our comprehensive enterprise cloud platform. 380+ services across 11 categories including AI/ML, security, compute, storage, and more. Built for Nepal market with global scale." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="keywords" content="enterprise cloud platform, cloud services, AI ML, cybersecurity, multi-cloud, kubernetes, serverless, blockchain, IoT, nepal cloud, enterprise infrastructure" />
        <link rel="icon" href="/favicon.ico" />
        <meta property="og:title" content="AddToCloud - Enterprise Cloud Platform" />
        <meta property="og:description" content="380+ enterprise cloud services across 11 categories. Multi-cloud deployment with Nepal market optimization." />
        <meta property="og:type" content="website" />
        <meta name="twitter:card" content="summary_large_image" />
      </Head>

      <div className="min-h-screen bg-slate-950 relative overflow-hidden">
        {/* Background Effects */}
        <div className="absolute inset-0 bg-gradient-to-br from-slate-950 via-blue-950/20 to-purple-950/20"></div>
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(59,130,246,0.1),transparent_50%)] pointer-events-none"></div>
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_70%_80%,rgba(147,51,234,0.1),transparent_50%)] pointer-events-none"></div>

        <Navigation />

        {/* Hero Section */}
        <section className="relative min-h-screen flex items-center justify-center pt-20 px-4">
          {/* 3D Background */}
          <div className="absolute inset-0 z-0 opacity-20">
            <Canvas camera={{ position: [0, 0, 10], fov: 60 }}>
              <CloudScene />
            </Canvas>
          </div>
          
          {/* Hero Content */}
          <div className="relative z-10 text-center max-w-7xl mx-auto">
            <div className="floating-animation">
              <h1 className="hero-title mb-8">
                Add<span className="text-blue-400">To</span>Cloud
              </h1>
            </div>
            
            <div className="text-2xl md:text-4xl lg:text-5xl mb-6 font-semibold bg-gradient-to-r from-blue-200 to-purple-200 bg-clip-text text-transparent">
              Next-Generation Enterprise Cloud Platform
            </div>
            
            <p className="text-xl md:text-2xl lg:text-3xl mb-12 max-w-5xl mx-auto text-gray-300 leading-relaxed">
              Transform your business with <span className="text-blue-400 font-semibold">398 pages</span> and <span className="text-purple-400 font-semibold">380+ enterprise cloud services</span> across 11 cutting-edge categories
            </p>
            
            {/* Enhanced Stats Grid */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-16 max-w-5xl mx-auto">
              <div className="stats-card group">
                <div className="text-4xl md:text-5xl font-black text-blue-400 mb-2 group-hover:scale-110 transition-transform duration-300">398</div>
                <div className="text-gray-300 font-medium">Total Pages</div>
                <div className="text-sm text-gray-500">Complete Platform</div>
              </div>
              <div className="stats-card group">
                <div className="text-4xl md:text-5xl font-black text-green-400 mb-2 group-hover:scale-110 transition-transform duration-300">380+</div>
                <div className="text-gray-300 font-medium">Cloud Services</div>
                <div className="text-sm text-gray-500">Enterprise Grade</div>
              </div>
              <div className="stats-card group">
                <div className="text-4xl md:text-5xl font-black text-purple-400 mb-2 group-hover:scale-110 transition-transform duration-300">11</div>
                <div className="text-gray-300 font-medium">Categories</div>
                <div className="text-sm text-gray-500">Full Coverage</div>
              </div>
              <div className="stats-card group">
                <div className="text-4xl md:text-5xl font-black text-yellow-400 mb-2 group-hover:scale-110 transition-transform duration-300">🇳🇵</div>
                <div className="text-gray-300 font-medium">Nepal Ready</div>
                <div className="text-sm text-gray-500">Global Scale</div>
              </div>
            </div>

            {/* Enhanced CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
              <Link href="/services" className="btn-primary group">
                <span className="relative z-10">Explore 380+ Services</span>
                <div className="absolute right-4 top-1/2 transform -translate-y-1/2 group-hover:translate-x-1 transition-transform duration-300">
                  →
                </div>
              </Link>
              <Link href="/dashboard" className="btn-secondary group">
                <span className="relative z-10">Start Free - No Payment Required</span>
                <div className="absolute right-4 top-1/2 transform -translate-y-1/2 group-hover:scale-110 transition-transform duration-300">
                  ✨
                </div>
              </Link>
            </div>
          </div>
        </section>

        {/* Service Categories Section */}
        <section className="py-32 px-4 relative">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-20">
              <h2 className="section-title">
                Comprehensive Service Portfolio
              </h2>
              <p className="text-xl md:text-2xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
                From compute and storage to AI/ML and blockchain - everything you need for modern enterprise infrastructure
              </p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
              <Link href="/compute" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">⚡</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-blue-400 transition-colors duration-300">
                  Compute Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  50+ services including VMs, containers, Kubernetes, serverless functions, and GPU computing
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-blue-400 font-semibold text-lg">50 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>
              
              <Link href="/storage" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">💾</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-green-400 transition-colors duration-300">
                  Storage Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  40+ storage solutions from object storage to data lakes and intelligent backup systems
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-green-400 font-semibold text-lg">40 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>
              
              <Link href="/database" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">🗄️</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-purple-400 transition-colors duration-300">
                  Database Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  45+ database services including SQL, NoSQL, graph, and time-series databases
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-purple-400 font-semibold text-lg">45 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>
              
              <Link href="/aiml" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">🤖</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-orange-400 transition-colors duration-300">
                  AI/ML Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  38+ AI/ML services including computer vision, NLP, and automated model training
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-orange-400 font-semibold text-lg">38 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>

              <Link href="/security" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">🔒</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-red-400 transition-colors duration-300">
                  Security Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  40+ security services including identity management, threat detection, and compliance
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-red-400 font-semibold text-lg">40 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>

              <Link href="/networking" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">🌐</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-cyan-400 transition-colors duration-300">
                  Networking Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  33+ networking solutions including CDN, load balancers, and VPN services
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-cyan-400 font-semibold text-lg">33 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>

              <Link href="/analytics" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">📊</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-indigo-400 transition-colors duration-300">
                  Analytics Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  29+ analytics services including real-time processing and business intelligence
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-indigo-400 font-semibold text-lg">29 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>

              <Link href="/blockchain" className="category-card">
                <div className="text-6xl mb-6 group-hover:scale-110 transition-transform duration-500">⛓️</div>
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-yellow-400 transition-colors duration-300">
                  Blockchain Services
                </h3>
                <p className="text-gray-300 mb-6 leading-relaxed">
                  15+ blockchain services including smart contracts, DeFi, and digital assets
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-yellow-400 font-semibold text-lg">15 Services</span>
                  <span className="text-2xl group-hover:translate-x-2 transition-transform duration-300">→</span>
                </div>
              </Link>
            </div>
          </div>
        </section>

        {/* Multi-Cloud Infrastructure Section */}
        <section className="py-32 px-4 relative">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 to-purple-500/5"></div>
          <div className="max-w-7xl mx-auto relative">
            <div className="text-center mb-20">
              <h2 className="section-title">
                Multi-Cloud Infrastructure
              </h2>
              <p className="text-xl md:text-2xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
                Deploy across Azure AKS, AWS EKS, and GCP GKE for maximum availability and performance
              </p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
              <div className="feature-card text-center">
                <div className="text-5xl mb-6">☁️</div>
                <h3 className="text-2xl font-bold text-white mb-4">Azure AKS</h3>
                <p className="text-gray-300 leading-relaxed">
                  Primary cloud provider for enterprise workloads with comprehensive service portfolio
                </p>
              </div>
              
              <div className="feature-card text-center">
                <div className="text-5xl mb-6">🚀</div>
                <h3 className="text-2xl font-bold text-white mb-4">AWS EKS</h3>
                <p className="text-gray-300 leading-relaxed">
                  Secondary provider for high availability and disaster recovery scenarios
                </p>
              </div>
              
              <div className="feature-card text-center">
                <div className="text-5xl mb-6">☀️</div>
                <h3 className="text-2xl font-bold text-white mb-4">GCP GKE</h3>
                <p className="text-gray-300 leading-relaxed">
                  Global distribution and edge computing for optimal performance worldwide
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Nepal Market Focus Section */}
        <section className="py-32 px-4 relative">
          <div className="max-w-7xl mx-auto">
            <div className="glass-effect rounded-3xl p-12 md:p-16">
              <div className="text-center mb-12">
                <div className="text-6xl mb-6">🇳🇵</div>
                <h2 className="section-title">Built for Nepal Market</h2>
                <p className="text-xl md:text-2xl text-gray-300 max-w-4xl mx-auto leading-relaxed">
                  Specially designed for Nepal's growing tech ecosystem with local payment options, currency support, and dedicated customer service
                </p>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                <div className="space-y-8">
                  <div className="flex items-start space-x-4">
                    <div className="text-3xl">💰</div>
                    <div>
                      <h3 className="text-xl font-bold text-white mb-2">Local Payment Options</h3>
                      <p className="text-gray-300">Payoneer, bank transfers, and cryptocurrency payments accepted</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start space-x-4">
                    <div className="text-3xl">🏢</div>
                    <div>
                      <h3 className="text-xl font-bold text-white mb-2">Nepal Business Support</h3>
                      <p className="text-gray-300">Dedicated support team understanding local market requirements</p>
                    </div>
                  </div>
                </div>
                
                <div className="space-y-8">
                  <div className="flex items-start space-x-4">
                    <div className="text-3xl">🌏</div>
                    <div>
                      <h3 className="text-xl font-bold text-white mb-2">Global Scale</h3>
                      <p className="text-gray-300">International infrastructure with local optimization</p>
                    </div>
                  </div>
                  
                  <div className="flex items-start space-x-4">
                    <div className="text-3xl">⚡</div>
                    <div>
                      <h3 className="text-xl font-bold text-white mb-2">High Performance</h3>
                      <p className="text-gray-300">Optimized for low latency and high throughput in South Asia</p>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="text-center mt-12">
                <Link href="/dashboard" className="btn-primary inline-block">
                  Schedule Demo
                </Link>
              </div>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-16 px-4 border-t border-white/10">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-8">
              <h3 className="text-3xl font-bold text-white mb-4">AddToCloud</h3>
              <p className="text-gray-300 max-w-2xl mx-auto">
                Enterprise cloud platform with 380+ services for modern businesses
              </p>
            </div>
            
            <div className="text-center text-gray-400">
              <p>© 2025 AddToCloud. Built with ❤️ for the cloud-native future.</p>
            </div>
          </div>
        </footer>
      </div>
    </>
  )
}
