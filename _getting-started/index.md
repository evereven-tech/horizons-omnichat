---
layout: default
title: Getting Started
---

# Getting Started with Horizons OmniChat

Welcome to Horizons OmniChat! Let's guide you through your journey from initial setup to your first deployment.

## Your First Steps with Horizons

Before diving in, let's make sure you have everything you need. Horizons is designed to be flexible and powerful, but it does have some basic requirements to run smoothly.

### Setting Up Your Environment

Your system should meet these minimum specifications for the best experience:
- A modern machine with at least 8GB RAM and 4 CPU cores
- 20GB of available storage space
- Docker or Podman installed
- If you're planning to use GPU acceleration, an NVIDIA GPU with CUDA support

> 💡 **Pro Tip**: While these are minimum requirements, we recommend 16GB RAM and an SSD for optimal performance, especially when running multiple models.

### Installing Horizons

Getting started with Horizons is straightforward. Open your terminal and follow these steps:

```bash
# Clone the repository
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat

# Initialize your environment
make init
```

## Choosing Your Path

One of Horizons' key strengths is its flexibility in deployment. Let's explore which mode best suits your needs:

### Local Mode: Perfect for Getting Started

Local mode is your ideal starting point. It runs entirely on your infrastructure, offering complete privacy and control. This mode is perfect for:
- Development and testing
- Learning the platform
- Privacy-focused deployments
- Offline environments

To start in local mode:
```bash
cp local/.env.example local/.env
# Edit local/.env with your preferences
make local-up
```

### Hybrid Mode: The Best of Both Worlds

When you're ready to expand, hybrid mode combines local deployment with powerful cloud capabilities through AWS Bedrock. This gives you:
- Access to state-of-the-art cloud models
- Maintained privacy for sensitive data
- Cost-effective scaling options
- Flexibility in model selection

Setting up hybrid mode:
```bash
cp hybrid/.env.example hybrid/.env
cp hybrid/config.json.template hybrid/config.json
# Configure your AWS settings
make hybrid-up
```

### AWS Mode: Enterprise-Scale Solution

For organizations requiring full cloud capabilities, AWS mode provides:
- Automatic scaling
- High availability
- Enterprise-grade security
- Comprehensive monitoring

Deploy to AWS:
```bash
cp aws/terraform.tfvars.template aws/terraform.tfvars
cp aws/backend.hcl.example aws/backend.hcl
# Configure your AWS deployment
make aws-init
make aws-plan
make aws-apply
```

## Your First Conversation

Once deployed, accessing your Horizons instance is simple:
1. Navigate to http://localhost:3002 (for local/hybrid mode) or your AWS endpoint
2. Log in with your credentials
3. Select a model from the available options
4. Start your first conversation!

> 🌟 **Success Tip**: Start with smaller models like TinyLlama for quick testing, then move to more powerful models as needed.

## Making the Most of Horizons

### Essential Features to Explore

As you get comfortable with the basics, explore these powerful features:
- Model management for downloading and configuring different AI models
- Chat history and conversation management
- Advanced security controls

### Best Practices for Success

Here are some tips from our experience:
- Start with local mode to familiarize yourself with the platform
- Test different models to find the best fit for your use case
- Regular backups of your configuration and data
- Monitor system resources, especially when running larger models

## Getting Help

We're here to support your journey:
- Check our comprehensive [Documentation](../index.md)
- Join our [Community Discussions](https://github.com/evereven-tech/horizons-omnichat/discussions)
- Review common questions in our [FAQ](../community/faq.md)
- For enterprise users, explore our [Enterprise Support](../enterprise/support.md)

## Next Steps

Ready to dive deeper? Here are your next destinations:
- Explore detailed [Deployment Options](../deployment/)
- Learn about [Security Features](../security/)
- Understand [Architecture Components](../architecture/)
- Review [Operation Guidelines](../operations/)

{% include footer.html %}
