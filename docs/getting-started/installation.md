---
layout: default
title: Installation Guide
---

# Installation Guide

This guide will walk you through the installation process for Horizons OmniChat based on your chosen deployment mode.

## Prerequisites

Before starting, ensure you have reviewed and met all [system requirements](requirements.md).

## Installation Methods

Choose your preferred installation method:

### 1. Local Installation

Perfect for development, testing, or single-machine deployments.

```bash
# Clone the repository
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat

# Initialize the environment
make init

# Configure local environment
cp local/.env.example local/.env
# Edit local/.env with your preferred settings

# Start the services
make local-up
```

### 2. Hybrid Installation

Combines local deployment with AWS Bedrock integration.

```bash
# Clone and initialize
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat
make init

# Configure environment
cp hybrid/.env.example hybrid/.env
cp hybrid/config.json.template hybrid/config.json
# Edit both files with your AWS settings

# Start services
make hybrid-up
```

### 3. AWS Installation

Full cloud deployment on AWS infrastructure.

```bash
# Clone and initialize
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat
make init

# Configure AWS deployment
cp aws/terraform.tfvars.template aws/terraform.tfvars
cp aws/backend.hcl.example aws/backend.hcl
# Edit both files with your AWS configuration

# Deploy infrastructure
make aws-init
make aws-plan
make aws-apply
```

## Post-Installation Steps

### 1. Verify Installation

#### Local/Hybrid Mode
```bash
# Check service status
docker compose ps

# Verify web interface
curl http://localhost:3002/health

# Check Ollama status
curl http://localhost:11434/api/tags
```

#### AWS Mode
```bash
# Check ECS services
aws ecs list-services --cluster horizons-compute-fargate

# Verify RDS instance
aws rds describe-db-instances --db-instance-identifier horizons-persistence-db
```

### 2. Initial Configuration

1. Access the web interface:
   - Local/Hybrid mode: http://localhost:3002
   - AWS mode: Check the ALB DNS name in AWS Console

2. Configure authentication:
   - Set up admin credentials
   - Configure user access (AWS mode uses Cognito)

3. Install models:
   - Select and download required models
   - Configure model settings

## Troubleshooting Common Installation Issues

### Docker/Podman Issues
```bash
# Check container logs
docker compose logs

# Verify network connectivity
docker network inspect local_chatbot-net
```

### Database Issues
```bash
# Check database connection
docker exec open-webui-db pg_isready

# Verify database initialization
docker logs open-webui-db
```

### AWS Deployment Issues
```bash
# Check CloudFormation status
aws cloudformation list-stacks

# View ECS task logs
aws logs get-log-events --log-group-name /ecs/horizons/webui
```

## Upgrading

### Local/Hybrid Mode
```bash
# Pull latest changes
git pull origin main

# Update containers
make local-down
docker compose pull
make local-up
```

### AWS Mode
```bash
# Update infrastructure
git pull origin main
make aws-plan
make aws-apply
```

## Next Steps

- Review the [Configuration Guide](../operations/configuration.md)
- Set up [Monitoring](../operations/monitoring.md)
- Implement [Security Best Practices](../security/overview.md)
- Join our [Community](../community/)

{% include footer.html %}
