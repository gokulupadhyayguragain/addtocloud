# 🏗️ AddToCloud Architecture Documentation

## Table of Contents
- [System Overview](#system-overview)
- [Multi-Cloud Architecture](#multi-cloud-architecture)
- [Component Details](#component-details)
- [Network Architecture](#network-architecture)
- [Security Architecture](#security-architecture)
- [Data Flow](#data-flow)
- [Deployment Architecture](#deployment-architecture)

## System Overview

AddToCloud implements a distributed, multi-cloud architecture designed for high availability, scalability, and resilience. The platform spans three major cloud providers (AWS, Azure, GCP) with unified management and service mesh connectivity.

### Core Principles
- **Multi-Cloud First**: No vendor lock-in, cloud-agnostic design
- **Microservices Architecture**: Loosely coupled, independently deployable services
- **Event-Driven Design**: Asynchronous communication and real-time updates
- **Zero-Trust Security**: Every request authenticated and authorized
- **Infrastructure as Code**: Fully automated provisioning and management

## Multi-Cloud Architecture

### 🌍 Global Distribution

```
┌─────────────────────────────────────────────────────────────────┐
│                     Cloudflare Global CDN                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   US-WEST   │ │   US-EAST   │ │   EUROPE    │ │   ASIA      │ │
│  │   Caching   │ │   Caching   │ │   Caching   │ │   Caching   │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend Layer (Next.js)                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Login     │ │  Dashboard  │ │ Monitoring  │ │  Services   │ │
│  │   Portal    │ │   Console   │ │   Views     │ │   Panel     │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Istio Service Mesh                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Gateway   │ │ Virtual Svc │ │ Destination │ │  Policies   │ │
│  │  (Ingress)  │ │   Rules     │ │    Rules    │ │  (AuthZ)    │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
            │                       │                       │
            ▼                       ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│   AWS REGION    │   │  AZURE REGION   │   │   GCP REGION    │
│   us-west-2     │   │    eastus       │   │  us-central1    │
│                 │   │                 │   │                 │
│ ┌─────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
│ │     EKS     │ │   │ │     AKS     │ │   │ │     GKE     │ │
│ │   Cluster   │ │   │ │   Cluster   │ │   │ │   Cluster   │ │
│ │             │ │   │ │             │ │   │ │             │ │
│ │ 3x t3.medium│ │   │ │3x D2s_v3    │ │   │ │3x e2-medium │ │
│ └─────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
│                 │   │                 │   │                 │
│ ┌─────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
│ │RDS PostgreSQL│ │   │ │PostgreSQL   │ │   │ │Cloud SQL    │ │
│ │             │ │   │ │  Flexible   │ │   │ │ PostgreSQL  │ │
│ └─────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
│                 │   │                 │   │                 │
│ ┌─────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
│ │     ECR     │ │   │ │     ACR     │ │   │ │Artifact Reg │ │
│ │  Registry   │ │   │ │  Registry   │ │   │ │             │ │
│ └─────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

## Component Details

### 🎨 Frontend Layer (Next.js)

**Technologies**: Next.js 14, React 18, TypeScript, TailwindCSS

**Components**:
```
frontend/
├── components/
│   ├── dashboard/          # Admin dashboard components
│   ├── layout/            # Navigation and common layout
│   ├── ui/                # Reusable UI components
│   └── 3d/                # 3D visualizations
├── pages/
│   ├── index.js           # Landing page
│   ├── dashboard.js       # Admin dashboard
│   ├── monitoring.js      # Multi-cloud monitoring
│   └── services.js        # Service management
├── context/               # React context providers
├── hooks/                 # Custom React hooks
└── utils/                 # Utility functions
```

**Key Features**:
- **Server-Side Rendering**: Optimized performance and SEO
- **Real-time Updates**: WebSocket connections for live data
- **Responsive Design**: Mobile-first approach with TailwindCSS
- **3D Visualizations**: Interactive cloud architecture views

### 🔧 Backend Services (Go)

**Technologies**: Go 1.21, Gin Framework, PostgreSQL, JWT

**Service Architecture**:
```
backend/
├── cmd/
│   └── main.go           # Application entry point
├── internal/
│   ├── handlers/         # HTTP request handlers
│   │   ├── user.go       # User management
│   │   └── cloud.go      # Cloud operations
│   ├── services/         # Business logic layer
│   │   ├── user.go       # User service
│   │   └── cloud.go      # Cloud service
│   ├── models/           # Data models
│   ├── repository/       # Data access layer
│   └── middleware/       # HTTP middleware
├── pkg/
│   ├── auth/             # Authentication utilities
│   ├── database/         # Database connections
│   ├── logger/           # Structured logging
│   └── utils/            # Common utilities
└── configs/              # Configuration management
```

**Microservices**:
1. **Authentication Service**: JWT token management, user authentication
2. **User Management Service**: User registration, profile management
3. **Cloud Management Service**: Multi-cloud operations, deployment management
4. **Monitoring Service**: Metrics collection, health checks

### 🗄️ Database Architecture

**Multi-Cloud Database Strategy**:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Database Replication                        │
└─────────────────────────────────────────────────────────────────┘
            │                       │                       │
            ▼                       ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  AWS RDS        │   │  Azure PostgreSQL│   │  GCP Cloud SQL  │
│  PostgreSQL     │   │  Flexible Server │   │  PostgreSQL     │
│                 │   │                 │   │                 │
│ - Primary Write │   │ - Read Replica  │   │ - Read Replica  │
│ - Auto Backup   │   │ - Geo-Redundant │   │ - Point-in-Time │
│ - Multi-AZ      │   │ - Auto Scaling  │   │ - Auto Backup   │
│ - Encryption    │   │ - Encryption    │   │ - Encryption    │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

**Schema Design**:
```sql
-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Cloud Deployments Table
CREATE TABLE deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    cloud_provider VARCHAR(50) NOT NULL,
    region VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    config JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Access Requests Table
CREATE TABLE access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    organization VARCHAR(255),
    reason TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    reviewed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    reviewed_at TIMESTAMP
);
```

## Network Architecture

### 🌐 Service Mesh (Istio)

**Multi-Cluster Service Mesh Configuration**:

```yaml
# Istio Multi-Cluster Setup
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: primary
spec:
  values:
    pilot:
      env:
        ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY: true
        PILOT_ENABLE_REMOTE_JWKS: true
  components:
    pilot:
      k8s:
        env:
        - name: CLUSTER_ID
          value: aws-primary
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: addtocloud-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.addtocloud.com"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: addtocloud-tls
    hosts:
    - "*.addtocloud.com"
```

**Traffic Management**:
```yaml
# Virtual Service for Multi-Cloud Load Balancing
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: addtocloud-vs
spec:
  hosts:
  - api.addtocloud.com
  gateways:
  - addtocloud-gateway
  http:
  - match:
    - headers:
        region:
          exact: us-west
    route:
    - destination:
        host: addtocloud-api.aws
        port:
          number: 8080
      weight: 100
  - match:
    - headers:
        region:
          exact: us-east
    route:
    - destination:
        host: addtocloud-api.azure
        port:
          number: 8080
      weight: 100
  - route:
    - destination:
        host: addtocloud-api.aws
        port:
          number: 8080
      weight: 60
    - destination:
        host: addtocloud-api.azure
        port:
          number: 8080
      weight: 30
    - destination:
        host: addtocloud-api.gcp
        port:
          number: 8080
      weight: 10
```

## Security Architecture

### 🔒 Zero-Trust Security Model

**Authentication Flow**:
```
1. User Request → Cloudflare → mTLS Check
2. Istio Gateway → JWT Validation
3. Service Mesh → RBAC Policies
4. Application → Business Logic
5. Database → Row-Level Security
```

**Security Layers**:
1. **Edge Security**: Cloudflare DDoS protection, WAF rules
2. **Network Security**: Istio mTLS, network policies
3. **Application Security**: JWT authentication, RBAC
4. **Data Security**: Encryption at rest and in transit

## Data Flow

### 📊 Request Flow Diagram

```
Client Request
      │
      ▼
┌─────────────┐
│ Cloudflare  │ ◄─── Global CDN, DDoS Protection
│     CDN     │
└─────────────┘
      │
      ▼
┌─────────────┐
│   Istio     │ ◄─── mTLS, Traffic Management
│  Gateway    │
└─────────────┘
      │
      ▼
┌─────────────┐
│  Load       │ ◄─── Weighted Routing
│ Balancer    │
└─────────────┘
   │    │    │
   ▼    ▼    ▼
┌─────┐ ┌─────┐ ┌─────┐
│ AWS │ │Azure│ │ GCP │ ◄─── Multi-Cloud Backend
│ EKS │ │ AKS │ │ GKE │
└─────┘ └─────┘ └─────┘
   │    │    │
   ▼    ▼    ▼
┌─────┐ ┌─────┐ ┌─────┐
│ RDS │ │PSQL │ │SQL  │ ◄─── Database Layer
└─────┘ └─────┘ └─────┘
```

## Deployment Architecture

### 🚀 CI/CD Pipeline

```yaml
# GitHub Actions Workflow
name: Multi-Cloud Deployment
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build Container
      run: docker build -t ghcr.io/gokulupadhyayguragain/addtocloud:${{ github.sha }} .
    - name: Push to Registry
      run: docker push ghcr.io/gokulupadhyayguragain/addtocloud:${{ github.sha }}

  deploy-aws:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to EKS
      run: |
        aws eks update-kubeconfig --name addtocloud-prod-eks
        kubectl set image deployment/addtocloud-api api=ghcr.io/gokulupadhyayguragain/addtocloud:${{ github.sha }}

  deploy-azure:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to AKS
      run: |
        az aks get-credentials --name aks-addtocloud-prod --resource-group addtocloud-prod
        kubectl set image deployment/addtocloud-api api=ghcr.io/gokulupadhyayguragain/addtocloud:${{ github.sha }}

  deploy-gcp:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to GKE
      run: |
        gcloud container clusters get-credentials addtocloud-gke-cluster --zone us-central1-a
        kubectl set image deployment/addtocloud-api api=ghcr.io/gokulupadhyayguragain/addtocloud:${{ github.sha }}
```

### 📊 Monitoring Architecture

**Observability Stack**:
```
┌─────────────────────────────────────────────────────────────────┐
│                        Monitoring Layer                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │ Prometheus  │ │   Grafana   │ │   Jaeger    │ │   Kiali     │ │
│  │   Metrics   │ │ Dashboards  │ │   Tracing   │ │Service Graph│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
            │                │                │                │
            ▼                ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Istio Service Mesh                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │  Envoy      │ │   Pilot     │ │   Citadel   │ │   Galley    │ │
│  │  Proxies    │ │   Control   │ │   Security  │ │   Config    │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

### 📈 Scalability Metrics

| Component | Baseline | Target | Max Scale |
|-----------|----------|---------|-----------|
| Frontend | 1,000 RPS | 10,000 RPS | 100,000 RPS |
| Backend API | 5,000 RPS | 50,000 RPS | 500,000 RPS |
| Database | 1,000 QPS | 10,000 QPS | 50,000 QPS |
| K8s Nodes | 9 nodes | 30 nodes | 300 nodes |

### 🌍 Global Latency Targets

| Region | Target Latency | CDN Cache Hit |
|--------|----------------|---------------|
| North America | < 50ms | 95% |
| Europe | < 80ms | 90% |
| Asia Pacific | < 100ms | 85% |
| South America | < 150ms | 80% |

This architecture provides a robust, scalable, and secure foundation for multi-cloud container management with enterprise-grade capabilities.
