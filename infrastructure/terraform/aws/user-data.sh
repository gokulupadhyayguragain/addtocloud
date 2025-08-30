#!/bin/bash

# AddToCloud EC2 Instance Initialization Script
# This script sets up the environment for AddToCloud platform

# Update system
yum update -y

# Install essential packages
yum install -y \
    git \
    curl \
    wget \
    htop \
    unzip \
    nano \
    awscli \
    docker

# Start Docker service
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Node.js (for frontend)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Go (for backend)
cd /tmp
wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ec2-user/.bashrc

# Install PostgreSQL client
yum install -y postgresql

# Create application directory
mkdir -p /opt/addtocloud
chown ec2-user:ec2-user /opt/addtocloud

# Create systemd service files
cat > /etc/systemd/system/addtocloud-frontend.service << 'EOF'
[Unit]
Description=AddToCloud Frontend Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/addtocloud/frontend
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/addtocloud-backend.service << 'EOF'
[Unit]
Description=AddToCloud Backend Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/addtocloud/backend
ExecStart=/opt/addtocloud/backend/bin/main
Restart=always
RestartSec=5
Environment=PORT=8080
Environment=GO_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "namespace": "AddToCloud/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Setup deployment script
cat > /home/ec2-user/deploy-addtocloud.sh << 'EOF'
#!/bin/bash

# AddToCloud Deployment Script
echo "🚀 Starting AddToCloud deployment..."

# Clone or update repository
if [ -d "/opt/addtocloud/.git" ]; then
    echo "📦 Updating existing repository..."
    cd /opt/addtocloud
    git pull origin main
else
    echo "📦 Cloning repository..."
    git clone https://github.com/your-org/addtocloud.git /opt/addtocloud
    cd /opt/addtocloud
fi

# Deploy frontend
if [ -f "/opt/addtocloud/frontend/package.json" ]; then
    echo "🎨 Building frontend..."
    cd /opt/addtocloud/frontend
    npm install
    npm run build
    sudo systemctl restart addtocloud-frontend
    sudo systemctl enable addtocloud-frontend
fi

# Deploy backend
if [ -f "/opt/addtocloud/backend/go.mod" ]; then
    echo "⚙️ Building backend..."
    cd /opt/addtocloud/backend
    /usr/local/go/bin/go mod download
    /usr/local/go/bin/go build -o bin/main cmd/main.go
    sudo systemctl restart addtocloud-backend
    sudo systemctl enable addtocloud-backend
fi

echo "✅ AddToCloud deployment completed!"
echo "Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "Backend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
EOF

chmod +x /home/ec2-user/deploy-addtocloud.sh
chown ec2-user:ec2-user /home/ec2-user/deploy-addtocloud.sh

# Setup nginx for reverse proxy (optional)
yum install -y nginx

cat > /etc/nginx/conf.d/addtocloud.conf << 'EOF'
upstream frontend {
    server 127.0.0.1:3000;
}

upstream backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /api/ {
        proxy_pass http://backend/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

systemctl enable nginx

# Create initial status file
echo "AddToCloud EC2 instance initialized at $(date)" > /home/ec2-user/status.txt
echo "Instance: ${project_name}-${environment}" >> /home/ec2-user/status.txt
echo "Ready for deployment!" >> /home/ec2-user/status.txt

# Log completion
echo "AddToCloud EC2 initialization completed successfully" > /var/log/addtocloud-init.log
