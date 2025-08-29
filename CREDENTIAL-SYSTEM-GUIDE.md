# 🔐 AddToCloud Credential Management System

## Overview
Automated credential request and email notification system for the AddToCloud enterprise platform.

## Features
- 🌐 **Web-based request form** - Clean, responsive interface for credential requests
- 📧 **Automated email notifications** - Instant notifications to admin with generated credentials
- 🔒 **Secure credential generation** - Auto-generated passwords and API keys with expiration
- 🎯 **Multi-environment support** - Production-ready with staging/dev configurations
- 📊 **Request tracking** - Unique request IDs for audit trails
- ✅ **Health monitoring** - Built-in health checks and status endpoints

## Quick Setup

### 1. Email Configuration
Create a Gmail App Password and update the Kubernetes secret:

```bash
# Generate base64 encoded password
echo -n "your_gmail_app_password" | base64

# Update the secret in infrastructure/kubernetes/credential-service.yaml
kubectl apply -f infrastructure/kubernetes/credential-service.yaml
```

### 2. Deploy the Service
```bash
# Deploy to your cluster
kubectl apply -f infrastructure/kubernetes/credential-service.yaml

# Check deployment status
kubectl get pods -n addtocloud -l app=credential-service
```

### 3. Configure Gateway Routing
Add to your Istio VirtualService:

```yaml
- match:
  - uri:
      prefix: /credential-request
  route:
  - destination:
      host: credential-service
      port:
        number: 8080
```

## How It Works

### User Flow
1. User visits `/credential-request` form
2. Fills out: Name, Email, Company, Purpose
3. Submits request with validation
4. Receives confirmation with request ID

### Admin Flow
1. Receives detailed email notification instantly
2. Email contains:
   - User request details
   - Auto-generated credentials (username, password, API key)
   - Platform access endpoints
   - 30-day expiration notice
3. Reviews request and forwards credentials if approved

### Email Template Features
- 📧 **Professional HTML design** with company branding
- 🔑 **Complete credential package** ready to forward
- 🌐 **Live endpoint links** for immediate access
- ⚠️ **Security warnings** and expiration notices
- 📋 **Request audit trail** with timestamps

## API Endpoints

### `POST /api/request-credentials`
Submit a new credential request.

**Request:**
```json
{
  "full_name": "John Doe",
  "email": "john@company.com", 
  "company": "Tech Corp",
  "purpose": "API integration and testing"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Credential request submitted successfully",
  "request_id": "abc123def456",
  "note": "You will receive credentials via email after admin approval"
}
```

### `GET /health`
Service health check.

### `GET /api/status`
Service status and platform information.

## Generated Credentials Format

Each request generates:
- **Username**: `firstname.lastname@addtocloud.tech`
- **Password**: 16-character secure password
- **API Key**: Base64-encoded 32-byte key
- **Expiration**: 30 days from generation
- **Endpoints**: Live platform URLs

## Environment Variables

```bash
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_FROM=noreply@addtocloud.tech
EMAIL_TO=admin@addtocloud.tech
EMAIL_PASSWORD=your_gmail_app_password
API_PORT=8080
ENVIRONMENT=production
```

## Security Features

- 🔒 **BCrypt password hashing** (12 rounds)
- 🎲 **Cryptographically secure random generation**
- ⏰ **Time-limited credentials** (30-day expiration)
- 🛡️ **Input validation and sanitization**
- 📝 **Audit logging** with request IDs
- 🚫 **Rate limiting** ready (configurable)

## Production Deployment

### Container Build
```bash
cd apps/credential-service
docker build -t ghcr.io/gokulupadhyayguragain/addtocloud/credential-service:latest .
docker push ghcr.io/gokulupadhyayguragain/addtocloud/credential-service:latest
```

### Kubernetes Deployment
```bash
kubectl apply -f infrastructure/kubernetes/credential-service.yaml
kubectl get svc credential-service -n addtocloud
```

### Monitoring
```bash
# Check logs
kubectl logs -f deployment/credential-service -n addtocloud

# Test health endpoint
kubectl port-forward svc/credential-service 8080:8080 -n addtocloud
curl http://localhost:8080/health
```

## Email Notification Sample

```
🚀 AddToCloud Credential Request

📋 Request Details
Full Name: John Doe
Email: john@company.com
Company: Tech Corp
Purpose: API integration and testing
Request Time: 2025-08-29 18:30:00

🔑 Generated Credentials
Username: john.doe@addtocloud.tech
Password: Xp9#mK2$nR8qW5!z
API Key: AbC123DeF456...
Expires: 2025-09-28 18:30:00

🌐 Platform Access
Primary: http://52.224.84.148
Secondary: http://a21f927dc7e504cbe99d241bc3562345-1460504033.us-west-2.elb.amazonaws.com
API Endpoint: https://api.addtocloud.tech

⚠️ Action Required:
Please review this request and forward the credentials to the user if approved.
```

## Integration with Frontend

Add to your main application routing:

```javascript
// React Router example
<Route path="/credential-request" component={CredentialRequestForm} />

// Or iframe embed
<iframe src="http://credential-service:8080" width="100%" height="600px" />
```

## Troubleshooting

### Common Issues

1. **Email not sending**
   - Check Gmail App Password is correct
   - Verify SMTP settings
   - Check Kubernetes secret is properly base64 encoded

2. **Form not submitting**
   - Verify service is running: `kubectl get pods -n addtocloud`
   - Check Istio routing configuration
   - Test health endpoint

3. **Credentials not generating**
   - Check service logs: `kubectl logs deployment/credential-service -n addtocloud`
   - Verify environment variables are set

### Debug Commands
```bash
# Check service status
kubectl describe deployment credential-service -n addtocloud

# View logs
kubectl logs -f deployment/credential-service -n addtocloud

# Test locally
go run main.go
```

## Future Enhancements

- 📊 **Admin dashboard** for request management
- 🔄 **Credential renewal** workflow
- 📈 **Usage analytics** and reporting
- 🔐 **SSO integration** (OIDC/SAML)
- 📱 **Mobile-responsive** form improvements
- 🤖 **Slack/Teams** notifications
- 🔍 **Approval workflow** automation

---

**🎯 Ready for Production!** The credential service is now deployed and ready to handle user requests with automated email notifications to keep you informed of all access requests.
