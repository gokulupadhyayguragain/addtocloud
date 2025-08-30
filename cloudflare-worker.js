// CloudFlare Worker to proxy API calls from HTTPS frontend to HTTP backend
const BACKEND_API_URL = 'http://a06c2978d6fb9432dac72a7c932ae332-111698843.us-west-2.elb.amazonaws.com';

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Handle CORS preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        },
      });
    }
    
    // Handle specific API endpoints
    const validPaths = ['/contact', '/auth/login', '/auth/register'];
    const isValidPath = validPaths.some(path => url.pathname.startsWith(path)) || url.pathname.startsWith('/api/');
    
    if (!isValidPath) {
      return new Response('Not Found', { status: 404 });
    }

    // Construct backend URL
    const backendUrl = `${BACKEND_API_URL}${url.pathname}`;
    
    // Forward the request to backend
    const backendRequest = new Request(backendUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
    });

    try {
      const response = await fetch(backendRequest);
      
      // Clone response to modify headers
      const modifiedResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: {
          ...Object.fromEntries(response.headers),
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });

      return modifiedResponse;
    } catch (error) {
      return new Response(JSON.stringify({
        error: 'Backend API unavailable',
        message: error.message
      }), {
        status: 502,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }
  },
};
