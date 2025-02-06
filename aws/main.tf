terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "evereven-iac-533267020467"
    key            = "terraform/horizons/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locking"
    encrypt        = true
  }
}

# Data source para la tabla DynamoDB existente
data "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-locking"
}

# Output para verificar la tabla de locking
output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table used for Terraform state locking"
  value       = data.aws_dynamodb_table.terraform_lock.arn
}
