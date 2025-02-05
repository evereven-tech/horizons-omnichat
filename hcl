# AWS Region
aws_region = "eu-west-1"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-west-1a", "eu-west-1b"]
private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]

# SSL Certificate
certificate_arn = "arn:aws:acm:eu-west-1:533267020467:certificate/710bd2fc-e7a2-4096-b3e8-8b5dc0fa92a8"

# Domain Configuration
domain_name = "horizons.example.com"
# AWS Region
aws_region = "eu-west-1"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-west-1a", "eu-west-1b"]
private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]

# SSL Certificate
certificate_arn = "arn:aws:acm:eu-west-1:533267020467:certificate/710bd2fc-e7a2-4096-b3e8-8b5dc0fa92a8"

# Domain Configuration
domain_name = "horizons.example.com"  # Cambiar según tu dominio
# User Pool
resource "aws_cognito_user_pool" "main" {
  name = "horizons-user-pool"

  # Políticas de contraseña
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Configuración de verificación
  auto_verified_attributes = ["email"]
  
  # Configuración de emails
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Verificación de cuenta Horizons"
    email_message = "Tu código de verificación es {####}"
  }
}

# User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name = "horizons-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # No generar secret key ya que es una aplicación web pública
  generate_secret = false

  # Configuración de OAuth2
  allowed_oauth_flows = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["email", "openid", "profile"]

  # URLs de callback
  callback_urls = ["http://localhost:3002"] # Añadiremos más URLs cuando tengamos el ALB
  logout_urls  = ["http://localhost:3002"]

  # Configuración de tokens
  refresh_token_validity = 30
  access_token_validity = 1
  id_token_validity = 1

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "horizons-${random_string.random.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Generador de string aleatorio para el dominio
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}
# Security Group para el ALB
resource "aws_security_group" "alb" {
  name        = "horizons-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "horizons-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "horizons-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "horizons-alb"
  }
}

# Target Group (lo usaremos más adelante para el servicio de OpenWebUI)
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
    matcher            = "200"
    path               = "/health"
    port               = "traffic-port"
    timeout            = 5
    unhealthy_threshold = 2
  }
}

# Listener HTTPS (necesitaremos un certificado SSL)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.main.arn
      user_pool_client_id = aws_cognito_user_pool_client.main.id
      user_pool_domain    = aws_cognito_user_pool_domain.main.domain
    }
  }
}
