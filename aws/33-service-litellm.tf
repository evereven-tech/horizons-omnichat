#
# LiteLLM: Service & Task Definition
# #############################################################################

# Task Definition for LiteLLM
resource "aws_ecs_task_definition" "litellm" {
  family                   = "${var.project_name}-compute-litellm"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.litellm_task.arn

  container_definitions = jsonencode([
    {
      name  = "litellm-proxy"
      image = "${aws_ecr_repository.litellm.repository_url}:${var.litellm_version}"
      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        }
      ]

      #command = ["--config", "/app/config.yaml", "--port", "4000", "--num_workers", "2"]
      command = ["--port", "4000", "--num_workers", "2"]

      environment = [
        {
          name  = "STORE_MODEL_IN_DB"
          value = "True"
        },
        {
          name  = "UI_USERNAME"
          value = "admin"
        }
      ]

      secrets = concat([
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:database_url::"
        },
        {
          name      = "UI_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:litellm_ui_password::"
        },
        {
          name      = "LITELLM_MASTER_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:litellm_master_key::"
        }
      ], local.external_api_secrets)

      healthCheck = {
        command     = ["CMD", "wget", "-q", "-O", "/dev/null", "http://localhost:4000/health/liveness"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.litellm.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "litellm"
        }
      }
    }
  ])

  tags = {
    Name  = "${var.project_name}-compute-litellm"
    Layer = "Compute"
  }
}

# ECS Service for LiteLLM
resource "aws_ecs_service" "litellm" {
  name            = "${var.project_name}-compute-litellm"
  cluster         = aws_ecs_cluster.fargate.id
  task_definition = aws_ecs_task_definition.litellm.arn
  desired_count   = var.litellm_desired_count

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.litellm_tasks.id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  service_registries {
    registry_arn = aws_service_discovery_service.litellm.arn
  }

  enable_execute_command = true

  tags = {
    Name  = "${var.project_name}-compute-litellm"
    Layer = "Compute"
  }
}

#
# LiteLLM: Networking
# #############################################################################

# Security Group for LiteLLM
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "litellm_tasks" {
  name        = "${var.project_name}-compute-litellm-tasks"
  description = "Allow inbound traffic from WebUI to LiteLLM"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "Allow access to API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic"
  }

  tags = {
    Name  = "${var.project_name}-compute-litellm-tasks"
    Layer = "Compute"
  }
}

#
# LiteLLM: IAM
# #############################################################################

# ECS Task Role for LiteLLM
resource "aws_iam_role" "litellm_task" {
  name = "${var.project_name}-security-litellm-task"

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
    Name  = "${var.project_name}-security-litellm-task"
    Layer = "Security"
  }
}

# SSM Policy for LiteLLM ECS Exec
resource "aws_iam_role_policy" "litellm_ecs_exec" {
  name = "${var.project_name}-security-litellm-ecs-exec"
  role = aws_iam_role.litellm_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for LiteLLM task role
resource "aws_iam_role_policy" "litellm_task" {
  name = "${var.project_name}-security-litellm-task-policy"
  role = aws_iam_role.litellm_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.litellm.arn}:*"
      }
    ]
  })
}
