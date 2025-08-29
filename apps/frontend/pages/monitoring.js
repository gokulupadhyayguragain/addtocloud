import Head from 'next/head'
import Navigation from '../components/layout/Navigation'
import { useState, useEffect } from 'react'
import { withAuth } from '../context/AuthContext'

function Monitoring() {
  const [metrics, setMetrics] = useState({
    cpu: 45,
    memory: 67,
    disk: 32,
    network: 78
  })

  const [alerts] = useState([
    { id: 1, type: 'warning', message: 'High memory usage on AWS EKS cluster', time: '5 minutes ago' },
    { id: 2, type: 'info', message: 'GCP GKE cluster scaled up successfully', time: '12 minutes ago' },
    { id: 3, type: 'success', message: 'Azure AKS backup completed', time: '1 hour ago' }
  ])

  // Simulate real-time metrics
  useEffect(() => {
    const interval = setInterval(() => {
      setMetrics(prev => ({
        cpu: Math.max(20, Math.min(90, prev.cpu + (Math.random() - 0.5) * 10)),
        memory: Math.max(30, Math.min(95, prev.memory + (Math.random() - 0.5) * 8)),
        disk: Math.max(15, Math.min(80, prev.disk + (Math.random() - 0.5) * 5)),
        network: Math.max(40, Math.min(100, prev.network + (Math.random() - 0.5) * 15))
      }))
    }, 3000)

    return () => clearInterval(interval)
  }, [])

  const getAlertColor = (type) => {
    switch (type) {
      case 'warning': return 'border-yellow-500 bg-yellow-500/10'
      case 'error': return 'border-red-500 bg-red-500/10'
      case 'success': return 'border-green-500 bg-green-500/10'
      default: return 'border-blue-500 bg-blue-500/10'
    }
  }

  const clusters = [
    { name: 'AWS EKS', region: 'us-east-1', status: 'healthy', nodes: 12, pods: 156 },
    { name: 'GCP GKE', region: 'us-central1', status: 'healthy', nodes: 8, pods: 124 },
    { name: 'Azure AKS', region: 'eastus', status: 'warning', nodes: 6, pods: 89 }
  ]

  return (
    <>
      <Head>
        <title>Monitoring - AddToCloud</title>
        <meta name="description" content="Real-time monitoring and analytics for your cloud infrastructure" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <div className="pt-24 pb-16 px-4">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <div className="text-center mb-12">
              <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
                Infrastructure Monitoring
              </h1>
              <p className="text-xl text-slate-400 max-w-3xl mx-auto">
                Real-time metrics and analytics across your multi-cloud infrastructure
              </p>
            </div>

            {/* Real-time Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-white">CPU Usage</h3>
                  <div className="text-2xl">🔥</div>
                </div>
                <div className="text-3xl font-bold text-white mb-2">{metrics.cpu.toFixed(1)}%</div>
                <div className="w-full bg-slate-700/50 rounded-full h-2">
                  <div 
                    className="bg-gradient-to-r from-blue-500 to-cyan-500 h-2 rounded-full transition-all duration-1000"
                    style={{ width: `${metrics.cpu}%` }}
                  ></div>
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-white">Memory</h3>
                  <div className="text-2xl">💾</div>
                </div>
                <div className="text-3xl font-bold text-white mb-2">{metrics.memory.toFixed(1)}%</div>
                <div className="w-full bg-slate-700/50 rounded-full h-2">
                  <div 
                    className="bg-gradient-to-r from-green-500 to-emerald-500 h-2 rounded-full transition-all duration-1000"
                    style={{ width: `${metrics.memory}%` }}
                  ></div>
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-white">Disk Usage</h3>
                  <div className="text-2xl">💿</div>
                </div>
                <div className="text-3xl font-bold text-white mb-2">{metrics.disk.toFixed(1)}%</div>
                <div className="w-full bg-slate-700/50 rounded-full h-2">
                  <div 
                    className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full transition-all duration-1000"
                    style={{ width: `${metrics.disk}%` }}
                  ></div>
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-white">Network I/O</h3>
                  <div className="text-2xl">🌐</div>
                </div>
                <div className="text-3xl font-bold text-white mb-2">{metrics.network.toFixed(1)}%</div>
                <div className="w-full bg-slate-700/50 rounded-full h-2">
                  <div 
                    className="bg-gradient-to-r from-orange-500 to-red-500 h-2 rounded-full transition-all duration-1000"
                    style={{ width: `${metrics.network}%` }}
                  ></div>
                </div>
              </div>
            </div>

            {/* Cluster Status */}
            <div className="grid lg:grid-cols-2 gap-8 mb-12">
              <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                <h3 className="text-2xl font-bold text-white mb-6">Cluster Status</h3>
                <div className="space-y-4">
                  {clusters.map((cluster, index) => (
                    <div key={index} className="flex items-center justify-between p-4 bg-slate-700/30 rounded-lg">
                      <div>
                        <h4 className="text-lg font-semibold text-white">{cluster.name}</h4>
                        <p className="text-slate-400">{cluster.region}</p>
                      </div>
                      <div className="text-right">
                        <div className={`inline-flex px-3 py-1 rounded-full text-sm font-medium ${
                          cluster.status === 'healthy' ? 'bg-green-500/20 text-green-400' :
                          cluster.status === 'warning' ? 'bg-yellow-500/20 text-yellow-400' :
                          'bg-red-500/20 text-red-400'
                        }`}>
                          {cluster.status}
                        </div>
                        <p className="text-slate-400 text-sm mt-1">{cluster.nodes} nodes • {cluster.pods} pods</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                <h3 className="text-2xl font-bold text-white mb-6">Recent Alerts</h3>
                <div className="space-y-4">
                  {alerts.map((alert) => (
                    <div key={alert.id} className={`p-4 rounded-lg border ${getAlertColor(alert.type)}`}>
                      <p className="text-white font-medium">{alert.message}</p>
                      <p className="text-slate-400 text-sm mt-1">{alert.time}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="bg-white/10 backdrop-blur-md rounded-xl p-8 border border-white/20">
              <h3 className="text-2xl font-bold text-white mb-6">Quick Actions</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <button className="flex items-center justify-center p-4 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors duration-200">
                  <span className="text-white font-medium">View Logs</span>
                </button>
                <button className="flex items-center justify-center p-4 bg-green-600 hover:bg-green-700 rounded-lg transition-colors duration-200">
                  <span className="text-white font-medium">Scale Cluster</span>
                </button>
                <button className="flex items-center justify-center p-4 bg-purple-600 hover:bg-purple-700 rounded-lg transition-colors duration-200">
                  <span className="text-white font-medium">Backup Data</span>
                </button>
                <button className="flex items-center justify-center p-4 bg-orange-600 hover:bg-orange-700 rounded-lg transition-colors duration-200">
                  <span className="text-white font-medium">Generate Report</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}

export default withAuth(Monitoring)
