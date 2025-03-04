#
# EFS
# #############################################################################

# Security Group para EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-storage-efs"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ollama_tasks.id]
  }

  tags = {
    Name  = "${var.project_name}-storage-efs"
    Layer = "Storage"
  }
}

# EFS File System
resource "aws_efs_file_system" "models" {
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

# Mount targets en cada subnet privada
resource "aws_efs_mount_target" "models" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.models.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# Access Point para modelos
resource "aws_efs_access_point" "models" {
  file_system_id = aws_efs_file_system.models.id

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

#
# ECR
# #############################################################################

# ECR Repository para OpenWebUI
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

# Política de ciclo de vida para OpenWebUI
resource "aws_ecr_lifecycle_policy" "webui" {
  repository = aws_ecr_repository.webui.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 5 images with 'latest' tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
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
      }
    ]
  })
}

# ECR Repository para Bedrock Gateway
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

# Política de ciclo de vida para Bedrock Gateway
resource "aws_ecr_lifecycle_policy" "bedrock_gateway" {
  repository = aws_ecr_repository.bedrock_gateway.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 5 images with 'latest' tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
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
      }
    ]
  })
}

# ECR Repository para Ollama
resource "aws_ecr_repository" "ollama" {
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

# Política de ciclo de vida para Ollama
resource "aws_ecr_lifecycle_policy" "ollama" {
  repository = aws_ecr_repository.ollama.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 5 images with 'latest' tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
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
      }
    ]
  })
}
