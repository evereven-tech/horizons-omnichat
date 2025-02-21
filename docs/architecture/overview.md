# Architecture Overview

## Components

### Core Services
- **Open WebUI**: Main user interface and chat frontend
- **Ollama**: Local model serving and inference
- **Bedrock Gateway**: AWS Bedrock integration layer

### Deployment Options
1. **Local**: Single machine deployment with Ollama
2. **Hybrid**: Local deployment with AWS Bedrock integration and Ollama
3. **AWS**: Full cloud infrastructure deployment on AWS

## System Architecture

### Local/Hybrid Mode
```
[User] -> [Open WebUI] -> [Ollama/Bedrock Gateway] -> [LLM Models]
```

### AWS Mode
```
[User] -> [ALB] -> [Open WebUI (ECS/Fargate)] -> [Bedrock Gateway (ECS/Fargate)/Ollama (ECS/EC2)] -> [Models]
```

## Data Flow
1. Select appropriated model at WebUI
1. User sends request through WebUI
1. Request routed to appropriate model backend
1. Response processed and returned to user
1. Chat history stored in PostgreSQL

## Security Considerations
- Authentication via Cognito (AWS mode)
- TLS encryption for all traffic
- Private VPC deployment
- Least privilege IAM roles
