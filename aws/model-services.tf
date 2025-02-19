
#
# Ollama: Service & Task Definition
# #############################################################################

# Task Definition para Ollama
resource "aws_ecs_task_definition" "ollama" {
  family                   = "${var.project_name}-compute-ollama"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 8192
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ollama_task.arn

  volume {
    name = "models"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.models.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.models.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name       = "ollama"
      image      = "${aws_ecr_repository.ollama.repository_url}:${var.ollama_version}"
      user       = "root"
      privileged = true
      essential  = true
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
        },
        {
          name  = "NVIDIA_DRIVER_CAPABILITIES"
          value = "compute,utility"
        }
      ]

      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]

      linuxParameters = {
        devices = [
          {
            hostPath      = "/dev/nvidia0"
            containerPath = "/dev/nvidia0"
            permissions   = ["read", "write"]
          },
          {
            hostPath      = "/dev/nvidiactl"
            containerPath = "/dev/nvidiactl"
            permissions   = ["read", "write"]
          },
          {
            hostPath      = "/dev/nvidia-uvm"
            containerPath = "/dev/nvidia-uvm"
            permissions   = ["read", "write"]
          }
        ]
      }

      dockerLabels = {
        "com.nvidia.volumes.needed" = "nvidia_driver"
      }

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



      systemControls = [
        {
          namespace = "net.ipv4.tcp_keepalive_time",
          value     = "60"
        },
        {
          namespace = "net.ipv4.tcp_keepalive_intvl",
          value     = "15"
        }
      ]

      runtimePlatform = {
        operatingSystemFamily = "LINUX"
        cpuArchitecture       = "X86_64"
      }

      # Habilitar proceso init
      linuxParameters = {
        initProcessEnabled = true
        capabilities = {
          add = ["SYS_ADMIN"]
        }
      }
    }
  ])

  #runtime_platform {
  #  operating_system_family = "LINUX"
  #  cpu_architecture        = "X86_64"
  #}

  tags = {
    Name  = "${var.project_name}-compute-ollama"
    Layer = "Compute"
  }
}

# Servicio ECS para Ollama
resource "aws_ecs_service" "ollama" {
  name            = "${var.project_name}-compute-ollama"
  cluster         = aws_ecs_cluster.ec2.id
  task_definition = aws_ecs_task_definition.ollama.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ollama_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ollama.arn
  }

  enable_execute_command  = true
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  tags = {
    Name  = "${var.project_name}-compute-ollama"
    Layer = "Compute"
  }
}

#
# Ollama: Networking
# #############################################################################

# Security Group para las tareas de Ollama
resource "aws_security_group" "ollama_tasks" {
  name        = "${var.project_name}-compute-ollama-tasks"
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
    Name  = "${var.project_name}-compute-ollama-tasks"
    Layer = "Compute"
  }
}

#
# Ollama: IAM
# #############################################################################


# ECS Task Role para Ollama
resource "aws_iam_role" "ollama_task" {
  name = "${var.project_name}-security-ollama-task"

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
    Name  = "${var.project_name}-security-ollama-task"
    Layer = "Security"
  }
}

# Policy para el rol de Ollama task
resource "aws_iam_role_policy" "ollama_task" {
  name = "${var.project_name}-security-ollama-task-policy"
  role = aws_iam_role.ollama_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ollama.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:DescribeFileSystems"
        ]
        Resource = [
          aws_efs_file_system.models.arn,
          "${aws_efs_file_system.models.arn}/*"
        ]
      }
    ]
  })
}
