provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ====================================================================
# NETWORKING AND SECURITY INFRASTRUCTURE
# ====================================================================

# VPC for AI Research Infrastructure
resource "aws_vpc" "ai_research_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ai-research-vpc"
    Environment = "production"
    Purpose     = "AI-Research"
  }
}

# Public Subnets for NAT Gateways and Load Balancers
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.ai_research_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "ai-research-public-subnet-1a"
    Environment = "production"
    Type        = "Public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.ai_research_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "ai-research-public-subnet-1b"
    Environment = "production"
    Type        = "Public"
  }
}

# Private Subnets for ML Training and Compute
resource "aws_subnet" "private_ml_subnet_1" {
  vpc_id            = aws_vpc.ai_research_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "ai-research-ml-private-subnet-1a"
    Environment = "production"
    Type        = "Private-ML"
  }
}

resource "aws_subnet" "private_ml_subnet_2" {
  vpc_id            = aws_vpc.ai_research_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "ai-research-ml-private-subnet-1b"
    Environment = "production"
    Type        = "Private-ML"
  }
}

# Private Subnets for Data Storage
resource "aws_subnet" "private_data_subnet_1" {
  vpc_id            = aws_vpc.ai_research_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "ai-research-data-private-subnet-1a"
    Environment = "production"
    Type        = "Private-Data"
  }
}

resource "aws_subnet" "private_data_subnet_2" {
  vpc_id            = aws_vpc.ai_research_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "ai-research-data-private-subnet-1b"
    Environment = "production"
    Type        = "Private-Data"
  }
}

# Internet Gateway for Public Subnets
resource "aws_internet_gateway" "ai_research_igw" {
  vpc_id = aws_vpc.ai_research_vpc.id

  tags = {
    Name        = "ai-research-igw"
    Environment = "production"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"

  tags = {
    Name        = "ai-research-nat-eip-1a"
    Environment = "production"
  }
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"

  tags = {
    Name        = "ai-research-nat-eip-1b"
    Environment = "production"
  }
}

# NAT Gateways for Private Subnet Internet Access
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name        = "ai-research-nat-gw-1a"
    Environment = "production"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name        = "ai-research-nat-gw-1b"
    Environment = "production"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ai_research_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ai_research_igw.id
  }

  tags = {
    Name        = "ai-research-public-rt"
    Environment = "production"
  }
}

# Route Tables for Private Subnets
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.ai_research_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name        = "ai-research-private-rt-1a"
    Environment = "production"
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.ai_research_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name        = "ai-research-private-rt-1b"
    Environment = "production"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_ml_rta_1" {
  subnet_id      = aws_subnet.private_ml_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_ml_rta_2" {
  subnet_id      = aws_subnet.private_ml_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

resource "aws_route_table_association" "private_data_rta_1" {
  subnet_id      = aws_subnet.private_data_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_data_rta_2" {
  subnet_id      = aws_subnet.private_data_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}

# Security Group for ML Training Instances
resource "aws_security_group" "ml_training_sg" {
  name        = "ml-training-security-group"
  description = "Security group for ML training instances"
  vpc_id      = aws_vpc.ai_research_vpc.id

  # Ingress Rules
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"] # From public subnets only
  }

  ingress {
    description = "HTTPS for model serving"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Within VPC only
  }

  ingress {
    description = "TensorBoard"
    from_port   = 6006
    to_port     = 6006
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Distributed training communication"
    from_port   = 8000
    to_port     = 9000
    protocol    = "tcp"
    self        = true
  }

  # Egress Rules
  egress {
    description = "HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "S3 access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3_endpoint.prefix_list_id]
  }

  egress {
    description = "Internal VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name        = "ml-training-sg"
    Environment = "production"
  }
}

# Security Group for SageMaker Endpoints
resource "aws_security_group" "sagemaker_endpoint_sg" {
  name        = "sagemaker-endpoint-security-group"
  description = "Security group for SageMaker endpoints"
  vpc_id      = aws_vpc.ai_research_vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sagemaker-endpoint-sg"
    Environment = "production"
  }
}

# Security Group for Data Storage
resource "aws_security_group" "data_storage_sg" {
  name        = "data-storage-security-group"
  description = "Security group for data storage services"
  vpc_id      = aws_vpc.ai_research_vpc.id

  ingress {
    description     = "NFS from ML subnets"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ml_training_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name        = "data-storage-sg"
    Environment = "production"
  }
}

# Network ACL for ML Subnets
resource "aws_network_acl" "ml_nacl" {
  vpc_id     = aws_vpc.ai_research_vpc.id
  subnet_ids = [aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id]

  # Ingress Rules
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  # Egress Rules
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "ml-subnet-nacl"
    Environment = "production"
  }
}

# VPC Endpoints for AWS Services
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.ai_research_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_rt_1.id,
    aws_route_table.private_rt_2.id
  ]

  tags = {
    Name        = "s3-vpc-endpoint"
    Environment = "production"
  }
}

resource "aws_vpc_endpoint" "sagemaker_api_endpoint" {
  vpc_id              = aws_vpc.ai_research_vpc.id
  service_name        = "com.amazonaws.us-east-1.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id]
  security_group_ids  = [aws_security_group.sagemaker_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "sagemaker-api-vpc-endpoint"
    Environment = "production"
  }
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id              = aws_vpc.ai_research_vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id]
  security_group_ids  = [aws_security_group.ml_training_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-api-vpc-endpoint"
    Environment = "production"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id              = aws_vpc.ai_research_vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id]
  security_group_ids  = [aws_security_group.ml_training_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-dkr-vpc-endpoint"
    Environment = "production"
  }
}

# ====================================================================
# SECURITY AND COMPLIANCE INFRASTRUCTURE
# ====================================================================

# KMS Key for Data Encryption
resource "aws_kms_key" "ml_data_key" {
  description             = "KMS key for ML data encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow services to use the key"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "sagemaker.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "ml-data-encryption-key"
    Environment = "production"
    Compliance  = "Required"
  }
}

resource "aws_kms_alias" "ml_data_key_alias" {
  name          = "alias/ml-data-key"
  target_key_id = aws_kms_key.ml_data_key.key_id
}

# GuardDuty for Threat Detection
resource "aws_guardduty_detector" "ai_research_guardduty" {
  enable = true

  tags = {
    Name        = "ai-research-guardduty"
    Environment = "production"
  }
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/ai-research-flow-logs"
  retention_in_days = 90

  tags = {
    Name        = "ai-research-vpc-flow-logs"
    Environment = "production"
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "vpc-flow-logs-role"
    Environment = "production"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "ai_research_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.ai_research_vpc.id

  tags = {
    Name        = "ai-research-vpc-flow-log"
    Environment = "production"
  }
}

# AWS Config for Compliance Monitoring
resource "aws_config_configuration_recorder" "ai_research_config" {
  name     = "ai-research-config-recorder"
  role_arn = "arn:aws:iam::123456789012:role/aws-config-role"

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# S3 Bucket for AWS Config
resource "aws_s3_bucket" "config_bucket" {
  bucket = "ai-research-config-bucket"

  tags = {
    Name        = "ai-research-config-bucket"
    Environment = "production"
    Compliance  = "Required"
  }
}

resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ml_data_key.arn
    }
  }
}

# ====================================================================
# ORIGINAL RESOURCES (Updated with Security)
# ====================================================================

resource "aws_instance" "my_web_app" {
  ami = "ami-005e54dee72cc1d00"

  instance_type = "m3.xlarge"
  subnet_id     = aws_subnet.private_ml_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ml_training_sg.id]

  tags = {
    Environment = "production"
    Service     = "web-app"
    Name        = "dash"
  }

  root_block_device {
    volume_size = 1000
    encrypted   = true
    kms_key_id  = aws_kms_key.ml_data_key.arn
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

resource "aws_s3_bucket_server_side_encryption_configuration" "ml_artifacts_encryption" {
  bucket = aws_s3_bucket.ml_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ml_data_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ml_artifacts_pab" {
  bucket = aws_s3_bucket.ml_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EFS for shared model storage
resource "aws_efs_file_system" "ml_shared_storage" {
  creation_token = "ml-shared-storage"
  encrypted      = true
  kms_key_id     = aws_kms_key.ml_data_key.arn

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Environment = "production"
    Purpose     = "ML-SharedStorage"
    Workload    = "AI-DL"
  }
}

resource "aws_efs_mount_target" "ml_shared_storage_mt_1" {
  file_system_id  = aws_efs_file_system.ml_shared_storage.id
  subnet_id       = aws_subnet.private_data_subnet_1.id
  security_groups = [aws_security_group.data_storage_sg.id]
}

resource "aws_efs_mount_target" "ml_shared_storage_mt_2" {
  file_system_id  = aws_efs_file_system.ml_shared_storage.id
  subnet_id       = aws_subnet.private_data_subnet_2.id
  security_groups = [aws_security_group.data_storage_sg.id]
}

# GPU EC2 instance for deep learning training
resource "aws_instance" "ml_gpu_instance" {
  ami           = "ami-0c02fb55d7179e87b"
  instance_type = "p3.2xlarge"
  subnet_id     = aws_subnet.private_ml_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ml_training_sg.id]

  tags = {
    Environment = "production"
    Purpose     = "ML-Training"
    Workload    = "AI-DL"
    GPU         = "V100"
  }

  root_block_device {
    volume_size = 500
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = aws_kms_key.ml_data_key.arn
  }
}

# SageMaker Notebook Instance for ML development
resource "aws_sagemaker_notebook_instance" "ml_notebook" {
  name          = "ml-development-notebook"
  role_arn      = "arn:aws:iam::123456789012:role/service-role/AmazonSageMaker-ExecutionRole"
  instance_type = "ml.t3.xlarge"
  subnet_id     = aws_subnet.private_ml_subnet_1.id
  security_groups = [aws_security_group.sagemaker_endpoint_sg.id]
  kms_key_id      = aws_kms_key.ml_data_key.id

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

  vpc_config {
    subnets            = [aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id]
    security_group_ids = [aws_security_group.sagemaker_endpoint_sg.id]
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
  instance_type = "p4d.24xlarge"
  subnet_id     = element([aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id], count.index)
  vpc_security_group_ids = [aws_security_group.ml_training_sg.id]

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
    encrypted   = true
    kms_key_id  = aws_kms_key.ml_data_key.arn
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 5000
    volume_type = "gp3"
    iops        = 16000
    throughput  = 1000
    encrypted   = true
    kms_key_id  = aws_kms_key.ml_data_key.arn
  }
}

# Additional P3 instances for medium-scale training
resource "aws_instance" "ml_gpu_medium" {
  count         = 12
  ami           = "ami-0c02fb55d7179e87b"
  instance_type = "p3.8xlarge"
  subnet_id     = element([aws_subnet.private_ml_subnet_1.id, aws_subnet.private_ml_subnet_2.id], count.index)
  vpc_security_group_ids = [aws_security_group.ml_training_sg.id]

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
    encrypted   = true
    kms_key_id  = aws_kms_key.ml_data_key.arn
  }
}
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
