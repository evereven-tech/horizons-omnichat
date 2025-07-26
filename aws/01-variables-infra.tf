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

#
# Persistence
# #############################################################################

variable "efs_models_throughput" {
  description = "Throughput in MiB/s for EFS models volume"
  type        = number
  default     = 100
}

#
# Network Optimization
# #############################################################################

variable "nat_gateway_config" {
  description = "NAT Gateway configuration"
  type = object({
    enabled    = bool
    single_nat = bool # true = single NAT, false = one per AZ
  })
  default = {
    enabled    = true
    single_nat = true # Default to cost-optimized single NAT
  }
}

variable "vpc_endpoints_enabled" {
  description = "Whether to create VPC endpoints for private communication"
  type        = bool
  default     = false # Default to minimal setup
}

#
# GPU EC2 Spot based
# #############################################################################

variable "enable_gpu" {
  description = "Whether to provision GPU-enabled EC2 instances for Ollama"
  type        = bool
}

variable "gpu_config" {
  description = "GPU configuration for Ollama instances"
  type = object({
    instance_types = list(string)
    min_gpus       = number
    max_gpus       = number
  })
  default = {
    instance_types = ["g4dn.xlarge", "g5.xlarge", "p3.2xlarge"]
    min_gpus       = 1
    max_gpus       = 4
  }
}

variable "spot_config" {
  description = "Spot configuration for GPU instances"
  type = object({
    interruption_behavior = string
    allocation_strategy   = string
  })
  default = {
    interruption_behavior = "terminate"
    allocation_strategy   = "lowest-price"
  }
}
