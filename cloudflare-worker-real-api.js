// CloudFlare Worker for AddToCloud API Proxy
// Updated with Real API Backend
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
      // Updated backend URL for real API with email support
      const backendUrl = 'http://a63972cf0604645e0a888cd84dc026d8-1402199394.us-west-2.elb.amazonaws.com';
      const targetUrl = `${backendUrl}${url.pathname}${url.search}`;
      
      console.log(`Proxying to: ${targetUrl}`);
      
      // Forward the request to the backend
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
          backend_url: backendUrl
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
      
      // Create new response with CORS headers
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
      
      console.log(`Response: ${response.status} ${response.statusText}`);
      return corsResponse;
      
    } catch (error) {
      console.error('Proxy error:', error);
      
      return new Response(JSON.stringify({
        error: 'Proxy service error',
        message: error.message,
        timestamp: new Date().toISOString(),
        note: 'Real API with email support is being deployed. Please try again in a moment.',
        backend_url: 'http://a63972cf0604645e0a888cd84dc026d8-1402199394.us-west-2.elb.amazonaws.com'
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
