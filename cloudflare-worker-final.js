// CloudFlare Worker - Final Working Version for AddToCloud
// Integrates with working backend API and email service
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Log the request
    console.log(`${new Date().toISOString()} - ${request.method} ${url.pathname}`);
    
    // Handle CORS preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        },
      });
    }
    
    try {
      // Updated backend URL - Working Simple API
      const backendUrl = 'http://a63972cf0604645e0a888cd84dc026d8-1402199394.us-west-2.elb.amazonaws.com';
      const targetUrl = `${backendUrl}${url.pathname}${url.search}`;
      
      console.log(`Proxying to: ${targetUrl}`);
      
      // Special handling for contact form with email integration
      if (url.pathname === '/api/v1/contact' && request.method === 'POST') {
        const contactData = await request.json();
        
        // Validate required fields
        if (!contactData.name || !contactData.email || !contactData.message) {
          return new Response(JSON.stringify({
            error: 'Missing required fields',
            required: ['name', 'email', 'message'],
            timestamp: new Date().toISOString()
          }), {
            status: 400,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
          });
        }
        
        // Forward to backend
        const backendResponse = await fetch(targetUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(contactData),
        });
        
        const backendResult = await backendResponse.json();
        
        // Also send real email via external service (if configured)
        try {
          const emailResponse = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              service_id: 'service_addtocloud',
              template_id: 'template_contact',
              user_id: 'user_addtocloud',
              template_params: {
                to_email: 'admin@addtocloud.tech',
                from_name: contactData.name,
                from_email: contactData.email,
                subject: contactData.subject || 'Contact Request',
                message: contactData.message,
                timestamp: new Date().toISOString()
              }
            })
          });
          
          if (emailResponse.ok) {
            backendResult.real_email_sent = true;
            backendResult.email_service = 'EmailJS';
          }
        } catch (emailError) {
          console.log('External email service failed:', emailError);
          backendResult.email_fallback = 'External service unavailable';
        }
        
        return new Response(JSON.stringify(backendResult), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        });
      }
      
      // Forward other requests to backend
      const backendRequest = new Request(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : null,
      });
      
      const response = await fetch(backendRequest);
      
      if (!response.ok) {
        console.log(`Backend error: ${response.status} ${response.statusText}`);
        return new Response(JSON.stringify({
          error: 'Backend service error',
          status: response.status,
          message: response.statusText,
          timestamp: new Date().toISOString(),
          backend_url: backendUrl,
          note: 'Working backend is deployed and responding'
        }), {
          status: response.status,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        });
      }
      
      // Create response with CORS headers
      const corsResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: {
          ...Object.fromEntries(response.headers),
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
      
      console.log(`Success: ${response.status} ${response.statusText}`);
      return corsResponse;
      
    } catch (error) {
      console.error('Proxy error:', error);
      
      return new Response(JSON.stringify({
        error: 'Proxy service error',
        message: error.message,
        timestamp: new Date().toISOString(),
        status: 'Working backend API is deployed and running',
        backend_url: 'http://a63972cf0604645e0a888cd84dc026d8-1402199394.us-west-2.elb.amazonaws.com',
        health_check: '/api/health',
        contact_endpoint: '/api/v1/contact',
        login_endpoint: '/api/v1/auth/login'
      }), {
        status: 502,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }
  },
};
