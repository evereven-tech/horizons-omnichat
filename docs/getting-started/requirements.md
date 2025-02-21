---
layout: default
title: System Requirements
---

# System Requirements

Before installing Horizons OmniChat, ensure your system meets the following requirements based on your chosen deployment mode.

## Hardware Requirements

### Minimum Requirements (Local/Hybrid Mode)
- **CPU**: 4 cores
- **RAM**: 8GB
- **Storage**: 20GB free space
- **Network**: Broadband internet connection
- **GPU** (Optional): NVIDIA GPU with CUDA support for improved performance

### Recommended Requirements
- **CPU**: 8+ cores
- **RAM**: 16GB or more
- **Storage**: 50GB+ SSD storage
- **GPU**: NVIDIA GPU with 8GB+ VRAM

### AWS Mode Requirements
- AWS Account with appropriate permissions
- Sufficient quota for required services:
  - ECS/Fargate
  - RDS
  - ElastiCache
  - Application Load Balancer
  - AWS Bedrock (if using managed models)

## Software Requirements

### Local/Hybrid Mode
- **Operating System**:
  - Linux (Ubuntu 20.04+, Debian 11+, or similar)
  - macOS 12+ (Intel or Apple Silicon)
  - Windows 10/11 with WSL2
- **Container Runtime**:
  - Docker Engine 20.10+ or
  - Podman 3.0+
- **Other Tools**:
  - Make
  - Git
  - curl or wget

### AWS Mode
Additional requirements:
- **AWS CLI** v2.0+
- **Terraform** v1.0+
- **Valid SSL certificate** (for production deployments)
- **Domain name** (for production deployments)

## Network Requirements

### Local Mode
- Ports required:
  - 3002 (Web UI)
  - 11434 (Ollama API)
  - 5432 (PostgreSQL)

### Hybrid Mode
- All Local Mode requirements
- AWS connectivity:
  - Outbound access to AWS Bedrock endpoints
  - Valid AWS credentials configured

### AWS Mode
- VPC with:
  - Public and private subnets
  - NAT Gateway or Internet Gateway
  - Route53 Hosted Zone (for domain management)

## AWS IAM Permissions

When deploying in Hybrid or AWS mode, your AWS credentials need the following permissions:

```yaml
- bedrock:*
- ecs:*
- ec2:*
- rds:*
- elasticache:*
- iam:*
- s3:*
- route53:*
- acm:*
```

## Pre-deployment Checklist

- [ ] Hardware meets minimum requirements
- [ ] Required software is installed and configured
- [ ] Network ports are available
- [ ] AWS credentials configured (for Hybrid/AWS mode)
- [ ] SSL certificate available (for production)
- [ ] Domain name configured (for production)
- [ ] Sufficient disk space available
- [ ] Required AWS services enabled (for AWS mode)

## Next Steps

Once you have verified all requirements are met, proceed to the [Installation Guide](installation.md) to begin setting up Horizons OmniChat.

{% include footer.html %}
