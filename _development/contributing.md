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

# Run tests (feature in roadmap)
make test

# Run linters (feature in roadmap)
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
- Include comprehensive description
- Link related issues
- Add appropriate labels

3. **PR Checklist**
- [ ] Documentation updated
- [ ] Code follows style guide
- [ ] CI checks pass


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
