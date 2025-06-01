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

  # Generate secret key for authentication with ALB
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true

  # Explicit authentication flows
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

# Secrets Manager to store app secrets
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

    webui_secret_key     = random_password.webui_secret_key.result
    postgres_password    = random_password.postgres.result
    bedrock_api_key      = random_password.bedrock_api_key.result
    litellm_master_key   = random_password.litellm_master_key.result
    litellm_ui_password  = random_password.litellm_ui_password.result
    database_url         = "postgresql://${var.postgres_user}:${random_password.postgres.result}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"
    openai_api_keys      = "${random_password.bedrock_api_key.result};${random_password.litellm_master_key.result}"
    openai_api_base_urls = "http://${aws_service_discovery_service.bedrock.name}.${aws_service_discovery_private_dns_namespace.main.name}:80/api/v1;http://${aws_service_discovery_service.litellm.name}.${aws_service_discovery_private_dns_namespace.main.name}:4000"
  })
}

# IAM policy for managing access to secrets
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

# Attach secrets policy to the ECS execution role
resource "aws_iam_role_policy" "ecs_task_secrets" {
  name   = "${var.project_name}-config-secrets-access"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.secrets_access.json
}

#
# External API Keys Secrets
# Dynamic secrets for third-party providers
# #############################################################################

# Create individual secrets for each external API key
resource "aws_secretsmanager_secret" "external_api_keys" {
  for_each = nonsensitive(toset(keys(var.external_api_keys)))

  name        = "${var.project_name}/external-api-keys/${each.key}"
  description = "API key for ${each.key} provider"

  tags = {
    Name     = "${var.project_name}-external-api-${each.key}"
    Layer    = "Configuration"
    Provider = each.key
  }
}

resource "aws_secretsmanager_secret_version" "external_api_keys" {
  for_each = nonsensitive(toset(keys(var.external_api_keys)))

  secret_id = aws_secretsmanager_secret.external_api_keys[each.key].id
  secret_string = jsonencode({
    api_key = var.external_api_keys[each.key]
  })
}

# IAM policy for accessing external API secrets
data "aws_iam_policy_document" "external_secrets_access" {
  count = length(var.external_api_keys) > 0 ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      for secret in aws_secretsmanager_secret.external_api_keys : secret.arn
    ]
  }
}

resource "aws_iam_role_policy" "ecs_external_secrets" {
  count = length(var.external_api_keys) > 0 ? 1 : 0

  name   = "${var.project_name}-config-external-secrets-access"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.external_secrets_access[0].json
}

# Additional policy for SSM in the execution role
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

# Random secure password generator for PostgreSQL
resource "random_password" "postgres" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# Random secure password generator for Bedrock Gateway
resource "random_password" "bedrock_api_key" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# Random secure password generator for Open WebUI
resource "random_password" "webui_secret_key" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# Random secure password generator for LiteLLM Master Key
resource "random_password" "litellm_master_key" {
  length           = 32
  special          = true
  override_special = "-_"
  min_special      = 2
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# Random secure password generator for LiteLLM UI credentials
resource "random_password" "litellm_ui_password" {
  length           = 16
  special          = true
  override_special = "-_"
  min_special      = 1
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}
