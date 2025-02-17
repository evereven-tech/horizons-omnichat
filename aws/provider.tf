provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = var.project_name
      License    = "MIT"
      ManagedBy  = "terraform"
      Support    = "horizons@evereven.tech"
      Brand      = "evereven.tech"
      Repository = "evereven-tech/horizons-ommnichat"
      Namespace  = "evereven"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

