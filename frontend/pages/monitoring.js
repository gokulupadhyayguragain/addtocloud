import { useState, useEffect } from 'react';
import Head from 'next/head';
import Link from 'next/link';

export default function Monitoring() {
  const [alerts, setAlerts] = useState([
    { id: 1, severity: 'warning', service: 'Cloud Service', message: 'High CPU usage detected', time: '2 minutes ago' },
    { id: 2, severity: 'info', service: 'API Gateway', message: 'New deployment successful', time: '15 minutes ago' },
    { id: 3, severity: 'resolved', service: 'Database', message: 'Connection pool optimized', time: '1 hour ago' }
  ]);

  const [metrics, setMetrics] = useState({
    requestRate: 0,
    errorRate: 0,
    responseTime: 0,
    throughput: 0
  });

  useEffect(() => {
    // Simulate real-time metrics
    const interval = setInterval(() => {
      setMetrics({
        requestRate: Math.floor(Math.random() * 500) + 1000,
        errorRate: Math.random() * 2,
        responseTime: Math.floor(Math.random() * 50) + 50,
        throughput: Math.floor(Math.random() * 200) + 800
      });
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'critical':
        return 'text-red-400 bg-red-500/20 border-red-500/30';
      case 'warning':
        return 'text-yellow-400 bg-yellow-500/20 border-yellow-500/30';
      case 'info':
        return 'text-blue-400 bg-blue-500/20 border-blue-500/30';
      case 'resolved':
        return 'text-green-400 bg-green-500/20 border-green-500/30';
      default:
        return 'text-gray-400 bg-gray-500/20 border-gray-500/30';
    }
  };

  return (
    <>
      <Head>
        <title>Monitoring - AddToCloud Enterprise Platform</title>
        <meta name="description" content="Real-time monitoring and alerting dashboard" />
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
                <Link href="/services" className="text-gray-300 hover:text-white transition-colors">
                  Services
                </Link>
                <Link href="/dashboard" className="text-gray-300 hover:text-white transition-colors">
                  Dashboard
                </Link>
                <Link href="/monitoring" className="text-white font-semibold">
                  Monitoring
                </Link>
              </nav>
            </div>
          </div>
        </header>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Page Title */}
          <div className="mb-8">
            <h1 className="text-4xl font-bold text-white mb-2">Monitoring & Alerts</h1>
            <p className="text-gray-300">Real-time observability across your cloud infrastructure</p>
          </div>

          {/* Real-time Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Request Rate</h3>
                <span className="text-2xl">📈</span>
              </div>
              <p className="text-3xl font-bold text-blue-400">{metrics.requestRate}</p>
              <p className="text-gray-300 text-sm">requests/sec</p>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Error Rate</h3>
                <span className="text-2xl">⚠️</span>
              </div>
              <p className="text-3xl font-bold text-yellow-400">{metrics.errorRate.toFixed(2)}%</p>
              <p className="text-gray-300 text-sm">of total requests</p>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Response Time</h3>
                <span className="text-2xl">⏱️</span>
              </div>
              <p className="text-3xl font-bold text-green-400">{metrics.responseTime}ms</p>
              <p className="text-gray-300 text-sm">avg response</p>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Throughput</h3>
                <span className="text-2xl">🚀</span>
              </div>
              <p className="text-3xl font-bold text-purple-400">{metrics.throughput}</p>
              <p className="text-gray-300 text-sm">MB/s</p>
            </div>
          </div>

          {/* Monitoring Tools */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-6">Monitoring Tools</h2>
              <div className="space-y-4">
                <div className="bg-white/5 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-lg font-semibold text-white">Grafana Dashboard</h3>
                    <span className="text-green-400">🟢 Online</span>
                  </div>
                  <p className="text-gray-300 text-sm mb-3">Advanced visualization and analytics</p>
                  <button className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg text-sm transition-colors">
                    Open Grafana
                  </button>
                </div>

                <div className="bg-white/5 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-lg font-semibold text-white">Prometheus Metrics</h3>
                    <span className="text-green-400">🟢 Collecting</span>
                  </div>
                  <p className="text-gray-300 text-sm mb-3">Time-series monitoring and alerting</p>
                  <button className="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded-lg text-sm transition-colors">
                    View Metrics
                  </button>
                </div>

                <div className="bg-white/5 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-lg font-semibold text-white">Istio Service Mesh</h3>
                    <span className="text-green-400">🟢 Active</span>
                  </div>
                  <p className="text-gray-300 text-sm mb-3">Service-to-service observability</p>
                  <button className="bg-purple-500 hover:bg-purple-600 text-white px-4 py-2 rounded-lg text-sm transition-colors">
                    Service Graph
                  </button>
                </div>
              </div>
            </div>

            {/* Recent Alerts */}
            <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-6">Recent Alerts</h2>
              <div className="space-y-4">
                {alerts.map((alert) => (
                  <div key={alert.id} className="bg-white/5 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className={`text-sm px-3 py-1 rounded-full border ${getSeverityColor(alert.severity)}`}>
                        {alert.severity.toUpperCase()}
                      </span>
                      <span className="text-gray-400 text-sm">{alert.time}</span>
                    </div>
                    <h3 className="text-white font-medium mb-1">{alert.service}</h3>
                    <p className="text-gray-300 text-sm">{alert.message}</p>
                  </div>
                ))}
              </div>
              
              <button className="w-full mt-6 bg-gray-600 hover:bg-gray-700 text-white py-2 px-4 rounded-lg text-sm transition-colors">
                View All Alerts
              </button>
            </div>
          </div>

          {/* Infrastructure Status */}
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20 mb-8">
            <h2 className="text-2xl font-bold text-white mb-6">Infrastructure Status</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="text-4xl mb-3">☁️</div>
                <h3 className="text-lg font-semibold text-white mb-2">AWS EKS</h3>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">Nodes:</span>
                    <span className="text-green-400">3/3 Ready</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">Pods:</span>
                    <span className="text-green-400">12/12 Running</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">CPU:</span>
                    <span className="text-blue-400">45%</span>
                  </div>
                </div>
              </div>

              <div className="text-center">
                <div className="text-4xl mb-3">🌐</div>
                <h3 className="text-lg font-semibold text-white mb-2">Azure AKS</h3>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">Nodes:</span>
                    <span className="text-green-400">2/2 Ready</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">Pods:</span>
                    <span className="text-green-400">8/8 Running</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">CPU:</span>
                    <span className="text-blue-400">38%</span>
                  </div>
                </div>
              </div>

              <div className="text-center">
                <div className="text-4xl mb-3">🌍</div>
                <h3 className="text-lg font-semibold text-white mb-2">GCP GKE</h3>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">Nodes:</span>
                    <span className="text-yellow-400">2/3 Ready</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">Pods:</span>
                    <span className="text-green-400">6/6 Running</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-300">CPU:</span>
                    <span className="text-yellow-400">67%</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* CloudFlare Analytics */}
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 border border-white/20">
            <h2 className="text-2xl font-bold text-white mb-6">CloudFlare Analytics</h2>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-blue-400 mb-2">1.2M</div>
                <p className="text-gray-300 text-sm">Total Requests</p>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-green-400 mb-2">156ms</div>
                <p className="text-gray-300 text-sm">Avg. Response Time</p>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-purple-400 mb-2">99.9%</div>
                <p className="text-gray-300 text-sm">Cache Hit Ratio</p>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-yellow-400 mb-2">45GB</div>
                <p className="text-gray-300 text-sm">Bandwidth Saved</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
