provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Referencia a la tabla DynamoDB existente
data "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-locking"
}
