# CloudWatch Dashboard para Ollama
resource "aws_cloudwatch_dashboard" "ollama" {
  dashboard_name = "${var.project_name}-${var.environment}-ollama"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "GPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.ollama.name],
            ["AWS/EC2", "GPUMemoryUtilization", "AutoScalingGroupName", aws_autoscaling_group.ollama.name]
          ]
          period = 300
          stat   = "Average"
          title  = "GPU Utilization"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.ollama.name]
          ]
          period = 300
          stat   = "Average"
          title  = "CPU Utilization"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", aws_autoscaling_group.ollama.name],
            ["AWS/EC2", "NetworkOut", "AutoScalingGroupName", aws_autoscaling_group.ollama.name]
          ]
          period = 300
          stat   = "Average"
          title  = "Network Traffic"
          region = var.aws_region
        }
      },
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

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "gpu_utilization_high" {
  alarm_name          = "${var.project_name}-${var.environment}-gpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "85"
  alarm_description  = "GPU utilization is too high"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ollama.name
  }
}

resource "aws_cloudwatch_metric_alarm" "gpu_memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-gpu-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GPUMemoryUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "85"
  alarm_description  = "GPU memory utilization is too high"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ollama.name
  }
}

# Auto Scaling Policies basadas en GPU
resource "aws_autoscaling_policy" "gpu_scale_up" {
  name                   = "${var.project_name}-${var.environment}-gpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.ollama.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown              = 300
}

resource "aws_cloudwatch_metric_alarm" "gpu_scale_up_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-gpu-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "Scale up when GPU utilization is high"
  alarm_actions      = [aws_autoscaling_policy.gpu_scale_up.arn]
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ollama.name
  }
}
