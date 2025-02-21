---
layout: default
title: Getting Started
---

# Getting Started with Horizons OmniChat

Welcome to Horizons OmniChat! This guide will help you get started with our platform, from initial setup to your first deployment.

## Quick Start

### 1. Prerequisites
Check our [System Requirements](requirements.md) to ensure your environment meets the minimum specifications:
- 8GB RAM minimum
- 4+ CPU cores
- 20GB storage
- Docker/Podman installed
- (Optional) NVIDIA GPU

### 2. Installation
```bash
# Clone the repository
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat

# Initialize environment
make init
```

### 3. Choose Your Deployment Mode

| Mode | Best For | Key Features |
|------|----------|--------------|
| [Local](../deployment/local.md) | Development & Testing | Complete privacy, Local models |
| [Hybrid](../deployment/hybrid.md) | Production & Cost-effective | Mixed models, AWS integration |
| [AWS](../deployment/aws.md) | Enterprise & Scale | Full cloud, Auto-scaling |

## Deployment Options

### Local Mode
Perfect for development, testing, or privacy-focused deployments.
```bash
# Configure environment
cp local/.env.example local/.env
# Edit local/.env with your settings

# Start services
make local-up
```

### Hybrid Mode
Combines local deployment with AWS Bedrock capabilities.
```bash
# Configure environment
cp hybrid/.env.example hybrid/.env
cp hybrid/config.json.template hybrid/config.json
# Edit both files with your AWS settings

# Start services
make hybrid-up
```

### AWS Mode
Full cloud deployment with enterprise features.
```bash
# Configure deployment
cp aws/terraform.tfvars.template aws/terraform.tfvars
cp aws/backend.hcl.example aws/backend.hcl
# Edit with your AWS configuration

# Deploy infrastructure
make aws-init
make aws-plan
make aws-apply
```

## First Steps

### 1. Access the Platform
- Local/Hybrid mode: http://localhost:3002
- AWS mode: Check ALB DNS in AWS Console

### 2. Configure Authentication
- Set up admin credentials
- Configure user access
- (AWS mode) Set up Cognito

### 3. Install Models
1. Access model management
2. Choose from available models:
   - Local: Llama 2, Mistral, TinyLlama
   - Cloud: Claude, Titan, Jurassic (via AWS Bedrock)
3. Download and configure selected models

## Basic Usage

### Chat Interface
1. Select a model
2. Start a new conversation
3. Enter your prompt
4. View model response
5. Continue conversation

### Model Management
- Download new models
- Update existing models
- Configure model parameters
- Monitor model performance

### User Management
- Create user accounts
- Assign roles
- Manage permissions
- Monitor usage

## Next Steps

### 1. Explore Advanced Features
- Custom model configuration
- API integration
- Backup and recovery
- Monitoring and logging

### 2. Security Configuration
- Review [Security Guide](../security/overview.md)
- Configure authentication
- Set up encryption
- Implement access controls

### 3. Operations Setup
- Configure [Monitoring](../operations/monitoring.md)
- Set up [Backup Strategy](../operations/backup.md)
- Review [Troubleshooting Guide](../operations/troubleshooting.md)

## Common Questions

### How do I update the platform?
```bash
# Local/Hybrid Mode
git pull origin main
make local-down   # or hybrid-down
docker compose pull
make local-up     # or hybrid-up

# AWS Mode
git pull origin main
make aws-plan
make aws-apply
```

### How do I backup my data?
See our [Backup Guide](../operations/backup.md) for detailed instructions.

### Where can I get help?
- Check our [FAQ](../community/faq.md)
- Join [Community Discussions](https://github.com/evereven-tech/horizons-omnichat/discussions)
- Review [Troubleshooting Guide](../operations/troubleshooting.md)
- Contact [Enterprise Support](../enterprise/support.md)

## Additional Resources

- [Architecture Overview](../architecture/)
- [Development Guide](../development/)
- [Community Resources](../community/)
- [Enterprise Features](../enterprise/)

{% include footer.html %}
