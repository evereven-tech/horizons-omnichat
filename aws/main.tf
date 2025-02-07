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
