# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "addtocloud"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "addtocloud-eks-cluster"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "addtocloud-node-group"
}

variable "node_instance_types" {
  description = "EC2 instance types for nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "node_count" {
  description = "Number of nodes (alias for desired_capacity)"
  type        = number
  default     = 3
}

variable "node_max_capacity" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "node_min_capacity" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "addtocloud"
    Environment = "prod"
    ManagedBy   = "terraform"
    Cloud       = "aws"
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "addtocloud.tech"
}

variable "aws_node_instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
  default     = "t3.medium"
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "enable_database_encryption" {
  description = "Enable RDS encryption"
  type        = bool
  default     = true
}

# EC2 Standalone Variables
variable "ec2_public_key" {
  description = "Public key for EC2 instances SSH access"
  type        = string
  default     = ""
}

variable "ec2_instance_type_frontend" {
  description = "EC2 instance type for frontend"
  type        = string
  default     = "t3.small"
}

variable "ec2_instance_type_backend" {
  description = "EC2 instance type for backend"
  type        = string
  default     = "t3.medium"
}

variable "ec2_instance_type_database" {
  description = "EC2 instance type for database"
  type        = string
  default     = "t3.medium"
}

variable "ec2_root_volume_size" {
  description = "Root volume size for EC2 instances in GB"
  type        = number
  default     = 20
}

variable "ec2_database_volume_size" {
  description = "Root volume size for database EC2 instance in GB"
  type        = number
  default     = 30
}

variable "ec2_database_data_volume_size" {
  description = "Data volume size for database storage in GB"
  type        = number
  default     = 100
}
