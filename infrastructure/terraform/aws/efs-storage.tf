# AWS EFS Configuration for Persistent Storage
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "addtocloud"
      ManagedBy   = "terraform"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "addtocloud-eks-primary"
}

# Get VPC information
data "aws_vpc" "cluster_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.cluster_name}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.cluster_vpc.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# EFS File System
resource "aws_efs_file_system" "addtocloud_efs" {
  creation_token   = "addtocloud-efs-${var.environment}"
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 1024
  
  # Encryption at rest
  encrypted = true
  
  # Lifecycle policy
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }
  
  tags = {
    Name        = "addtocloud-efs-${var.environment}"
    Environment = var.environment
    Purpose     = "kubernetes-persistent-storage"
  }
}

# EFS Mount Targets (one per availability zone)
resource "aws_efs_mount_target" "addtocloud_efs_mt" {
  count          = length(data.aws_subnets.private.ids)
  file_system_id = aws_efs_file_system.addtocloud_efs.id
  subnet_id      = data.aws_subnets.private.ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

# Security Group for EFS
resource "aws_security_group" "efs_sg" {
  name        = "addtocloud-efs-sg-${var.environment}"
  description = "Security group for EFS mount targets"
  vpc_id      = data.aws_vpc.cluster_vpc.id

  ingress {
    description = "NFS traffic from EKS nodes"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.cluster_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "addtocloud-efs-sg-${var.environment}"
  }
}

# EFS Access Points for different services
resource "aws_efs_access_point" "postgresql_ap" {
  file_system_id = aws_efs_file_system.addtocloud_efs.id
  
  root_directory {
    path = "/postgresql"
    creation_info {
      owner_uid   = 999
      owner_gid   = 999
      permissions = "0755"
    }
  }
  
  posix_user {
    uid = 999
    gid = 999
  }
  
  tags = {
    Name = "postgresql-access-point"
    Service = "postgresql"
  }
}

resource "aws_efs_access_point" "mongodb_ap" {
  file_system_id = aws_efs_file_system.addtocloud_efs.id
  
  root_directory {
    path = "/mongodb"
    creation_info {
      owner_uid   = 999
      owner_gid   = 999
      permissions = "0755"
    }
  }
  
  posix_user {
    uid = 999
    gid = 999
  }
  
  tags = {
    Name = "mongodb-access-point"
    Service = "mongodb"
  }
}

resource "aws_efs_access_point" "redis_ap" {
  file_system_id = aws_efs_file_system.addtocloud_efs.id
  
  root_directory {
    path = "/redis"
    creation_info {
      owner_uid   = 999
      owner_gid   = 999
      permissions = "0755"
    }
  }
  
  posix_user {
    uid = 999
    gid = 999
  }
  
  tags = {
    Name = "redis-access-point"
    Service = "redis"
  }
}

resource "aws_efs_access_point" "logs_ap" {
  file_system_id = aws_efs_file_system.addtocloud_efs.id
  
  root_directory {
    path = "/logs"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
  
  posix_user {
    uid = 1000
    gid = 1000
  }
  
  tags = {
    Name = "logs-access-point"
    Service = "logging"
  }
}

resource "aws_efs_access_point" "backup_ap" {
  file_system_id = aws_efs_file_system.addtocloud_efs.id
  
  root_directory {
    path = "/backup"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
  
  posix_user {
    uid = 1000
    gid = 1000
  }
  
  tags = {
    Name = "backup-access-point"
    Service = "backup"
  }
}

# IAM Role for EFS CSI Driver
resource "aws_iam_role" "efs_csi_driver_role" {
  name = "AmazonEKS_EFS_CSI_DriverRole_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the required policy to the role
resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy" {
  role       = aws_iam_role.efs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Outputs
output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.addtocloud_efs.id
}

output "efs_file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = aws_efs_file_system.addtocloud_efs.dns_name
}

output "efs_access_points" {
  description = "EFS access points"
  value = {
    postgresql = aws_efs_access_point.postgresql_ap.id
    mongodb    = aws_efs_access_point.mongodb_ap.id
    redis      = aws_efs_access_point.redis_ap.id
    logs       = aws_efs_access_point.logs_ap.id
    backup     = aws_efs_access_point.backup_ap.id
  }
}

output "efs_csi_driver_role_arn" {
  description = "ARN of the EFS CSI driver IAM role"
  value       = aws_iam_role.efs_csi_driver_role.arn
}
