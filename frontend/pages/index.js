import Head from 'next/head'
import { Canvas } from '@react-three/fiber'
import { OrbitControls, Text, Box } from '@react-three/drei'
import { Suspense } from 'react'

function CloudScene() {
  return (
    <>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <Box position={[-2, 0, 0]} args={[1, 1, 1]}>
        <meshStandardMaterial color="hotpink" />
      </Box>
      <Box position={[2, 0, 0]} args={[1, 1, 1]}>
        <meshStandardMaterial color="blue" />
      </Box>
      <Text
        position={[0, 2, 0]}
        fontSize={0.5}
        color="white"
        anchorX="center"
        anchorY="middle"
      >
        AddToCloud Platform
      </Text>
      <OrbitControls />
    </>
  )
}

export default function Home() {
  return (
    <>
      <Head>
        <title>AddToCloud - Enterprise Cloud Platform</title>
        <meta name="description" content="Multi-cloud enterprise platform providing PaaS, FaaS, IaaS, and SaaS services" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800">
        {/* Hero Section */}
        <section className="relative h-screen flex items-center justify-center">
          <div className="absolute inset-0 z-0">
            <Canvas>
              <Suspense fallback={null}>
                <CloudScene />
              </Suspense>
            </Canvas>
          </div>
          
          <div className="relative z-10 text-center text-white px-4">
            <h1 className="text-5xl md:text-7xl font-bold mb-6 animate-fade-in">
              Add<span className="text-blue-400">To</span>Cloud
            </h1>
            <p className="text-xl md:text-2xl mb-8 max-w-2xl mx-auto opacity-90">
              Enterprise Cloud Platform providing PaaS, FaaS, IaaS, and SaaS services across multiple cloud providers
            </p>
            <div className="space-x-4">
              <button className="bg-blue-600 hover:bg-blue-700 px-8 py-3 rounded-lg font-semibold transition-colors">
                Get Started
              </button>
              <button className="border border-white/30 hover:bg-white/10 px-8 py-3 rounded-lg font-semibold transition-colors">
                Learn More
              </button>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="py-20 px-4">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-4xl font-bold text-center text-white mb-16">
              Multi-Cloud Excellence
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
              <div className="bg-white/5 backdrop-blur-sm rounded-lg p-6 border border-white/10">
                <div className="text-blue-400 text-3xl mb-4">🚀</div>
                <h3 className="text-xl font-semibold text-white mb-3">PaaS</h3>
                <p className="text-gray-300">Platform-as-a-Service for rapid application deployment and scaling</p>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm rounded-lg p-6 border border-white/10">
                <div className="text-green-400 text-3xl mb-4">⚡</div>
                <h3 className="text-xl font-semibold text-white mb-3">FaaS</h3>
                <p className="text-gray-300">Function-as-a-Service for serverless computing solutions</p>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm rounded-lg p-6 border border-white/10">
                <div className="text-purple-400 text-3xl mb-4">🏗️</div>
                <h3 className="text-xl font-semibold text-white mb-3">IaaS</h3>
                <p className="text-gray-300">Infrastructure-as-a-Service for complete control over resources</p>
              </div>
              
              <div className="bg-white/5 backdrop-blur-sm rounded-lg p-6 border border-white/10">
                <div className="text-orange-400 text-3xl mb-4">☁️</div>
                <h3 className="text-xl font-semibold text-white mb-3">SaaS</h3>
                <p className="text-gray-300">Software-as-a-Service for ready-to-use business applications</p>
              </div>
            </div>
          </div>
        </section>

        {/* Cloud Providers Section */}
        <section className="py-20 px-4 bg-black/20">
          <div className="max-w-6xl mx-auto text-center">
            <h2 className="text-4xl font-bold text-white mb-8">
              Multi-Cloud Infrastructure
            </h2>
            <p className="text-xl text-gray-300 mb-12">
              Deploy across Azure, AWS, and GCP for maximum availability and performance
            </p>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="bg-blue-600/10 rounded-lg p-8 border border-blue-500/30">
                <h3 className="text-2xl font-bold text-blue-400 mb-4">Azure AKS</h3>
                <p className="text-gray-300">Primary cloud provider for enterprise workloads</p>
              </div>
              
              <div className="bg-orange-600/10 rounded-lg p-8 border border-orange-500/30">
                <h3 className="text-2xl font-bold text-orange-400 mb-4">AWS EKS</h3>
                <p className="text-gray-300">Secondary provider for high availability</p>
              </div>
              
              <div className="bg-green-600/10 rounded-lg p-8 border border-green-500/30">
                <h3 className="text-2xl font-bold text-green-400 mb-4">GCP GKE</h3>
                <p className="text-gray-300">Global distribution and edge computing</p>
              </div>
            </div>
          </div>
        </section>

        {/* Technology Stack */}
        <section className="py-20 px-4">
          <div className="max-w-6xl mx-auto">
            <h2 className="text-4xl font-bold text-center text-white mb-16">
              Enterprise Technology Stack
            </h2>
            
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-6">
              {[
                'Next.js', 'Go', 'Kubernetes', 'Docker', 'Terraform', 'Istio',
                'PostgreSQL', 'MongoDB', 'Redis', 'Grafana', 'Prometheus', 'ArgoCD'
              ].map((tech, index) => (
                <div key={index} className="bg-white/5 rounded-lg p-4 text-center border border-white/10 hover:bg-white/10 transition-colors">
                  <span className="text-white font-medium">{tech}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="bg-black/30 py-12 px-4">
          <div className="max-w-6xl mx-auto text-center">
            <h3 className="text-2xl font-bold text-white mb-4">Ready to Scale?</h3>
            <p className="text-gray-300 mb-6">Join thousands of companies using AddToCloud for their infrastructure needs</p>
            <button className="bg-blue-600 hover:bg-blue-700 px-8 py-3 rounded-lg font-semibold text-white transition-colors">
              Start Free Trial
            </button>
            <div className="mt-8 pt-8 border-t border-white/10 text-gray-400">
              <p>&copy; 2025 AddToCloud. Built with ❤️ for the cloud-native future.</p>
            </div>
          </div>
        </footer>
      </main>
    </>
  )
}
