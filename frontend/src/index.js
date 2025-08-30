export default {
  async fetch(request, env, ctx) {
    // For CloudFlare Workers - serve static content
    const url = new URL(request.url);
    
    // Handle API proxying to backend
    if (url.pathname.startsWith('/api/')) {
      // List of backend endpoints to try
      const backends = [
        'http://52.224.84.148',  // Azure
        'http://a21f927dc7e504cbe99d241bc3562345-1460504033.us-west-2.elb.amazonaws.com',  // AWS
      ];
      
      for (const backend of backends) {
        try {
          const backendUrl = `${backend}${url.pathname}${url.search}`;
          const response = await fetch(backendUrl, {
            method: request.method,
            headers: request.headers,
            body: request.method === 'GET' ? null : request.body,
          });
          
          // Add CORS headers
          const newResponse = new Response(response.body, response);
          newResponse.headers.set('Access-Control-Allow-Origin', '*');
          newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
          newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
          
          if (response.ok) {
            return newResponse;
          }
        } catch (error) {
          console.error(`Backend ${backend} failed:`, error);
          continue;
        }
      }
      
      // If all backends fail, return error
      return new Response(JSON.stringify({
        error: 'All backend services unavailable',
        message: 'Please try again later'
      }), {
        status: 503,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
    
    // Serve static files - this will be handled by CloudFlare Pages
    // For now, return a simple response
    return new Response('CloudFlare Worker is running - use CloudFlare Pages for static content', {
      headers: { 'Content-Type': 'text/plain' }
    });
  },
};
