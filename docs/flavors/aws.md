# AWS Deployment Guide

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- S3 bucket for Terraform state
- Route53 hosted zone (for SSL/domain)
- AWS Bedrock models enabled in your AWS account
  > **IMPORTANT**: Before deploying, you must enable the models you plan to use:
  > 1. Go to AWS Console -> Bedrock -> Model access
  > 2. Click "Manage model access"
  > 3. Select and request access for desired models
  > 4. Wait for approval (usually immediate for most models)

## Quick Start

1. Initialize deployment:
```bash
cp aws/terraform.tfvars.template aws/terraform.tfvars
cp aws/backend.hcl.example aws/backend.hcl
# Edit both files with your configuration
```

2. Deploy infrastructure:
```bash
make aws-init
make aws-plan
make aws-apply
```

## Troubleshooting

### Infrastructure Deployment

1. **Terraform State Issues**
```bash
# Check state
terraform -chdir=aws state list

# Refresh state
terraform -chdir=aws refresh
```

2. **Resource Creation Failures**
```bash
# Get detailed error output
TF_LOG=DEBUG terraform -chdir=aws apply

# Check AWS CloudTrail for API errors
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=CreateStack
```

### ECS Services

1. **Task Definition Issues**
```bash
# List task definitions
aws ecs list-task-definitions

# Describe specific task
aws ecs describe-task-definition --task-definition horizons-dev-webui
```

2. **Service Health**
```bash
# Check service status
aws ecs list-services --cluster horizons-dev-fargate
aws ecs describe-services --cluster horizons-dev-fargate --services horizons-dev-webui
```

3. **Container Logs**
```bash
# Get log streams
aws logs get-log-streams --log-group-name /ecs/horizons-dev/webui

# View logs
aws logs get-log-events --log-group-name /ecs/horizons-dev/webui --log-stream-name STREAM_NAME
```

### Network Issues

1. **VPC Configuration**
```bash
# Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=vpc-XXXXX

# Verify security groups
aws ec2 describe-security-groups --filters Name=group-name,Values=horizons-*
```

2. **Load Balancer**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn TARGET_GROUP_ARN

# View ALB logs
aws logs get-log-events --log-group-name /aws/alb/horizons-alb
```

### Authentication

1. **Cognito Issues**
```bash
# List user pools
aws cognito-idp list-user-pools --max-results 20

# Check user pool status
aws cognito-idp describe-user-pool --user-pool-id POOL_ID
```

2. **SSL Certificate**
```bash
# Verify certificate
aws acm describe-certificate --certificate-arn CERT_ARN
```

### Database

1. **RDS Connectivity**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier horizons-dev-db

# Monitor metrics
aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name CPUUtilization
```

2. **Performance Issues**
```bash
# View slow query logs
aws rds download-db-log-file-portion --db-instance-identifier horizons-dev-db --log-file-name postgresql.log
```

## Maintenance

### Backup and Recovery

1. **Database Backups**
```bash
# Create snapshot
aws rds create-db-snapshot --db-instance-identifier horizons-dev-db --db-snapshot-identifier manual-backup

# List snapshots
aws rds describe-db-snapshots --db-instance-identifier horizons-dev-db
```

2. **EFS Backups**
```bash
# Create EFS backup
aws backup start-backup-job --backup-vault-name horizons-backup --resource-arn EFS_ARN
```

### Updates and Upgrades

1. **Container Images**
```bash
# Update task definitions
aws ecs update-service --cluster horizons-dev-fargate --service horizons-dev-webui --force-new-deployment
```

2. **Infrastructure Updates**
```bash
# Apply Terraform changes
make aws-plan
make aws-apply
```

### Monitoring

1. **CloudWatch Dashboards**
```bash
# View metrics
aws cloudwatch get-dashboard --dashboard-name horizons-dev-ollama
```

2. **Alerts and Notifications**
```bash
# Check alarm status
aws cloudwatch describe-alarms --alarm-names horizons-dev-gpu-utilization-high
```

## Cost Optimization

1. **Resource Utilization**
```bash
# View EC2 Spot pricing
aws ec2 describe-spot-price-history --instance-types g4dn.xlarge

# Check ECS service scaling
aws ecs describe-services --cluster horizons-dev-ec2 --services horizons-dev-ollama
```

2. **Storage Costs**
```bash
# Monitor EFS usage
aws cloudwatch get-metric-statistics --namespace AWS/EFS --metric-name StorageBytes

# Check RDS storage
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,AllocatedStorage]'
```

## Security

1. **IAM Roles**
```bash
# Review role policies
aws iam list-role-policies --role-name horizons-dev-ecs-execution

# Check service roles
aws iam get-role --role-name horizons-dev-webui-task
```

2. **Security Groups**
```bash
# Audit security groups
aws ec2 describe-security-group-rules --filters Name=group-id,Values=sg-XXXXX
```

## Getting Help

1. Check [AWS ECS Documentation](https://docs.aws.amazon.com/ecs)
2. Review [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
3. Join our [Community Discussion](https://github.com/evereven-tech/horizons-omnichat/discussions)
