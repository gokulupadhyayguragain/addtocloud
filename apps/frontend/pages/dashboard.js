import Head from 'next/head'
import Navigation from '../components/layout/Navigation'
import { withAuth } from '../context/AuthContext'

function Dashboard() {
  const metrics = [
    { name: 'Total Services', value: '24', change: '+12%', color: 'text-green-400' },
    { name: 'Active Users', value: '1,234', change: '+8%', color: 'text-green-400' },
    { name: 'Server Uptime', value: '99.9%', change: '+0.1%', color: 'text-green-400' },
    { name: 'Response Time', value: '45ms', change: '-5ms', color: 'text-green-400' },
  ]

  const services = [
    { name: 'Web Application', status: 'Running', cpu: '45%', memory: '67%' },
    { name: 'Database Server', status: 'Running', cpu: '23%', memory: '34%' },
    { name: 'API Gateway', status: 'Running', cpu: '12%', memory: '28%' },
    { name: 'Cache Service', status: 'Running', cpu: '8%', memory: '15%' },
  ]

  return (
    <>
      <Head>
        <title>Dashboard - AddToCloud</title>
        <meta name="description" content="AddToCloud Enterprise Dashboard" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <div className="pt-24 pb-16 px-4">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <div className="mb-8">
              <h1 className="text-4xl font-bold text-white mb-2">Dashboard</h1>
              <p className="text-slate-400">Monitor and manage your cloud infrastructure</p>
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              {metrics.map((metric, index) => (
                <div key={index} className="card">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-slate-400 text-sm">{metric.name}</p>
                      <p className="text-2xl font-bold text-white">{metric.value}</p>
                    </div>
                    <div className={`text-sm font-medium ${metric.color}`}>
                      {metric.change}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Services Status */}
            <div className="grid lg:grid-cols-2 gap-8">
              <div className="card">
                <h2 className="text-xl font-semibold text-white mb-6">Service Status</h2>
                <div className="space-y-4">
                  {services.map((service, index) => (
                    <div key={index} className="flex items-center justify-between p-4 bg-slate-700/30 rounded-lg">
                      <div>
                        <h3 className="text-white font-medium">{service.name}</h3>
                        <div className="flex items-center space-x-2 mt-1">
                          <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                          <span className="text-sm text-slate-400">{service.status}</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-slate-400">CPU: {service.cpu}</p>
                        <p className="text-sm text-slate-400">Memory: {service.memory}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Quick Actions */}
              <div className="card">
                <h2 className="text-xl font-semibold text-white mb-6">Quick Actions</h2>
                <div className="grid grid-cols-2 gap-4">
                  <button className="btn-primary text-center py-4">
                    Deploy Service
                  </button>
                  <button className="btn-secondary text-center py-4">
                    View Logs
                  </button>
                  <button className="btn-secondary text-center py-4">
                    Scale Resources
                  </button>
                  <button className="btn-secondary text-center py-4">
                    Monitor Health
                  </button>
                </div>
                
                <div className="mt-6 p-4 bg-primary-500/10 border border-primary-500/20 rounded-lg">
                  <h3 className="text-primary-400 font-medium mb-2">System Health</h3>
                  <p className="text-sm text-slate-300">All systems operational. No issues detected.</p>
                </div>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="mt-8">
              <div className="card">
                <h2 className="text-xl font-semibold text-white mb-6">Recent Activity</h2>
                <div className="space-y-3">
                  {[
                    { action: 'Service deployed', time: '2 minutes ago', type: 'success' },
                    { action: 'Database backup completed', time: '15 minutes ago', type: 'info' },
                    { action: 'SSL certificate renewed', time: '1 hour ago', type: 'success' },
                    { action: 'Scaling policy updated', time: '3 hours ago', type: 'info' },
                  ].map((activity, index) => (
                    <div key={index} className="flex items-center justify-between p-3 bg-slate-700/20 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <div className={`w-2 h-2 rounded-full ${activity.type === 'success' ? 'bg-green-400' : 'bg-blue-400'}`}></div>
                        <span className="text-white">{activity.action}</span>
                      </div>
                      <span className="text-sm text-slate-400">{activity.time}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}

export default withAuth(Dashboard)
