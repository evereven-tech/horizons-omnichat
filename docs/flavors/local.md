# Local Deployment Guide

## Prerequisites

- Docker or Podman
- Make
- 8GB RAM minimum
- (Optional) NVIDIA GPU with CUDA support

## Quick Start

1. Clone the repository and initialize:
```bash
git clone https://github.com/evereven-tech/horizons-omnichat.git
cd horizons-omnichat
make init
```

2. Configure environment:
```bash
cp local/.env.example local/.env
# Edit local/.env to set your preferences
```

3. Start services:
```bash
make local-up
```

## Troubleshooting

### Common Issues

#### Container Startup Failures

1. **Database Connection Issues**
```bash
# Check database logs
docker logs webui-db

# Verify database is running
docker exec webui-db pg_isready
```

2. **Ollama Model Download Issues**
```bash
# Check Ollama logs
docker logs ollama

# Manually trigger model download
docker exec ollama ollama pull tinyllama
```

3. **WebUI Connection Issues**
```bash
# Check WebUI logs
docker logs open-webui

# Verify WebUI is responding
curl http://localhost:3002/health
```

### GPU Support

1. **Verify NVIDIA Driver Installation**
```bash
nvidia-smi
```

2. **Check Docker GPU Access**
```bash
# Should list GPU devices
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

3. **Enable GPU in Configuration**
```bash
# Edit .env file
OLLAMA_USE_GPU=true
```

### Resource Issues

1. **Memory Problems**
```bash
# Check container memory usage
docker stats

# Increase container memory limits in docker-compose.yml if needed
```

2. **Disk Space**
```bash
# Check available space
df -h

# Clean up unused Docker resources
docker system prune
```

### Network Issues

1. **Port Conflicts**
```bash
# Check what's using port 3002
sudo lsof -i :3002

# Change port in docker-compose.yml if needed
```

2. **Container Communication**
```bash
# Verify network creation
docker network ls | grep chatbot-net

# Check network connectivity
docker network inspect chatbot-net
```

## Maintenance

### Backup Data

```bash
# Backup PostgreSQL database
docker exec webui-db pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup.sql

# Backup Ollama models
tar -czf ollama-models.tar.gz $(docker volume inspect -f '{{.Mountpoint}}' local_ollama-data)
```

### Update Components

```bash
# Pull latest images
docker compose pull

# Restart services
make local-down
make local-up
```

### Logs and Monitoring

```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f ollama
docker compose logs -f open-webui
```

## Advanced Configuration

### Custom Model Configuration
Edit `local/.env`:
```
INSTALLED_MODELS=llama2,mistral,tinyllama
```

### Database Tuning
Edit PostgreSQL configuration:
```bash
docker exec -it webui-db psql -U $POSTGRES_USER -d $POSTGRES_DB
```

### Security Hardening
1. Change default passwords in `.env`
2. Enable TLS for database connections
3. Configure authentication for WebUI

## Getting Help

1. Check the [GitHub Issues](https://github.com/evereven-tech/horizons-omnichat/issues)
2. Join our [Community Discussion](https://github.com/evereven-tech/horizons-omnichat/discussions)
3. Review logs using commands above
