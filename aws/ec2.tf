# Launch Template para instancias GPU
resource "aws_launch_template" "ollama" {
  name = "${var.project_name}-${var.environment}-ollama"
  
  image_id = "ami-0989fb15ce71ba39e"  # Amazon Linux 2 with GPU support
  instance_type = "g4dn.xlarge"       # Instancia con GPU NVIDIA T4

  # Metadata options recomendadas
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # User data para instalar drivers NVIDIA y Docker
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              # Instalar drivers NVIDIA
              DRIVER_VERSION="470.57.02"
              wget https://us.download.nvidia.com/tesla/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run
              sudo sh NVIDIA-Linux-x86_64-$DRIVER_VERSION.run -s --no-nvidia-modprobe
              
              # Instalar nvidia-container-toolkit
              distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
              curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
              curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
              yum install -y nvidia-container-toolkit
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
