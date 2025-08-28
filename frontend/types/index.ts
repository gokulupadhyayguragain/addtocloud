export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CloudService {
  id: string;
  name: string;
  provider: 'aws' | 'azure' | 'gcp';
  category: string;
  description: string;
  pricing: {
    model: 'pay-as-you-go' | 'subscription' | 'reserved';
    amount: number;
    currency: string;
    billingPeriod?: string;
  };
  features: string[];
  status: 'active' | 'inactive' | 'deprecated';
}

export interface Payment {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  paymentMethod: string;
  transactionId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Subscription {
  id: string;
  userId: string;
  plan: 'basic' | 'pro' | 'enterprise';
  status: 'active' | 'cancelled' | 'expired';
  startDate: string;
  endDate: string;
  autoRenew: boolean;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface DashboardMetrics {
  totalServices: number;
  activeServices: number;
  totalUsers: number;
  revenue: number;
  growth: number;
}

export interface ThreeJSProps {
  className?: string;
  children?: React.ReactNode;
}
