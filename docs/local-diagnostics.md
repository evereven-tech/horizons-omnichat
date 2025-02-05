# Local Deployment Diagnostics Guide

This guide provides a comprehensive list of diagnostic commands for troubleshooting the local deployment of horizons.

## Environment Setup

```bash
# Copy environment file
cp local/.env.example local/.env

# Verify environment variables
cat local/.env | grep OLLAMA_USE_GPU
cat local/.env | grep OLLAMA_MODELS
```

## Deployment Status

```bash
# Check all running containers
docker compose -f local/docker-compose.yml ps

# View real-time logs
docker compose -f local/docker-compose.yml logs -f

# View logs for specific service
docker compose -f local/docker-compose.yml logs ollama
docker compose -f local/docker-compose.yml logs open-webui
docker compose -f local/docker-compose.yml logs webui-db
```

## GPU Support Diagnostics

```bash
# Check if container has NVIDIA capabilities
docker inspect ollama | grep -i nvidia

# View container's device requests
docker container inspect ollama | grep -A 10 "DeviceRequests"

# Check GPU status inside container
docker exec ollama nvidia-smi

# Check host GPU status (Linux/Windows WSL)
nvidia-smi
```

## Ollama Service Health

```bash
# Check if Ollama API is responding
curl -s http://localhost:11434/api/tags

# List available models
curl -s http://localhost:11434/api/tags | jq

# Check specific model status
curl -s http://localhost:11434/api/show -d '{"name":"llama2"}'

# Enter Ollama container
docker exec -it ollama /bin/bash

# Check Ollama process
docker exec ollama ps aux | grep ollama
```

## Bedrock-gateway Service Health

```bash

# Debug from docker host
export OPENAI_API_KEY=123456
export OPENAI_BASE_URL=http://localhost:8000/api/v1

# List models availables at Bedrock
curl http://localhost:8000/api/v1/models \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Test a model
curl $OPENAI_BASE_URL/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "anthropic.claude-3-sonnet-20240229-v1:0",
    "messages": [
      {
        "role": "user",
        "content": "Hello!"
      }
    ]
  }'


```


## Database Health

```bash
# Check PostgreSQL connection
docker exec webui-db pg_isready -U $POSTGRES_USER -d $POSTGRES_DB

# Enter PostgreSQL console
docker exec -it webui-db psql -U $POSTGRES_USER -d $POSTGRES_DB

# Check database logs
docker logs webui-db
```

## Network Diagnostics

```bash
# Check network connectivity between containers
docker network inspect chatbot-net

# Test Open WebUI endpoint
curl -s http://localhost:3002/health

# View network settings
docker inspect ollama | grep -i network
```

## Resource Usage

```bash
# Monitor container resource usage
docker stats ollama open-webui webui-db

# Check container details
docker inspect ollama
docker inspect open-webui
docker inspect webui-db
```

## Common Issues

### Model Download Issues
```bash
# Force model re-download
docker exec ollama ollama rm llama2
docker exec ollama ollama pull llama2
```

### Permission Issues
```bash
# Check volume permissions
docker exec ollama ls -la /root/.ollama
```

### Container Restart
```bash
# Restart specific service
docker compose -f local/docker-compose.yml restart ollama

# Full deployment restart
make local-down && make local-up
```

## Clean Up

```bash
# Remove all containers and volumes
docker compose -f local/docker-compose.yml down -v

# Remove specific model
docker exec ollama ollama rm llama2

# Clean Docker cache
docker system prune -a
```

Note: Replace environment variables ($POSTGRES_USER, $POSTGRES_DB) with actual values from your .env file when executing commands.
