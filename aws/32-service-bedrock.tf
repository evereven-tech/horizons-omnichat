
#
# Bedrock Gateway: Service & Task Definition
# #############################################################################

# Task Definition para Bedrock Gateway
resource "aws_ecs_task_definition" "bedrock" {
  family                   = "${var.project_name}-compute-bedrock"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.bedrock_task.arn

  container_definitions = jsonencode([
    {
      name  = "bedrock-gateway"
      image = "${aws_ecr_repository.bedrock_gateway.repository_url}:${var.bedrock_version}"
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region_bedrock
        }
      ]
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:bedrock_api_key::"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import http.client; conn = http.client.HTTPConnection('localhost', 80); conn.request('GET', '/health'); response = conn.getresponse(); exit(0 if response.status == 200 else 1)\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bedrock.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "bedrock"
        }
      }
    }
  ])

  tags = {
    Name  = "${var.project_name}-compute-bedrock"
    Layer = "Compute"
  }
}

# Servicio ECS para Bedrock Gateway
resource "aws_ecs_service" "bedrock" {
  name            = "${var.project_name}-compute-bedrock"
  cluster         = aws_ecs_cluster.fargate.id
  task_definition = aws_ecs_task_definition.bedrock.arn
  desired_count   = var.bedrock_desired_count

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.bedrock_tasks.id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  service_registries {
    registry_arn = aws_service_discovery_service.bedrock.arn
  }

  enable_execute_command = true

  tags = {
    Name  = "${var.project_name}-compute-bedrock"
    Layer = "Compute"
  }
}

#
# Bedrock Gateway: Networking
# #############################################################################

# Security Group para Bedrock Gateway
resource "aws_security_group" "bedrock_tasks" {
  name        = "${var.project_name}-compute-bedrock-tasks"
  description = "Allow inbound traffic from WebUI to Bedrock Gateway"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.project_name}-compute-bedrock-tasks"
    Layer = "Compute"
  }
}

#
# Bedrock Gateway: IAM
# #############################################################################


# ECS Task Role for Bedrock Gateway
resource "aws_iam_role" "bedrock_task" {
  name = "${var.project_name}-security-bedrock-task"

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
    Name  = "${var.project_name}-security-bedrock-task"
    Layer = "Security"
  }
}

# SSM Policy for ECS Exec
resource "aws_iam_role_policy" "ecs_exec" {
  name = "${var.project_name}-security-ecs-exec"
  role = aws_iam_role.bedrock_task.id

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

# Policy for Bedrock Gateway task role
resource "aws_iam_role_policy" "bedrock_task" {
  name = "${var.project_name}-security-bedrock-task-policy"
  role = aws_iam_role.bedrock_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.bedrock.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels",
          "bedrock:ListInferenceProfiles"
        ]
        Resource = "*"
      }
    ]
  })
}
