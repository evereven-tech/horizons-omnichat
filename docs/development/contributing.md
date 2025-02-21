---
layout: default
title: Contributing Guide
---

# Contributing to Horizons OmniChat

## Introduction

Thank you for your interest in contributing to Horizons OmniChat! This guide will help you understand our development process and how you can contribute effectively to the project.

## Code of Conduct

Our project adheres to a Code of Conduct that we expect all participants to follow. Please read [our Code of Conduct](../community/code-of-conduct.md) before contributing.

## Getting Started

### Development Environment Setup

1. **Fork and Clone**
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/horizons-omnichat.git
cd horizons-omnichat

# Add upstream remote
git remote add upstream https://github.com/evereven-tech/horizons-omnichat.git
```

2. **Install Dependencies**
```bash
# Initialize development environment
make init

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

3. **Run Local Environment**
```bash
# Start local development environment
make local-up

# Check services
make local-status
```

## Development Workflow

### 1. Branch Strategy

- `main`: Production-ready code
- `develop`: Development branch
- Feature branches: `feature/your-feature`
- Bug fixes: `fix/issue-description`
- Documentation: `docs/topic-description`

### 2. Making Changes

```bash
# Create a new branch
git checkout -b feature/your-feature

# Make your changes
# ... edit files ...

# Run tests
make test

# Run linters
make lint
```

### 3. Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```bash
# Format
<type>(<scope>): <description>

# Examples
feat(webui): add new chat interface component
fix(ollama): resolve model loading issue
docs(deployment): update AWS installation guide
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

### 4. Pull Request Process

1. **Update your branch**
```bash
git fetch upstream
git rebase upstream/main
```

2. **Create Pull Request**
- Use our PR template
- Include comprehensive description
- Link related issues
- Add appropriate labels

3. **PR Checklist**
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Code follows style guide
- [ ] CI checks pass

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific test suite
make test-unit
make test-integration

# Run with coverage
make test-coverage
```

### Writing Tests

```python
# Example test
from unittest import TestCase

class TestYourFeature(TestCase):
    def setUp(self):
        self.feature = YourFeature()

    def test_feature_behavior(self):
        result = self.feature.do_something()
        self.assertEqual(result, expected_value)
```

## Documentation

### Building Documentation

```bash
# Serve documentation locally
make serve

# Build documentation
make docs-build
```

### Documentation Guidelines

1. **Structure**
- Clear headings
- Logical flow
- Code examples
- Diagrams when helpful

2. **Style**
- Clear and concise
- Proper grammar
- Consistent formatting
- Updated links

## Code Style Guide

### Python Code

We follow PEP 8 with some modifications:

```python
# Good
def process_request(self, request: Request) -> Response:
    """Process incoming request.
    
    Args:
        request: The incoming request object
        
    Returns:
        Response object
    """
    if not request.is_valid():
        raise ValidationError("Invalid request")
    
    return self._handle_request(request)
```

### JavaScript/TypeScript Code

We follow StandardJS with some modifications:

```javascript
// Good
async function handleMessage(message) {
  try {
    const response = await processMessage(message)
    return response
  } catch (error) {
    console.error('Message processing failed:', error)
    throw error
  }
}
```

## Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):
- MAJOR.MINOR.PATCH
- Example: 1.2.3

### Release Steps

1. **Prepare Release**
```bash
# Update version
make version-bump VERSION=1.2.3

# Update changelog
make changelog
```

2. **Create Release**
```bash
# Tag release
git tag -a v1.2.3 -m "Release v1.2.3"

# Push to upstream
git push upstream v1.2.3
```

## Getting Help

- Join our [Discord Community](https://discord.gg/horizons)
- Check [FAQ](../community/faq.md)
- Open [GitHub Discussions](https://github.com/evereven-tech/horizons-omnichat/discussions)

## Next Steps

1. Browse [Good First Issues](https://github.com/evereven-tech/horizons-omnichat/labels/good%20first%20issue)
2. Review [Development API](api.md)
3. Join [Developer Discussions](../community/discussions.md)

{% include footer.html %}
