# Azure Variables
variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "East US"
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

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "addtocloud-rg"
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
  default     = ["10.2.1.0/24"]
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "addtocloud-aks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "min_node_count" {
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
    Cloud       = "azure"
  }
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "addtocloud.tech"
}
