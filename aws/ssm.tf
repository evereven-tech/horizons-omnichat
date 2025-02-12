resource "aws_ssm_parameter" "webui_config" {
  name  = "/${var.project_name}/${var.environment}/webui/config.json"
  type  = "SecureString"
  value = templatefile("${path.module}/templates/webui-config.tftpl", {
    namespace = "${var.project_name}-${var.environment}.local"
    api_key   = var.bedrock_api_key
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-webui-config"
    Environment = var.environment
  }
}
