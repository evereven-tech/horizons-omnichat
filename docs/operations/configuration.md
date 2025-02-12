# Configuration Guide

## Environment Setup

### Local/Hybrid Mode
Copy the example environment file:
```bash
cp local/.env.example local/.env   # For local mode
cp hybrid/.env.example hybrid/.env # For hybrid mode
```

### AWS Mode
Copy the terraform variables template:
```bash
cp aws/terraform.tfvars.template aws/terraform.tfvars
```

## Configuration Options

### Database Settings
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password

### Open WebUI Settings
- `WEBUI_SECRET_KEY`: Secret key for session management
- `WEBUI_VERSION`: Version of Open WebUI to use

### Ollama Settings
- `OLLAMA_USE_GPU`: Enable/disable GPU support
- `INSTALLED_MODELS`: Comma-separated list of models to install

### AWS Settings (Hybrid/AWS modes)
- `AWS_REGION`: AWS region for services
- `BEDROCK_API_KEY`: API key for Bedrock gateway

## Advanced Configuration
See terraform.tfvars.template for full AWS deployment options
