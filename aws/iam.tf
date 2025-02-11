# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution"

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
    Name        = "${var.project_name}-${var.environment}-ecs-execution"
    Environment = var.environment
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role for OpenWebUI
resource "aws_iam_role" "webui_task" {
  name = "${var.project_name}-${var.environment}-webui-task"

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
    Name        = "${var.project_name}-${var.environment}-webui-task"
    Environment = var.environment
  }
}

# ECS Task Role for Bedrock Gateway
resource "aws_iam_role" "bedrock_task" {
  name = "${var.project_name}-${var.environment}-bedrock-task"

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
    Name        = "${var.project_name}-${var.environment}-bedrock-task"
    Environment = var.environment
  }
}

# SSM Policy for ECS Exec
resource "aws_iam_role_policy" "ecs_exec" {
  name = "${var.project_name}-${var.environment}-ecs-exec"
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
  name = "${var.project_name}-${var.environment}-bedrock-task-policy"
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
  name = "${var.project_name}-${var.environment}-webui-ecs-exec"
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
  name = "${var.project_name}-${var.environment}-webui-task-policy"
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
  name = "${var.project_name}-${var.environment}-ollama-task"

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
    Name        = "${var.project_name}-${var.environment}-ollama-task"
    Environment = var.environment
  }
}

# Policy para el rol de Ollama task
resource "aws_iam_role_policy" "ollama_task" {
  name = "${var.project_name}-${var.environment}-ollama-task-policy"
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
      }
    ]
  })
}

# IAM Role para las instancias EC2 de Ollama
resource "aws_iam_role" "ollama_instance" {
  name = "${var.project_name}-${var.environment}-ollama-instance"

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
    Name        = "${var.project_name}-${var.environment}-ollama-instance"
    Environment = var.environment
  }
}

# Instance Profile para las instancias EC2 de Ollama
resource "aws_iam_instance_profile" "ollama" {
  name = "${var.project_name}-${var.environment}-ollama"
  role = aws_iam_role.ollama_instance.name
}

# Añadir política administrada de SSM al rol de la instancia
resource "aws_iam_role_policy_attachment" "ollama_instance_ssm" {
  role       = aws_iam_role.ollama_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Política básica para las instancias EC2 de Ollama
resource "aws_iam_role_policy" "ollama_instance" {
  name = "${var.project_name}-${var.environment}-ollama-instance-policy"
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
