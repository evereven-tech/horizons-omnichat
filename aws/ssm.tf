resource "aws_ssm_parameter" "webui_config" {
  name = "/${var.project_name}/configuration/webui/config.json"
  type = "SecureString"
  value = templatefile("${path.module}/templates/webui-config.tftpl", {
    namespace        = "${var.project_name}-configuration.local"
    api_key          = random_password.webui_secret_key.result
    domain_name      = var.domain_name
    user_permissions = var.webui_user_permissions
    auth_config      = var.webui_auth_config
    ldap_enabled     = var.webui_ldap_enabled
    channels_enabled = var.webui_channels_enabled
  })

  tags = {
    Name  = "${var.project_name}-configuration-webui-config"
    Layer = "Configuration"
  }
}
