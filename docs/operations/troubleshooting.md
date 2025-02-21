---
layout: default
title: Troubleshooting Guide
---

# Troubleshooting Guide

This guide provides solutions for common issues across all deployment modes of Horizons OmniChat.

## Quick Diagnostic Commands

### Local/Hybrid Mode
```bash
# Check component healthchecks
curl http://localhost:3002/health    # WebUI
curl http://localhost:11434/api/tags # Ollama
curl http://localhost:8000/health    # Bedrock Gateway (hybrid only)
```

### AWS Mode
```bash
# Check ECS services
aws ecs list-services --cluster horizons-compute-fargate
aws ecs list-services --cluster horizons-compute-ec2

# View CloudWatch logs
aws logs get-log-events \
    --log-group-name /ecs/horizons/webui \
    --log-stream-name $(aws logs describe-log-streams \
        --log-group-name /ecs/horizons/webui \
        --order-by LastEventTime \
        --descending \
        --limit 1 \
        --query 'logStreams[0].logStreamName' \
        --output text)
```

## Common Issues and Solutions

### 1. WebUI Issues

#### Cannot Access WebUI

**Symptoms:**
- Browser shows "Connection refused"
- 502 Bad Gateway error
- Blank page

**Solutions:**

1. Check service status:
```bash
# Local/Hybrid mode
docker compose ps
docker logs open-webui

# AWS mode
aws ecs describe-services \
    --cluster horizons-compute-fargate \
    --services horizons-compute-webui
```

2. Verify network configuration:
```bash
# Local/Hybrid mode
docker network inspect local_chatbot-net

# AWS mode
aws elbv2 describe-target-health \
    --target-group-arn $TARGET_GROUP_ARN
```

3. Check database connection:
```bash
# Local/Hybrid mode
docker exec open-webui-db pg_isready

# AWS mode
aws rds describe-db-instances \
    --db-instance-identifier horizons-persistence-db
```

### 2. Model Issues

#### Models Not Loading

**Symptoms:**
- "Model not found" errors
- Slow model loading
- Incomplete model downloads

**Solutions:**

1. Check Ollama status:
```bash
# Local/Hybrid mode
docker logs ollama
docker exec ollama ollama list

# AWS mode
aws ecs describe-tasks \
    --cluster horizons-compute-ec2 \
    --tasks $(aws ecs list-tasks \
        --cluster horizons-compute-ec2 \
        --service-name horizons-compute-ollama \
        --query 'taskArns[0]' \
        --output text)
```

2. Verify model storage:
```bash
# Local/Hybrid mode
docker exec ollama du -sh /root/.ollama

# AWS mode
aws efs describe-file-systems \
    --file-system-id $EFS_ID
```

### 3. Performance Issues

#### Slow Response Times

**Symptoms:**
- Long waiting times for responses
- Timeout errors
- High latency

**Solutions:**

1. Check resource usage:
```bash
# Local/Hybrid mode
docker stats
nvidia-smi  # if using GPU

# AWS mode
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ClusterName,Value=horizons-compute-fargate \
    --start-time $STARTING_TIME \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 300 \
    --statistics Average
```

2. Monitor database performance:
```bash
# Local/Hybrid mode
docker exec open-webui-db \
    psql -U $POSTGRES_USER -d $POSTGRES_DB \
    -c "SELECT * FROM pg_stat_activity;"

# AWS mode
aws rds describe-db-instances \
    --db-instance-identifier horizons-persistence-db \
    --query 'DBInstances[0].DBInstanceStatus'
```

3. Check network latency:
```bash
# Local/Hybrid mode
docker exec open-webui ping -c 3 ollama
docker exec open-webui ping -c 3 bedrock-gateway  # hybrid only

# AWS mode
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name TargetResponseTime \
    --dimensions Name=LoadBalancer,Value=$ALB_NAME
```

### 4. Authentication Issues

#### Login Problems

**Symptoms:**
- Cannot log in
- Token errors
- Session expiration

**Solutions:**

1. Verify authentication configuration:
```bash
# AWS mode
aws cognito-idp describe-user-pool \
    --user-pool-id $USER_POOL_ID
```

2. Check authentication logs:
```bash
# AWS mode
aws cognito-idp describe-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-id $CLIENT_ID
```

## Getting Help

1. Check the [Documentation](https://evereven-tech.github.io/horizons-omnichat/)
2. Join our [Community Discussion](https://github.com/evereven-tech/horizons-omnichat/discussions)
3. Open an [Issue](https://github.com/evereven-tech/horizons-omnichat/issues)
4. Contact [Enterprise Support](../enterprise/support.md)

{% include footer.html %}
