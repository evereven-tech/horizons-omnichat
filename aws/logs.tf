# CloudWatch Log Group para Bedrock Gateway
resource "aws_cloudwatch_log_group" "bedrock" {
  name              = "/ecs/${var.project_name}/bedrock"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-bedrock-logs"
    Layer = "Monitoring"
  }
}

# CloudWatch Log Group para WebUI
resource "aws_cloudwatch_log_group" "webui" {
  name              = "/ecs/${var.project_name}/webui"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-webui-logs"
    Layer = "Monitoring"
  }
}

# CloudWatch Log Group para Ollama
resource "aws_cloudwatch_log_group" "ollama" {
  name              = "/ecs/${var.project_name}/ollama"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-ollama-logs"
    Layer = "Monitoring"
  }
}

