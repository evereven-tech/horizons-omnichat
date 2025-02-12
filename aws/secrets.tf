# Secrets Manager para secretos de la aplicación
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.project_name}/${var.environment}/app-secrets"
  description = "Application secrets for ${var.project_name} ${var.environment}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-secrets"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    webui_secret_key  = var.webui_secret_key
    postgres_password = var.postgres_password
    bedrock_api_key   = var.bedrock_api_key
    database_url      = "postgresql://${var.postgres_user}:${var.postgres_password}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"

    # TODO 1 // Unleash to generate randp
    # TODO 2 // Remove from tfvars & tfavars.example

    #webui_secret_key  = random_password.webui_secret_key.result
    #postgres_password = random_password.postgres.result                                                                                                                                      
    #bedrock_api_key   = random_password.bedrock_api_key.result
    #database_url      = "postgresql://${var.postgres_user}:${random_password.postgres.result}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"
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
  name   = "${var.project_name}-${var.environment}-secrets-access"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.secrets_access.json
}

# Generador de contraseña segura para PostgreSQL                                                                                                                                             
resource "random_password" "postgres_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_special      = 2
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}

# Generador de contraseña segura para Bedrock Gateway                                                                                                                                             
resource "random_password" "bedrock_api_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_special      = 2
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}

# Generador de contraseña segura para Open WebUI                                                                                                                                        
resource "random_password" "webui_secret_key" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_special      = 2
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}
