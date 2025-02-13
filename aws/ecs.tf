#
# Global ECS Setup 
# #############################################################################

# Cluster ECS para Ollama (EC2)
resource "aws_ecs_cluster" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2"
    Environment = var.environment
  }
}

# Añadir la capacidad del cluster EC2
resource "aws_ecs_cluster_capacity_providers" "ec2" {
  cluster_name = aws_ecs_cluster.ec2.name

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
}

# Capacity Provider para EC2
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ollama.arn

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2"
    Environment = var.environment
  }
}

#
# Ollama
# #############################################################################

# Task Definition para Ollama
resource "aws_ecs_task_definition" "ollama" {
  family                   = "${var.project_name}-${var.environment}-ollama"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ollama_task.arn

  volume {
    name = "models"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.models.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.models.id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = "ollama"
      image = "${aws_ecr_repository.ollama.repository_url}:${var.ollama_version}"
      portMappings = [
        {
          containerPort = 11434
          hostPort      = 11434
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "OLLAMA_HOST"
          value = "0.0.0.0"
        },
        {
          name  = "INSTALLED_MODELS"
          value = var.ollama_models
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "models"
          containerPath = "/root/.ollama"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ollama.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ollama"
        }
      }
      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]
      runtimePlatform = {
        operatingSystemFamily = "LINUX"
        cpuArchitecture       = "X86_64"
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ollama"
    Environment = var.environment
  }
}

# Servicio ECS para Ollama
resource "aws_ecs_service" "ollama" {
  name            = "${var.project_name}-${var.environment}-ollama"
  cluster         = aws_ecs_cluster.ec2.id
  task_definition = aws_ecs_task_definition.ollama.arn
  desired_count   = 1
  launch_type     = "EC2"

  service_registries {
    registry_arn   = aws_service_discovery_service.ollama.arn
    container_name = "ollama"
    container_port = 11434
  }

  enable_execute_command = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ollama"
    Environment = var.environment
  }
}

# Security Group para las tareas de Ollama
resource "aws_security_group" "ollama_tasks" {
  name        = "${var.project_name}-${var.environment}-ollama-tasks"
  description = "Allow inbound traffic to Ollama tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 11434
    to_port         = 11434
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
    Name        = "${var.project_name}-${var.environment}-ollama-tasks"
    Environment = var.environment
  }
}

#
# Open WebUI
# #############################################################################

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
      entryPoint = ["/bin/sh", "-c"]
      command = [
        <<-EOF
        aws ssm get-parameter \
          --name /${var.project_name}/${var.environment}/webui/config.json \
          --with-decryption \
          --region ${var.aws_region} \
          --query Parameter.Value \
          --output text > /app/backend/data/config.json && \
        /docker-entrypoint.sh
        EOF
      ]

      secrets = [
        {
          name      = "WEBUI_SECRET_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:webui_secret_key::"
        }
      ]
      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        }
      ]
      secrets = [
        {
          name      = "WEBUI_SECRET_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:webui_secret_key::"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:database_url::"
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

#
# Bedrock Gateway
# #############################################################################

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
      image                = "${aws_ecr_repository.bedrock_gateway.repository_url}:${var.bedrock_version}"
      enableExecuteCommand = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:bedrock_api_key::"
        }
      ]
      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region_bedrock
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
