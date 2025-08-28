# Terraform variables for multi-cloud deployment
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "addtocloud"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 3
}

# Azure specific variables
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

variable "azure_node_vm_size" {
  description = "Azure VM size for nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

# AWS specific variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_availability_zones" {
  description = "AWS availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "aws_node_instance_type" {
  description = "AWS EC2 instance type for nodes"
  type        = string
  default     = "t3.medium"
}

# GCP specific variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_node_machine_type" {
  description = "GCP machine type for nodes"
  type        = string
  default     = "e2-medium"
}

# Network configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# Domain and SSL
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "addtocloud.tech"
}

variable "certificate_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
  default     = "admin@addtocloud.tech"
}

# Istio configuration
variable "istio_version" {
  description = "Istio version to install"
  type        = string
  default     = "1.20.0"
}

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = true
}

# Monitoring configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack (ELK/EFK)"
  type        = bool
  default     = true
}

# Database configuration
variable "database_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
}

variable "enable_database_encryption" {
  description = "Enable database encryption at rest"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AddToCloud"
    Environment = "production"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}
