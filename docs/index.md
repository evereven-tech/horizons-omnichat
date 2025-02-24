---
layout: default
title: Home
---

<div align="center">

# 🌅 Horizons: The OmniChat

Welcome to Horizons, a flexible and powerful chatbot platform that brings enterprise-grade LLM capabilities to your infrastructure.

[Get Started](#quick-start){: .btn .btn-primary }
[Documentation](#documentation){: .btn }
[Enterprise](#editions)

</div>

## Introduction

Imagine deploying an enterprise-grade chatbot with complete data control and unmatched flexibility. That's exactly what Horizons delivers.

> 💡 **Tip**: New to Horizons? Start with our [Getting Started Guide](getting-started/) for a step-by-step introduction.

### Why Horizons?

In a world where data privacy and deployment flexibility are crucial, Horizons stands out by offering:

🔒 **Complete Privacy Control**
  
Your data never leaves your control. Unlike other solutions:
- Deploy on your infrastructure
- Keep your data under your control
- Operate without external service dependencies

⚠️ **Important**: Privacy isn't an add-on feature; it's core to our design.

🚀 **Deployment Flexibility**

We adapt Horizons to your needs, not the other way around:

- **Local Mode**: Perfect for development and testing
  > 💡 **Tip**: Ideal for teams starting out and need to experiment
- **Hybrid Mode**: Combine local resources with cloud services
  > ⚠️ **Note**: Requires AWS account for Bedrock features
- **AWS Mode**: Full cloud deployment
  > 💫 **Pro-tip**: Best choice for enterprise scalability
- **Kubernetes Mode**: For scalable infrastructures
  > 🚧 **In Development**: Coming soon

## Quick Start

Ready to begin? Here are the basic commands:

```bash
# Clone the repository
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons

# Initialize the environment
make init

# Choose your deployment mode
make local-up    # For local deployment
make hybrid-up   # For hybrid deployment
make aws-apply   # For AWS deployment
```

> ⚠️ **Important**: Make sure to check the [system requirements](getting-started/requirements.md) before starting.

## Documentation

We've organized our documentation with your learning journey in mind:

📚 **Getting Started**
- [Getting Started Guide](getting-started/): Your starting point
- [Requirements](getting-started/requirements.md): What you need
- [Installation](getting-started/installation.md): Step by step guide

🏗️ **Deployment Options**
- [Local](deployment/local.md): For development and testing
- [Hybrid](deployment/hybrid.md): Best of both worlds
- [AWS](deployment/aws.md): Enterprise scale
- [Kubernetes](deployment/kubernetes.md): Advanced orchestration

> 💡 **Tip**: Start with local mode to familiarize yourself with the platform before moving to more complex deployments.

## Editions

Horizons is available in three editions to suit different needs:

| Community | Cloud | Enterprise |
|-----------|-------|------------|
| Open Source | Cloud Deployment | Premium Support |
| Local Deployment | AWS Integration | Guaranteed SLA |
| Community Support | Pay-as-you-go | Consulting |
| [Get Started](getting-started/) | [Cloud Guide](deployment/aws) | [Enterprise](enterprise/) |

> 🌟 **Pro-tip**: Community Edition is perfect for starting and evaluating the platform.

## Built With

Horizons stands on the shoulders of giants:

- [Ollama](https://github.com/ollama/ollama): Local model engine
- [Open WebUI](https://github.com/open-webui/open-webui): User interface
- [AWS Bedrock Access Gateway](https://github.com/aws-samples/bedrock-access-gateway): AWS integration

## Need Help?

- 🤔 Have questions? Visit our [FAQ](community/faq.md)
- 🐛 Found a bug? Open an [Issue](https://github.com/evereven-tech/horizons-omnichat/issues)
- 💡 Looking for inspiration? Check our [Use Cases](community/showcase.md)
- 🤝 Need enterprise support? [Contact Us](enterprise/support.md)

---

<div align="center">
Built with 💚 by <a href="https://www.evereven.tech">evereven</a>
</div>
