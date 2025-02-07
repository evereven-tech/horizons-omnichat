# Buscar la AMI más reciente de Amazon Linux 2 con soporte GPU
data "aws_ami" "amazon_linux_2_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Launch Template para instancias GPU
resource "aws_launch_template" "ollama" {
  name = "${var.project_name}-${var.environment}-ollama"
  
  image_id = data.aws_ami.amazon_linux_2_gpu.id
  instance_type = "g4dn.xlarge"       # Instancia con GPU NVIDIA T4

  # Metadata options recomendadas
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # User data para instalar drivers y Docker
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              # Instalar dependencias necesarias
              yum groupinstall -y "Development Tools"
              yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)

              # Configurar repositorio EPEL
      	      amazon-linux-extras install -y epel
      
              # Instalar ROCm (AMD GPU drivers)
              yum install -y https://repo.radeon.com/rocm/centos/rpm/rocm-repo-5.7.1-44.el8.noarch.rpm
              yum install -y rocm-hip-runtime rocm-hip-sdk

              # Configurar Docker para usar ROCm
              cat > /etc/docker/daemon.json <<'EOL'
              {
                  "runtimes": {
                      "rocr-runtime": {
                          "path": "/opt/rocm/bin/rocr-runtime"
                      }
                  },
                  "default-runtime": "rocr-runtime"
              }
              EOL

              systemctl restart docker
              EOF
  )

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.ollama.id]
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
      Name        = "${var.project_name}-${var.environment}-ollama"
      Environment = var.environment
    }
  }
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
  max_size           = var.ollama_max_count
  min_size           = var.ollama_min_count
  target_group_arns  = [aws_lb_target_group.ollama.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
      spot_max_price                          = "0.25"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ollama.id
        version           = "$Latest"
      }

      override {
        instance_type = var.ollama_instance_type
      }
      
      # Tipos de instancia alternativos si el principal no está disponible
      override {
        instance_type = "g4ad.2xlarge"
      }
      override {
        instance_type = "g4ad.4xlarge"
      }
    }
  }

  tag {
    key                 = "Name"
    value              = "${var.project_name}-${var.environment}-ollama"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value              = var.environment
    propagate_at_launch = true
  }

  # Importante para la integración con ECS
  tag {
    key                 = "AmazonECSManaged"
    value              = true
    propagate_at_launch = true
  }

  # Proteger contra scale-in para mantener la instancia
  protect_from_scale_in = true

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
    matcher            = "200"
    path               = "/api/tags"
    port               = "traffic-port"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ollama"
    Environment = var.environment
  }
}
