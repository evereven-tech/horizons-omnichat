variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
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

variable "certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "cognito_domain_prefix" {
  description = "Prefix for Cognito domain"
  type        = string
}

variable "webui_secret_key" {
  description = "Secret key for OpenWebUI"
  type        = string
  sensitive   = true
}

variable "webui_version" {
  description = "Version of OpenWebUI to deploy"
  type        = string
  default     = "0.5.7"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "chatbot_db"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "chatbot_user"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "webui_desired_count" {
  description = "Desired number of OpenWebUI tasks"
  type        = number
  default     = 1
}
