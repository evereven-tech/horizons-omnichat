# AGENT.md - Horizons OmniChat System Prompt

## Project Overview

You are working on **Horizons OmniChat**, an enterprise-grade LLM chatbot platform that provides flexible deployment options with complete privacy control. This project enables organisations to deploy powerful AI capabilities on their own infrastructure with multiple deployment modes: local, hybrid, cloud (AWS), and Kubernetes.

### Core Technologies
- **Infrastructure**: Terraform, Docker/Podman, AWS ECS, Kubernetes
- **Backend**: Python (FastAPI), Shell scripting
- **AI/ML**: Ollama, Open WebUI, AWS Bedrock, LiteLLM
- **Data**: PostgreSQL, S3
- **Monitoring**: CloudWatch, ECS Service Connect

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

### File-Specific Standards

#### Python Code
```python
# Use British spelling in comments and docstrings
def optimise_model_performance():
    """Optimise the model's behaviour for better performance."""
    # Configure colour scheme for the interface
    colour_config = {"primary_colour": "#007bff"}
    return colour_config
```

#### Terraform
```hcl
# Use British spelling in comments and descriptions
variable "availability_zones" {
  description = "List of availability zones for optimised distribution"
  type        = list(string)
}

resource "aws_instance" "web_server" {
  # Configure instance behaviour
  instance_type = var.instance_type
  
  tags = {
    Name        = "horizons-web-server"
    Environment = var.environment
    # Use British spelling in tag values where appropriate
    Purpose     = "optimised-web-serving"
  }
}
```

#### YAML/Docker Compose
```yaml
# Service configuration with British spelling in comments
services:
  web-ui:
    # Optimise container behaviour for production
    container_name: horizons-webui
    environment:
      # Configure colour scheme
      - UI_COLOUR_SCHEME=corporate
```

## Architecture Guidelines

### Multi-Environment Design
- **Local**: Development and testing with Ollama + Open WebUI
- **Hybrid**: Local resources + AWS Bedrock integration
- **AWS**: Full cloud deployment on ECS with auto-scaling
- **Kubernetes**: Container orchestration (future implementation)

### Service Architecture Patterns
- **Microservices**: Each component (WebUI, Ollama, Bedrock Gateway) as separate services
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
- **develop**: Integration branch
- **feature/***: Feature development
- **hotfix/***: Critical fixes

### Commit Standards
```bash
# Use conventional commits with British spelling
feat: optimise model loading behaviour
fix: correct colour rendering in dark mode
docs: update deployment guide with optimised settings
```

### Pre-commit Requirements
All code must pass these checks:
- **Linting**: terraform fmt, markdownlint
- **Security**: gitleaks, terraform trivy
- **Quality**: terraform validate
- **Cost Analysis**: infracost breakdown
- **Format**: trailing whitespace, end-of-file-fixer

### Testing Standards
- **Unit Tests**: For all Python functions
- **Integration Tests**: For service interactions
- **Infrastructure Tests**: Terraform validation
- **Security Tests**: Container and infrastructure scanning

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

### Code Documentation
```python
def configure_llm_behaviour(model_name: str, optimisation_level: str) -> dict:
    """
    Configure the behaviour of the specified LLM model.
    
    Args:
        model_name: Name of the model to configure
        optimisation_level: Level of optimisation (low, medium, high)
    
    Returns:
        Dictionary containing the optimised configuration
        
    Raises:
        ValueError: If optimisation_level is not recognised
    """
```

### Infrastructure Documentation
```hcl
# Terraform resources should include comprehensive descriptions
resource "aws_ecs_service" "webui" {
  name = "horizons-webui"
  
  # Configure service behaviour for optimal performance
  desired_count = var.webui_desired_count
  
  # Health check configuration optimised for WebUI startup time
  health_check_grace_period_seconds = 300
}
```

## Deployment Patterns

### Local Development
```bash
# Initialise development environment
make init
make local-up

# Check environment prerequisites
./bin/check-dev-environment.sh
```

### Hybrid Deployment
```bash
# Configure hybrid environment with optimised settings
make hybrid-validate
make hybrid-up
```

### AWS Production
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

## Quality Assurance

### Code Quality Gates
1. **Pre-commit Hooks**: Must pass all configured checks
2. **Security Scanning**: No high/critical vulnerabilities
3. **Performance**: Infrastructure cost analysis
4. **Documentation**: All public APIs documented
5. **Testing**: Minimum test coverage requirements

### Monitoring & Observability
- **Logging**: Structured JSON logging with correlation IDs
- **Metrics**: CloudWatch metrics for all services
- **Tracing**: Distributed tracing for request flows
- **Alerting**: Proactive alerts for service degradation

### Performance Standards
- **Response Time**: API responses < 200ms (95th percentile)
- **Availability**: 99.9% uptime for production services
- **Scalability**: Auto-scaling based on CPU/memory utilisation
- **Resource Optimisation**: Regular cost and performance reviews

## Security & Compliance

### Security Requirements
- **Authentication**: Multi-factor authentication for admin access
- **Authorisation**: Role-based access control (RBAC)
- **Audit Logging**: Complete audit trail for all actions
- **Data Protection**: Encryption at rest and in transit
- **Network Security**: VPC, security groups, NACLs

### Compliance Considerations
- **Data Residency**: Configurable data location
- **Privacy**: No external service dependencies by default
- **Audit**: Complete audit trails for compliance reporting
- **Backup**: Automated backup and recovery procedures

## Error Handling & Logging

### Error Handling Patterns
```python
import logging

logger = logging.getLogger(__name__)

def process_llm_request(request_data: dict) -> dict:
    """Process LLM request with proper error handling."""
    try:
        # Optimise request processing
        result = optimise_request(request_data)
        logger.info("Request processed successfully", extra={
            "request_id": request_data.get("id"),
            "processing_time": result.get("duration")
        })
        return result
    except ValidationError as e:
        logger.warning("Request validation failed", extra={
            "request_id": request_data.get("id"),
            "error": str(e)
        })
        raise
    except Exception as e:
        logger.error("Unexpected error processing request", extra={
            "request_id": request_data.get("id"),
            "error": str(e)
        })
        raise
```

### Logging Standards
- **Structured Logging**: Use JSON format for machine readability
- **Log Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Correlation IDs**: Track requests across services
- **Sensitive Data**: Never log secrets or personal information

## Contribution Guidelines

### Before Contributing
1. **Read Documentation**: Understand the project architecture
2. **Environment Setup**: Run `./bin/check-dev-environment.sh`
3. **Pre-commit Setup**: Install and configure pre-commit hooks
4. **Testing**: Ensure all tests pass locally

### Pull Request Requirements
- **Description**: Clear description of changes and rationale
- **Testing**: Include tests for new functionality
- **Documentation**: Update relevant documentation
- **Security**: Consider security implications
- **Performance**: Assess performance impact

### Code Review Checklist
- [ ] Follows British English spelling conventions
- [ ] Includes comprehensive error handling
- [ ] Has appropriate logging and monitoring
- [ ] Includes security considerations
- [ ] Updates relevant documentation
- [ ] Passes all quality gates
- [ ] Optimises for performance and cost

---

**Remember**: This is an enterprise-grade platform. Prioritise security, reliability, and maintainability in all decisions. When in doubt, favour explicit configuration over implicit behaviour, and always consider the operational impact of changes.
