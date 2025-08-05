provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

terraform {
  required_version = "~> 1.10.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }

  backend "s3" {}
}
