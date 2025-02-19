#
# Cognito
# #############################################################################

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
  generate_secret                      = true
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
  id_token_validity      = 8

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

#
# Application Secrets
# #############################################################################

# Secrets Manager para secretos de la aplicación
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.project_name}/config/app-secrets"
  description = "Application secrets for ${var.project_name} configuration"

  tags = {
    Name  = "${var.project_name}-config-app-secrets"
    Layer = "Configuration"
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({

    webui_secret_key  = random_password.webui_secret_key.result
    postgres_password = random_password.postgres.result
    bedrock_api_key   = random_password.bedrock_api_key.result
    database_url      = "postgresql://${var.postgres_user}:${random_password.postgres.result}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"
  })
}

# Política IAM para acceso a los secretos
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.app_secrets.arn
    ]
  }
}

# Adjuntar política de secretos al rol de ejecución de ECS
resource "aws_iam_role_policy" "ecs_task_secrets" {
  name   = "${var.project_name}-config-secrets-access"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.secrets_access.json
}

# Política adicional para SSM en el rol de ejecución
resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "${var.project_name}-security-ecs-execution-ssm"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}

#
# Password seeds
# #############################################################################

# Generador de contraseña segura para PostgreSQL                                                                                                                                             
resource "random_password" "postgres" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# Generador de contraseña segura para Bedrock Gateway                                                                                                                                             
resource "random_password" "bedrock_api_key" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# Generador de contraseña segura para Open WebUI                                                                                                                                        
resource "random_password" "webui_secret_key" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}
