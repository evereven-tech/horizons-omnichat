---
layout: default
title: Security Overview
---

# Security Overview

When we designed Horizons OmniChat, we knew that security couldn't be an afterthought - it needed to be woven into the very fabric of the platform. Whether you're deploying locally for development or scaling up to enterprise-level AWS deployments, every aspect of Horizons is built with security at its core.

## Understanding Our Security Philosophy

Security in Horizons isn't just about checking boxes or meeting compliance requirements. It's about providing you with a platform that protects your data, your users, and your organization at every level. Let's explore how we achieve this.

## Defense in Depth

Think of Horizons' security like layers of an onion - each layer providing additional protection. At the outermost layer, we have our application security, ensuring that only authorized users can access your chatbot. Dive deeper, and you'll find network security protecting your data in transit, and at the core, you'll discover our data protection mechanisms keeping your information safe at rest.

### Securing Your Data

Your conversations with AI models often contain sensitive information. That's why we've implemented end-to-end encryption across all deployment modes. In Local mode, your data never leaves your infrastructure. In Hybrid mode, we ensure secure communication with AWS Bedrock while maintaining local control. And in AWS mode, we leverage the full power of AWS's security infrastructure.

### Authentication That Adapts

We understand that different organizations have different security needs. That's why our authentication system scales with your deployment:

In Local mode, you start with robust basic authentication - perfect for development and testing. Move to Hybrid mode, and you gain AWS IAM integration for enhanced security. In AWS mode, you get the full power of Cognito user pools, complete with MFA support and enterprise-grade authentication.

### Network Protection

Network security in Horizons isn't just about firewalls and encryption (though we have those too). We've created isolated network environments for each component, ensuring that even if one part of the system is compromised, the rest remains secure.

For AWS deployments, we take this further by placing services in private subnets, using security groups for granular access control, and implementing AWS WAF for additional protection against web threats.

## Real-World Security

Let's look at how this all comes together in practice. When a user makes a request:

1. First, their credentials are verified through our authentication layer
2. The request is encrypted and transmitted through secure channels
3. Our authorization system checks if they have permission for the requested action
4. The action is logged for audit purposes
5. The response is encrypted and returned through the same secure channel

This happens automatically for every interaction, ensuring consistent security without impacting performance.

## Enterprise-Grade Features

For organizations requiring additional security measures, our Enterprise edition includes advanced features like:

- Enhanced audit logging for complete visibility into system usage
- Custom security policies to match your organization's requirements
- Advanced threat detection and prevention
- Integration with enterprise security tools
- Compliance reporting for regulated industries

## Growing with Your Security Needs

As your organization grows and your security requirements evolve, Horizons grows with you. Start with Local mode's fundamental security features, add AWS security capabilities in Hybrid mode, or deploy the full suite of enterprise security features in AWS mode.

## Next Steps

Ready to dive deeper into securing your Horizons deployment? Check out our detailed guides:

- [Security Architecture](../architecture/security.md) - Understanding the technical implementation
- [Compliance Guide](compliance.md) - Meeting regulatory requirements
- [Privacy Guide](privacy.md) - Protecting user data
- [Operations Security](../operations/security.md) - Day-to-day security management

{% include footer.html %}
