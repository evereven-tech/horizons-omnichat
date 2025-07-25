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
  default     = "main"
}

variable "bedrock_version" {
  description = "Version of Bedrock Gateway to deploy"
  type        = string
  default     = "latest"
}

variable "litellm_version" {
  description = "Version of LiteLLM to deploy"
  type        = string
  default     = "main-stable"
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

#
# External API Keys
# Dynamic configuration for third-party LLM providers
# #############################################################################

variable "external_api_keys" {
  description = "External API keys for third-party providers (OpenAI, Mistral, Anthropic, etc.)"
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for provider, key in var.external_api_keys :
      can(regex("^[a-zA-Z0-9_-]+$", provider))
    ])
    error_message = "Provider names must contain only alphanumeric characters, hyphens, and underscores."
  }
}
