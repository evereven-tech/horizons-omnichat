# Contributing to Horizons

Thank you for your interest in contributing to Horizons! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct (see CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in our [Issues](https://github.com/evereven/horizons/issues)
2. If not, create a new issue using our [Bug Report Template](https://github.com/evereven/horizons/issues/new?template=bug_report.md)
3. Include as much relevant information as possible:
   - Clear description of the issue
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Relevant logs or screenshots

### Suggesting Enhancements

1. Review existing [Feature Requests](https://github.com/evereven/horizons/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. If your idea is new, create an issue using our [Feature Request Template](https://github.com/evereven/horizons/issues/new?template=feature_request.md)

## Pull Request Process

1. **Fork the Repository**
   ```bash
   git clone https://github.com/evereven/horizons.git
   cd horizons
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Follow our coding standards
   - Write clear commit messages
   - Include tests when applicable
   - Update documentation as needed

3. **Test Your Changes**
   - Run existing tests
   - Add new tests for new functionality
   - Ensure all tests pass

4. **Create a Pull Request**
   - Use our [Pull Request Template](https://github.com/evereven/horizons/blob/main/.github/PULL_REQUEST_TEMPLATE.md)
   - Link any related issues
   - Provide a clear description of your changes
   - Include screenshots if applicable

5. **Review Process**
   - Maintainers will review your PR
   - Address any requested changes
   - Once approved, your PR will be merged

## Development Setup

1. **Prerequisites**
   - Docker or Podman
   - Make
   - AWS CLI (for AWS deployment)
   - Terraform (for AWS deployment)

2. **Local Development**
   ```bash
   # Initialize the project
   make init

   # Start local development environment
   make local-up
   ```

## Coding Standards

- Follow existing code style
- Use meaningful variable and function names
- Comment complex logic
- Keep functions focused and concise
- Write self-documenting code when possible

## Documentation

- Update README.md if needed
- Add inline documentation for new functions
- Update deployment guides if changing infrastructure
- Keep documentation clear and concise

## Questions?

- Check our [Discussions](https://github.com/evereven/horizons/discussions)
- Join our community chat
- Contact the maintainers

## License

By contributing to Horizons, you agree that your contributions will be licensed under the MIT License.
