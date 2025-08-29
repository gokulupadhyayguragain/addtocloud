import React, { useState } from 'react';
import Link from 'next/link';
import { useAuth } from '../../context/AuthContext';

export default function Navigation() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { user, logout, isAuthenticated } = useAuth();

  const handleLogout = () => {
    logout();
  };

  return (
    <nav className="fixed top-0 w-full bg-slate-900/90 backdrop-blur-md border-b border-slate-700/50 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link href={isAuthenticated() ? "/dashboard" : "/"} className="flex items-center space-x-2">
            <div className="text-2xl font-bold">
              <span className="text-white">Add</span>
              <span className="text-gradient">To</span>
              <span className="text-white">Cloud</span>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            {!isAuthenticated() && (
              <Link href="/" className="nav-link">
                Home
              </Link>
            )}
            
            {isAuthenticated() && (
              <>
                <Link href="/dashboard" className="nav-link">
                  Dashboard
                </Link>
                <Link href="/services-new" className="nav-link">
                  Services
                </Link>
                <Link href="/monitoring" className="nav-link">
                  Monitoring
                </Link>
                <Link href="/test" className="nav-link">
                  API Test
                </Link>
              </>
            )}
            
            {/* Auth Buttons */}
            {!isAuthenticated() ? (
              <div className="flex items-center space-x-4">
                <Link href="/request-access" className="btn-secondary text-sm py-2 px-4">
                  Request Access
                </Link>
                <Link href="/login" className="btn-primary text-sm py-2 px-4">
                  Sign In
                </Link>
              </div>
            ) : (
              <div className="flex items-center space-x-4">
                <span className="text-slate-300 text-sm">
                  {user ? `${user.firstName} ${user.lastName}` : 'User'}
                </span>
                <button
                  onClick={handleLogout}
                  className="bg-red-600 hover:bg-red-700 text-white text-sm py-2 px-4 rounded-lg transition-colors"
                >
                  Logout
                </button>
              </div>
            )}
          </div>

          {/* Mobile menu button */}
          <div className="md:hidden">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="text-slate-300 hover:text-white p-2"
            >
              <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {isMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {isMenuOpen && (
          <div className="md:hidden py-4 border-t border-slate-700/50">
            <div className="flex flex-col space-y-4">
              {!isAuthenticated() && (
                <Link href="/" className="nav-link block px-4 py-2">
                  Home
                </Link>
              )}
              
              {isAuthenticated() && (
                <>
                  <Link href="/dashboard" className="nav-link block px-4 py-2">
                    Dashboard
                  </Link>
                  <Link href="/services-new" className="nav-link block px-4 py-2">
                    Services
                  </Link>
                  <Link href="/monitoring" className="nav-link block px-4 py-2">
                    Monitoring
                  </Link>
                  <Link href="/test" className="nav-link block px-4 py-2">
                    API Test
                  </Link>
                </>
              )}
              
              <div className="px-4 pt-2">
                {!isAuthenticated() ? (
                  <Link href="/login" className="btn-primary block text-center">
                    Sign In
                  </Link>
                ) : (
                  <div className="space-y-2">
                    <p className="text-slate-300 text-sm">
                      {user ? `${user.firstName} ${user.lastName}` : 'User'}
                    </p>
                    <button
                      onClick={handleLogout}
                      className="bg-red-600 hover:bg-red-700 text-white w-full py-2 px-4 rounded-lg transition-colors"
                    >
                      Logout
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
