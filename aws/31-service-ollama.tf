
#
# Ollama: Service & Task Definition
# #############################################################################

# Task Definition for Ollama
resource "aws_ecs_task_definition" "ollama" {

  count = local.gpu_enabled_flap

  family                   = "${var.project_name}-compute-ollama"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 8192
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = local.iam_role_ollama_task_arn

  volume {
    name                = "models"
    configure_at_launch = false

    efs_volume_configuration {
      file_system_id     = local.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = local.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name       = "ollama"
      image      = "${local.ecr_repository_ollama_url}:${var.ollama_version}"
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

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:11434/api/tags || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 90 # Models may take time to load
      }

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
        initProcessEnabled = true
        capabilities = {
          add  = ["SYS_ADMIN"]
          drop = []
        }
      }

      dockerLabels = {
        "com.nvidia.volumes.needed" = "nvidia_driver"
      }

      volumesFrom = []
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
          "awslogs-group"         = "/ecs/${var.project_name}/ollama"
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
    }
  ])

  tags = {
    Name  = "${var.project_name}-compute-ollama"
    Layer = "Compute"
  }
}

# ECS Service for Ollama
resource "aws_ecs_service" "ollama" {

  count = local.gpu_enabled_flap

  name            = "${var.project_name}-compute-ollama"
  cluster         = local.ecs_cluster_ec2_id
  task_definition = local.ecs_task_definition_ollama_arn

  desired_count = 1
  launch_type   = "EC2"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [local.security_group_ollama_tasks_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = local.service_discovery_ollama_arn
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

# Security Group for Ollama's tasks
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "ollama_tasks" {

  count = local.gpu_enabled_flap

  name        = "${var.project_name}-compute-ollama-tasks"
  description = "Allow inbound traffic to Ollama tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 11434
    to_port         = 11434
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
    Name  = "${var.project_name}-compute-ollama-tasks"
    Layer = "Compute"
  }
}

#
# Ollama: IAM
# #############################################################################


# ECS Task Role for Ollama
resource "aws_iam_role" "ollama_task" {

  count = local.gpu_enabled_flap

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

# Policy for the role of Ollama task
resource "aws_iam_role_policy" "ollama_task" {

  count = local.gpu_enabled_flap

  name = "${var.project_name}-security-ollama-task-policy"
  role = local.iam_role_ollama_task_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${local.cloudwatch_log_group_ollama_arn}:*"
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
          local.efs_file_system_arn,
          "${local.efs_file_system_arn}/*"
        ]
      }
    ]
  })
}
