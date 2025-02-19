#
# Container setup
# #############################################################################

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

#
# Application versions
# Obtained from AWS ECR custom repositories
# #############################################################################

variable "webui_version" {
  description = "Version of OpenWebUI to deploy"
  type        = string
  default     = "latest"
}

variable "bedrock_version" {
  description = "Version of Bedrock Gateway to deploy"
  type        = string
  default     = "latest"
}

variable "ollama_version" {
  description = "Version of Ollama to deploy"
  type        = string
  default     = "latest"
}

#
# Ollama | Model lists
# Installed on first run by script, and saved to a models volume on EFS
# #############################################################################

variable "ollama_models" {
  description = "Comma-separated list of Ollama models to install"
  type        = string
  default     = "tinyllama"
}
