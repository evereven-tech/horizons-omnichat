---
layout: default
title: Frequently Asked Questions
---

# Frequently Asked Questions (FAQ)

## General Questions

### What is Horizons OmniChat?
Horizons OmniChat is an open-source chatbot platform that brings enterprise-grade LLM capabilities to your infrastructure, with flexible deployment options including local, hybrid, and AWS modes.

### What makes Horizons different from other chatbot platforms?
- Complete privacy control with on-premises deployment options
- Multiple deployment modes (Local/Hybrid/AWS)
- Enterprise-grade security and compliance features
- Integration with both local and cloud LLM models
- Open-source with enterprise support options

### Which deployment mode should I choose?

| Mode | Best For | Requirements | Key Benefits |
|------|----------|-------------|--------------|
| Local | Development, Testing, Privacy | 8GB RAM, Docker | Complete Control |
| Hybrid | Production, Cost-Effective | AWS Account, 8GB RAM | Flexibility |
| AWS | Enterprise, Scalability | AWS Account | Full Cloud Benefits |

## Technical Questions

### What are the system requirements?
See our detailed [System Requirements](../getting-started/requirements.md) guide, but in general:
- Minimum 8GB RAM
- 4+ CPU cores
- 20GB storage
- Docker/Podman
- (Optional) NVIDIA GPU

### Which models are supported?
#### Local Models (via Ollama)
- Llama 2
- Mistral
- TinyLlama
- Deepseek
- Qwen
- ALIA/Salamandra
- Custom models

#### Cloud Models (via AWS Bedrock)
- Claude (Anthropic)
- Titan (Amazon)
- Nova (Amazon)
- Jurassic (AI21)
- Command (Cohere)

### How do I update to the latest version?

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

## Deployment Questions

### Can I deploy Horizons in my own datacenter?
Yes! The Local and Hybrid modes are specifically designed for on-premises deployment. You maintain complete control over your infrastructure and data.

### How do I scale Horizons?
#### Local/Hybrid Mode
- Vertical scaling (more CPU/RAM)
- GPU acceleration
- Connection pooling

#### AWS Mode
- Auto-scaling groups
- Load balancing
- Multi-AZ deployment
- Elastic scaling

### How do I backup my data?
See our detailed [Backup Guide](../operations/backup.md), but in general:

```bash
# Local/Hybrid Mode
docker exec open-webui-db pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup.sql

# AWS Mode
aws rds create-db-snapshot --db-instance-identifier horizons-persistence-db
```

## Security Questions

### How is data protected?
- End-to-end encryption
- Data encryption at rest
- TLS 1.3 for all communications
- Role-based access control
- Audit logging
- See our [Security Overview](../security/overview.md)

### Does Horizons comply with GDPR/HIPAA/SOC2?
- GDPR compliance features included
- HIPAA compliance possible with Enterprise edition
- SOC 2 controls available in Enterprise edition
- See our [Compliance Guide](../security/compliance.md)

### How are updates and security patches handled?
- Regular security updates
- Automated vulnerability scanning
- Dependency updates
- Security advisories
- See our [Security Best Practices](../operations/security.md)

## Enterprise Questions

### What enterprise features are available?
- Advanced security controls
- High availability deployment
- Premium support
- Custom development
- Compliance assistance
- See our [Enterprise Guide](../enterprise/)

### How do I get enterprise support?
Contact our [Enterprise Support Team](../enterprise/support.md) for:
- Dedicated support
- SLA guarantees
- Custom features
- Training
- Consulting

### Can I customize Horizons for my organization?
Yes! Options include:
- Custom model integration
- UI customization
- Authentication integration
- Custom workflows
- See our [Development Guide](../development/)

## Troubleshooting

### Common Issues

#### Model Loading Issues
```bash
# Check Ollama status
docker logs ollama
docker exec ollama ollama list
```

#### Performance Issues
```bash
# Check resource usage
docker stats
nvidia-smi  # if using GPU
```

#### Connection Issues
```bash
# Verify services
docker compose ps
curl http://localhost:3002/health
```

See our [Troubleshooting Guide](../operations/troubleshooting.md) for more details.

## Getting Help

### Where can I find documentation?
- [Getting Started Guide](../getting-started/)
- [Deployment Options](../deployment/)
- [Operations Guide](../operations/)
- [Security Documentation](../security/)

### How do I report issues?
1. Check existing [GitHub Issues](https://github.com/evereven-tech/horizons-omnichat/issues)
2. Create a new issue with:
   - Deployment mode
   - Error messages
   - Steps to reproduce
   - System information

### How do I contribute?
See our [Contributing Guide](../development/contributing.md) for:
- Development setup
- Coding standards
- Pull request process
- Community guidelines

### Where can I get community support?
- [GitHub Discussions](https://github.com/evereven-tech/horizons-omnichat/discussions)
- [Discord Community](https://discord.gg/horizons)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/horizons-omnichat)

{% include footer.html %}
