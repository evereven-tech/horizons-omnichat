# Horizons: The OmniChat

A flexible chatbot solution that can be deployed in multiple environments:

- **Local**: Simple setup with Ollama + Open-WebUI
- **Hybrid**: Ollama + Open-WebUI + AWS Bedrock integration
- **AWS**: Full cloud deployment on AWS ECS with Cognito authentication
- **K8s**: Kubernetes deployment for cloud-agnostic installations

## Requirements
- Docker and Docker Compose for local/hybrid modes
- AWS credentials for hybrid/aws modes
- Kubernetes cluster for k8s mode

## Quick Start
1. Copy `.env.example` to `.env` and configure your environment
2. Initialize the repository: `make init`
3. Choose your deployment mode:
   - Local: `make local-up`
   - Hybrid: `make hybrid-up`
   - AWS: `make aws-apply`
   - K8s: `make k8s-apply` (WIP)

## Documentation
See the `docs/` directory for detailed setup and configuration instructions.
