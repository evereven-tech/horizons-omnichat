---
layout: default
title: Backup and Recovery
---

# Backup and Recovery

This guide covers backup and recovery procedures for all deployment modes of Horizons OmniChat.

## Backup Components

### 1. Database Backups

#### Local/Hybrid Mode
```bash
# Manual backup
docker exec open-webui-db pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup.sql

# Automated backup script
cat << 'EOF' > backup-db.sh
#!/bin/bash
BACKUP_DIR="/path/to/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker exec open-webui-db pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_DIR/db_backup_$TIMESTAMP.sql
EOF
chmod +x backup-db.sh
```

#### AWS Mode
```bash
# Manual RDS snapshot
aws rds create-db-snapshot \
    --db-instance-identifier horizons-persistence-db \
    --db-snapshot-identifier manual-backup-$(date +%Y%m%d)

# List available snapshots
aws rds describe-db-snapshots \
    --db-instance-identifier horizons-persistence-db
```

### 2. Model Storage Backups

#### Local/Hybrid Mode
```bash
# Backup Ollama models directory
tar -czf ollama-models-$(date +%Y%m%d).tar.gz \
    $(docker volume inspect -f '{{.Mountpoint}}' local_ollama-data)
```

#### AWS Mode
```bash
# EFS backup using AWS Backup
aws backup start-backup-job \
    --backup-vault-name horizons-backup \
    --resource-arn arn:aws:elasticfilesystem:region:account-id:file-system/fs-id
```

### 3. Configuration Backups

#### Local/Hybrid Mode
```bash
# Backup environment files
cp local/.env local/.env.backup-$(date +%Y%m%d)
cp hybrid/.env hybrid/.env.backup-$(date +%Y%m%d)
cp hybrid/config.json hybrid/config.json.backup-$(date +%Y%m%d)
```

#### AWS Mode
```bash
# Backup Terraform state and configs
cp aws/terraform.tfvars aws/terraform.tfvars.backup-$(date +%Y%m%d)
aws s3 cp s3://your-terraform-state-bucket/horizons/terraform.tfstate \
    s3://your-terraform-state-bucket/horizons/terraform.tfstate.backup-$(date +%Y%m%d)
```

## Backup Scheduling

### Local/Hybrid Mode

Create a cron job for automated backups:

```bash
# Add to crontab
0 2 * * * /path/to/backup-db.sh
0 3 * * * tar -czf /path/to/backups/ollama-models-$(date +\%Y\%m\%d).tar.gz /path/to/ollama/models
```

### AWS Mode

Configure AWS Backup plans:

```bash
# Create backup plan
aws backup create-backup-plan --cli-input-json file://backup-plan.json

# Example backup-plan.json
{
    "BackupPlan": {
        "BackupPlanName": "HorizonsBackupPlan",
        "Rules": [
            {
                "RuleName": "DailyBackups",
                "TargetBackupVaultName": "horizons-backup",
                "ScheduleExpression": "cron(0 5 ? * * *)",
                "StartWindowMinutes": 60,
                "CompletionWindowMinutes": 120,
                "Lifecycle": {
                    "DeleteAfterDays": 30
                }
            }
        ]
    }
}
```

## Recovery Procedures

### 1. Database Recovery

#### Local/Hybrid Mode
```bash
# Stop services
make local-down  # or make hybrid-down

# Restore database
cat backup.sql | docker exec -i open-webui-db psql -U $POSTGRES_USER -d $POSTGRES_DB

# Start services
make local-up  # or make hybrid-up
```

#### AWS Mode
```bash
# Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier horizons-persistence-db-restored \
    --db-snapshot-identifier snapshot-identifier
```

### 2. Model Storage Recovery

#### Local/Hybrid Mode
```bash
# Stop services
make local-down

# Restore models
tar -xzf ollama-models-backup.tar.gz -C /path/to/ollama/models

# Start services
make local-up
```

#### AWS Mode
```bash
# Restore EFS from backup
aws backup start-restore-job \
    --recovery-point-arn arn:aws:backup:region:account-id:recovery-point:backup-id \
    --iam-role-arn arn:aws:iam::account-id:role/service-role/restore-role \
    --resource-type EFS
```

## Backup Verification

### Testing Backups

1. **Database Verification**
```bash
# Check backup integrity
pg_restore --list backup.sql

# Test restore in temporary database
docker exec -i open-webui-db createdb test_restore
cat backup.sql | docker exec -i open-webui-db psql -U $POSTGRES_USER -d test_restore
```

2. **Model Storage Verification**
```bash
# Test model archive
tar -tvf ollama-models-backup.tar.gz

# Verify model files
find /path/to/ollama/models -type f -exec md5sum {} \;
```

### Monitoring Backup Status

#### Local/Hybrid Mode
```bash
# Check backup script logs
tail -f /var/log/backup.log

# Verify backup files
ls -lh /path/to/backups/
```

#### AWS Mode
```bash
# Check AWS Backup status
aws backup list-backup-jobs --by-resource-arn $RESOURCE_ARN

# Monitor RDS snapshots
aws rds describe-db-snapshots --db-instance-identifier horizons-persistence-db
```

## Best Practices

1. **Retention Policy**
   - Keep daily backups for 7 days
   - Keep weekly backups for 1 month
   - Keep monthly backups for 6 months

2. **Security**
   - Encrypt backups at rest
   - Use secure transfer methods
   - Implement access controls

3. **Documentation**
   - Maintain backup inventory
   - Document recovery procedures
   - Regular testing schedule

## Next Steps

- Review [Monitoring Guide](monitoring.md)
- Configure [Alerting](monitoring.md#alerting)
- Implement [Security Best Practices](../security/overview.md)

{% include footer.html %}
