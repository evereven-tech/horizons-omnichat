
# Launch Template para instancias GPU
resource "aws_launch_template" "ollama" {
  name = "${var.project_name}-compute-ollama"

  #image_id      = "ami-0dc6fd3fcf713ce9d" # AMI con drivers y software preinstalado
  image_id      = data.aws_ami.ecs_ami.id # Update this with the latest ECS-optimized AMI ID for your region
  instance_type = "g4dn.xlarge"           # Instancia con GPU NVIDIA T4

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

# Target Group para Ollama
resource "aws_lb_target_group" "ollama" {
  name        = "${var.project_name}-compute-ollama"
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
    Name  = "${var.project_name}-compute-ollama"
    Layer = "Compute"
  }
}
