#!/bin/bash
# Deployment script for AddToCloud Credential Service

echo "🚀 Deploying AddToCloud Credential Service..."

# Build and push Docker image
echo "📦 Building credential service image..."
docker build -t addtocloud/credential-service:latest -f apps/credential-service/Dockerfile .

# Create namespace if not exists
kubectl create namespace addtocloud --dry-run=client -o yaml | kubectl apply -f -

# Create email secret (you need to update the email credentials)
echo "🔐 Creating email secret..."
kubectl create secret generic email-secret \
  --from-literal=smtp-username="your-email@gmail.com" \
  --from-literal=smtp-password="your-app-password" \
  --namespace=addtocloud --dry-run=client -o yaml | kubectl apply -f -

# Deploy the credential service
echo "📋 Applying Kubernetes manifests..."
kubectl apply -f infrastructure/kubernetes/credential-service.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/credential-service -n addtocloud

# Get service URL
echo "🌐 Service endpoints:"
kubectl get services -n addtocloud

echo "✅ Deployment complete!"
echo "📝 Update the email secret with your actual Gmail credentials:"
echo "   kubectl patch secret email-secret -n addtocloud -p '{\"data\":{\"smtp-username\":\"$(echo -n 'your-email@gmail.com' | base64)\",\"smtp-password\":\"$(echo -n 'your-app-password' | base64)\"}}'"
