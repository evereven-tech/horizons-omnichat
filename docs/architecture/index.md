---
layout: default
title: Architecture Overview
---

# Architecture Overview

## System Architecture

Horizons OmniChat is engineered with modularity and flexibility at its core, enabling a robust platform that adapts to diverse deployment scenarios while maintaining consistent functionality and security. Our architecture is designed to scale from individual development environments to enterprise-grade deployments without compromising on performance or security features.

### Core Components

The system is thoughtfully divided into four interconnected layers, each designed to handle specific aspects of the platform's functionality while working in harmony with the others:

```mermaid
graph LR
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
Open WebUI serves as the primary interface and application logic hub of Horizons. Built with modern technologies, it provides a seamless experience for both users and administrators. The component leverages Svelte for the frontend, delivering exceptional performance through its compiled approach, while FastAPI powers the backend with its high-performance asynchronous capabilities. This combination enables:

- A responsive and intuitive chat interface that adapts to various use cases
- Comprehensive model management capabilities for administrators
- Robust user authentication and session management
- Real-time communication through WebSocket support
- RESTful APIs for seamless integration with external systems

#### 2. Ollama
Ollama functions as our local model serving engine, providing sophisticated AI capabilities directly within your infrastructure. It's designed to optimize model performance while maintaining flexibility:

- Efficient model management with support for multiple model formats
- Intelligent inference optimization based on available hardware
- GPU acceleration capabilities for enhanced performance
- Extensive support for custom models and fine-tuning
- Advanced caching mechanisms for improved response times

#### 3. Bedrock Gateway
The Bedrock Gateway represents our bridge to AWS's powerful AI capabilities, thoughtfully designed to provide seamless access to cloud-based models while maintaining security and performance:

- Intelligent request routing and load balancing
- Sophisticated request transformation for optimal model interaction
- Robust error handling and retry mechanisms
- Enterprise-grade authentication and security controls
- Comprehensive monitoring and logging capabilities

## Deployment Architectures

### 1. Local Mode

```mermaid
graph LR
    User --> WebUI
    WebUI --> Ollama
    WebUI --> PostgreSQL
    Ollama --> LocalModels
```

Local mode provides a complete, self-contained environment perfect for development, testing, and privacy-focused deployments. This architecture ensures:

- Complete data sovereignty with all components running locally
- Simplified deployment and maintenance procedures
- Perfect for development and testing environments
- Ideal for organizations with strict data privacy requirements

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
  - ECS EC2 for Ollama with GPU Optimisation
  - RDS for PostgreSQL
  - EFS for model storage
- **Features**:
  - Auto-scaling **(ENTERPRISE)**
  - High availability **(ENTERPRISE)**
  - Managed services 
  - Enterprise security **(ENTERPRISE)**

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

## Next Steps

- Review detailed [Component Architecture](components.md)
- Explore [Security Architecture](security.md)
- Check [Deployment Options](../deployment/)
- Learn about [Operations](../operations/)

{% include footer.html %}
