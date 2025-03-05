#
# Container Orchestration
# #############################################################################

# ECS Cluster for Ollama
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

# Capacity Provider for cluster using EC2 (ASG+Spot)
resource "aws_ecs_cluster_capacity_providers" "ec2" {
  cluster_name = aws_ecs_cluster.ec2.name

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
}

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

# Auto Scaling Group for Ollama
resource "aws_autoscaling_group" "ollama" {
  name                = "${var.project_name}-compute-ollama"
  desired_capacity    = var.ollama_desired_count
  max_size            = var.ollama_max_count
  min_size            = var.ollama_min_count
  target_group_arns   = [aws_lb_target_group.ollama.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0 # Use only Spot instances
      on_demand_percentage_above_base_capacity = 0 # 0% on-demand over the base capacity
      spot_allocation_strategy                 = var.spot_config.allocation_strategy
      spot_instance_pools                      = 3 # Number of spot pools to consider
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ollama.id
        version            = "$Latest"
      }

      # Iterator to add all types of instances with their priorities
      dynamic "override" {
        for_each = var.gpu_config.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
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

  # Tag Important and required for integration with ECS
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  # Do not protect against scale-in to allow replacement of spot instances
  protect_from_scale_in = false

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for GPU instances
resource "aws_launch_template" "ollama" {
  name          = "${var.project_name}-compute-ollama"
  image_id      = data.aws_ami.ecs_ami.id # Calc using a terraform data structure
  instance_type = "g4dn.xlarge"           # An instance with GPU NVIDIA

  update_default_version = true

  # Recommended metadata options
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # User data to install the ECS agent and configure Docker
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

# Scheduled scaling for business hours (M-F, 9-19)
resource "aws_autoscaling_schedule" "scale_up_workday" {
  scheduled_action_name  = "${var.project_name}-compute-scale-up-workday"
  min_size               = var.ollama_min_count
  max_size               = var.ollama_max_count
  desired_capacity       = var.ollama_desired_count
  recurrence             = "0 9 * * mon-fri" # 9:00 AM, Monday to Friday
  time_zone              = "Europe/Madrid"   # Time zone of Spain
  autoscaling_group_name = aws_autoscaling_group.ollama.name
}

resource "aws_autoscaling_schedule" "scale_down_workday" {
  scheduled_action_name  = "${var.project_name}-compute-scale-down-workday"
  min_size               = 0
  max_size               = var.ollama_max_count # Keep the maximum in order not to lose the configuration.
  desired_capacity       = 0                    # Scale to 0 instances => avoid costs
  recurrence             = "0 19 * * mon-fri"   # 19:00 PM, Monday to Friday
  time_zone              = "Europe/Madrid"      # Time zone of Spain
  autoscaling_group_name = aws_autoscaling_group.ollama.name
}

#
# Networking
# #############################################################################

# Security Group for Ollama
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "ollama" {
  name        = "${var.project_name}-compute-ollama"
  description = "Security group for Ollama instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 11434
    to_port         = 11434
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "Allow access to Ollama API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic"
  }

  tags = {
    Name  = "${var.project_name}-compute-ollama"
    Layer = "Compute"
  }
}

#
# IAM
# #############################################################################

# IAM Role for EC2 Instances running Ollama container
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

# Instance Profile for Ollama EC2 instances
resource "aws_iam_instance_profile" "ollama" {
  name = "${var.project_name}-security-ollama"
  role = aws_iam_role.ollama_instance.name
}

# Basic policy for Ollama EC2 instances
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

# SSM Administered Policy for the instance
resource "aws_iam_role_policy_attachment" "ollama_instance_ssm" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Managed Policy for the instance
resource "aws_iam_role_policy_attachment" "ollama_instance_cloudwatch" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Policy for ECS
resource "aws_iam_role_policy_attachment" "ollama_instance_ecs" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ENI Management Policy for Ollama
resource "aws_iam_role_policy_attachment" "ecs_instance_eni" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
