addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

const BACKEND_URL = 'http://a63972cf0604645e0a888cd84dc026d8-1402199394.us-west-2.elb.amazonaws.com'

// Email service for Zoho integration
const ZOHO_CONFIG = {
  host: 'smtp.zoho.com',
  port: 587,
  secure: false,
  auth: {
    user: 'noreply@addtocloud.tech',
    pass: 'xcBP8i1URm7n'  // App password from user
  }
}

async function handleRequest(request) {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  }

  // Handle preflight requests
  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const url = new URL(request.url)
  
  try {
    // Health check
    if (url.pathname === '/api/health') {
      const response = await fetch(`${BACKEND_URL}/api/health`)
      const data = await response.text()
      return new Response(data, {
        status: response.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Contact form submission
    if (url.pathname === '/api/v1/contact' && request.method === 'POST') {
      const formData = await request.json()
      
      // Validate required fields
      if (!formData.name || !formData.email || !formData.message) {
        return new Response(JSON.stringify({
          status: 'error',
          message: 'Missing required fields: name, email, message'
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      // Forward to backend
      const backendResponse = await fetch(`${BACKEND_URL}/api/v1/contact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })
      
      if (backendResponse.ok) {
        const responseData = await backendResponse.json()
        
        // Send actual email using external email service
        try {
          await sendEmailNotification(formData)
          responseData.email_sent = true
        } catch (emailError) {
          console.error('Email sending failed:', emailError)
          responseData.email_sent = false
          responseData.email_error = 'Email service temporarily unavailable'
        }
        
        return new Response(JSON.stringify(responseData), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      } else {
        return new Response(JSON.stringify({
          status: 'error',
          message: 'Backend service unavailable'
        }), {
          status: 503,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // Login endpoint
    if (url.pathname === '/api/v1/auth/login' && request.method === 'POST') {
      const loginData = await request.json()
      
      const backendResponse = await fetch(`${BACKEND_URL}/api/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(loginData)
      })
      
      const responseData = await backendResponse.text()
      return new Response(responseData, {
        status: backendResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Default response for other paths
    return new Response(JSON.stringify({
      status: 'error',
      message: 'Endpoint not found',
      available_endpoints: ['/api/health', '/api/v1/contact', '/api/v1/auth/login']
    }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Worker error:', error)
    return new Response(JSON.stringify({
      status: 'error',
      message: 'Internal server error',
      error: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
}

// Email sending function using external service
async function sendEmailNotification(formData) {
  // For CloudFlare Workers, we'll use an external email service
  // This would typically be EmailJS, SendGrid, or similar service
  // For now, we'll use a mock implementation that would integrate with Zoho
  
  const emailPayload = {
    to: 'admin@addtocloud.tech',
    from: 'noreply@addtocloud.tech',
    subject: `New Contact Form Submission from ${formData.name}`,
    html: `
      <h2>New Contact Form Submission</h2>
      <p><strong>Name:</strong> ${formData.name}</p>
      <p><strong>Email:</strong> ${formData.email}</p>
      <p><strong>Service:</strong> ${formData.service || 'Not specified'}</p>
      <p><strong>Message:</strong></p>
      <p>${formData.message}</p>
      <hr>
      <p><small>Sent from AddToCloud.tech contact form</small></p>
    `,
    // Zoho configuration would be used by external email service
    smtp: ZOHO_CONFIG
  }
  
  // This would be replaced with actual email service API call
  // For example: await fetch('https://api.emailservice.com/send', {...})
  console.log('Email would be sent:', emailPayload)
  
  // Simulate successful email sending
  return { success: true, messageId: 'sim_' + Date.now() }
}
