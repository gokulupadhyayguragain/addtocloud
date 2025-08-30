import { useState } from 'react'
import Head from 'next/head'
import Navigation from '../components/layout/Navigation'

export default function RequestAccess() {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    address: '',
    city: '',
    country: '',
    businessReason: '',
    projectDescription: ''
  })
  
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [error, setError] = useState('')

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsSubmitting(true)
    setError('')

    try {
      const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
      const apiUrl = `${apiBaseUrl}/api/v1/request-access`;
      console.log('Submitting to API:', apiUrl);
      console.log('Form data:', formData);
      
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
      })
      
      console.log('Response status:', response.status);
      console.log('Response headers:', Object.fromEntries(response.headers.entries()));

      if (response.ok) {
        const result = await response.json();
        console.log('Success response:', result);
        setIsSubmitted(true)
      } else {
        const errorData = await response.text();
        console.error('Error response:', errorData);
        throw new Error(`HTTP ${response.status}: ${errorData}`)
      }
    } catch (err) {
      console.error('Full error details:', err);
      console.error('Error name:', err.name);
      console.error('Error message:', err.message);
      setError(`Failed to submit request. Please try again. Error: ${err.message}`)
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isSubmitted) {
    return (
      <>
        <Head>
          <title>Access Request Submitted - AddToCloud</title>
        </Head>
        <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
          <Navigation />
          <div className="pt-24 pb-16 px-4">
            <div className="max-w-2xl mx-auto text-center">
              <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20">
                <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
                  <svg className="w-8 h-8 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h1 className="text-3xl font-bold text-white mb-4">Request Submitted Successfully!</h1>
                <p className="text-slate-300 mb-6">
                  Thank you for your interest in AddToCloud. Your access request has been received and is under review.
                </p>
                <div className="bg-blue-500/20 rounded-lg p-4 mb-6">
                  <p className="text-blue-200 text-sm">
                    <strong>What happens next:</strong><br/>
                    1. Our team will review your application<br/>
                    2. If approved, you'll receive an email with your login credentials<br/>
                    3. Your auto-generated password will be secure and unique to you
                  </p>
                </div>
                <p className="text-slate-400 text-sm">
                  Questions? Contact us at support@addtocloud.tech
                </p>
              </div>
            </div>
          </div>
        </div>
      </>
    )
  }

  return (
    <>
      <Head>
        <title>Request Access - AddToCloud</title>
        <meta name="description" content="Request access to AddToCloud enterprise platform" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
        <Navigation />
        
        <div className="pt-24 pb-16 px-4">
          <div className="max-w-2xl mx-auto">
            <div className="text-center mb-8">
              <h1 className="text-4xl font-bold text-white mb-4">Request Platform Access</h1>
              <p className="text-slate-300">
                AddToCloud is an exclusive enterprise platform. Please provide your information for review and approval.
              </p>
            </div>

            <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20">
              {error && (
                <div className="bg-red-500/20 border border-red-500/50 rounded-lg p-4 mb-6">
                  <p className="text-red-200">{error}</p>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Personal Information */}
                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Personal Information</h3>
                  <div className="grid md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        First Name *
                      </label>
                      <input
                        type="text"
                        name="firstName"
                        required
                        value={formData.firstName}
                        onChange={handleChange}
                        className="input-field"
                        placeholder="Enter your first name"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Last Name *
                      </label>
                      <input
                        type="text"
                        name="lastName"
                        required
                        value={formData.lastName}
                        onChange={handleChange}
                        className="input-field"
                        placeholder="Enter your last name"
                      />
                    </div>
                  </div>
                </div>

                {/* Contact Information */}
                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Contact Information</h3>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Email Address *
                      </label>
                      <input
                        type="email"
                        name="email"
                        required
                        value={formData.email}
                        onChange={handleChange}
                        className="input-field"
                        placeholder="your.email@company.com"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Phone Number *
                      </label>
                      <input
                        type="tel"
                        name="phone"
                        required
                        value={formData.phone}
                        onChange={handleChange}
                        className="input-field"
                        placeholder="+1 (555) 123-4567"
                      />
                    </div>
                  </div>
                </div>

                {/* Business Information */}
                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Business Information</h3>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Company/Organization *
                      </label>
                      <input
                        type="text"
                        name="company"
                        required
                        value={formData.company}
                        onChange={handleChange}
                        className="input-field"
                        placeholder="Your company name"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Business Address *
                      </label>
                      <input
                        type="text"
                        name="address"
                        required
                        value={formData.address}
                        onChange={handleChange}
                        className="input-field"
                        placeholder="Street address"
                      />
                    </div>
                    <div className="grid md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-2">
                          City *
                        </label>
                        <input
                          type="text"
                          name="city"
                          required
                          value={formData.city}
                          onChange={handleChange}
                          className="input-field"
                          placeholder="City"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-300 mb-2">
                          Country *
                        </label>
                        <input
                          type="text"
                          name="country"
                          required
                          value={formData.country}
                          onChange={handleChange}
                          className="input-field"
                          placeholder="Country"
                        />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Use Case Information */}
                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Platform Usage</h3>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Business Reason for Access *
                      </label>
                      <textarea
                        name="businessReason"
                        required
                        value={formData.businessReason}
                        onChange={handleChange}
                        rows={3}
                        className="input-field"
                        placeholder="Describe why you need access to AddToCloud platform..."
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-300 mb-2">
                        Project Description
                      </label>
                      <textarea
                        name="projectDescription"
                        value={formData.projectDescription}
                        onChange={handleChange}
                        rows={3}
                        className="input-field"
                        placeholder="Briefly describe your project or use case (optional)..."
                      />
                    </div>
                  </div>
                </div>

                {/* Important Notice */}
                <div className="bg-yellow-500/20 border border-yellow-500/50 rounded-lg p-4">
                  <div className="flex items-start space-x-3">
                    <svg className="w-5 h-5 text-yellow-400 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                    </svg>
                    <div className="text-yellow-200 text-sm">
                      <p className="font-medium mb-1">Important Information:</p>
                      <ul className="list-disc list-inside space-y-1">
                        <li>Access is granted on approval basis only</li>
                        <li>Login credentials will be emailed to you if approved</li>
                        <li>Passwords are auto-generated and cannot be changed</li>
                        <li>This platform is exclusive to authorized team members</li>
                      </ul>
                    </div>
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isSubmitting}
                  className={`w-full btn-primary ${isSubmitting ? 'opacity-50 cursor-not-allowed' : ''}`}
                >
                  {isSubmitting ? 'Submitting Request...' : 'Submit Access Request'}
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
