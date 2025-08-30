import { useState, useEffect } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';

export default function AdminDashboard() {
  const [pendingRequests, setPendingRequests] = useState([]);
  const [provisioningStatus, setProvisioningStatus] = useState({});
  const [loading, setLoading] = useState(true);
  const [adminToken, setAdminToken] = useState(null);
  const router = useRouter();

  useEffect(() => {
    const token = localStorage.getItem('adminToken');
    const adminUser = localStorage.getItem('adminUser');
    
    if (!token || !adminUser) {
      router.push('/admin-login');
      return;
    }
    
    setAdminToken(token);
    fetchPendingRequests(token);
  }, []);

  const fetchPendingRequests = async (token) => {
    try {
      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/admin/requests`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setPendingRequests(data.requests || []);
      } else if (response.status === 401) {
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminUser');
        router.push('/admin-login');
      }
    } catch (error) {
      console.error('Failed to fetch requests:', error);
    } finally {
      setLoading(false);
    }
  };

  const approveUser = async (request) => {
    try {
      setProvisioningStatus(prev => ({ ...prev, [request.id]: 'approving' }));

      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      
      const approveResponse = await fetch(`${apiBaseUrl}/api/admin/requests/${request.id}/approve`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
      });

      if (!approveResponse.ok) throw new Error('Approval failed');
      const approvalData = await approveResponse.json();

      setProvisioningStatus(prev => ({ ...prev, [request.id]: 'provisioning-vm' }));

      const vmResponse = await fetch(`${apiBaseUrl}/api/admin/provision-vm`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: approvalData.user.id
        })
      });

      if (!vmResponse.ok) throw new Error('VM provisioning failed');
      const vmData = await vmResponse.json();

      setProvisioningStatus(prev => ({ ...prev, [request.id]: 'completed' }));

      setPendingRequests(prev => 
        prev.map(req => 
          req.id === request.id 
            ? { ...req, status: 'approved', vmDetails: vmData }
            : req
        )
      );

      alert(`✅ User approved and VM provisioned!\n\nInstance: ${vmData.instance.instanceId}\nPublic IP: ${vmData.instance.publicIp}\n\nCredentials are ready for manual delivery.`);

    } catch (error) {
      console.error('Approval/provisioning error:', error);
      setProvisioningStatus(prev => ({ ...prev, [request.id]: 'error' }));
      alert(`❌ Error: ${error.message}`);
    }
  };

  const rejectUser = async (request) => {
    if (!confirm(`Are you sure you want to reject ${request.firstName} ${request.lastName}'s request?`)) {
      return;
    }

    try {
      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/admin/requests/${request.id}/reject`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        setPendingRequests(prev => 
          prev.map(req => 
            req.id === request.id 
              ? { ...req, status: 'rejected' }
              : req
          )
        );
        alert(`❌ Request rejected for ${request.firstName} ${request.lastName}`);
      } else {
        throw new Error('Rejection failed');
      }
    } catch (error) {
      console.error('Rejection error:', error);
      alert(`Error rejecting request: ${error.message}`);
    }
  };

  const provisionAdminVM = async () => {
    if (!confirm('Do you want to provision an admin VM for yourself?')) {
      return;
    }

    try {
      setProvisioningStatus(prev => ({ ...prev, 'admin': 'provisioning' }));

      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/admin/provision-admin-vm`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setProvisioningStatus(prev => ({ ...prev, 'admin': 'completed' }));
        alert(`🔧 Admin VM provisioned!\n\nInstance: ${data.instance.instanceId}\nPublic IP: ${data.instance.publicIp}\n\nEnhanced with monitoring and management tools.`);
      } else {
        throw new Error('Admin VM provisioning failed');
      }
    } catch (error) {
      console.error('Admin VM provisioning error:', error);
      setProvisioningStatus(prev => ({ ...prev, 'admin': 'error' }));
      alert(`Error: ${error.message}`);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    router.push('/admin-login');
  };

  const getStatusBadge = (status, requestId) => {
    const provStatus = provisioningStatus[requestId];
    
    if (provStatus === 'approving') return <span className="bg-yellow-500/20 text-yellow-300 px-2 py-1 rounded text-xs">Approving...</span>;
    if (provStatus === 'provisioning-vm') return <span className="bg-blue-500/20 text-blue-300 px-2 py-1 rounded text-xs">Provisioning VM...</span>;
    if (provStatus === 'completed') return <span className="bg-green-500/20 text-green-300 px-2 py-1 rounded text-xs">✅ Completed</span>;
    if (provStatus === 'error') return <span className="bg-red-500/20 text-red-300 px-2 py-1 rounded text-xs">❌ Error</span>;
    
    switch (status) {
      case 'pending': return <span className="bg-yellow-500/20 text-yellow-300 px-2 py-1 rounded text-xs">🕐 Pending Review</span>;
      case 'approved': return <span className="bg-green-500/20 text-green-300 px-2 py-1 rounded text-xs">✅ Approved</span>;
      case 'rejected': return <span className="bg-red-500/20 text-red-300 px-2 py-1 rounded text-xs">❌ Rejected</span>;
      default: return <span className="bg-gray-500/20 text-gray-300 px-2 py-1 rounded text-xs">{status}</span>;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 flex items-center justify-center">
        <div className="text-white text-center">
          <div className="animate-spin w-8 h-8 border-2 border-white border-t-transparent rounded-full mx-auto mb-4"></div>
          <p>Loading admin dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      <Head>
        <title>Admin Dashboard - AddToCloud</title>
        <meta name="robots" content="noindex, nofollow" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900">
        <header className="bg-slate-900/90 backdrop-blur-md border-b border-slate-700/50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between items-center h-16">
              <div className="flex items-center space-x-4">
                <h1 className="text-2xl font-bold text-white">
                  <span className="text-gradient bg-gradient-to-r from-blue-400 to-purple-600 bg-clip-text text-transparent">AddToCloud</span>
                  <span className="text-white"> Admin</span>
                </h1>
                <span className="bg-blue-500/20 text-blue-300 px-3 py-1 rounded-full text-sm">OTP Authenticated</span>
              </div>
              <div className="flex items-center space-x-4">
                <button
                  onClick={provisionAdminVM}
                  disabled={provisioningStatus['admin'] === 'provisioning'}
                  className="bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 text-white px-4 py-2 rounded-lg text-sm transition-colors"
                >
                  {provisioningStatus['admin'] === 'provisioning' ? '🔧 Provisioning...' : '🔧 Provision Admin VM'}
                </button>
                <button
                  onClick={handleLogout}
                  className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg text-sm transition-colors"
                >
                  🚪 Logout
                </button>
              </div>
            </div>
          </div>
        </header>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="grid md:grid-cols-3 gap-6 mb-8">
            <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
              <h3 className="text-lg font-semibold text-white mb-2">Pending Requests</h3>
              <p className="text-3xl font-bold text-yellow-400">{pendingRequests.filter(r => r.status === 'pending').length}</p>
            </div>
            <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
              <h3 className="text-lg font-semibold text-white mb-2">Approved</h3>
              <p className="text-3xl font-bold text-green-400">{pendingRequests.filter(r => r.status === 'approved').length}</p>
            </div>
            <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
              <h3 className="text-lg font-semibold text-white mb-2">Rejected</h3>
              <p className="text-3xl font-bold text-red-400">{pendingRequests.filter(r => r.status === 'rejected').length}</p>
            </div>
          </div>

          <div className="bg-white/10 backdrop-blur-lg rounded-xl border border-white/20 overflow-hidden">
            <div className="px-6 py-4 border-b border-white/20">
              <h2 className="text-xl font-bold text-white">Access Requests</h2>
              <p className="text-slate-300 text-sm">Manual review and approval required</p>
            </div>
            
            {pendingRequests.length === 0 ? (
              <div className="p-8 text-center">
                <p className="text-slate-400">No access requests found</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-800/50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">User</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Company</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Reason</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/10">
                    {pendingRequests.map((request) => (
                      <tr key={request.id} className="hover:bg-white/5">
                        <td className="px-6 py-4">
                          <div>
                            <p className="text-white font-medium">{request.firstName} {request.lastName}</p>
                            <p className="text-slate-400 text-sm">{request.email}</p>
                            <p className="text-slate-500 text-xs">{request.phone}</p>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div>
                            <p className="text-white">{request.company}</p>
                            <p className="text-slate-400 text-sm">{request.city}, {request.country}</p>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="max-w-xs">
                            <p className="text-slate-300 text-sm">{request.businessReason}</p>
                            <details className="mt-2">
                              <summary className="text-blue-400 text-xs cursor-pointer">View Project Details</summary>
                              <p className="text-slate-400 text-xs mt-1">{request.projectDescription}</p>
                            </details>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          {getStatusBadge(request.status, request.id)}
                        </td>
                        <td className="px-6 py-4">
                          {request.status === 'pending' && (
                            <div className="flex space-x-2">
                              <button
                                onClick={() => approveUser(request)}
                                disabled={provisioningStatus[request.id]}
                                className="bg-green-600 hover:bg-green-700 disabled:bg-gray-600 text-white px-3 py-1 rounded text-sm transition-colors"
                              >
                                {provisioningStatus[request.id] ? '⏳' : '✅ Approve & Provision VM'}
                              </button>
                              <button
                                onClick={() => rejectUser(request)}
                                disabled={provisioningStatus[request.id]}
                                className="bg-red-600 hover:bg-red-700 disabled:bg-gray-600 text-white px-3 py-1 rounded text-sm transition-colors"
                              >
                                ❌ Reject
                              </button>
                            </div>
                          )}
                          {request.status === 'approved' && request.vmDetails && (
                            <div className="text-xs">
                              <p className="text-green-300">✅ VM Provisioned</p>
                              <p className="text-slate-400">IP: {request.vmDetails.instance.publicIp}</p>
                              <p className="text-slate-400">Instance: {request.vmDetails.instance.instanceId}</p>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className="mt-8 bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-blue-300 mb-3">🔧 VM Provisioning Details</h3>
            <div className="grid md:grid-cols-2 gap-4 text-sm">
              <div>
                <h4 className="font-medium text-white mb-2">✅ Auto-Provisioned Per User:</h4>
                <ul className="text-slate-300 space-y-1">
                  <li>• Free-tier EC2 t2.micro instance</li>
                  <li>• Dedicated security group & key pair</li>
                  <li>• Public IP with SSH access</li>
                  <li>• Pre-installed AWS CLI, Azure CLI, GCP CLI</li>
                </ul>
              </div>
              <div>
                <h4 className="font-medium text-white mb-2">🔑 Credential Management:</h4>
                <ul className="text-slate-300 space-y-1">
                  <li>• KMS-managed API keys</li>
                  <li>• Generated SSH key pairs</li>
                  <li>• Multi-cloud authentication</li>
                  <li>• Manual delivery by admin</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
