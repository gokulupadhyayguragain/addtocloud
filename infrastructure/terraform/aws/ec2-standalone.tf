# Standalone EC2 Instances for AddToCloud Platform
# This configuration creates EC2 instances for direct deployment

# Data source for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_addtocloud" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend API (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend (3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Key pair for SSH access
resource "aws_key_pair" "addtocloud_key" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.ec2_public_key

  tags = var.common_tags
}

# User data script for EC2 initialization
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))
}

# Frontend EC2 Instance
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type_frontend
  key_name              = aws_key_pair.addtocloud_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_addtocloud.id]
  subnet_id             = aws_subnet.public[0].id
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  
  associate_public_ip_address = true
  
  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.ec2_root_volume_size
    encrypted   = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-frontend"
    Type = "frontend"
  })
}

# Backend EC2 Instance
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type_backend
  key_name              = aws_key_pair.addtocloud_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_addtocloud.id]
  subnet_id             = aws_subnet.public[1].id
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  
  associate_public_ip_address = true
  
  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.ec2_root_volume_size
    encrypted   = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-backend"
    Type = "backend"
  })
}

# Database EC2 Instance (PostgreSQL)
resource "aws_instance" "database" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type_database
  key_name              = aws_key_pair.addtocloud_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_addtocloud.id, aws_security_group.database.id]
  subnet_id             = aws_subnet.private[0].id
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  
  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.ec2_database_volume_size
    encrypted   = true
  }

  # Additional EBS volume for database storage
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.ec2_database_data_volume_size
    encrypted   = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-database"
    Type = "database"
  })
}

# Database security group
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL access from backend
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_addtocloud.id]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "addtocloud" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_addtocloud.id]
  subnets           = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = var.common_tags
}

# Target group for frontend
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-${var.environment}-frontend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.common_tags
}

# Target group for backend
resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-${var.environment}-backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.common_tags
}

# Target group attachments
resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.frontend.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.backend.id
  port             = 8080
}

# Load balancer listener
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.addtocloud.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.addtocloud.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Outputs
output "frontend_public_ip" {
  description = "Public IP of frontend EC2 instance"
  value       = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  description = "Public IP of backend EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "database_private_ip" {
  description = "Private IP of database EC2 instance"
  value       = aws_instance.database.private_ip
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.addtocloud.dns_name
}

output "ssh_command_frontend" {
  description = "SSH command to connect to frontend instance"
  value       = "ssh -i ~/.ssh/${var.project_name}-${var.environment}-key.pem ec2-user@${aws_instance.frontend.public_ip}"
}

output "ssh_command_backend" {
  description = "SSH command to connect to backend instance"
  value       = "ssh -i ~/.ssh/${var.project_name}-${var.environment}-key.pem ec2-user@${aws_instance.backend.public_ip}"
}
