---
layout: default
title: Operations Security
---

# Security Best Practices

## Authentication

### Local Mode
- Default basic authentication
- Configure strong passwords

### AWS Mode
- AWS Cognito integration
- MFA support
- Custom domain with SSL/TLS

## Network Security

### Local/Hybrid Mode
- Internal network isolation
- TLS encryption for API endpoints
- Secure environment variable handling

### AWS Mode
- VPC deployment
- Private subnets for compute
- Security groups for service isolation
- ALB with SSL termination

## Access Control
- Role-based access control
- API key management
- Session management
- Audit logging

## Data Protection
- Database encryption
- Secure secret management
- TLS for data in transit

{% include footer.html %}
