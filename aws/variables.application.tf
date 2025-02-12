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

variable "bedrock_api_key" {
  description = "API Key for Bedrock Gateway"
  type        = string
  sensitive   = true
}

variable "bedrock_image" {
  description = "ECR URI to Bedrock Gateway Image"
  type        = string
  default     = "533267020467.dkr.ecr.eu-west-1.amazonaws.com/horizons-bedrock-gateway:latest"
}

variable "bedrock_desired_count" {
  description = "Desired number of Bedrock Gateway tasks"
  type        = number
  default     = 1
}

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
