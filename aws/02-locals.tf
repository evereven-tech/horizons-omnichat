# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-gpu-hvm-*-x86_64-ebs"]
  }
}

locals {
  default_tags = {
    Project    = var.project_name
    License    = "MIT"
    ManagedBy  = "terraform"
    Support    = "horizons@evereven.tech"
    Brand      = "evereven.tech"
    Repository = "evereven-tech/horizons-ommnichat"
    Namespace  = "evereven"
  }
}
