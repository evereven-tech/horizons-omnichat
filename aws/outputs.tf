output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "efs_filesystem_id" {
  description = "ID of EFS filesystem for models"
  value       = aws_efs_file_system.models.id
}

output "efs_access_point_id" {
  description = "ID of EFS access point"
  value       = aws_efs_access_point.models.id
}

output "ssm_parameter_name" {
  description = "Name of SSM parameter for WebUI config"
  value       = aws_ssm_parameter.webui_config.name
}

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    webui           = aws_ecr_repository.webui.repository_url
    bedrock_gateway = aws_ecr_repository.bedrock_gateway.repository_url
    ollama          = aws_ecr_repository.ollama.repository_url
  }
}

output "service_dns" {
  description = "DNS names for the services"
  value = {
    webui   = "${aws_service_discovery_service.webui.name}.${aws_service_discovery_private_dns_namespace.main.name}"
    bedrock = "${aws_service_discovery_service.bedrock.name}.${aws_service_discovery_private_dns_namespace.main.name}"
    ollama  = "${aws_service_discovery_service.ollama.name}.${aws_service_discovery_private_dns_namespace.main.name}"
  }
}
