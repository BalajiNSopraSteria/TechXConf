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

