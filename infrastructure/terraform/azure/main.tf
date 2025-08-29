# Azure AKS Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "addtocloud" {
  name     = "rg-addtocloud-prod"
  location = "East US"

  tags = {
    Environment = "production"
    Project     = "addtocloud"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "addtocloud" {
  name                = "vnet-addtocloud-prod"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.addtocloud.location
  resource_group_name = azurerm_resource_group.addtocloud.name

  tags = {
    Environment = "production"
    Project     = "addtocloud"
  }
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_resource_group.addtocloud.name
  virtual_network_name = azurerm_virtual_network.addtocloud.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "addtocloud" {
  name                = "aks-addtocloud-prod"
  location            = azurerm_resource_group.addtocloud.location
  resource_group_name = azurerm_resource_group.addtocloud.name
  dns_prefix          = "addtocloud"

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  tags = {
    Environment = "production"
    Project     = "addtocloud"
  }
}

# Container Registry
resource "azurerm_container_registry" "addtocloud" {
  name                = "addtocloudacr2025"
  resource_group_name = azurerm_resource_group.addtocloud.name
  location            = azurerm_resource_group.addtocloud.location
  sku                 = "Premium"
  admin_enabled       = false

  tags = {
    Environment = "production"
    Project     = "addtocloud"
  }
}

# Database
resource "azurerm_postgresql_flexible_server" "addtocloud" {
  name                   = "psql-addtocloud-prod"
  resource_group_name    = azurerm_resource_group.addtocloud.name
  location              = azurerm_resource_group.addtocloud.location
  version               = "15"
  administrator_login    = "addtocloudadmin"
  administrator_password = var.db_password
  zone                  = "1"

  storage_mb = 32768

  sku_name = "GP_Standard_D2s_v3"

  tags = {
    Environment = "production"
    Project     = "addtocloud"
  }
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.addtocloud.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.addtocloud.name
}
