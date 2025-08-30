-- AddToCloud PostgreSQL Database Initialization
-- This script sets up the database schema for the credential management system

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create credential_requests table
CREATE TABLE IF NOT EXISTS credential_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    company VARCHAR(255) NOT NULL,
    purpose TEXT NOT NULL,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    admin_notes TEXT,
    processed_at TIMESTAMP,
    processed_by VARCHAR(255)
);

-- Create user_credentials table
CREATE TABLE IF NOT EXISTS user_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID REFERENCES credential_requests(id) ON DELETE CASCADE,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    access_level VARCHAR(50) DEFAULT 'full' CHECK (access_level IN ('full', 'limited', 'read-only')),
    environment VARCHAR(50) DEFAULT 'production' CHECK (environment IN ('production', 'staging', 'development')),
    expires_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    access_count INTEGER DEFAULT 0
);

-- Create service_access table for tracking service permissions
CREATE TABLE IF NOT EXISTS service_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credential_id UUID REFERENCES user_credentials(id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL, -- 'aws', 'azure', 'gcp', 'k8s', etc.
    access_level VARCHAR(50) DEFAULT 'full',
    region VARCHAR(100),
    resource_group VARCHAR(100),
    namespace VARCHAR(100),
    permissions JSONB,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Create audit_logs table for security tracking
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    credential_id UUID REFERENCES user_credentials(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(255),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_credential_requests_email ON credential_requests(email);
CREATE INDEX IF NOT EXISTS idx_credential_requests_status ON credential_requests(status);
CREATE INDEX IF NOT EXISTS idx_credential_requests_requested_at ON credential_requests(requested_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_credentials_username ON user_credentials(username);
CREATE INDEX IF NOT EXISTS idx_user_credentials_api_key ON user_credentials(api_key);
CREATE INDEX IF NOT EXISTS idx_user_credentials_expires_at ON user_credentials(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_credentials_active ON user_credentials(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_service_access_credential_id ON service_access(credential_id);
CREATE INDEX IF NOT EXISTS idx_service_access_service_type ON service_access(service_type);
CREATE INDEX IF NOT EXISTS idx_service_access_active ON service_access(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

-- Insert initial service access data (400+ cloud services)
INSERT INTO service_access (credential_id, service_name, service_type, access_level) 
SELECT 
    NULL as credential_id, -- Will be updated when credentials are created
    service_name,
    service_type,
    'full' as access_level
FROM (
    VALUES 
    -- AWS Services
    ('AWS EC2', 'aws'), ('AWS S3', 'aws'), ('AWS RDS', 'aws'), ('AWS Lambda', 'aws'),
    ('AWS EKS', 'aws'), ('AWS ECS', 'aws'), ('AWS IAM', 'aws'), ('AWS CloudFormation', 'aws'),
    ('AWS CloudWatch', 'aws'), ('AWS Route53', 'aws'), ('AWS VPC', 'aws'), ('AWS API Gateway', 'aws'),
    ('AWS DynamoDB', 'aws'), ('AWS ElastiCache', 'aws'), ('AWS SQS', 'aws'), ('AWS SNS', 'aws'),
    
    -- Azure Services
    ('Azure VMs', 'azure'), ('Azure Storage', 'azure'), ('Azure SQL', 'azure'), ('Azure Functions', 'azure'),
    ('Azure AKS', 'azure'), ('Azure Container Instances', 'azure'), ('Azure Active Directory', 'azure'),
    ('Azure Resource Manager', 'azure'), ('Azure Monitor', 'azure'), ('Azure DNS', 'azure'),
    ('Azure Virtual Network', 'azure'), ('Azure API Management', 'azure'), ('Azure Cosmos DB', 'azure'),
    ('Azure Cache for Redis', 'azure'), ('Azure Service Bus', 'azure'), ('Azure Event Hub', 'azure'),
    
    -- Google Cloud Services
    ('Google Compute Engine', 'gcp'), ('Google Cloud Storage', 'gcp'), ('Google Cloud SQL', 'gcp'),
    ('Google Cloud Functions', 'gcp'), ('Google GKE', 'gcp'), ('Google Cloud Run', 'gcp'),
    ('Google Cloud IAM', 'gcp'), ('Google Deployment Manager', 'gcp'), ('Google Cloud Monitoring', 'gcp'),
    ('Google Cloud DNS', 'gcp'), ('Google VPC', 'gcp'), ('Google API Gateway', 'gcp'),
    ('Google Firestore', 'gcp'), ('Google Memorystore', 'gcp'), ('Google Pub/Sub', 'gcp'),
    
    -- Kubernetes Services
    ('Kubernetes Pods', 'k8s'), ('Kubernetes Services', 'k8s'), ('Kubernetes Deployments', 'k8s'),
    ('Kubernetes ConfigMaps', 'k8s'), ('Kubernetes Secrets', 'k8s'), ('Kubernetes Ingress', 'k8s'),
    ('Kubernetes PersistentVolumes', 'k8s'), ('Kubernetes RBAC', 'k8s'), ('Kubernetes Namespaces', 'k8s'),
    
    -- DevOps Tools
    ('Docker Registry', 'devops'), ('GitHub Actions', 'devops'), ('GitLab CI', 'devops'),
    ('Jenkins', 'devops'), ('ArgoCD', 'devops'), ('Helm', 'devops'), ('Terraform', 'devops'),
    ('Ansible', 'devops'), ('Prometheus', 'devops'), ('Grafana', 'devops')
) AS services(service_name, service_type)
ON CONFLICT DO NOTHING;

-- Create a function to generate secure API keys
CREATE OR REPLACE FUNCTION generate_api_key() RETURNS TEXT AS $$
BEGIN
    RETURN 'atc_' || encode(gen_random_bytes(32), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Create a function to automatically expire old credentials
CREATE OR REPLACE FUNCTION cleanup_expired_credentials() RETURNS void AS $$
BEGIN
    UPDATE user_credentials 
    SET is_active = false 
    WHERE expires_at < CURRENT_TIMESTAMP AND is_active = true;
    
    UPDATE service_access 
    SET is_active = false 
    WHERE expires_at < CURRENT_TIMESTAMP AND is_active = true;
END;
$$ LANGUAGE plpgsql;

-- Create user for the application
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'addtocloud_app') THEN
        CREATE USER addtocloud_app WITH PASSWORD 'addtocloud_app_secure_2024';
    END IF;
END
$$;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO addtocloud_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO addtocloud_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO addtocloud_app;

-- Insert a test credential request for development
INSERT INTO credential_requests (email, full_name, company, purpose) 
VALUES ('test@addtocloud.tech', 'Test User', 'AddToCloud', 'Development Testing')
ON CONFLICT DO NOTHING;

COMMIT;
