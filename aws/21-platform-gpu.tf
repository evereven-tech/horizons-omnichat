#
# Container Orchestration
# #############################################################################

# Cluster ECS para Ollama (EC2)
resource "aws_ecs_cluster" "ec2" {
  name = "${var.project_name}-compute-ec2"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name  = "${var.project_name}-compute-ec2"
    Layer = "Compute"
  }
}

# Añadir la capacidad del cluster EC2
resource "aws_ecs_cluster_capacity_providers" "ec2" {
  cluster_name = aws_ecs_cluster.ec2.name

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
}

# Capacity Provider para EC2
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.project_name}-compute-ec2"

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
    Name  = "${var.project_name}-compute-ec2"
    Layer = "Compute"
  }
}

#
# Resilience
# #############################################################################

# Auto Scaling Group para Ollama
resource "aws_autoscaling_group" "ollama" {
  name                = "${var.project_name}-compute-ollama"
  desired_capacity    = var.ollama_desired_count
  max_size            = var.ollama_max_count
  min_size            = 1 # Garantizamos mínimo 1 instancia
  target_group_arns   = [aws_lb_target_group.ollama.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 1 # Garantizamos 1 instancia on-demand
      on_demand_percentage_above_base_capacity = 0 # El resto en spot
      spot_allocation_strategy                 = "capacity-optimized"
      spot_max_price                           = var.spot_config.spot_price["g4dn.xlarge"]
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ollama.id
        version            = "$Latest"
      }

      override {
        instance_type = "g4dn.xlarge"
      }
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-compute-ollama"
    propagate_at_launch = true
  }

  tag {
    key                 = "Layer"
    value               = "Compute"
    propagate_at_launch = true
  }

  # Importante para la integración con ECS
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  # No proteger contra scale-in para permitir reemplazo de instancias spot
  protect_from_scale_in = false

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template para instancias GPU
resource "aws_launch_template" "ollama" {
  name = "${var.project_name}-compute-ollama"

  #image_id      = "ami-0dc6fd3fcf713ce9d" # AMI con drivers y software preinstalado
  image_id      = data.aws_ami.ecs_ami.id # Update this with the latest ECS-optimized AMI ID for your region
  instance_type = "g4dn.xlarge"           # Instancia con GPU NVIDIA T4

  update_default_version = true

  # Metadata options recomendadas
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # User data para instalar el agente ECS y configurar Docker
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.ec2.name} >> /etc/ecs/ecs.config
              echo ECS_ENABLE_GPU_SUPPORT=true >> /etc/ecs/ecs.config
              EOF
  )

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ollama.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ollama.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name             = "${var.project_name}-compute-ollama"
      Layer            = "Compute"
      AmazonECSManaged = "true"
    }
  }
}

# Scheduled scaling para horario laboral (L-V, 9-19)
resource "aws_autoscaling_schedule" "scale_up_workday" {
  scheduled_action_name  = "${var.project_name}-compute-scale-up-workday"
  min_size               = var.ollama_min_count
  max_size               = var.ollama_max_count
  desired_capacity       = var.ollama_desired_count
  recurrence             = "0 9 * * mon-fri" # 9:00 AM, Lunes a Viernes
  time_zone              = "Europe/Madrid"   # Zona horaria de España
  autoscaling_group_name = aws_autoscaling_group.ollama.name
}

resource "aws_autoscaling_schedule" "scale_down_workday" {
  scheduled_action_name  = "${var.project_name}-compute-scale-down-workday"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * mon-fri" # 19:00 PM, Lunes a Viernes
  time_zone              = "Europe/Madrid"    # Zona horaria de España
  autoscaling_group_name = aws_autoscaling_group.ollama.name
}

#
# Networking
# #############################################################################

# Security Group para Ollama
resource "aws_security_group" "ollama" {
  name        = "${var.project_name}-compute-ollama"
  description = "Security group for Ollama instances"
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
    Name  = "${var.project_name}-compute-ollama"
    Layer = "Compute"
  }
}

#
# IAM
# #############################################################################

# IAM Role para las instancias EC2 de Ollama
resource "aws_iam_role" "ollama_instance" {
  name = "${var.project_name}-security-ollama-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name  = "${var.project_name}-security-ollama-instance"
    Layer = "Security"
  }
}

# Instance Profile para las instancias EC2 de Ollama
resource "aws_iam_instance_profile" "ollama" {
  name = "${var.project_name}-security-ollama"
  role = aws_iam_role.ollama_instance.name
}

# Política básica para las instancias EC2 de Ollama
resource "aws_iam_role_policy" "ollama_instance" {
  name = "${var.project_name}-security-ollama-instance-policy"
  role = aws_iam_role.ollama_instance.id

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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance",
          "ecs:UpdateContainerInstancesState",
          "ecs:DiscoverPollEndpoint",
          "ecs:Submit*",
          "ecs:Poll",
          "ecs:StartTelemetrySession",
          "ecs:TagResource",
          "ecs:UntagResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:UpdateInstanceInformation",
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
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.ollama_task.arn,
          aws_iam_role.ecs_task_execution.arn
        ]
      }
    ]
  })
}

# Política administrada de SSM para la instancia
resource "aws_iam_role_policy_attachment" "ollama_instance_ssm" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Política administrada de CloudWatch para la instancia
resource "aws_iam_role_policy_attachment" "ollama_instance_cloudwatch" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Política para ECS
resource "aws_iam_role_policy_attachment" "ollama_instance_ecs" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
} # Política para manejo de ENIs para Ollama

resource "aws_iam_role_policy_attachment" "ecs_instance_eni" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
