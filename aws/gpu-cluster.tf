#
# ECS
# #############################################################################

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.my_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_asg_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_capacity_provider.name
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_capacity_provider" "ecs_asg_capacity_provider" {
  name = "my-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED" # 필요에 따라 "ENABLED" 또는 "DISABLED"

    managed_scaling {
      status                    = "ENABLED" # 필요에 따라 "ENABLED" 또는 "DISABLED"
      target_capacity           = 100       # 원하는 타겟 용량 비율
      minimum_scaling_step_size = 1         # 최소 스케일링 단계 크기
      maximum_scaling_step_size = 100       # 최대 스케일링 단계 크기
    }
  }
}

#
# ASG
# #############################################################################

resource "aws_autoscaling_group" "ecs_asg" {
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  min_size            = 0
  max_size            = 10
  desired_capacity    = 1
  vpc_zone_identifier = [for id in aws_subnet.private.*.id : id]

  tag {
    key                 = "Name"
    value               = "ECS Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "ecsCluster"
    value               = aws_ecs_cluster.my_cluster.name
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "ecs-launch-template-"
  image_id      = data.aws_ami.ecs_ami.id # Update this with the latest ECS-optimized AMI ID for your region
  instance_type = "g4dn.xlarge"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.my_cluster.name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_GPU_SUPPORT=true >> /etc/ecs/ecs.config
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ECS Instance - g4dn.xlarge"
    }
  }
}

#
# APP
# #############################################################################

resource "aws_ecs_service" "ollama_service" {
  name            = "ollama-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.ollama_gpu_task.arn
  desired_count   = 1

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ollama_sg.id, aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_capacity_provider.name
    weight            = 1
    base              = 1
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.instance-type == g4dn.xlarge"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

resource "aws_ecs_task_definition" "ollama_gpu_task" {
  family                   = "ollama-gpu-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "8192" # Ollama require a lot of memory for the models

  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_tasks_role.arn

  container_definitions = jsonencode([
    {
      name      = "ollama-gpu"
      image     = "ollama/ollama:latest"
      cpu       = 2048
      memory    = 8192
      essential = true

      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]

      portMappings = [
        {
          containerPort = 11434
          hostPort      = 11434
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/ollama-gpu-task"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ollama"
        }
      }
    }
  ])
}

#
# CW
# #############################################################################

resource "aws_cloudwatch_log_group" "ollama_logs" {
  name              = "/ecs/ollama-gpu-task"
  retention_in_days = 30
}

#
# IAM
# #############################################################################

resource "aws_iam_role" "ecs_tasks_role" {
  name = "ecs-tasks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name = "ecs-tasks-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "ecs_cloudwatch_logs" {
  name = "ecs-cloudwatch-logs"
  role = aws_iam_role.ecs_tasks_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ollama_logs.arn}:*"
      }
    ]
  })
}

# Attach the necessary policy to the execution role to allow ECS tasks to pull images and store logs
resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role_policy" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "my-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

# 
# Networking
# #############################################################################

# Ollama specific Security Group
resource "aws_security_group" "ollama_sg" {
  name        = "ollama-sg"
  description = "Security group for Ollama API"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    #cidr_blocks = ["10.0.0.0/16"] # Only visible from VPC
    security_groups = [ aws_security_group.ecs_tasks.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ollama-sg"
  }
}
