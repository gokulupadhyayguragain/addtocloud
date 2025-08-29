# AddToCloud Credential Management System

## 🎯 Overview
Automated credential request and notification system for the AddToCloud platform. When users request access, an email is automatically sent to administrators with user details and a secure auto-generated password.

## 🏗️ Architecture
- **Backend**: Go web service with Gin framework
- **Frontend**: Professional HTML form with responsive design
- **Email**: SMTP integration with Gmail App Password
- **Deployment**: Kubernetes with health checks and secrets management
- **Security**: JWT tokens, bcrypt password hashing, base64 encoding

## 🚀 Quick Start

### 1. Deploy the Service
```bash
# For Linux/Mac
./scripts/deploy-credential-service.sh

# For Windows
powershell -ExecutionPolicy Bypass -File scripts\deploy-credential-service.ps1
```

### 2. Configure Email Credentials
```bash
# Update with your Gmail credentials
kubectl patch secret email-secret -n addtocloud \
  --type='json' \
  -p='[{"op":"replace","path":"/data/smtp-username","value":"'$(echo -n 'your-email@gmail.com' | base64)'"}]'

kubectl patch secret email-secret -n addtocloud \
  --type='json' \
  -p='[{"op":"replace","path":"/data/smtp-password","value":"'$(echo -n 'your-app-password' | base64)'"}]'
```

### 3. Access the Service
- **Web Form**: `http://your-cluster-ip:8080`
- **Health Check**: `http://your-cluster-ip:8080/health`

## 📧 Email Setup (Gmail)
1. Enable 2FA on your Gmail account
2. Generate an App Password:
   - Google Account → Security → 2-Step Verification → App passwords
   - Select "Mail" and generate password
3. Use the generated password (not your regular Gmail password)

## 🔄 User Workflow
1. User fills out the credential request form
2. System generates secure random password
3. Email sent to admin with:
   - User's full name and email
   - Company and purpose
   - Auto-generated secure password
   - Timestamp
4. Admin receives notification and can manually send credentials

## 🛠️ Development

### Local Testing
```bash
cd apps/credential-service
go run main.go
```

### Build Docker Image
```bash
docker build -t addtocloud/credential-service:latest -f apps/credential-service/Dockerfile .
```

### Environment Variables
- `SMTP_USERNAME`: Gmail address
- `SMTP_PASSWORD`: Gmail app password
- `SMTP_HOST`: smtp.gmail.com
- `SMTP_PORT`: 587

## 📋 API Endpoints

### POST /request-credentials
Request new credentials
```json
{
  "full_name": "John Doe",
  "email": "john@company.com",
  "company": "Tech Corp",
  "purpose": "Development access"
}
```

### GET /health
Health check endpoint

### GET /
Serves the credential request form

## 🔧 Troubleshooting

### Email Not Sending
1. Verify Gmail App Password is correct
2. Check 2FA is enabled on Gmail account
3. Ensure SMTP credentials are properly base64 encoded in Kubernetes secret

### Pod Not Starting
1. Check logs: `kubectl logs -f deployment/credential-service -n addtocloud`
2. Verify secret exists: `kubectl get secrets -n addtocloud`
3. Check resource limits and requests

### Form Not Loading
1. Verify service is accessible: `kubectl get svc -n addtocloud`
2. Check pod status: `kubectl get pods -n addtocloud`
3. Test health endpoint: `curl http://service-ip:8080/health`

## 📁 File Structure
```
apps/credential-service/
├── main.go                 # Main Go application
├── public/
│   └── index.html         # Credential request form
├── Dockerfile             # Container image definition
└── go.mod                 # Go dependencies

infrastructure/kubernetes/
└── credential-service.yaml # Kubernetes manifests

scripts/
├── deploy-credential-service.sh  # Linux/Mac deployment
└── deploy-credential-service.ps1 # Windows deployment
```

## 🔐 Security Features
- Auto-generated secure passwords (16 characters, mixed case, numbers, symbols)
- bcrypt password hashing
- JWT token support (for future authentication)
- Kubernetes secrets for sensitive data
- Input validation and sanitization
- CORS protection

## 📈 Monitoring
The service includes health checks and can be monitored via:
- Kubernetes liveness/readiness probes
- Prometheus metrics (can be added)
- Application logs via `kubectl logs`

## 🔄 Updates
To update the service:
1. Build new image with version tag
2. Update deployment: `kubectl set image deployment/credential-service credential-service=addtocloud/credential-service:v1.1 -n addtocloud`
3. Monitor rollout: `kubectl rollout status deployment/credential-service -n addtocloud`
