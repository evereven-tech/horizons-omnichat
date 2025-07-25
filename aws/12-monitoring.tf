#
# CloudWatch Logs
# #############################################################################

# CloudWatch Log Group for WebUI
resource "aws_cloudwatch_log_group" "webui" {
  name              = "/ecs/${var.project_name}/webui"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-webui-logs"
    Layer = "Monitoring"
  }
}

# CloudWatch Log Group for Ollama
resource "aws_cloudwatch_log_group" "ollama" {

  count = local.gpu_enabled_flap

  name              = "/ecs/${var.project_name}/ollama"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-ollama-logs"
    Layer = "Monitoring"
  }
}

# CloudWatch Log Group for Bedrock Gateway
resource "aws_cloudwatch_log_group" "bedrock" {
  name              = "/ecs/${var.project_name}/bedrock"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-bedrock-logs"
    Layer = "Monitoring"
  }
}

# CloudWatch Log Group for LiteLLM
resource "aws_cloudwatch_log_group" "litellm" {
  name              = "/ecs/${var.project_name}/litellm"
  retention_in_days = 30

  tags = {
    Name  = "${var.project_name}-monitoring-litellm-logs"
    Layer = "Monitoring"
  }
}

#
# CloudWatch Dashboard
# #############################################################################

# CloudWatch Dashboard for Horizons
resource "aws_cloudwatch_dashboard" "horizons" {
  dashboard_name = "${var.project_name}-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = concat([
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-monitoring-webui"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-monitoring-webui"]
            ], local.gpu_enabled ? [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-monitoring-ollama"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-monitoring-ollama"],
            ["AWS/EC2", "GPUUtilization", "AutoScalingGroupName", local.autoscaling_group_ollama_name],
            ["AWS/EC2", "GPUMemoryUtilization", "AutoScalingGroupName", local.autoscaling_group_ollama_name]
          ] : [])
          period = 300
          stat   = "Average"
          title  = local.gpu_enabled ? "Ollama & WebUI Resource Utilization" : "WebUI Resource Utilization"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-monitoring-webui"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-monitoring-webui"],
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
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-monitoring-bedrock"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-monitoring-bedrock"],
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
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-monitoring-litellm"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.project_name}-monitoring-litellm"],
            ["AWS/Logs", "IncomingLogEvents", "LogGroupName", aws_cloudwatch_log_group.litellm.name]
          ]
          period = 300
          stat   = "Average"
          title  = "LiteLLM Health"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = concat([
            ["AWS/ECS", "RunningTaskCount", "ClusterName", aws_ecs_cluster.fargate.name],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.webui.id]
            ], local.gpu_enabled ? [
            ["AWS/ECS", "RunningTaskCount", "ClusterName", local.ecs_cluster_ec2_name],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", local.autoscaling_group_ollama_name]
          ] : [])
          period = 300
          stat   = "Average"
          title  = "System Health"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = concat([
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ECS", "ServiceCount", "ClusterName", aws_ecs_cluster.fargate.name]
            ], local.gpu_enabled ? [
            ["AWS/ECS", "ServiceCount", "ClusterName", local.ecs_cluster_ec2_name]
          ] : [])
          period = 300
          stat   = "Sum"
          title  = "Error Rates"
          region = var.aws_region
        }
      }
    ]
  })
}
