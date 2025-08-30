-- AddToCloud Enterprise Database Schema
-- Production-ready database structure for multi-cloud platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users and Authentication
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    phone VARCHAR(50),
    role VARCHAR(50) DEFAULT 'user',
    plan VARCHAR(50) DEFAULT 'starter',
    status VARCHAR(50) DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- API Keys and Access Tokens
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    key_name VARCHAR(255) NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    key_prefix VARCHAR(20) NOT NULL,
    permissions JSONB DEFAULT '{}',
    last_used TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Access Requests
CREATE TABLE access_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    company VARCHAR(255) NOT NULL,
    use_case TEXT,
    access_level VARCHAR(50) DEFAULT 'enterprise',
    status VARCHAR(50) DEFAULT 'pending',
    reviewer_id UUID REFERENCES users(id),
    review_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contact Messages
CREATE TABLE contact_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'new',
    assigned_to UUID REFERENCES users(id),
    response TEXT,
    responded_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clusters
CREATE TABLE clusters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    cluster_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    provider VARCHAR(50) NOT NULL, -- aws, azure, gcp, cloudflare
    region VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'creating',
    kubernetes_version VARCHAR(50),
    node_count INTEGER DEFAULT 0,
    pod_count INTEGER DEFAULT 0,
    cpu_usage DECIMAL(5,2) DEFAULT 0.0,
    memory_usage DECIMAL(5,2) DEFAULT 0.0,
    cost_per_hour DECIMAL(10,4) DEFAULT 0.0,
    configuration JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Deployments
CREATE TABLE deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    cluster_id UUID REFERENCES clusters(id) ON DELETE CASCADE,
    deployment_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    namespace VARCHAR(255) DEFAULT 'default',
    image VARCHAR(500) NOT NULL,
    replicas INTEGER DEFAULT 1,
    status VARCHAR(50) DEFAULT 'pending',
    cpu_request VARCHAR(50),
    memory_request VARCHAR(50),
    cpu_limit VARCHAR(50),
    memory_limit VARCHAR(50),
    environment_vars JSONB DEFAULT '{}',
    ports JSONB DEFAULT '[]',
    volumes JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Billing and Usage
CREATE TABLE billing_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan VARCHAR(50) NOT NULL,
    billing_cycle VARCHAR(50) DEFAULT 'monthly',
    current_usage DECIMAL(10,2) DEFAULT 0.0,
    monthly_limit DECIMAL(10,2),
    next_billing_date DATE,
    payment_method JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Usage Tracking
CREATE TABLE usage_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    cluster_id UUID REFERENCES clusters(id) ON DELETE CASCADE,
    resource_type VARCHAR(100) NOT NULL, -- compute, storage, network, api_calls
    quantity DECIMAL(15,6) NOT NULL,
    unit VARCHAR(50) NOT NULL, -- hours, gb, requests
    cost DECIMAL(10,4) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    billing_period DATE NOT NULL
);

-- System Metrics
CREATE TABLE cluster_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cluster_id UUID REFERENCES clusters(id) ON DELETE CASCADE,
    metric_type VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    value DECIMAL(15,6) NOT NULL,
    unit VARCHAR(50),
    node_name VARCHAR(255),
    namespace VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- API Request Logs
CREATE TABLE api_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    api_key_id UUID REFERENCES api_keys(id) ON DELETE SET NULL,
    method VARCHAR(10) NOT NULL,
    endpoint VARCHAR(500) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    ip_address INET,
    user_agent TEXT,
    request_size INTEGER,
    response_size INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL, -- email, sms, webhook
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    sent_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_key ON api_keys(api_key);
CREATE INDEX idx_clusters_user_id ON clusters(user_id);
CREATE INDEX idx_clusters_provider ON clusters(provider);
CREATE INDEX idx_deployments_user_id ON deployments(user_id);
CREATE INDEX idx_deployments_cluster_id ON deployments(cluster_id);
CREATE INDEX idx_usage_records_user_id ON usage_records(user_id);
CREATE INDEX idx_usage_records_date ON usage_records(billing_period);
CREATE INDEX idx_cluster_metrics_cluster_id ON cluster_metrics(cluster_id);
CREATE INDEX idx_cluster_metrics_timestamp ON cluster_metrics(timestamp);
CREATE INDEX idx_api_requests_user_id ON api_requests(user_id);
CREATE INDEX idx_api_requests_timestamp ON api_requests(timestamp);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);

-- Insert sample data for testing
INSERT INTO users (email, password_hash, name, company, role, plan, email_verified) VALUES
('admin@addtocloud.tech', crypt('admin123', gen_salt('bf')), 'Admin User', 'AddToCloud', 'admin', 'enterprise', true),
('user@example.com', crypt('user123', gen_salt('bf')), 'Test User', 'Example Corp', 'user', 'professional', true),
('gokulupadhyayguragain@gmail.com', crypt('gokul123', gen_salt('bf')), 'Gokul Upadhyay', 'AddToCloud', 'admin', 'enterprise', true);

-- Sample API keys
INSERT INTO api_keys (user_id, key_name, api_key, key_prefix, permissions) 
SELECT id, 'Production API Key', 'ak_live_' || generate_random_uuid()::text, 'ak_live', '{"clusters": "full", "deployments": "full"}'::jsonb
FROM users WHERE email = 'gokulupadhyayguragain@gmail.com';

-- Sample clusters
INSERT INTO clusters (user_id, cluster_id, name, provider, region, status, kubernetes_version, node_count, pod_count, cpu_usage, memory_usage, cost_per_hour)
SELECT id, 'eks-prod-001', 'Production EKS Cluster', 'aws', 'us-east-1', 'running', 'v1.28.2', 5, 127, 67.5, 72.3, 2.45
FROM users WHERE email = 'gokulupadhyayguragain@gmail.com';

INSERT INTO clusters (user_id, cluster_id, name, provider, region, status, kubernetes_version, node_count, pod_count, cpu_usage, memory_usage, cost_per_hour)
SELECT id, 'aks-staging-001', 'Staging AKS Cluster', 'azure', 'eastus', 'running', 'v1.28.1', 3, 67, 45.2, 58.7, 1.23
FROM users WHERE email = 'gokulupadhyayguragain@gmail.com';

-- Create functions for common operations
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clusters_updated_at BEFORE UPDATE ON clusters FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deployments_updated_at BEFORE UPDATE ON deployments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_billing_accounts_updated_at BEFORE UPDATE ON billing_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (adjust as needed)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO addtocloud_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO addtocloud_admin;
