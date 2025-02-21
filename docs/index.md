---
layout: default
title: Home
---

<div align="center">

# 🌅 Horizons: The OmniChat

A flexible and powerful chatbot platform that brings enterprise-grade LLM capabilities to your infrastructure.

[Get Started](#quick-start){: .btn .btn-primary }
[Documentation](#documentation){: .btn }
[Enterprise](#enterprise){: .btn }

</div>

## Why Horizons

Horizons is an **open source** chatbot platform designed for organizations that need:

- 🔒 **Complete Privacy Control**
  - Deploy on your infrastructure
  - Data always under your control
  - No external service dependencies

- 🚀 **Deployment Flexibility**
  - Local: Perfect for development and testing
  - Hybrid: Combine local resources with cloud services
  - Cloud: Full AWS deployment
  - Kubernetes: For scalable infrastructures

- 💼 **Enterprise Capabilities**
  - Built-in authentication and authorization
  - Complete audit trails
  - High availability
  - Auto-scaling

## Quick Start

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

## Documentation

- [📚 Getting Started Guide](getting-started/)
- [🏗️ Deployment Options](deployment/)
- [🔧 Operations](operations/)
- [🔐 Security](security/)
- [👩‍💻 Development](development/)

## Enterprise

Horizons is available in three editions:

| Community | Cloud | Enterprise |
|-----------|-------|------------|
| Open Source | Cloud Deployment | Premium Support |
| Local Deployment | AWS Integration | Guaranteed SLA |
| Community Support | Pay-as-you-go | Consulting |
| [Get Started](getting-started/) | [Cloud Guide](deployment/aws) | [Enterprise](enterprise/) |

## Built With

- [Ollama](https://github.com/ollama/ollama)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [AWS Bedrock Access Gateway](https://github.com/aws-samples/bedrock-access-gateway)

---

<div align="center">
Built with 💚 by <a href="https://www.evereven.tech">evereven</a>
</div>
