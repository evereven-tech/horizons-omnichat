<div align="center">

# 🌅 Horizons: The OmniChat - Documentation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-github.io-blue)](https://evereven-tech.github.io/horizons-omnichat/)

Documentation repository for Horizons OmniChat platform.

[View Documentation](https://evereven-tech.github.io/horizons-omnichat/) •
[Main Repository](https://github.com/evereven-tech/horizons-omnichat/tree/main)

</div>

---

## 📚 About This Repository

This repository contains the documentation for the Horizons OmniChat platform. The actual implementation code can be found in the [main branch](https://github.com/evereven-tech/horizons-omnichat/tree/main).

## 🛠 Technical Stack

### Documentation Build
- **Jekyll**: Static site generator for documentation
- **GitHub Pages**: Hosting platform
- **Architect Theme**: Base theme with customizations

### Build Tools
- **Make**: Build automation using Makefile
- **Container Support**: 
  - Podman (preferred) or Docker for container management
  - Auto-detection of available container runtime

## 🚀 Local Development

### Prerequisites
- Make
- Podman or Docker
- Ruby (optional, for local Jekyll development)

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat
```

2. Build documentation:
```bash
make build
```

3. Serve locally:
```bash
make serve
```

The documentation will be available at `http://localhost:4200`

## 📖 Documentation Structure

```
docs/
├── architecture/    # System architecture documentation
├── deployment/      # Deployment guides
├── development/     # Development guides
├── enterprise/      # Enterprise features
├── operations/      # Operations guides
└── security/        # Security documentation
```

## 🤝 Contributing

We welcome contributions to improve our documentation:

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

---

<div align="center">
Made with 💚 by <a href="https://www.evereven.tech">evereven</a>
</div>
