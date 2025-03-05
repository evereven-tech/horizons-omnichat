#
# Application Load Balancer
# #############################################################################

# Application Load Balancer
#trivy:ignore:AVD-AWS-0053
resource "aws_lb" "main" {
  name               = "horizons-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name = "horizons-alb"
  }
}

# ALB Listener HTTP
# HTTP to HTTPS redirect
resource "aws_lb_listener" "front_end_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (we will need an SSL certificate)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.main.arn
      user_pool_client_id = aws_cognito_user_pool_client.main.id
      user_pool_domain    = aws_cognito_user_pool_domain.main.domain
      session_timeout     = 28800
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webui.arn
  }
}

# Security Group for the ALB
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "alb" {
  name        = "horizons-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow redirection from http:80 to https:443"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Internet, but protected by Cognito"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic"
  }

  tags = {
    Name = "horizons-alb-sg"
  }
}

#
# Target Groups
# #############################################################################

# Open WebUI Target Group
resource "aws_lb_target_group" "webui" {
  name        = "horizons-webui-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# Ollama Target Group
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
