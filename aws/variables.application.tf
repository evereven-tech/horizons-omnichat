#
# Container setup
# #############################################################################

variable "webui_secret_key" {
  description = "Secret key for OpenWebUI"
  type        = string
  sensitive   = true
}

variable "bedrock_api_key" {
  description = "API Key for Bedrock Gateway"
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
# Open WebUI | Config.json
# Inserted on first run by command order
# #############################################################################

variable "webui_user_permissions" {
  description = "User permissions configuration for WebUI"
  type = object({
    workspace = object({
      models    = bool
      knowledge = bool
      prompts   = bool
      tools     = bool
    })
    chat = object({
      controls    = bool
      file_upload = bool
      delete      = bool
      edit        = bool
      temporary   = bool
    })
    features = object({
      web_search       = bool
      image_generation = bool
      code_interpreter = bool
    })
  })
  default = {
    workspace = {
      models    = true
      knowledge = true
      prompts   = true
      tools     = true
    }
    chat = {
      controls    = true
      file_upload = true
      delete      = true
      edit        = true
      temporary   = true
    }
    features = {
      web_search       = true
      image_generation = true
      code_interpreter = true
    }
  }
}

variable "webui_auth_config" {
  description = "Authentication configuration for WebUI"
  type = object({
    admin = object({
      show = bool
    })
    api_key = object({
      enable                = bool
      endpoint_restrictions = bool
      allowed_endpoints     = string
    })
    jwt_expiry = string
  })
  default = {
    admin = {
      show = true
    }
    api_key = {
      enable                = true
      endpoint_restrictions = false
      allowed_endpoints     = ""
    }
    jwt_expiry = "1d"
  }
}

variable "webui_ldap_enabled" {
  description = "Enable LDAP authentication"
  type        = bool
  default     = false
}

variable "webui_channels_enabled" {
  description = "Enable channels feature"
  type        = bool
  default     = false
}
