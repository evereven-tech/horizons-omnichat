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
  value       = local.efs_file_system_id
}

output "efs_access_point_id" {
  description = "ID of EFS access point"
  value       = local.efs_access_point_id
}

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    webui           = aws_ecr_repository.webui.repository_url
    bedrock_gateway = aws_ecr_repository.bedrock_gateway.repository_url
    ollama          = local.ecr_repository_ollama_url
  }
}

output "service_dns" {
  description = "DNS names for the services"
  value = {
    webui   = "${aws_service_discovery_service.webui.name}.${aws_service_discovery_private_dns_namespace.main.name}"
    bedrock = "${aws_service_discovery_service.bedrock.name}.${aws_service_discovery_private_dns_namespace.main.name}"
    ollama  = var.enable_gpu ? "${local.service_discovery_ollama_name}.${aws_service_discovery_private_dns_namespace.main.name}" : null
  }
}
