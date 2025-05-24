#
# Container Orchestration
# #############################################################################

# ECS Cluster for OpenWebUI & Bedrock Gateway
resource "aws_ecs_cluster" "fargate" {
  name = "${var.project_name}-compute-fargate"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name  = "${var.project_name}-compute-fargate"
    Layer = "Compute"
  }
}

# Capacity Provider for cluster using Fargate Spot
resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.fargate.name

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}

#
# IAM
# #############################################################################

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-security-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name  = "${var.project_name}-security-ecs-execution"
    Layer = "Security"
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add Cloudwatch logs permissions to execution role
resource "aws_iam_role_policy" "ecs_task_execution_logs" {
  name = "${var.project_name}-security-ecs-execution-logs"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = compact([
          "${aws_cloudwatch_log_group.bedrock.arn}:*",
          "${aws_cloudwatch_log_group.webui.arn}:*",
          local.cloudwatch_log_group_ollama_arn != null ? "${local.cloudwatch_log_group_ollama_arn}:*" : null
        ])
      }
    ]
  })
}
