# Security Group para RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
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
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-${var.environment}-rds"
  subnet_ids = aws_subnet.private[*].id  # Usar todas las subnets privadas disponibles

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds"
    Environment = var.environment
  }
}

# Instancia RDS PostgreSQL
resource "aws_db_instance" "webui" {
  identifier        = "${var.project_name}-${var.environment}-db"
  engine            = "postgres"
  engine_version    = "13"
  instance_class    = "db.t3.small"
  allocated_storage = 20
  storage_type      = "gp3"
  
  # Habilitar auto-scaling del almacenamiento
  max_allocated_storage = 100

  db_name  = var.postgres_db
  username = var.postgres_user
  password = var.postgres_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name

  skip_final_snapshot = true
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  # Mejoras de rendimiento
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  
  # Configuración de almacenamiento
  iops                  = 3000
  storage_throughput    = 125

  # Configuración de disponibilidad
  multi_az               = false
  publicly_accessible    = false

  # Parámetros de la base de datos
  parameter_group_name = aws_db_parameter_group.postgres13.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
  }
}

# Grupo de parámetros personalizado
resource "aws_db_parameter_group" "postgres13" {
  family = "postgres13"
  name   = "${var.project_name}-${var.environment}-pg13"

  parameter {
    name  = "work_mem"
    value = "16384"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "128000"
    apply_method = "pending-reboot"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-pg13"
    Environment = var.environment
  }
}
