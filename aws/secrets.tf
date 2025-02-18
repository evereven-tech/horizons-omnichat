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

    # TODO 1 // Unleash to generate random_pwd
    # TODO 2 // Remove from tfvars & tfavars.example

    #webui_secret_key  = var.webui_secret_key
    webui_secret_key = random_password.webui_secret_key.result

    #postgres_password = var.postgres_password
    postgres_password = random_password.postgres.result

    #bedrock_api_key   = var.bedrock_api_key
    bedrock_api_key = random_password.bedrock_api_key.result

    #database_url      = "postgresql://${var.postgres_user}:${var.postgres_password}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"
    database_url = "postgresql://${var.postgres_user}:${random_password.postgres.result}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"
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
