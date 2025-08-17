# AGENT.md - Horizons OmniChat Development System Prompt

## Project Overview

You are working on **Horizons OmniChat**, an enterprise-grade LLM chatbot platform that provides flexible deployment options with complete privacy control. This project enables organisations to deploy powerful AI capabilities on their own infrastructure with multiple deployment modes: local, hybrid, cloud (AWS), and Kubernetes.

### Core Technologies
- **Infrastructure**: Terraform, Docker/Podman, AWS ECS, Kubernetes
- **Frontend**: Open WebUIPython (Javascript/Vue)
- **Backend**: Ollama, LiteLLM, AWS Bedrock Gateway
- **AI/ML**: AWS Bedrock or other API  Providers
- **Data**: PostgreSQL, S3
- **Monitoring**: CloudWatch, ECS Service Connect

## Architecture Guidelines

### Multi-Environment Design
- **Local**: Use LLM Models with ONLY local resources with Ollama + Open WebUI
- **Hybrid**: Use as well Local resources as external providers like AWS Bedrock integration,...
- **AWS**: Full cloud deployment on ECS & RDS
- **Kubernetes**: Container orchestration (future implementation)

### Service Architecture Patterns
- **Distributed**: Each component (WebUI, Ollama, Bedrock Gateway) as separate services
- **Health Checks**: Comprehensive health monitoring for all services
- **Service Discovery**: Use Docker networks and ECS Service Connect
- **Load Balancing**: Application Load Balancer for AWS deployments

### Security Principles
- **Zero Trust**: No implicit trust between components
- **Least Privilege**: Minimal required permissions
- **Encryption**: TLS in transit, encryption at rest
- **Secrets Management**: AWS Secrets Manager, environment variables
- **Network Isolation**: VPC, security groups, private subnets

## Development Workflow

### Branch Strategy
- **main**: Production-ready code
- **dev**: Integration branch
- **feature/***: Feature development

### Commit Standards

Use conventional commits with British spelling with a prefix from this list:

* feat: new feadures
* doc: related with documentation
* fix: corrections or bugs
* refactor: improve some implementation
* chore: maintenance and repetitive actions

Some examples could be:

```bash
feat: optimise model loading behaviour
fix: correct colour rendering in dark mode
docs: update deployment guide with optimised settings
```

## Code Style & Conventions

### Language Standards
- **Code Language**: English (British spelling preferred)
  - Use "colour" instead of "color"
  - Use "behaviour" instead of "behavior"
  - Use "optimise" instead of "optimize"
  - Use "centre" instead of "center"
- **Comments**: English (British spelling)
- **Documentation**: English (British spelling)
- **Variable/Function Names**: Use British English where applicable

### Formatting Standards
- **Indentation**: 2 spaces for all files (YAML, JSON, Terraform, Python)
- **Line Endings**: LF (Unix-style)
- **Encoding**: UTF-8
- **Final Newline**: Always include
- **Trailing Whitespace**: Remove (except in Markdown)

## Configuration Management

### Environment Variables
```bash
# Use descriptive names with British spelling where applicable
WEBUI_COLOUR_SCHEME=corporate
OLLAMA_OPTIMISATION_LEVEL=high
BEDROCK_BEHAVIOUR_CONFIG=conservative
```

### Configuration Files
- **Terraform**: Use `.tfvars` for environment-specific values
- **Docker**: Use `.env` files for container configuration
- **Application**: Use JSON/YAML for structured configuration

### Secrets Handling
- **Never commit secrets** to version control
- **Use AWS Secrets Manager** for production
- **Use .env files** for local development
- **Template files**: Provide `.example` files for reference

## Documentation Standards

### README Structure
- **Clear project description**
- **Quick start guide**
- **Deployment options table**
- **Links to comprehensive documentation**

## Environment Patterns

### Local Use
```bash
# Initialise development environment
make init
make local-up

# Check environment prerequisites
./bin/check-dev-environment.sh
```

### Local & Hybrid use
```bash
# Configure hybrid environment with optimised settings
make hybrid-validate
make hybrid-up
```

### AWS Cloud use
```bash
# Deploy with infrastructure optimisation
make aws-validate
make aws-plan
make aws-apply
```

### Container Standards
- **Base Images**: Use official, minimal images
- **Multi-stage Builds**: Optimise image size
- **Health Checks**: Include comprehensive health endpoints
- **Resource Limits**: Set appropriate CPU/memory limits
- **Security**: Run as non-root user where possible

### Code Review Checklist
- [ ] Follows British English spelling conventions
- [ ] Has appropriate logging and monitoring
- [ ] Includes security considerations
- [ ] Updates relevant documentation
- [ ] Optimises for performance and cost

---

**Remember**: This is an enterprise-grade platform. Prioritise security, reliability, and maintainability in all decisions. When in doubt, favour explicit configuration over implicit behaviour, and always consider the operational impact of changes.
