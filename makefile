# AWS Credentials
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_access_key_here
AWS_REGION=eu-west-1

# Terraform Variables
TF_VAR_environment=dev
TF_VAR_project_name=omnichatbot

# VPC Configuration
TF_VAR_vpc_cidr=10.0.0.0/16
TF_VAR_aws_region=eu-west-1

# Resource Tags
TF_VAR_tags_environment=development
TF_VAR_tags_project=omnichatbot
TF_VAR_tags_terraform=true

# ECS Configuration
TF_VAR_openwebui_container_version=0.5.7
TF_VAR_bedrock_gateway_container_version=latest
