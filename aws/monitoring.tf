# CloudWatch Dashboard para Ollama
resource "aws_cloudwatch_dashboard" "ollama" {
  dashboard_name = "${var.project_name}-${var.environment}-ollama"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.ollama.name]
          ]
          period = 300
          stat   = "Average"
          title  = "Active Instances"
          region = var.aws_region
        }
      }
    ]
  })
}
