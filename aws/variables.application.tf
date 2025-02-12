variable "webui_secret_key" {
  description = "Secret key for OpenWebUI"
  type        = string
  sensitive   = true
}

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
