#
# Open WebUI: Service & Task Definition
# #############################################################################

# Task Definition para OpenWebUI
resource "aws_ecs_task_definition" "webui" {
  family                   = "${var.project_name}-compute-webui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.webui_task.arn

  container_definitions = jsonencode([
    {
      name  = "webui"
      image = "${aws_ecr_repository.webui.repository_url}:${var.webui_version}"
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        },
        {
          name  = "BYPASS_MODEL_ACCESS_CONTROL"
          value = "True"
        },
        {
          "name" : "OPENAI_API_BASE_URL",
          "value" : "http://${aws_service_discovery_service.bedrock.name}.${aws_service_discovery_private_dns_namespace.main.name}:80/api/v1"
        },
        {
          "name" : "OLLAMA_BASE_URL",
          "value" : "http://${aws_service_discovery_service.ollama.name}.${aws_service_discovery_private_dns_namespace.main.name}:11434"
        }
      ]

      secrets = [
        {
          name      = "WEBUI_SECRET_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:webui_secret_key::"
        },
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:bedrock_api_key::"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:database_url::"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "nc -z localhost 8080 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.webui.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "webui"
        }
      }
    }
  ])

  tags = {
    Name  = "${var.project_name}-compute-webui"
    Layer = "Compute"
  }
}

# Servicio ECS para OpenWebUI
resource "aws_ecs_service" "webui" {
  name            = "${var.project_name}-compute-webui"
  cluster         = aws_ecs_cluster.fargate.id
  task_definition = aws_ecs_task_definition.webui.arn
  desired_count   = var.webui_desired_count

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.webui.arn
    container_name   = "webui"
    container_port   = 8080
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  service_registries {
    registry_arn = aws_service_discovery_service.webui.arn
  }

  enable_execute_command = true

  tags = {
    Name  = "${var.project_name}-compute-webui"
    Layer = "Compute"
  }
}

#
# Open WebUI: Networking
# #############################################################################

# Security Group para las tareas ECS
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-compute-ecs-tasks"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-compute-ecs-tasks"

  }
}

#
# Open WebUI: IAM
# #############################################################################

# ECS Task Role for OpenWebUI
resource "aws_iam_role" "webui_task" {
  name = "${var.project_name}-security-webui-task"

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
    Name  = "${var.project_name}-security-webui-task"
    Layer = "Security"
  }
}

# SSM Policy for WebUI ECS Exec
resource "aws_iam_role_policy" "webui_ecs_exec" {
  name = "${var.project_name}-security-webui-ecs-exec"
  role = aws_iam_role.webui_task.id

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

# Policy for OpenWebUI task role
resource "aws_iam_role_policy" "webui_task" {
  name = "${var.project_name}-security-webui-task-policy"
  role = aws_iam_role.webui_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.webui.arn}:*"
      }
    ]
  })
}
