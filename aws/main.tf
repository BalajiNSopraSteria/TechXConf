provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

resource "aws_instance" "my_web_app" {
  ami = "ami-005e54dee72cc1d00"

  instance_type = "m3.xlarge" # <<<<<<<<<< Try changing this to m5.xlarge to compare the costs

  tags = {
    Environment = "production"
    Service     = "web-app"
    Name        = "dash"
  }

  root_block_device {
    volume_size = 1000 # <<<<<<<<<< Try adding volume_type="gp3" to compare costs
  }
}

resource "aws_lambda_function" "my_hello_world" {
  runtime       = "nodejs12.x"
  handler       = "exports.test"
  image_uri     = "test"
  function_name = "test"
  role          = "arn:aws:ec2:us-east-1:123123123123:instance/i-1231231231"

  memory_size = 512
  tags = {
    Environment = "Prod"
  }
}

# S3 bucket for ML model artifacts and datasets
resource "aws_s3_bucket" "ml_artifacts" {
  bucket = "ml-artifacts-bucket-example"

  tags = {
    Environment = "production"
    Purpose     = "ML-Storage"
    Workload    = "AI-DL"
  }
}

resource "aws_s3_bucket_versioning" "ml_artifacts_versioning" {
  bucket = aws_s3_bucket.ml_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# EFS for shared model storage
resource "aws_efs_file_system" "ml_shared_storage" {
  creation_token = "ml-shared-storage"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Environment = "production"
    Purpose     = "ML-SharedStorage"
    Workload    = "AI-DL"
  }
}

# GPU EC2 instance for deep learning training
resource "aws_instance" "ml_gpu_instance" {
  ami           = "ami-0c02fb55d7179e87b" # Deep Learning AMI (Ubuntu 20.04)
  instance_type = "p3.2xlarge"            # GPU instance with NVIDIA V100

  tags = {
    Environment = "production"
    Purpose     = "ML-Training"
    Workload    = "AI-DL"
    GPU         = "V100"
  }

  root_block_device {
    volume_size = 500
    volume_type = "gp3"
  }
}

# SageMaker Notebook Instance for ML development
resource "aws_sagemaker_notebook_instance" "ml_notebook" {
  name          = "ml-development-notebook"
  role_arn      = "arn:aws:iam::123456789012:role/service-role/AmazonSageMaker-ExecutionRole"
  instance_type = "ml.t3.xlarge"

  tags = {
    Environment = "production"
    Purpose     = "ML-Development"
    Workload    = "AI-DL"
  }
}

# SageMaker Training Job (Placeholder - would be configured for specific training)
resource "aws_sagemaker_model" "ml_model" {
  name               = "deep-learning-model"
  execution_role_arn = "arn:aws:iam::123456789012:role/service-role/AmazonSageMaker-ExecutionRole"

  primary_container {
    image = "763104351884.dkr.ecr.us-east-1.amazonaws.com/pytorch-inference:1.12.0-gpu-py38"
  }

  tags = {
    Environment = "production"
    Purpose     = "ML-Inference"
    Workload    = "AI-DL"
  }
}

# SageMaker Endpoint Configuration for model serving
resource "aws_sagemaker_endpoint_configuration" "ml_endpoint_config" {
  name = "ml-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.ml_model.name
    initial_instance_count = 2
    instance_type          = "ml.g4dn.xlarge" # GPU instance for inference
  }

  tags = {
    Environment = "production"
    Purpose     = "ML-Inference"
    Workload    = "AI-DL"
  }
}

# SageMaker Endpoint for real-time inference
resource "aws_sagemaker_endpoint" "ml_endpoint" {
  name                 = "ml-inference-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.ml_endpoint_config.name

  tags = {
    Environment = "production"
    Purpose     = "ML-Inference"
    Workload    = "AI-DL"
  }
}

# ECR repository for ML container images
resource "aws_ecr_repository" "ml_containers" {
  name                 = "ml-training-containers"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "production"
    Purpose     = "ML-Containers"
    Workload    = "AI-DL"
  }
}

# ====================================================================
# SCALED AI RESEARCH INFRASTRUCTURE - $100K Monthly Budget
# ====================================================================

# Multiple P4d instances for large-scale distributed training
resource "aws_instance" "ml_gpu_cluster" {
  count         = 8
  ami           = "ami-0c02fb55d7179e87b"
  instance_type = "p4d.24xlarge" # 8x A100 GPUs, 96 vCPUs, 1152GB RAM

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Training"
    Workload    = "AI-DL"
    GPU         = "A100"
    Cluster     = "distributed-training"
    Name        = "ml-gpu-cluster-${count.index + 1}"
  }

  root_block_device {
    volume_size = 2000
    volume_type = "gp3"
    iops        = 16000
    throughput  = 1000
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 5000
    volume_type = "gp3"
    iops        = 16000
    throughput  = 1000
  }
}

# Additional P3 instances for medium-scale training
resource "aws_instance" "ml_gpu_medium" {
  count         = 12
  ami           = "ami-0c02fb55d7179e87b"
  instance_type = "p3.8xlarge" # 4x V100 GPUs

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Training"
    Workload    = "AI-DL"
    GPU         = "V100"
    Name        = "ml-gpu-medium-${count.index + 1}"
  }

  root_block_device {
    volume_size = 1000
    volume_type = "gp3"
  }
}

# FSx for Lustre for high-performance distributed training storage
resource "aws_fsx_lustre_file_system" "ml_hpc_storage" {
  storage_capacity            = 50400 # 50.4 TB
  deployment_type             = "PERSISTENT_2"
  per_unit_storage_throughput = 250
  subnet_ids                  = ["subnet-12345678"]

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Storage"
    Workload    = "AI-DL"
  }
}

# Large S3 buckets for massive dataset storage
resource "aws_s3_bucket" "ml_research_datasets" {
  bucket = "ml-research-datasets-petascale"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Data"
    Workload    = "AI-DL"
  }
}

resource "aws_s3_bucket" "ml_model_checkpoints" {
  bucket = "ml-model-checkpoints-archive"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Checkpoints"
    Workload    = "AI-DL"
  }
}

# SageMaker Training Jobs - Multiple concurrent jobs
resource "aws_sagemaker_training_job" "research_training_1" {
  count         = 1
  training_job_name = "ai-research-training-job-1"
  role_arn          = "arn:aws:iam::123456789012:role/service-role/AmazonSageMaker-ExecutionRole"

  algorithm_specification {
    training_image = "763104351884.dkr.ecr.us-east-1.amazonaws.com/pytorch-training:2.0.0-gpu-py310"
  }

  input_data_config {
    channel_name = "training"
    data_source {
      s3_data_source {
        s3_data_type = "S3Prefix"
        s3_uri       = "s3://ml-research-datasets-petascale/training-data"
      }
    }
  }

  output_data_config {
    s3_output_path = "s3://ml-model-checkpoints-archive/outputs"
  }

  resource_config {
    instance_type   = "ml.p4d.24xlarge"
    instance_count  = 16
    volume_size_in_gb = 500
  }

  stopping_condition {
    max_runtime_in_seconds = 259200 # 72 hours
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Training"
    Workload    = "AI-DL"
  }
}

# SageMaker HyperPod for distributed training clusters
resource "aws_sagemaker_domain" "research_domain" {
  domain_name = "ai-research-domain"
  auth_mode   = "IAM"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  default_user_settings {
    execution_role = "arn:aws:iam::123456789012:role/service-role/AmazonSageMaker-ExecutionRole"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Platform"
    Workload    = "AI-DL"
  }
}

# Multiple SageMaker Endpoints for high-throughput inference
resource "aws_sagemaker_endpoint_configuration" "research_endpoint_config" {
  name = "ai-research-endpoint-config"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.ml_model.name
    initial_instance_count = 20
    instance_type          = "ml.p3.2xlarge"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Inference"
    Workload    = "AI-DL"
  }
}

resource "aws_sagemaker_endpoint" "research_endpoint" {
  name                 = "ai-research-inference-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.research_endpoint_config.name

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Inference"
    Workload    = "AI-DL"
  }
}

# EBS volumes for data preprocessing
resource "aws_ebs_volume" "ml_preprocessing_storage" {
  count             = 10
  availability_zone = "us-east-1a"
  size              = 10000
  type              = "gp3"
  iops              = 16000
  throughput        = 1000

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Preprocessing"
    Workload    = "AI-DL"
    Name        = "preprocessing-volume-${count.index + 1}"
  }
}

# ElastiCache for distributed training coordination
resource "aws_elasticache_cluster" "ml_cache" {
  cluster_id           = "ml-research-cache"
  engine               = "redis"
  node_type            = "cache.r6g.4xlarge"
  num_cache_nodes      = 3
  parameter_group_name = "default.redis7"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Cache"
    Workload    = "AI-DL"
  }
}

# VPC Endpoints for optimized S3 access
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = "vpc-12345678"
  service_name = "com.amazonaws.us-east-1.s3"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Networking"
    Workload    = "AI-DL"
  }
}

# CloudWatch Log Groups for extensive monitoring
resource "aws_cloudwatch_log_group" "ml_training_logs" {
  name              = "/aws/sagemaker/ai-research-training"
  retention_in_days = 90

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Monitoring"
    Workload    = "AI-DL"
  }
}
