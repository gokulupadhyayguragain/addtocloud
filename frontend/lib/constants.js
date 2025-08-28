export const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://api.addtocloud.tech' 
  : 'http://localhost:8080';

export const API_ENDPOINTS = {
  // Authentication
  LOGIN: '/api/v1/auth/login',
  REGISTER: '/api/v1/auth/register',
  LOGOUT: '/api/v1/auth/logout',
  REFRESH: '/api/v1/auth/refresh',
  
  // User management
  USER_PROFILE: '/api/v1/users/profile',
  UPDATE_PROFILE: '/api/v1/users/profile',
  
  // Cloud services
  CLOUD_SERVICES: '/api/v1/cloud/services',
  SERVICE_DETAILS: '/api/v1/cloud/services',
  
  // Payments
  PROCESS_PAYMENT: '/api/v1/payments/process',
  PAYMENT_HISTORY: '/api/v1/payments/history',
  
  // Subscriptions
  SUBSCRIPTIONS: '/api/v1/subscriptions',
  UPGRADE_PLAN: '/api/v1/subscriptions/upgrade',
  
  // Analytics
  DASHBOARD_METRICS: '/api/v1/analytics/dashboard',
  USAGE_STATS: '/api/v1/analytics/usage',
};

export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,
};

export const SUBSCRIPTION_PLANS = {
  BASIC: {
    name: 'Basic',
    price: 9.99,
    features: ['Up to 5 services', 'Basic support', 'Monthly billing'],
  },
  PRO: {
    name: 'Pro',
    price: 29.99,
    features: ['Up to 50 services', 'Priority support', 'Advanced analytics'],
  },
  ENTERPRISE: {
    name: 'Enterprise',
    price: 99.99,
    features: ['Unlimited services', '24/7 support', 'Custom integrations'],
  },
};

export const CLOUD_PROVIDERS = {
  AWS: 'aws',
  AZURE: 'azure',
  GCP: 'gcp',
};
