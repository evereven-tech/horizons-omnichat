#
# EFS
# #############################################################################

# EFS File System
resource "aws_efs_file_system" "models" {

  count = local.gpu_enabled_flap

  creation_token = "${var.project_name}-storage-models"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name  = "${var.project_name}-storage-models"
    Layer = "Storage"
  }
}

# Mount targets on each private subnet
resource "aws_efs_mount_target" "models" {

  count = var.enable_gpu ? length(var.private_subnets) : 0

  file_system_id  = local.efs_file_system_id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [local.security_group_efs_id]
}

# Access Point for models
resource "aws_efs_access_point" "models" {

  count = local.gpu_enabled_flap

  file_system_id = local.efs_file_system_id

  posix_user {
    gid = 0 # root group
    uid = 0 # root user
  }

  root_directory {
    path = "/models"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "0755"
    }
  }

  tags = {
    Name  = "${var.project_name}-storage-models"
    Layer = "Storage"
  }
}

# Security Group for EFS
resource "aws_security_group" "efs" {

  count = local.gpu_enabled_flap

  name        = "${var.project_name}-storage-efs"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [local.security_group_ollama_tasks_id]
    description     = "Allow access to EFS"
  }

  tags = {
    Name  = "${var.project_name}-storage-efs"
    Layer = "Storage"
  }
}

#
# ECR
# #############################################################################

# Define a venue for the common life-cycle policy
locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository for OpenWebUI
resource "aws_ecr_repository" "webui" {
  name                 = "${var.project_name}-webui"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name  = "${var.project_name}-webui"
    Layer = "Storage"
  }
}

# Lifecycle Policy for OpenWebUI
resource "aws_ecr_lifecycle_policy" "webui" {
  repository = aws_ecr_repository.webui.name
  policy     = local.ecr_lifecycle_policy
}

# ECR Repository for Bedrock Gateway
resource "aws_ecr_repository" "bedrock_gateway" {
  name                 = "${var.project_name}-bedrock-gateway"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name  = "${var.project_name}-bedrock-gateway"
    Layer = "Storage"
  }
}

# Lifecycle Policy for Bedrock Gateway
resource "aws_ecr_lifecycle_policy" "bedrock_gateway" {
  repository = aws_ecr_repository.bedrock_gateway.name
  policy     = local.ecr_lifecycle_policy
}

# ECR Repository for Ollama
resource "aws_ecr_repository" "ollama" {

  count = local.gpu_enabled_flap

  name                 = "${var.project_name}-ollama"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name  = "${var.project_name}-ollama"
    Layer = "Storage"
  }
}

# Life Cycle Policy for Ollama
resource "aws_ecr_lifecycle_policy" "ollama" {

  count = local.gpu_enabled_flap

  repository = local.ecr_repository_ollama_name
  policy     = local.ecr_lifecycle_policy
}
