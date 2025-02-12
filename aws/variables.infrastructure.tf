#
# Naming & global
# #############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "aws_region_bedrock" {
  description = "AWS region for Bedrock"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "horizons"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

#
# Network
# #############################################################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

#
# Delivery & DNS
# #############################################################################

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Prefix for Cognito domain"
  type        = string
}

#
# ECS & Containers
# #############################################################################

variable "webui_desired_count" {
  description = "Desired number of OpenWebUI tasks"
  type        = number
  default     = 1
}

variable "bedrock_desired_count" {
  description = "Desired number of Bedrock Gateway tasks"
  type        = number
  default     = 1
}

variable "ollama_desired_count" {
  description = "Desired number of Ollama instances"
  type        = number
  default     = 1
}

variable "ollama_max_count" {
  description = "Maximum number of Ollama instances"
  type        = number
  default     = 1
}

variable "ollama_min_count" {
  description = "Minimum number of Ollama instances"
  type        = number
  default     = 0
}

variable "bedrock_image" {
  description = "ECR URI to Bedrock Gateway Image"
  type        = string
  default     = "533267020467.dkr.ecr.eu-west-1.amazonaws.com/horizons-bedrock-gateway:latest"
}

#
# Persistence
# #############################################################################

variable "efs_models_throughput" {
  description = "Throughput in MiB/s for EFS models volume"
  type        = number
  default     = 100
}

#
# GPU EC2 Spot based
# #############################################################################

variable "ollama_instance_type" {
  description = "Instance type for Ollama"
  type        = string
  default     = "g4ad.xlarge"
}

variable "ollama_ami_id" {
  description = "AMI ID for Ollama instances"
  type        = string
  default     = "ami-0dc6fd3fcf713ce9d"
}
