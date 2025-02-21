---
layout: default
title: Deployment AWS
---

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
aws ecs describe-task-definition --task-definition horizons-compute-webui
```

2. **Service Health**
```bash
# Check service status
aws ecs describe-services --cluster horizons-compute-fargate --services horizons-compute-webui | grep -e status -e failures
```

3. **Container Logs**
```bash
# Get log streams
aws logs describe-log-streams --log-group-name /ecs/horizons/webui

# View logs
aws logs get-log-events --log-group-name /ecs/horizons/webui --log-stream-name $STREAM_NAME
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
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

### Authentication

1. **Cognito Issues**
```bash
# List user pools
aws cognito-idp list-user-pools --max-results 20

# Check user pool status
aws cognito-idp describe-user-pool --user-pool-id $POOL_ID
```

2. **SSL Certificate**
```bash
# Verify certificate
aws acm describe-certificate --certificate-arn $CERT_ARN
```

### Database

1. **RDS Connectivity**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier horizons-persistence-db
```

2. **Performance Issues**
```bash
# View slow query logs
aws rds download-db-log-file-portion --db-instance-identifier horizons-persistence-db --log-file-name error/postgresql.log.YYYY-MM-DD-HH
```

## Maintenance

### Backup and Recovery

1. **Database Backups**
```bash
# Create snapshot
aws rds create-db-snapshot --db-instance-identifier horizons-persistence-db --db-snapshot-identifier your-backup

# List snapshots
aws rds describe-db-snapshots --db-instance-identifier horizons-persistence-db
```

2. **EFS Backups**
```bash
# Create EFS backup
aws backup start-backup-job --backup-vault-name horizons-backup --resource-arn $EFS_ARN
```

### Updates and Upgrades

1. **Container Images**
```bash
# Update task definitions
aws ecs update-service --cluster horizons-compute-fargate --service horizons-compute-webui --force-new-deployment
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
aws cloudwatch get-dashboard --dashboard-name horizons-monitoring
```

## Getting Help

1. Check [AWS ECS Documentation](https://docs.aws.amazon.com/ecs)
2. Check [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock)
2. Review [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
3. Join our [Community Discussion](https://github.com/evereven-tech/horizons-omnichat/discussions)

{% include footer.html %}
