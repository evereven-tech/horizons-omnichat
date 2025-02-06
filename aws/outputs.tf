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
# Outputs para los repositorios ECR
output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    webui           = aws_ecr_repository.webui.repository_url
    bedrock_gateway = aws_ecr_repository.bedrock_gateway.repository_url
    ollama          = aws_ecr_repository.ollama.repository_url
  }
}