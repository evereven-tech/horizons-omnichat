# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-gpu-hvm-*-x86_64-ebs"]
  }
}

locals {
  default_tags = {
    Project    = var.project_name
    License    = "MIT"
    ManagedBy  = "terraform"
    Support    = "horizons@evereven.tech"
    Brand      = "evereven.tech"
    Repository = "evereven-tech/horizons-ommnichat"
    Namespace  = "evereven"
  }

  # GPU Management
  gpu_enabled      = var.enable_gpu
  gpu_enabled_flap = var.enable_gpu ? 1 : 0

  # Network Optimization
  nat_gateway_enabled   = var.nat_gateway_config.enabled
  nat_gateway_single    = var.nat_gateway_config.single_nat
  nat_gateway_count     = local.nat_gateway_enabled ? (local.nat_gateway_single ? 1 : length(var.public_subnets)) : 0
  vpc_endpoints_enabled = var.vpc_endpoints_enabled
  vpc_endpoints_flap    = var.vpc_endpoints_enabled ? 1 : 0

  # EFS & Storage
  efs_file_system_id          = local.gpu_enabled && length(aws_efs_file_system.models) > 0 ? aws_efs_file_system.models[0].id : null
  efs_file_system_arn         = local.gpu_enabled && length(aws_efs_file_system.models) > 0 ? aws_efs_file_system.models[0].arn : null
  efs_access_point_id         = local.gpu_enabled && length(aws_efs_access_point.models) > 0 ? aws_efs_access_point.models[0].id : null
  efs_allowed_security_groups = local.security_group_ollama_tasks_id != null ? [local.security_group_ollama_tasks_id] : []

  # Networking
  security_group_ollama_id        = length(aws_security_group.ollama) > 0 ? aws_security_group.ollama[0].id : null
  security_group_efs_id           = local.gpu_enabled && length(aws_security_group.efs) > 0 ? aws_security_group.efs[0].id : null
  security_group_ollama_tasks_id  = length(aws_security_group.ollama_tasks) > 0 ? aws_security_group.ollama_tasks[0].id : null
  security_group_vpc_endpoints_id = local.vpc_endpoints_enabled && length(aws_security_group.vpc_endpoints) > 0 ? aws_security_group.vpc_endpoints[0].id : null
  ollama_security_groups          = local.security_group_ollama_id != null ? [local.security_group_ollama_id] : []
  lb_target_group_ollama_arn      = local.gpu_enabled && length(aws_lb_target_group.ollama) > 0 ? aws_lb_target_group.ollama[0].arn : null

  # Service Discovery
  service_discovery_ollama_arn  = local.gpu_enabled && length(aws_service_discovery_service.ollama) > 0 ? aws_service_discovery_service.ollama[0].arn : null
  service_discovery_ollama_name = local.gpu_enabled && length(aws_service_discovery_service.ollama) > 0 ? aws_service_discovery_service.ollama[0].name : "no-ollama"

  # ECR
  ecr_repository_ollama_name = local.gpu_enabled && length(aws_ecr_repository.ollama) > 0 ? aws_ecr_repository.ollama[0].name : null
  ecr_repository_ollama_url  = local.gpu_enabled && length(aws_ecr_repository.ollama) > 0 ? aws_ecr_repository.ollama[0].repository_url : null

  # ECS
  ecs_cluster_ec2_id             = local.gpu_enabled && length(aws_ecs_cluster.ec2) > 0 ? aws_ecs_cluster.ec2[0].id : null
  ecs_cluster_ec2_name           = local.gpu_enabled && length(aws_ecs_cluster.ec2) > 0 ? aws_ecs_cluster.ec2[0].name : null
  ecs_task_definition_ollama_arn = local.gpu_enabled && length(aws_ecs_task_definition.ollama) > 0 ? aws_ecs_task_definition.ollama[0].arn : null
  ecs_capacity_provider_ec2_name = local.gpu_enabled && length(aws_ecs_capacity_provider.ec2) > 0 ? aws_ecs_capacity_provider.ec2[0].name : null

  # IAM
  iam_instance_profile_ollama_name = local.gpu_enabled && length(aws_iam_instance_profile.ollama) > 0 ? aws_iam_instance_profile.ollama[0].name : null
  iam_role_ollama_instance_id      = local.gpu_enabled && length(aws_iam_role.ollama_instance) > 0 ? aws_iam_role.ollama_instance[0].id : null
  iam_role_ollama_instance_name    = local.gpu_enabled && length(aws_iam_role.ollama_instance) > 0 ? aws_iam_role.ollama_instance[0].name : null
  iam_role_ollama_instance_arn     = local.gpu_enabled && length(aws_iam_role.ollama_instance) > 0 ? aws_iam_role.ollama_instance[0].arn : null
  iam_role_ollama_task_id          = local.gpu_enabled && length(aws_iam_role.ollama_task) > 0 ? aws_iam_role.ollama_task[0].id : null
  iam_role_ollama_task_arn         = local.gpu_enabled && length(aws_iam_role.ollama_task) > 0 ? aws_iam_role.ollama_task[0].arn : null

  # Auto Scaling Group
  autoscaling_group_ollama_arn  = local.gpu_enabled && length(aws_autoscaling_group.ollama) > 0 ? aws_autoscaling_group.ollama[0].arn : null
  autoscaling_group_ollama_name = local.gpu_enabled && length(aws_autoscaling_group.ollama) > 0 ? aws_autoscaling_group.ollama[0].name : null
  launch_template_ollama_id     = local.gpu_enabled && length(aws_launch_template.ollama) > 0 ? aws_launch_template.ollama[0].id : null

  # Logs
  cloudwatch_log_group_ollama_arn = local.gpu_enabled && length(aws_cloudwatch_log_group.ollama) > 0 ? aws_cloudwatch_log_group.ollama[0].arn : null

}
