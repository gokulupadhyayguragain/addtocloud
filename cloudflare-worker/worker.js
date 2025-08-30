export default {
  async fetch(request, env) {
    // Handle CORS preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    const url = new URL(request.url);
    
    // API routes
    if (url.pathname.startsWith('/api/')) {
      const targetUrl = `http://a646114b86e1c4d03a014b1a8fa217d0-832697644.us-west-2.elb.amazonaws.com${url.pathname}${url.search}`;
      
      // Create new request to AWS API
      const newRequest = new Request(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : null,
      });
      
      try {
        const response = await fetch(newRequest);
        const responseBody = await response.text();
        
        return new Response(responseBody, {
          status: response.status,
          statusText: response.statusText,
          headers: {
            ...Object.fromEntries(response.headers),
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept',
          },
        });
      } catch (error) {
        return new Response(JSON.stringify({ 
          error: 'API request failed', 
          message: error.message,
          timestamp: new Date().toISOString()
        }), {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        });
      }
    }
    
    // Default response for non-API routes
    return new Response(JSON.stringify({
      message: 'AddToCloud API Proxy Worker',
      status: 'operational',
      api_endpoints: [
        '/api/health',
        '/api/v1/contact',
        '/api/v1/access-request', 
        '/api/v1/deploy'
      ],
      target: 'a646114b86e1c4d03a014b1a8fa217d0-832697644.us-west-2.elb.amazonaws.com',
      timestamp: new Date().toISOString()
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  },
};
