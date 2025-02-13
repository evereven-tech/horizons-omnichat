# CloudWatch Dashboard para Horizons
resource "aws_cloudwatch_dashboard" "horizons" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-${var.environment}-ollama"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-${var.environment}-ollama"],
            ["AWS/EC2", "GPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.ollama.name],
            ["AWS/EC2", "GPUMemoryUtilization", "AutoScalingGroupName", aws_autoscaling_group.ollama.name]
          ]
          period = 300
          stat   = "Average"
          title  = "Ollama Resource Utilization"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-${var.environment}-webui"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-${var.environment}-webui"],
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", aws_lb_target_group.webui.arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", aws_lb_target_group.webui.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          title  = "WebUI Performance"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-${var.environment}-bedrock"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-${var.environment}-bedrock"],
            ["AWS/Logs", "IncomingLogEvents", "LogGroupName", aws_cloudwatch_log_group.bedrock.name]
          ]
          period = 300
          stat   = "Average"
          title  = "Bedrock Gateway Health"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ClusterName", aws_ecs_cluster.ec2.name],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.ollama.name],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.webui.id]
          ]
          period = 300
          stat   = "Average"
          title  = "System Health"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ECS", "ServiceCount", "ClusterName", aws_ecs_cluster.ec2.name]
          ]
          period = 300
          stat   = "Sum"
          title  = "Error Rates"
          region = var.aws_region
        }
      }
    ]
  })
}
