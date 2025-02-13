
# Launch Template para instancias GPU
resource "aws_launch_template" "ollama" {
  name = "${var.project_name}-${var.environment}-ollama"

  image_id      = "ami-0dc6fd3fcf713ce9d" # AMI con drivers y software preinstalado
  instance_type = "g4dn.xlarge"           # Instancia con GPU NVIDIA T4

  # Metadata options recomendadas
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # User data para instalar el agente ECS y configurar Docker
  user_data = base64encode(<<-EOF
              #!/bin/bash

              # Instalar agente ECS
              curl -O https://s3.us-west-2.amazonaws.com/amazon-ecs-agent-us-west-2/amazon-ecs-init-latest.x86_64.rpm
              yum localinstall -y amazon-ecs-init-latest.x86_64.rpm

              # Configurar el agente ECS
              cat <<'EOT' > /etc/ecs/ecs.config
              ECS_CLUSTER=${aws_ecs_cluster.ec2.name}
              ECS_ENABLE_GPU_SUPPORT=true
              ECS_ENABLE_TASK_IAM_ROLE=true
              ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
              ECS_CONTAINER_INSTANCE_TAGS={"Name": "${var.project_name}-${var.environment}-ollama", "Environment": "${var.environment}"}
              EOT

              # Reiniciar el agente ECS para aplicar la configuración
              service ecs restart
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
      Name             = "${var.project_name}-${var.environment}-ollama"
      Environment      = var.environment
      AmazonECSManaged = "true"
    }
  }
}

# Scheduled scaling para horario laboral (L-V, 9-19)
resource "aws_autoscaling_schedule" "scale_up_workday" {
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-up-workday"
  min_size               = var.ollama_min_count
  max_size               = var.ollama_max_count
  desired_capacity       = var.ollama_desired_count
  recurrence             = "0 9 * * mon-fri" # 9:00 AM, Lunes a Viernes
  time_zone              = "Europe/Madrid"   # Zona horaria de España
  autoscaling_group_name = aws_autoscaling_group.ollama.name
}

resource "aws_autoscaling_schedule" "scale_down_workday" {
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-down-workday"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * mon-fri" # 19:00 PM, Lunes a Viernes
  time_zone              = "Europe/Madrid"    # Zona horaria de España
  autoscaling_group_name = aws_autoscaling_group.ollama.name
}

# Security Group para Ollama
resource "aws_security_group" "ollama" {
  name        = "${var.project_name}-${var.environment}-ollama"
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
    Name        = "${var.project_name}-${var.environment}-ollama"
    Environment = var.environment
  }
}

# Auto Scaling Group para Ollama
resource "aws_autoscaling_group" "ollama" {
  name                = "${var.project_name}-${var.environment}-ollama"
  desired_capacity    = var.ollama_desired_count
  max_size            = var.ollama_max_count
  min_size            = var.ollama_min_count
  target_group_arns   = [aws_lb_target_group.ollama.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = var.spot_config.allocation_strategy
      spot_max_price                           = var.spot_config.spot_price["g4dn.xlarge"]
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ollama.id
        version            = "$Latest"
      }

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
    value               = "${var.project_name}-${var.environment}-ollama"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
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

# Target Group para Ollama
resource "aws_lb_target_group" "ollama" {
  name        = "${var.project_name}-${var.environment}-ollama"
  port        = 11434
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/tags"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ollama"
    Environment = var.environment
  }
}
# EventBridge rule para capturar interrupciones de spot
resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.project_name}-${var.environment}-spot-interruption"
  description = "Capture EC2 Spot Instance Interruption Warnings"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

# Política de Auto Scaling para reemplazo proactivo
resource "aws_autoscaling_policy" "spot_replacement" {
  name                   = "${var.project_name}-${var.environment}-spot-replacement"
  autoscaling_group_name = aws_autoscaling_group.ollama.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60 # Cooldown corto para respuesta rápida
}

# Conectar el evento de interrupción con la política de scaling
resource "aws_cloudwatch_event_target" "spot_replacement" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "TriggerASG"
  arn       = aws_autoscaling_policy.spot_replacement.arn

  role_arn = aws_iam_role.eventbridge_asg.arn
}

# IAM Role para permitir que EventBridge ejecute la política de ASG
resource "aws_iam_role" "eventbridge_asg" {
  name = "${var.project_name}-${var.environment}-eventbridge-asg"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# Política para permitir que EventBridge ejecute la política de ASG
resource "aws_iam_role_policy" "eventbridge_asg" {
  name = "${var.project_name}-${var.environment}-eventbridge-asg-policy"
  role = aws_iam_role.eventbridge_asg.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:ExecutePolicy"
        ]
        Resource = aws_autoscaling_policy.spot_replacement.arn
      }
    ]
  })
}
