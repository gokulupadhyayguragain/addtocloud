import { useState } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import Link from 'next/link';

export default function AdminLogin() {
  const [step, setStep] = useState('email'); // 'email' or 'otp'
  const [email, setEmail] = useState('admin@addtocloud.tech');
  const [otp, setOTP] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const router = useRouter();

  const requestOTP = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/v1/admin/request-otp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email })
      });

      if (response.ok) {
        const data = await response.json();
        setOtpSent(true);
        setStep('otp');
        setError('');
      } else {
        const errorData = await response.json();
        setError(errorData.error || 'Failed to send OTP');
      }
    } catch (err) {
      console.error('OTP request error:', err);
      setError('Failed to connect to admin API');
    } finally {
      setIsLoading(false);
    }
  };

  const verifyOTP = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      const response = await fetch(`${apiBaseUrl}/api/v1/admin/verify-otp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, otp })
      });

      if (response.ok) {
        const data = await response.json();
        // Store the admin token
        localStorage.setItem('adminToken', data.token);
        localStorage.setItem('adminUser', JSON.stringify(data.admin));
        
        // Redirect to admin dashboard
        router.push('/admin');
      } else {
        const errorData = await response.json();
        setError(errorData.error || 'Invalid OTP');
      }
    } catch (err) {
      console.error('OTP verification error:', err);
      setError('Failed to verify OTP');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOTPChange = (e) => {
    const value = e.target.value.replace(/\D/g, '').slice(0, 6);
    setOTP(value);
  };

  return (
    <>
      <Head>
        <title>Admin Login - AddToCloud</title>
        <meta name="robots" content="noindex, nofollow" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 flex items-center justify-center px-4">
        <div className="max-w-md w-full">
          {/* Header */}
          <div className="text-center mb-8">
            <Link href="/" className="text-3xl font-bold text-white inline-block mb-4">
              <span>Add</span>
              <span className="text-gradient bg-gradient-to-r from-blue-400 to-purple-600 bg-clip-text text-transparent">To</span>
              <span>Cloud</span>
            </Link>
            <h1 className="text-2xl font-bold text-white mb-2">Admin Panel</h1>
            <p className="text-slate-300">Manage user access requests and approvals</p>
          </div>

          {/* Login Form */}
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20">
            {error && (
              <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4 mb-6">
                <p className="text-red-200 text-sm">{error}</p>
              </div>
            )}

            {step === 'email' && (
              <form onSubmit={requestOTP} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Admin Email
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-4 py-3 bg-white/10 border border-slate-600/50 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="admin@addtocloud.tech"
                    required
                    disabled
                  />
                  <p className="text-xs text-slate-400 mt-1">Only admin@addtocloud.tech is allowed</p>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 disabled:from-slate-600 disabled:to-slate-700 text-white py-3 px-6 rounded-lg font-medium transition-all duration-200 shadow-lg shadow-blue-500/25 disabled:shadow-none disabled:cursor-not-allowed flex items-center justify-center"
                >
                  {isLoading ? (
                    <>
                      <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Sending OTP...
                    </>
                  ) : (
                    <>
                      📧 Send OTP to Email
                    </>
                  )}
                </button>
              </form>
            )}

            {step === 'otp' && (
              <>
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg className="w-8 h-8 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 7.89a3 3 0 004.22 0L21 9M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <h3 className="text-lg font-semibold text-white mb-2">OTP Sent!</h3>
                  <p className="text-slate-300 text-sm">Check your email for the 6-digit code</p>
                  <p className="text-slate-400 text-xs">Expires in 10 minutes</p>
                </div>

                <form onSubmit={verifyOTP} className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-slate-300 mb-2">
                      Enter OTP
                    </label>
                    <input
                      type="text"
                      value={otp}
                      onChange={handleOTPChange}
                      className="w-full px-4 py-3 bg-white/10 border border-slate-600/50 rounded-lg text-white text-center text-2xl font-mono tracking-widest placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="000000"
                      maxLength="6"
                      required
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={isLoading || otp.length !== 6}
                    className="w-full bg-gradient-to-r from-green-600 to-blue-600 hover:from-green-700 hover:to-blue-700 disabled:from-slate-600 disabled:to-slate-700 text-white py-3 px-6 rounded-lg font-medium transition-all duration-200 shadow-lg shadow-green-500/25 disabled:shadow-none disabled:cursor-not-allowed flex items-center justify-center"
                  >
                    {isLoading ? (
                      <>
                        <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Verifying OTP...
                      </>
                    ) : (
                      <>
                        🔐 Verify & Login
                      </>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setStep('email');
                      setOTP('');
                      setError('');
                    }}
                    className="w-full text-slate-400 hover:text-slate-300 text-sm transition-colors"
                  >
                    ← Back to Email
                  </button>
                </form>
              </>
            )}

            <div className="mt-6 text-center">
              <Link 
                href="/"
                className="text-slate-400 hover:text-slate-300 text-sm transition-colors"
              >
                ← Back to Homepage
              </Link>
            </div>

            {/* Development Info */}
            <div className="mt-6 p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
              <p className="text-blue-200 text-xs">
                <strong>🔧 OTP Authentication:</strong><br/>
                1. Click "Send OTP" button<br/>
                2. Check admin@addtocloud.tech email<br/>
                3. Enter 6-digit OTP code<br/>
                4. Access admin dashboard with VM provisioning
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
