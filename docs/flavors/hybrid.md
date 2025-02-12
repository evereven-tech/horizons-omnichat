# Hybrid Deployment Guide

## Prerequisites

- Docker or Podman
- Make
- AWS CLI configured with appropriate permissions
- AWS Bedrock models enabled in your AWS account
  > **IMPORTANT**: You must explicitly enable each model you want to use in the AWS Bedrock console
  > Go to AWS Console -> Bedrock -> Model access -> Request model access
- 8GB RAM minimum
- (Optional) NVIDIA GPU with CUDA support

## Quick Start

1. Clone and initialize:
```bash
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat
make init
```

2. Configure environment:
```bash
cp hybrid/.env.example hybrid/.env
cp hybrid/config.json.template hybrid/config.json
# Edit both files with your settings
```

3. Start services:
```bash
make hybrid-up
```

## Troubleshooting

### AWS Configuration Issues

1. **AWS Credentials**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check AWS environment variables
env | grep AWS_
```

2. **Bedrock Access**
```bash
# Test Bedrock connectivity
aws bedrock list-foundation-models

# Check Bedrock Gateway logs
docker logs bedrock-gateway
```

### Container Issues

1. **Service Dependencies**
```bash
# Check service health
docker compose ps

# View startup order issues
docker compose logs | grep -i error
```

2. **Network Connectivity**
```bash
# Test Bedrock Gateway endpoint
curl http://localhost:8000/health

# Verify internal DNS resolution
docker exec open-webui ping bedrock-gateway
```

### Model Issues

1. **Local Models (Ollama)**
```bash
# List downloaded models
docker exec ollama ollama list

# Check model download progress
docker logs -f ollama
```

2. **Bedrock Models**
```bash
# Test model availability
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer $BEDROCK_API_KEY"
```

### Common Error Scenarios

1. **Authentication Failures**
```bash
# Check API key configuration
grep BEDROCK_API_KEY hybrid/.env
grep api_key hybrid/config.json

# Verify AWS credentials expiry
aws sts get-caller-identity
```

2. **Resource Constraints**
```bash
# Monitor resource usage
docker stats

# Check GPU utilization (if enabled)
nvidia-smi -l 1
```

3. **Database Issues**
```bash
# Verify database connection
docker exec webui-db pg_isready

# Check database logs
docker logs webui-db
```

## Maintenance

### Updates and Upgrades

```bash
# Update AWS CLI
pip install --upgrade awscli

# Pull latest images
docker compose pull

# Restart services
make hybrid-down
make hybrid-up
```

### Backup Procedures

```bash
# Backup configuration
cp hybrid/.env hybrid/.env.backup
cp hybrid/config.json hybrid/config.json.backup

# Backup database
docker exec webui-db pg_dump -U $POSTGRES_USER $POSTGRES_DB > hybrid_backup.sql
```

### Log Management

```bash
# Collect all logs
docker compose logs > hybrid_deployment.log

# Monitor specific service
docker compose logs -f bedrock-gateway
```

## Advanced Configuration

### Fine-tuning Performance

1. **Ollama Configuration**
- Adjust GPU memory allocation
- Configure model preloading

2. **Bedrock Gateway Settings**
- Modify request timeouts
- Configure connection pooling

3. **Database Optimization**
- Tune PostgreSQL parameters
- Implement connection pooling

### Security Hardening

1. **Network Security**
- Enable TLS for all services
- Implement request rate limiting
- Configure proper CORS settings

2. **Access Control**
- Rotate API keys regularly
- Implement IP whitelisting
- Enable audit logging

### Monitoring Setup

1. **Health Checks**
```bash
# Create monitoring script
cat << 'EOF' > monitor.sh
#!/bin/bash
curl -s http://localhost:3002/health
curl -s http://localhost:8000/health
curl -s http://localhost:11434/api/tags
EOF
chmod +x monitor.sh
```

2. **Resource Monitoring**
```bash
# Install monitoring tools
docker run -d --name cadvisor \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  gcr.io/cadvisor/cadvisor:latest
```

## Getting Help

1. Check [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock)
2. Review [Open WebUI Issues](https://github.com/open-webui/open-webui/issues)
3. Join our [Community Discussion](https://github.com/evereven-tech/horizons-omnichat/discussions)
