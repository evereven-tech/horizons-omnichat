---
layout: default
title: Architecture Overview
---

# Architecture Overview

## System Architecture

Horizons OmniChat is designed with modularity and flexibility in mind, supporting multiple deployment modes while maintaining consistent functionality and security.

### Core Components

```mermaid
graph TD
    A[Client Layer] --> B[Application Layer]
    B --> C[Model Layer]
    B --> D[Persistence Layer]
    
    subgraph "Client Layer"
    A1[Web Interface]
    A2[API Clients]
    end
    
    subgraph "Application Layer"
    B1[Open WebUI]
    B2[Authentication]
    B3[Session Management]
    end
    
    subgraph "Model Layer"
    C1[Ollama]
    C2[Bedrock Gateway]
    end
    
    subgraph "Persistence Layer"
    D1[PostgreSQL/RDS]
    D2[File Storage/EFS]
    end
```

### Component Details

#### 1. Open WebUI
- **Purpose**: Main user interface and application logic
- **Features**:
  - Chat interface
  - Model management
  - User authentication
  - Session handling
- **Technology Stack**:
  - Svelte frontend
  - FastAPI backend
  - WebSocket support
  - REST APIs

#### 2. Ollama
- **Purpose**: Local model serving and inference
- **Features**:
  - Model management
  - Inference optimization
  - GPU acceleration
  - Custom model support
- **Supported Models**: Llama 2, Mistral, TinyLlama, etc.

#### 3. Bedrock Gateway
- **Purpose**: AWS Bedrock integration
- **Features**:
  - Model routing
  - Request transformation
  - Response handling
  - Authentication
- **Supported Models**: Claude, Titan, Jurassic, etc.

## Deployment Architectures

### 1. Local Mode

```mermaid
graph LR
    User --> WebUI
    WebUI --> Ollama
    WebUI --> PostgreSQL
    Ollama --> LocalModels
```

- **Components**:
  - Open WebUI container
  - Ollama container
  - PostgreSQL container
- **Features**:
  - Complete privacy
  - No cloud dependencies
  - Local model inference
  - Simplified deployment

### 2. Hybrid Mode

```mermaid
graph LR
    User --> WebUI
    WebUI --> Ollama
    WebUI --> BedrockGateway
    WebUI --> PostgreSQL
    Ollama --> LocalModels
    BedrockGateway --> AWSBedrock
```

- **Components**:
  - All Local Mode components
  - Bedrock Gateway container
  - AWS Bedrock integration
- **Features**:
  - Mixed model support
  - Cloud model access
  - Local infrastructure control
  - Cost optimization

### 3. AWS Mode
```mermaid
graph LR
    User --> ALB
    ALB --> WebUI-ECS-Fargate
    WebUI-ECS-Fargate --> Ollama-ECS-EC2
    WebUI-ECS-Fargate --> BedrockGateway-ECS-Fargate
    WebUI-ECS-Fargate --> RDS
    Ollama-ECS-EC2 --> EFS
    BedrockGateway-ECS-Fargate --> AWSBedrock
```

- **Components**:
  - Application Load Balancer
  - ECS Fargate for WebUI
  - ECS EC2 for Ollama
  - RDS for PostgreSQL
  - EFS for model storage
- **Features**:
  - Auto-scaling
  - High availability
  - Managed services
  - Enterprise security

## Data Flow

### 1. Chat Request Flow

```mermaid
sequenceDiagram
    participant User
    participant WebUI
    participant ModelBackend
    participant Database
    
    User->>WebUI: Send message
    WebUI->>Database: Log request
    WebUI->>ModelBackend: Forward to model
    ModelBackend->>WebUI: Return response
    WebUI->>Database: Store chat history
    WebUI->>User: Display response
```

### 2. Model Management Flow

```mermaid
sequenceDiagram
    participant Admin
    participant WebUI
    participant Ollama
    participant Storage
    
    Admin->>WebUI: Request model install
    WebUI->>Ollama: Download request
    Ollama->>Storage: Save model files
    Storage->>Ollama: Confirm storage
    Ollama->>WebUI: Installation complete
    WebUI->>Admin: Show success
```

## Security Architecture

- **Authentication**: Role-based access control
- **Encryption**: TLS for all communications
- **Data Protection**: Encrypted storage
- **Network Security**: Private subnets and security groups
- **Audit**: Comprehensive logging

## Performance Considerations

### 1. Resource Requirements
- **CPU**: Model inference, request handling
- **Memory**: Model loading, session management
- **Storage**: Model files, chat history
- **Network**: API communications, model downloads

### 2. Optimization Strategies
- Model quantization
- Response caching
- Connection pooling
- Load balancing

## Next Steps

- Review detailed [Component Architecture](components.md)
- Explore [Security Architecture](security.md)
- Check [Deployment Options](../deployment/)
- Learn about [Operations](../operations/)

{% include footer.html %}
