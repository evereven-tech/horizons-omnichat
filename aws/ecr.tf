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
    Name        = "${var.project_name}-webui"
    Environment = var.environment
  }
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
    Name        = "${var.project_name}-bedrock-gateway"
    Environment = var.environment
  }
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
    Name        = "${var.project_name}-ollama"
    Environment = var.environment
  }
}
