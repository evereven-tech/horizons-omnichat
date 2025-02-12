<div align="center">

# 🌅 Horizons: The OmniChat

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/evereven/horizons.svg)](https://GitHub.com/evereven/horizons/releases/)
[![CI Status](https://github.com/evereven/horizons/workflows/CI/badge.svg)](https://github.com/evereven/horizons/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/evereven/horizons)](https://hub.docker.com/r/evereven/horizons)

A flexible and powerful chatbot platform that brings enterprise-grade LLM capabilities to your infrastructure.

[Getting Started](#getting-started) •
[Documentation](https://evereven.github.io/horizons/) •
[Contributing](CONTRIBUTING.md) •
[Community](https://github.com/evereven/horizons/discussions)

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

| Flavor | Description | Documentation |
|--------|-------------|---------------|
| **Local** | Simple setup with Ollama + Open-WebUI | [Local Setup Guide](docs/flavors/local.md) |
| **Hybrid** | Ollama + Open-WebUI + AWS Bedrock | [Hybrid Setup Guide](docs/flavors/hybrid.md) |
| **AWS** | Full cloud deployment on AWS ECS | [AWS Setup Guide](docs/flavors/aws.md) |

## 🛠 Quick Start

1. **Prerequisites**
   - Docker and Docker Compose for local/hybrid modes
   - AWS credentials for hybrid/aws modes
   - Make utility

2. **Installation**
   ```bash
   # Clone the repository
   git clone https://github.com/evereven/horizons.git
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

- 🐛 [Report a bug](https://github.com/evereven/horizons/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/evereven/horizons/issues/new?template=feature_request.md)
- 📖 [Improve documentation](https://github.com/evereven/horizons/issues/new?template=documentation.md)

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

## 🙏 Acknowledgments

Built with:
- [Ollama](https://github.com/ollama/ollama)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [AWS Bedrock](https://aws.amazon.com/bedrock/)

## 📊 Project Status

![GitHub issues](https://img.shields.io/github/issues/evereven/horizons)
![GitHub pull requests](https://img.shields.io/github/issues-pr/evereven/horizons)
![Last commit](https://img.shields.io/github/last-commit/evereven/horizons)

---

<div align="center">
Made with ❤️ by <a href="https://evereven.com">Evereven</a>
</div>
