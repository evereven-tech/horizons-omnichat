# Cluster para OpenWebUI con Fargate Spot
resource "aws_ecs_cluster" "fargate" {
  name = "${var.project_name}-${var.environment}-fargate"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-fargate"
    Environment = var.environment
  }
}

# Capacity Provider para Fargate Spot
resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.fargate.name

  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}

# Task Definition para OpenWebUI
resource "aws_ecs_task_definition" "webui" {
  family                   = "${var.project_name}-${var.environment}-webui"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.webui_task.arn

  container_definitions = jsonencode([
    {
      name  = "webui"
      image = "ghcr.io/open-webui/open-webui:${var.webui_version}"
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "WEBUI_SECRET_KEY"
          value = var.webui_secret_key
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.postgres_user}:${var.postgres_password}@${aws_db_instance.webui.endpoint}/${var.postgres_db}"
        },
        {
          name  = "OPENAI_API_BASE"
          value = "http://bedrock-gateway.${var.project_name}-${var.environment}:80/api/v1"
        },
        {
          name  = "OPENAI_API_KEY"
          value = var.bedrock_api_key
        }
      ]
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
    Name        = "${var.project_name}-${var.environment}-webui"
    Environment = var.environment
  }
}

# Servicio ECS para OpenWebUI
resource "aws_ecs_service" "webui" {
  name            = "${var.project_name}-${var.environment}-webui"
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
    Name        = "${var.project_name}-${var.environment}-webui"
    Environment = var.environment
  }
}

# Security Group para las tareas ECS
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks"
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
    Name        = "${var.project_name}-${var.environment}-ecs-tasks"
    Environment = var.environment
  }
}

# Task Definition para Bedrock Gateway
resource "aws_ecs_task_definition" "bedrock" {
  family                   = "${var.project_name}-${var.environment}-bedrock"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.bedrock_task.arn

  container_definitions = jsonencode([
    {
      name                 = "bedrock-gateway"
      image                = var.bedrock_image
      enableExecuteCommand = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_KEY"
          value = var.bedrock_api_key
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]
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
    Name        = "${var.project_name}-${var.environment}-bedrock"
    Environment = var.environment
  }
}

# Servicio ECS para Bedrock Gateway
resource "aws_ecs_service" "bedrock" {
  name            = "${var.project_name}-${var.environment}-bedrock"
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
    Name        = "${var.project_name}-${var.environment}-bedrock"
    Environment = var.environment
  }
}

# Security Group para Bedrock Gateway
resource "aws_security_group" "bedrock_tasks" {
  name        = "${var.project_name}-${var.environment}-bedrock-tasks"
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
    Name        = "${var.project_name}-${var.environment}-bedrock-tasks"
    Environment = var.environment
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}-${var.environment}.local"
  vpc         = aws_vpc.main.id
  description = "Service Discovery namespace for ${var.project_name}-${var.environment}"
}

# Service Discovery Service para OpenWebUI
resource "aws_service_discovery_service" "webui" {
  name = "webui"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service Discovery Service para Bedrock Gateway
resource "aws_service_discovery_service" "bedrock" {
  name = "bedrock-gateway"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
