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
    // Check if admin is authenticated
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
        // Token expired, redirect to login
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
      
      // Step 1: Approve the request
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

      // Step 2: Provision VM
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

      // Update the request status in UI
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

      // Step 2: Provision EC2 infrastructure
      const ec2Response = await fetch('/api/admin/provision-ec2', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: userData.userId,
          email: request.email,
          instanceName: `addtocloud-${request.firstName.toLowerCase()}-${request.lastName.toLowerCase()}`
        })
      });

      if (!ec2Response.ok) throw new Error('EC2 provisioning failed');
      const ec2Data = await ec2Response.json();

      // Step 3: Send credentials email
      const emailResponse = await fetch('/api/admin/send-credentials', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: request.email,
          firstName: request.firstName,
          credentials: userData.credentials,
          ec2Details: ec2Data.instanceDetails
        })
      });

      if (!emailResponse.ok) throw new Error('Email sending failed');

      // Update UI
      setPendingRequests(prev => 
        prev.map(req => 
          req.id === request.id 
            ? { ...req, status: 'approved', approvedAt: new Date().toISOString() }
            : req
        )
      );

      setProvisioningStatus(prev => ({ ...prev, [request.id]: 'completed' }));

      alert(`✅ User approved successfully!\n\nEC2 Instance: ${ec2Data.instanceDetails.publicIp}\nCredentials sent to: ${request.email}`);

    } catch (error) {
      console.error('Approval failed:', error);
      setProvisioningStatus(prev => ({ ...prev, [request.id]: 'failed' }));
      alert(`❌ Approval failed: ${error.message}`);
    }
  };

  const rejectUser = (request) => {
    if (confirm(`Are you sure you want to reject ${request.firstName} ${request.lastName}?`)) {
      setPendingRequests(prev => 
        prev.map(req => 
          req.id === request.id 
            ? { ...req, status: 'rejected', rejectedAt: new Date().toISOString() }
            : req
        )
      );
    }
  };

  const getStatusBadge = (status, requestId) => {
    const provStatus = provisioningStatus[requestId];
    
    if (provStatus === 'provisioning') {
      return (
        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-blue-500/20 text-blue-400 border border-blue-500/30">
          <svg className="animate-spin -ml-1 mr-2 h-3 w-3" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Provisioning...
        </span>
      );
    }

    switch (status) {
      case 'pending':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-yellow-500/20 text-yellow-400 border border-yellow-500/30">⏳ Pending Review</span>;
      case 'approved':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-500/20 text-green-400 border border-green-500/30">✅ Approved</span>;
      case 'rejected':
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-red-500/20 text-red-400 border border-red-500/30">❌ Rejected</span>;
      default:
        return <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gray-500/20 text-gray-400 border border-gray-500/30">Unknown</span>;
    }
  };

  return (
    <>
      <Head>
        <title>Admin Dashboard - AddToCloud</title>
        <meta name="description" content="Admin dashboard for managing user access requests" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900">
        {/* Header */}
        <header className="bg-slate-900/90 backdrop-blur-md border-b border-slate-700/50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between items-center h-16">
              <div className="text-2xl font-bold text-white">
                <span>🛡️ AddToCloud</span>
                <span className="text-gradient bg-gradient-to-r from-blue-400 to-purple-600 bg-clip-text text-transparent ml-2">Admin</span>
              </div>
              <div className="text-slate-300 text-sm">
                Manual User Approval System
              </div>
            </div>
          </div>
        </header>

        {/* Content */}
        <div className="py-12 px-4 sm:px-6 lg:px-8">
          <div className="max-w-7xl mx-auto">
            <div className="mb-8">
              <h1 className="text-4xl font-bold text-white mb-4">
                User Access Requests
              </h1>
              <p className="text-xl text-slate-300">
                Review and approve user access requests. Approved users get auto-provisioned EC2 infrastructure.
              </p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
                <div className="text-3xl font-bold text-yellow-400">{pendingRequests.filter(r => r.status === 'pending').length}</div>
                <div className="text-slate-300">Pending Requests</div>
              </div>
              <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
                <div className="text-3xl font-bold text-green-400">{pendingRequests.filter(r => r.status === 'approved').length}</div>
                <div className="text-slate-300">Approved Users</div>
              </div>
              <div className="bg-white/10 backdrop-blur-lg rounded-xl p-6 border border-white/20">
                <div className="text-3xl font-bold text-red-400">{pendingRequests.filter(r => r.status === 'rejected').length}</div>
                <div className="text-slate-300">Rejected Requests</div>
              </div>
            </div>

            {/* Requests Table */}
            <div className="bg-white/10 backdrop-blur-lg rounded-xl border border-white/20 overflow-hidden">
              <div className="p-6 border-b border-white/20">
                <h3 className="text-xl font-bold text-white">Access Requests</h3>
              </div>
              
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-800/50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">User</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Company</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Business Reason</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Submitted</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-700/50">
                    {pendingRequests.map((request) => (
                      <tr key={request.id} className="hover:bg-white/5">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div>
                            <div className="text-sm font-medium text-white">
                              {request.firstName} {request.lastName}
                            </div>
                            <div className="text-sm text-slate-400">{request.email}</div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-300">
                          {request.company}
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-slate-300 max-w-xs">
                            {request.businessReason}
                          </div>
                          <div className="text-xs text-slate-500 mt-1">
                            {request.projectDescription.substring(0, 60)}...
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-400">
                          {new Date(request.submittedAt).toLocaleDateString()}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {getStatusBadge(request.status, request.id)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          {request.status === 'pending' && (
                            <div className="flex space-x-2">
                              <button
                                onClick={() => approveUser(request)}
                                disabled={provisioningStatus[request.id] === 'provisioning'}
                                className="bg-green-600 hover:bg-green-700 disabled:bg-green-800 text-white px-3 py-1 rounded text-xs font-medium transition-colors disabled:cursor-not-allowed"
                              >
                                ✅ Approve & Provision
                              </button>
                              <button
                                onClick={() => rejectUser(request)}
                                disabled={provisioningStatus[request.id] === 'provisioning'}
                                className="bg-red-600 hover:bg-red-700 disabled:bg-red-800 text-white px-3 py-1 rounded text-xs font-medium transition-colors disabled:cursor-not-allowed"
                              >
                                ❌ Reject
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Auto-Provisioning Info */}
            <div className="mt-8 bg-blue-500/10 border border-blue-500/30 rounded-lg p-6">
              <h4 className="text-blue-400 font-medium mb-3">🚀 Auto-Provisioning Process</h4>
              <div className="text-blue-200 text-sm space-y-2">
                <div><strong>Step 1:</strong> Create user account with secure auto-generated password</div>
                <div><strong>Step 2:</strong> Provision dedicated free-tier EC2 instance (t2.micro)</div>
                <div><strong>Step 3:</strong> Install AWS CLI, Azure CLI, and GCP CLI on the instance</div>
                <div><strong>Step 4:</strong> Configure user-specific access and security groups</div>
                <div><strong>Step 5:</strong> Send login credentials and instance details via email</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
