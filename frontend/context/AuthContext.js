import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';

// Authentication Context
import { createContext, useContext } from 'react';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = () => {
    try {
      const token = localStorage.getItem('authToken');
      const userData = localStorage.getItem('user');
      
      if (token && userData) {
        setUser(JSON.parse(userData));
      }
    } catch (error) {
      console.error('Auth check failed:', error);
      logout();
    } finally {
      setLoading(false);
    }
  };

  const login = (token, userData) => {
    localStorage.setItem('authToken', token);
    localStorage.setItem('user', JSON.stringify(userData));
    setUser(userData);
  };

  const logout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    setUser(null);
    router.push('/');
  };

  const isAuthenticated = () => {
    return !!user && !!localStorage.getItem('authToken');
  };

  return (
    <AuthContext.Provider value={{
      user,
      loading,
      login,
      logout,
      isAuthenticated,
      checkAuth
    }}>
      {children}
    </AuthContext.Provider>
  );
};

// Protected Route Component
export const ProtectedRoute = ({ children, redirectTo = '/login' }) => {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [showUnauthorized, setShowUnauthorized] = useState(false);

  useEffect(() => {
    if (!loading) {
      if (!user) {
        setShowUnauthorized(true);
        // Auto-redirect after 3 seconds
        const timer = setTimeout(() => {
          router.push(redirectTo);
        }, 3000);
        return () => clearTimeout(timer);
      }
    }
  }, [user, loading, router, redirectTo]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-white">Loading...</p>
        </div>
      </div>
    );
  }

  if (showUnauthorized || !user) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 flex items-center justify-center px-4">
        <div className="max-w-md w-full text-center">
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20">
            <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
              <svg className="w-8 h-8 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m0 0v2m0-2h2m-2 0H10m2-5V9m0 0V7m0 2h2m-2 0H10m5-6h.01M19 12h.01M12 19h.01M5 12h.01M12 5h.01" />
              </svg>
            </div>
            
            <h1 className="text-2xl font-bold text-white mb-4">
              🔐 Authentication Required
            </h1>
            
            <p className="text-slate-300 mb-6">
              This area is restricted to authenticated users only. Please sign in or request access to continue.
            </p>
            
            <div className="space-y-4">
              <Link 
                href="/login" 
                className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white py-3 px-6 rounded-lg transition-all duration-200 font-medium block"
              >
                🔑 Sign In
              </Link>
              
              <Link 
                href="/request-access" 
                className="w-full bg-white/10 hover:bg-white/20 text-white py-3 px-6 rounded-lg transition-all duration-200 border border-white/20 font-medium block"
              >
                📝 Request Access
              </Link>
              
              <Link 
                href="/" 
                className="text-blue-400 hover:text-blue-300 text-sm transition-colors block"
              >
                ← Back to Homepage
              </Link>
            </div>
            
            <div className="mt-6 text-xs text-slate-400">
              Redirecting to login in 3 seconds...
            </div>
          </div>
        </div>
      </div>
    );
  }

  return children;
};

// Hook to protect API calls
export const useAuthenticatedFetch = () => {
  const { logout } = useAuth();

  const authenticatedFetch = async (url, options = {}) => {
    const token = localStorage.getItem('authToken');
    
    if (!token) {
      throw new Error('No authentication token found');
    }

    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        ...options.headers,
      },
    };

    const response = await fetch(url, { ...options, ...defaultOptions });

    // Handle token expiry
    if (response.status === 401) {
      logout();
      throw new Error('Authentication expired. Please log in again.');
    }

    return response;
  };

  return authenticatedFetch;
};
