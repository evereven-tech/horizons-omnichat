<div align="center">

# 🌅 Horizons: The OmniChat

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub tag](https://img.shields.io/github/tag/evereven-tech/horizons-omnichat?include_prereleases=&sort=semver&color=green)](https://github.com/evereven-tech/horizons-omnichat/releases/)
[![Documentation](https://img.shields.io/badge/docs-evereven.tech-blue)](https://evereven-tech.github.io/horizons-omnichat/)
[![pages build and deployment](https://github.com/evereven-tech/horizons-omnichat/workflows/pages%20build%20and%20deployment/badge.svg)](https://github.com/evereven-tech/horizons-omnichat/actions?query=workflow:"pages-build-deployment")
[![issues - horizons-omnichat](https://img.shields.io/github/issues/evereven-tech/horizons-omnichat)](https://github.com/evereven-tech/horizons-omnichat/issues)

A flexible and powerful chatbot platform that brings enterprise-grade LLM capabilities to your infrastructure.

![Horizons Demo](assets/intro_horizon.gif)

[Getting Started](#-quick-start) •
[Documentation](https://evereven-tech.github.io/horizons-omnichat/) •
[Contributing](CONTRIBUTING.md) •
[Discussions](https://github.com/evereven-tech/horizons-omnichat/discussions)

</div>

---

## 🌟 Features

- **Complete Privacy Control**
  - Deploy on your infrastructure
  - Data always under your control
  - No external service dependencies
- **Deployment Flexibility**
  - Local: Perfect for development and testing
  - Hybrid: Combine local resources with cloud services
  - Cloud: Full AWS deployment
  - Kubernetes: Coming soon!
- **Enterprise Capabilities**
  - Built-in authentication and authorization
  - Complete audit trails
  - High availability
  - Auto-scaling

## 🚀 Deployment Options

Choose the deployment that best fits your needs:

| Mode | Description | Documentation | Status |
|------|-------------|---------------|--------|
| **Local** | Simple setup with Ollama + Open-WebUI | [Guide](https://evereven-tech.github.io/horizons-omnichat/deployment/local.html) | ✅ Stable |
| **Hybrid** | Ollama + Open-WebUI + AWS Bedrock | [Guide](https://evereven-tech.github.io/horizons-omnichat/deployment/hybrid.html) | ✅ Stable |
| **AWS** | Full cloud deployment on AWS ECS | [Guide](https://evereven-tech.github.io/horizons-omnichat/deployment/aws.html) | ✅ Stable |
| **K8s** | Kubernetes deployment | [Guide](https://evereven-tech.github.io/horizons-omnichat/deployment/kubernetes.html) | 🚧 Coming Soon |

## 🛠 Quick Start

1. **Prerequisites**
   ```bash
   # Check your environment
   ./bin/check-dev-environment.sh
   ```

2. **Installation**
   ```bash
   # Clone the repository
   git clone https://github.com/evereven-tech/horizons-omnichat.git
   cd horizons-omnichat

   # Initialize the environment
   make init

   # Choose your deployment mode
   make local-up    # For local deployment
   make hybrid-up   # For hybrid deployment
   make aws-apply   # For AWS deployment
   ```

## 📚 Documentation

Our comprehensive documentation covers everything you need:

- [Getting Started Guide](https://evereven-tech.github.io/horizons-omnichat/getting-started/)
- [Architecture Overview](https://evereven-tech.github.io/horizons-omnichat/architecture/)
- [Security Best Practices](https://evereven-tech.github.io/horizons-omnichat/security/)
- [API Reference](https://evereven-tech.github.io/horizons-omnichat/development/api.html)
- [Operations Guide](https://evereven-tech.github.io/horizons-omnichat/operations/)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Development Setup](https://evereven-tech.github.io/horizons-omnichat/development/)
- [Pull Request Process](CONTRIBUTING.md#pull-request-process)

## 📜 License & Acknowledgments

This project is licensed under the [MIT License](LICENSE.md). See [NOTICE.md](NOTICE.md) for third-party licenses.

Built with:
- [Ollama](https://github.com/ollama/ollama)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [AWS Bedrock Access Gateway](https://github.com/aws-samples/bedrock-access-gateway)

---

<div align="center">
Made with 💚 by <a href="https://www.evereven.tech">evereven</a>
</div>
