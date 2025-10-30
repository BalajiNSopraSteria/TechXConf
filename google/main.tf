provider "google" {
  region  = "us-central1"
  project = "test"
}

resource "google_compute_instance" "my_instance" {
  zone = "us-central1-a"
  name = "test"

  machine_type = "n1-standard-16" # <<<<<<<<<< Try changing this to n1-standard-32 to compare the costs
  network_interface {
    network = "default"
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
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

  versioning {
    enabled = true
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
  }

  network_interface {
    network = "default"
    access_config {}
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

  network = "default"

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

  network    = "default"
  subnetwork = "default"

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
