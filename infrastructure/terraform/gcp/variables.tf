# GCP Variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "static-operator-469115-h1"
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
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

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "addtocloud-gke-cluster"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 50
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "addtocloud.tech"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "addtocloud"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
