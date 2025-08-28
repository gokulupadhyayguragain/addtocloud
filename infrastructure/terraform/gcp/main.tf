# GCP GKE Cluster Configuration for AddToCloud
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"
}

# Subnet for GKE
resource "google_compute_subnetwork" "gke" {
  name          = "${var.project_name}-${var.environment}-gke-subnet"
  ip_cidr_range = var.vpc_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }

  private_ip_google_access = true
}

# Cloud Router and NAT Gateway
resource "google_compute_router" "main" {
  name    = "${var.project_name}-${var.environment}-router"
  region  = var.gcp_region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-${var.environment}-nat"
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Service Account for GKE
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.project_name}-${var.environment}-gke-nodes"
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE worker nodes"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-gke"
  location = var.gcp_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.gke.name

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Enable IP aliasing
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.3.0.0/28"
  }

  # Enable master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Enable shielded nodes
  enable_shielded_nodes = true

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    istio_config {
      disabled = !var.enable_istio
    }
  }

  # Enable logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T02:00:00Z"
      end_time   = "2024-01-01T06:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }

  # Resource labels
  resource_labels = var.common_tags
}

# Managed Node Pool
resource "google_container_node_pool" "main" {
  name       = "${var.project_name}-${var.environment}-nodes"
  location   = var.gcp_region
  cluster    = google_container_cluster.main.name
  node_count = var.node_count

  # Enable auto-scaling
  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }

  # Enable auto-upgrade and auto-repair
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = var.gcp_node_machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = var.common_tags

    # Enable shielded VM features
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Enable workload metadata config
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    tags = ["gke-node", "${var.project_name}-${var.environment}"]
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Random passwords for services
resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# Cloud SQL PostgreSQL Database
resource "google_sql_database_instance" "postgres" {
  name             = "${var.project_name}-${var.environment}-postgres"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = 20
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.gcp_region
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
      require_ssl     = true
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Private IP allocation for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

# Service networking connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud SQL Database
resource "google_sql_database" "database" {
  name     = "addtocloud"
  instance = google_sql_database_instance.postgres.name
}

# Cloud SQL User
resource "google_sql_user" "user" {
  name     = "addtocloud"
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres_password.result
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "main" {
  location      = var.gcp_region
  repository_id = "${var.project_name}-${var.environment}"
  description   = "Docker repository for AddToCloud"
  format        = "DOCKER"

  labels = var.common_tags
}

# Secret Manager for storing secrets
resource "google_secret_manager_secret" "postgres_password" {
  secret_id = "${var.project_name}-${var.environment}-postgres-password"

  replication {
    automatic = true
  }

  labels = var.common_tags
}

resource "google_secret_manager_secret_version" "postgres_password" {
  secret      = google_secret_manager_secret.postgres_password.id
  secret_data = random_password.postgres_password.result
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "${var.project_name}-${var.environment}-jwt-secret"

  replication {
    automatic = true
  }

  labels = var.common_tags
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

# Cloud Storage bucket for file uploads
resource "google_storage_bucket" "uploads" {
  name          = "${var.project_name}-${var.environment}-uploads"
  location      = var.gcp_region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = var.common_tags
}

# IAM binding for GKE to access Secret Manager
resource "google_project_iam_member" "gke_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.environment}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
}

# Outputs
output "cluster_endpoint" {
  value = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  value = google_container_cluster.main.master_auth[0].cluster_ca_certificate
}

output "cluster_name" {
  value = google_container_cluster.main.name
}

output "cluster_location" {
  value = google_container_cluster.main.location
}

output "artifact_registry_url" {
  value = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "postgres_connection_name" {
  value = google_sql_database_instance.postgres.connection_name
}

output "postgres_private_ip" {
  value = google_sql_database_instance.postgres.private_ip_address
}

output "postgres_password" {
  value     = random_password.postgres_password.result
  sensitive = true
}

output "jwt_secret" {
  value     = random_password.jwt_secret.result
  sensitive = true
}

output "storage_bucket_name" {
  value = google_storage_bucket.uploads.name
}

