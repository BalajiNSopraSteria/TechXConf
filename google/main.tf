provider "google" {
  region  = "us-central1"
  project = "test"
}

# ====================================================================
# NETWORKING AND SECURITY INFRASTRUCTURE
# ====================================================================

# VPC Network
resource "google_compute_network" "ai_research_vpc" {
  name                    = "ai-research-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  description = "VPC for AI Research Infrastructure"
}

# Subnets
resource "google_compute_subnetwork" "ml_training_subnet" {
  name          = "ml-training-subnet"
  ip_cidr_range = "10.0.10.0/24"
  region        = "us-central1"
  network       = google_compute_network.ai_research_vpc.id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "ml_inference_subnet" {
  name          = "ml-inference-subnet"
  ip_cidr_range = "10.0.20.0/24"
  region        = "us-central1"
  network       = google_compute_network.ai_research_vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "data_subnet" {
  name          = "data-subnet"
  ip_cidr_range = "10.0.30.0/24"
  region        = "us-central1"
  network       = google_compute_network.ai_research_vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.40.0/24"
  region        = "us-central1"
  network       = google_compute_network.ai_research_vpc.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.ai_research_vpc.name

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

  source_ranges = ["10.0.0.0/16"]
  priority      = 1000
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "allow-ssh-from-iap"
  network = google_compute_network.ai_research_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP source range
  priority      = 1000
}

resource "google_compute_firewall" "allow_https_ingress" {
  name    = "allow-https-ingress"
  network = google_compute_network.ai_research_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
  priority      = 1000
}

resource "google_compute_firewall" "deny_all_ingress" {
  name    = "deny-all-ingress"
  network = google_compute_network.ai_research_vpc.name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "ai_research_router" {
  name    = "ai-research-router"
  region  = "us-central1"
  network = google_compute_network.ai_research_vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for Private Instances
resource "google_compute_router_nat" "ai_research_nat" {
  name                               = "ai-research-nat"
  router                             = google_compute_router.ai_research_router.name
  region                             = google_compute_router.ai_research_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ====================================================================
# SECURITY AND COMPLIANCE INFRASTRUCTURE
# ====================================================================

# Cloud KMS Keyring
resource "google_kms_key_ring" "ai_research_keyring" {
  name     = "ai-research-keyring"
  location = "us-central1"
}

# Cloud KMS Crypto Key for Data Encryption
resource "google_kms_crypto_key" "ml_data_key" {
  name            = "ml-data-encryption-key"
  key_ring        = google_kms_key_ring.ai_research_keyring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = false
  }

  labels = {
    environment = "production"
    purpose     = "data-encryption"
  }
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "ai_research_policy" {
  name        = "ai-research-security-policy"
  description = "Security policy for AI research infrastructure"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["10.0.0.0/16"]
      }
    }
    description = "Allow internal traffic"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }
}

# VPC Service Controls Perimeter (Example)
resource "google_access_context_manager_service_perimeter" "ai_research_perimeter" {
  parent = "accessPolicies/000000000000"
  name   = "accessPolicies/000000000000/servicePerimeters/ai_research_perimeter"
  title  = "AI Research Service Perimeter"

  status {
    restricted_services = [
      "storage.googleapis.com",
      "bigquery.googleapis.com",
      "compute.googleapis.com"
    ]
  }

  lifecycle {
    ignore_changes = all
  }
}

# ====================================================================
# ORIGINAL RESOURCES (Updated with Security)
# ====================================================================

resource "google_compute_instance" "my_instance" {
  zone = "us-central1-a"
  name = "test"

  machine_type = "n1-standard-16"
  network_interface {
    network    = google_compute_network.ai_research_vpc.name
    subnetwork = google_compute_subnetwork.ml_training_subnet.name
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
    kms_key_self_link = google_kms_crypto_key.ml_data_key.id
  }

  scheduling {
    preemptible = true
  }

  guest_accelerator {
    type  = "nvidia-tesla-t4" # <<<<<<<<<< Try changing this to nvidia-tesla-p4 to compare the costs
    count = 4
  }

  labels = {
    environment = "production"
    service     = "web-app"
  }
}

resource "google_cloudfunctions_function" "my_function" {
  runtime             = "nodejs20"
  name                = "test"
  available_memory_mb = 512

  labels = {
    environment = "Prod"
  }
}

# Cloud Storage bucket for ML datasets and models
resource "google_storage_bucket" "ml_artifacts" {
  name          = "ml-artifacts-bucket-gcp-example"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
  
  public_access_prevention = "enforced"

  encryption {
    default_kms_key_name = google_kms_crypto_key.ml_data_key.id
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    environment = "production"
    purpose     = "ml-storage"
    workload    = "ai-dl"
  }
}

# GPU-enabled Compute Engine VM for deep learning
resource "google_compute_instance" "ml_gpu_instance" {
  zone         = "us-central1-a"
  name         = "ml-gpu-training-vm"
  machine_type = "n1-standard-8"

  boot_disk {
    initialize_params {
      image = "projects/ml-images/global/images/family/tf-latest-gpu"
      size  = 500
      type  = "pd-ssd"
    }
    kms_key_self_link = google_kms_crypto_key.ml_data_key.id
  }

  network_interface {
    network    = google_compute_network.ai_research_vpc.name
    subnetwork = google_compute_subnetwork.ml_training_subnet.name
  }

  guest_accelerator {
    type  = "nvidia-tesla-v100" # V100 GPU for deep learning
    count = 2
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
  }

  labels = {
    environment = "production"
    purpose     = "ml-training"
    workload    = "ai-dl"
    gpu         = "v100"
  }
}

# Cloud TPU for large-scale model training
resource "google_tpu_node" "ml_tpu" {
  name               = "ml-tpu-node"
  zone               = "us-central1-a"
  accelerator_type   = "v3-8"
  tensorflow_version = "2.13.0"

  network      = google_compute_network.ai_research_vpc.name
  cidr_block   = "10.3.0.0/29"

  labels = {
    environment = "production"
    purpose     = "ml-training"
    workload    = "ai-dl"
  }
}

# Vertex AI Workbench instance for ML development
resource "google_notebooks_instance" "ml_notebook" {
  name         = "ml-development-notebook"
  location     = "us-central1-a"
  machine_type = "n1-standard-4"

  vm_image {
    project      = "deeplearning-platform-release"
    image_family = "tf-latest-gpu"
  }

  install_gpu_driver = true

  accelerator_config {
    type       = "NVIDIA_TESLA_T4"
    core_count = 1
  }

  labels = {
    environment = "production"
    purpose     = "ml-development"
    workload    = "ai-dl"
  }
}

# Vertex AI Dataset
resource "google_vertex_ai_dataset" "ml_dataset" {
  display_name   = "ml-training-dataset"
  metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
  region         = "us-central1"

  labels = {
    environment = "production"
    purpose     = "ml-data"
    workload    = "ai-dl"
  }
}

# GKE cluster for ML model serving
resource "google_container_cluster" "ml_gke" {
  name     = "ml-inference-cluster"
  location = "us-central1"

  initial_node_count       = 1
  remove_default_node_pool = true

  network    = google_compute_network.ai_research_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/16"
      display_name = "VPC"
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.ml_data_key.id
  }

  workload_identity_config {
    workload_pool = "test.svc.id.goog"
  }

  resource_labels = {
    environment = "production"
    purpose     = "ml-inference"
    workload    = "ai-dl"
  }
}

# GKE node pool with GPUs for ML workloads
resource "google_container_node_pool" "ml_gpu_nodes" {
  name       = "ml-gpu-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.ml_gke.name
  node_count = 2

  node_config {
    machine_type = "n1-standard-4"
    disk_size_gb = 100

    guest_accelerator {
      type  = "nvidia-tesla-t4"
      count = 1
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "production"
      purpose     = "ml-inference"
      workload    = "ai-dl"
      gpu         = "t4"
    }
  }
}

# Cloud Run service for ML model inference
resource "google_cloud_run_service" "ml_inference" {
  name     = "ml-model-inference-service"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        resources {
          limits = {
            cpu    = "2"
            memory = "4Gi"
          }
        }
      }
    }
  }

  metadata {
    labels = {
      environment = "production"
      purpose     = "ml-inference"
      workload    = "ai-dl"
    }
  }
}

# BigQuery dataset for ML analytics
resource "google_bigquery_dataset" "ml_analytics" {
  dataset_id  = "ml_analytics_dataset"
  description = "Dataset for ML model analytics and feature engineering"
  location    = "US"

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.ml_data_key.id
  }

  labels = {
    environment = "production"
    purpose     = "ml-analytics"
    workload    = "ai-dl"
  }
}

# Artifact Registry for ML container images
resource "google_artifact_registry_repository" "ml_containers" {
  location      = "us-central1"
  repository_id = "ml-training-containers"
  description   = "Repository for ML training and inference containers"
  format        = "DOCKER"

  labels = {
    environment = "production"
    purpose     = "ml-containers"
    workload    = "ai-dl"
  }
}

# ====================================================================
# SCALED AI RESEARCH INFRASTRUCTURE - $500K Monthly Budget
# ====================================================================

# Large-scale TPU Pods for massive model training
resource "google_tpu_node" "ml_tpu_pod_large" {
  count              = 10
  name               = "ml-tpu-pod-large-${count.index + 1}"
  zone               = "us-central1-a"
  accelerator_type   = "v4-128" # 128 TPU v4 cores
  tensorflow_version = "2.13.0"
  network            = google_compute_network.ai_research_vpc.name
  cidr_block         = "10.4.${count.index}.0/29"

  labels = {
    environment = "production"
    purpose     = "ai-research-training"
    workload    = "ai-dl"
    tpu         = "v4-128"
  }
}

# Additional TPU v3 Pods for parallel training
resource "google_tpu_node" "ml_tpu_pod_medium" {
  count              = 20
  name               = "ml-tpu-pod-medium-${count.index + 1}"
  zone               = "us-central1-a"
  accelerator_type   = "v3-32" # 32 TPU v3 cores
  tensorflow_version = "2.13.0"
  network            = google_compute_network.ai_research_vpc.name
  cidr_block         = "10.5.${count.index}.0/29"

  labels = {
    environment = "production"
    purpose     = "ai-research-training"
    workload    = "ai-dl"
    tpu         = "v3-32"
  }
}

# A100 GPU instances for distributed training
resource "google_compute_instance" "ml_gpu_a100_cluster" {
  count        = 40
  zone         = "us-central1-a"
  name         = "ml-gpu-a100-${count.index + 1}"
  machine_type = "a2-megagpu-16g" # 16x A100 80GB GPUs

  boot_disk {
    initialize_params {
      image = "projects/ml-images/global/images/family/tf-latest-gpu"
      size  = 3000
      type  = "pd-ssd"
    }
    kms_key_self_link = google_kms_crypto_key.ml_data_key.id
  }

  network_interface {
    network    = google_compute_network.ai_research_vpc.name
    subnetwork = google_compute_subnetwork.ml_training_subnet.name
  }

  guest_accelerator {
    type  = "nvidia-tesla-a100"
    count = 16
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-training"
    workload    = "ai-dl"
    gpu         = "a100-80gb"
  }
}

# Additional A100 40GB instances
resource "google_compute_instance" "ml_gpu_a100_standard" {
  count        = 60
  zone         = "us-central1-a"
  name         = "ml-gpu-a100-std-${count.index + 1}"
  machine_type = "a2-highgpu-8g" # 8x A100 40GB GPUs

  boot_disk {
    initialize_params {
      image = "projects/ml-images/global/images/family/tf-latest-gpu"
      size  = 2000
      type  = "pd-ssd"
    }
    kms_key_self_link = google_kms_crypto_key.ml_data_key.id
  }

  network_interface {
    network    = google_compute_network.ai_research_vpc.name
    subnetwork = google_compute_subnetwork.ml_training_subnet.name
  }

  guest_accelerator {
    type  = "nvidia-tesla-a100"
    count = 8
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-training"
    workload    = "ai-dl"
    gpu         = "a100-40gb"
  }
}

# Large Cloud Storage buckets for petascale datasets
resource "google_storage_bucket" "ml_research_datasets" {
  name          = "ml-research-datasets-petascale-gcp"
  location      = "US"
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  encryption {
    default_kms_key_name = google_kms_crypto_key.ml_data_key.id
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-data"
    workload    = "ai-dl"
  }
}

resource "google_storage_bucket" "ml_model_registry" {
  name          = "ml-model-registry-archive-gcp"
  location      = "US"
  force_destroy = false
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  encryption {
    default_kms_key_name = google_kms_crypto_key.ml_data_key.id
  }

  versioning {
    enabled = true
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-models"
    workload    = "ai-dl"
  }
}

# Massive GKE cluster for distributed inference and training
resource "google_container_cluster" "ml_gke_research" {
  name     = "ml-research-gke-cluster"
  location = "us-central1"

  initial_node_count       = 5
  remove_default_node_pool = true

  network    = google_compute_network.ai_research_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.1.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/16"
      display_name = "VPC"
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.ml_data_key.id
  }

  workload_identity_config {
    workload_pool = "test.svc.id.goog"
  }

  resource_labels = {
    environment = "production"
    purpose     = "ai-research-platform"
    workload    = "ai-dl"
  }
}

# CPU node pool for orchestration
resource "google_container_node_pool" "ml_gke_cpu_pool" {
  name       = "cpu-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.ml_gke_research.name
  node_count = 50

  node_config {
    machine_type = "n2-highmem-32"
    disk_size_gb = 500
    disk_type    = "pd-ssd"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "production"
      purpose     = "ai-research-orchestration"
      workload    = "ai-dl"
    }
  }
}

# A100 GPU node pool for GKE
resource "google_container_node_pool" "ml_gke_gpu_a100_pool" {
  name       = "gpu-a100-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.ml_gke_research.name
  node_count = 30

  node_config {
    machine_type = "a2-highgpu-4g"
    disk_size_gb = 1000
    disk_type    = "pd-ssd"

    guest_accelerator {
      type  = "nvidia-tesla-a100"
      count = 4
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "production"
      purpose     = "ai-research-inference"
      workload    = "ai-dl"
      gpu         = "a100"
    }
  }
}

# BigQuery datasets for large-scale analytics
resource "google_bigquery_dataset" "ml_research_analytics" {
  dataset_id  = "ml_research_analytics_dataset"
  description = "Large-scale ML analytics and feature engineering"
  location    = "US"

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.ml_data_key.id
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-analytics"
    workload    = "ai-dl"
  }
}

# BigQuery tables for feature store
resource "google_bigquery_table" "ml_feature_store" {
  dataset_id = google_bigquery_dataset.ml_research_analytics.dataset_id
  table_id   = "ml_feature_store"

  time_partitioning {
    type = "DAY"
  }

  clustering = ["user_id", "timestamp"]

  labels = {
    environment = "production"
    purpose     = "ai-research-features"
    workload    = "ai-dl"
  }
}

# Vertex AI Training Pipeline
resource "google_vertex_ai_endpoint" "ml_research_endpoint" {
  count        = 10
  name         = "ml-research-endpoint-${count.index + 1}"
  display_name = "AI Research Endpoint ${count.index + 1}"
  location     = "us-central1"

  labels = {
    environment = "production"
    purpose     = "ai-research-inference"
    workload    = "ai-dl"
  }
}

# Cloud Composer for ML pipeline orchestration
resource "google_composer_environment" "ml_orchestration" {
  name   = "ml-research-orchestration"
  region = "us-central1"

  config {
    node_config {
      zone         = "us-central1-a"
      machine_type = "n1-standard-32"
      disk_size_gb = 1000
    }

    software_config {
      image_version = "composer-2-airflow-2"
    }
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-orchestration"
    workload    = "ai-dl"
  }
}

# Cloud Filestore for shared training data
resource "google_filestore_instance" "ml_shared_storage" {
  name     = "ml-research-shared-storage"
  location = "us-central1-a"
  tier     = "ENTERPRISE"

  file_shares {
    capacity_gb = 102400 # 100 TB
    name        = "ml_training_data"
  }

  networks {
    network = google_compute_network.ai_research_vpc.name
    modes   = ["MODE_IPV4"]
  }

  kms_key_name = google_kms_crypto_key.ml_data_key.id

  labels = {
    environment = "production"
    purpose     = "ai-research-storage"
    workload    = "ai-dl"
  }
}

# Persistent Disks for data staging
resource "google_compute_disk" "ml_staging_disks" {
  count = 50
  name  = "ml-staging-disk-${count.index + 1}"
  type  = "pd-ssd"
  zone  = "us-central1-a"
  size  = 10000 # 10 TB each

  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.ml_data_key.id
  }

  labels = {
    environment = "production"
    purpose     = "ai-research-staging"
    workload    = "ai-dl"
  }
}

# Cloud NAT for high-bandwidth egress (already created, removing duplicate)
# Keeping only the original ai_research_router and ai_research_nat

# Cloud Logging for extensive monitoring
resource "google_logging_project_sink" "ml_research_logs" {
  name        = "ml-research-log-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.ml_model_registry.name}"

  filter = "resource.type=\"gce_instance\" AND labels.workload=\"ai-dl\""

  unique_writer_identity = true
}
