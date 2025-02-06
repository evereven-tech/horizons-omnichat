# User Pool
resource "aws_cognito_user_pool" "main" {
  name = "horizons-user-pool"

  # Políticas de contraseña
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Configuración de verificación
  auto_verified_attributes = ["email"]
  
  # Configuración de emails
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Verificación de cuenta Horizons"
    email_message = "Tu código de verificación es {####}"
  }

  # Configuración de UI y seguridad
  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  # Configuración de la UI de inicio de sesión
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  # Configuración de recuperación de cuenta
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

# User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name = "horizons-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Generar secret key para la autenticación con ALB
  generate_secret = true

  # Configuración básica de OAuth2
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "email", "profile"]

  # URLs de callback
  callback_urls = [
    "https://${aws_lb.main.dns_name}/oauth2/idpresponse"
  ]
  logout_urls = [
    "https://${aws_lb.main.dns_name}"
  ]

  # Configuración de tokens
  refresh_token_validity = 30
  access_token_validity = 1
  id_token_validity = 1

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Flujos de autenticación explícitos
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

