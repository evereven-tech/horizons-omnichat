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
      version = "5.94.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }

  backend "s3" {}
}
