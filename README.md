<div align="center">

# 🌅 Horizons: The OmniChat

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/evereven/horizons.svg)](https://github.com/evereven-tech/horizons-omnichat/releases/)
[![CI Status](https://github.com/evereven-tech/horizons-omnichat/workflows/CI/badge.svg)](https://github.com/evereven-tech/horizons-omnichat/actions)

A flexible and powerful chatbot platform that brings enterprise-grade LLM capabilities to your infrastructure.

[Getting Started](#-quick-start) •
[Documentation](https://evereven-tech.github.io/horizons/) •
[Contributing](CONTRIBUTING.md) •
[Community](https://github.com/evereven-tech/horizons-omnichat/discussions)

</div>

---

## 🌟 Features

- **Multi-Environment Support**: Deploy anywhere - from local development to full cloud infrastructure
- **Enterprise Security**: Built-in authentication, authorization, and audit trails
- **High Availability**: Cloud-native architecture with auto-scaling and fault tolerance
- **Cost Optimization**: Smart resource management with spot instances and scaling policies
- **Developer Friendly**: Comprehensive documentation and easy-to-use CLI

## 🚀 Deployment Flavors

Choose the deployment that best fits your needs:

| Flavor | Description | Documentation | Troubleshooting |
|--------|-------------|---------------|-----------------|
| **Local** | Simple setup with Ollama + Open-WebUI | [Local Setup Guide](docs/flavors/local.md) | [Local Diagnostics](docs/local-diagnostics.md) |
| **Hybrid** | Ollama + Open-WebUI + AWS Bedrock | [Hybrid Setup Guide](docs/flavors/hybrid.md) | [Hybrid Section](docs/flavors/hybrid.md#troubleshooting) |
| **AWS** | Full cloud deployment on AWS ECS | [AWS Setup Guide](docs/flavors/aws.md) | [AWS Section](docs/flavors/aws.md#troubleshooting) |
| **K8s** | Coming soon! | TBD | TBD |

## 🛠 Quick Start

1. **Prerequisites**
   - Docker and Docker Compose for local/hybrid modes
   - AWS credentials for hybrid/aws modes
   - Make utility

2. **Installation**
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

## 📚 Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [Configuration Guide](docs/operations/configuration.md)
- [Security Best Practices](docs/operations/security.md)
- [Monitoring & Troubleshooting](docs/operations/monitoring.md)
- [API Reference](docs/development/api.md)

## 🤝 Contributing

We love your input! Check out our [Contributing Guide](CONTRIBUTING.md) to get started.

- 🐛 [Report a bug](https://github.com/evereven-tech/horizons-omnichat/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/evereven-tech/horizons-omnichat/issues/new?template=feature_request.md)
- 📖 [Improve documentation](https://github.com/evereven-tech/horizons-omnichat/issues/new?template=documentation.md)

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

## 🙏 Acknowledgments

Built with:
- [Ollama](https://github.com/ollama/ollama)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [AWS Bedrock Access Gateway](https://github.com/aws-samples/bedrock-access-gateway)

## 📊 Project Status

![GitHub issues](https://img.shields.io/github/issues/evereven/horizons)
![GitHub pull requests](https://img.shields.io/github/issues-pr/evereven/horizons)
![Last commit](https://img.shields.io/github/last-commit/evereven/horizons)

---

<div align="center">
Made with ❤️ by <a href="https://www.evereven.tech">evereven</a>
</div>
