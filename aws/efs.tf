# Security Group para EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-${var.environment}-efs"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ollama.id]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-efs"
    Environment = var.environment
  }
}

# EFS File System
resource "aws_efs_file_system" "models" {
  creation_token = "${var.project_name}-${var.environment}-models"
  encrypted      = true

  performance_mode                = "maxIO"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = var.efs_models_throughput

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-models"
    Environment = var.environment
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
    gid = 1001
    uid = 1001
  }

  root_directory {
    path = "/models"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "0755"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-models"
    Environment = var.environment
  }
}
