# User Pool
resource "aws_cognito_user_pool" "main" {
  name = "horizons-user-pool"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

# User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "horizons-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Generar secret key para la autenticación con ALB
  generate_secret = true
  allowed_oauth_flows_user_pool_client = true

  # Flujos de autenticación explícitos
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls                = ["https://${var.domain_name}/oauth2/idpresponse"]
  logout_urls                  = ["https://${var.domain_name}"]
  allowed_oauth_flows          = ["code"]
  allowed_oauth_scopes         = ["openid", "email", "profile"]
  supported_identity_providers = ["COGNITO"]

  refresh_token_validity = 30
  access_token_validity  = 8
  id_token_validity     = 8

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}
