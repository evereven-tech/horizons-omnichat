# CloudWatch Log Group para Bedrock Gateway
resource "aws_cloudwatch_log_group" "bedrock" {
  name              = "/ecs/${var.project_name}-${var.environment}/bedrock"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-bedrock-logs"
    Environment = var.environment
  }
}

# CloudWatch Log Group para WebUI
resource "aws_cloudwatch_log_group" "webui" {
  name              = "/ecs/${var.project_name}-${var.environment}/webui"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-webui-logs"
    Environment = var.environment
  }
}

# CloudWatch Log Group para Ollama
resource "aws_cloudwatch_log_group" "ollama" {
  name              = "/ecs/${var.project_name}-${var.environment}/ollama"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-ollama-logs"
    Environment = var.environment
  }
}

