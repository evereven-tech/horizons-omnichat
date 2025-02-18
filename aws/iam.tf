# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-security-ecs-execution"

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
    Name  = "${var.project_name}-security-ecs-execution"
    Layer = "Security"
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role for OpenWebUI
resource "aws_iam_role" "webui_task" {
  name = "${var.project_name}-security-webui-task"

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
    Name  = "${var.project_name}-security-webui-task"
    Layer = "Security"
  }
}

# ECS Task Role for Bedrock Gateway
resource "aws_iam_role" "bedrock_task" {
  name = "${var.project_name}-security-bedrock-task"

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
    Name  = "${var.project_name}-security-bedrock-task"
    Layer = "Security"
  }
}

# SSM Policy for ECS Exec
resource "aws_iam_role_policy" "ecs_exec" {
  name = "${var.project_name}-security-ecs-exec"
  role = aws_iam_role.bedrock_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for Bedrock Gateway task role
resource "aws_iam_role_policy" "bedrock_task" {
  name = "${var.project_name}-security-bedrock-task-policy"
  role = aws_iam_role.bedrock_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.bedrock.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels",
          "bedrock:ListInferenceProfiles"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM Policy for WebUI ECS Exec
resource "aws_iam_role_policy" "webui_ecs_exec" {
  name = "${var.project_name}-security-webui-ecs-exec"
  role = aws_iam_role.webui_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for OpenWebUI task role
resource "aws_iam_role_policy" "webui_task" {
  name = "${var.project_name}-security-webui-task-policy"
  role = aws_iam_role.webui_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.webui.arn}:*"
      }
    ]
  })
}

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
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.models.arn
      }
    ]
  })
}

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

# Añadir política administrada de SSM al rol de la instancia
resource "aws_iam_role_policy_attachment" "ollama_instance_ssm" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}
