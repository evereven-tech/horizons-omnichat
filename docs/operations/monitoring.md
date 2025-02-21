---
layout: default
title: Architecture Overview
---

# Monitoring & Troubleshooting

## Health Checks

### Local/Hybrid Mode
```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f
```

### AWS Mode
- CloudWatch metrics
- ECS service health
- RDS monitoring
- ALB metrics

## Common Issues

### Database Connection
```bash
# Check PostgreSQL
docker exec webui-db pg_isready
```

### Model Loading
```bash
# Check Ollama status
curl http://localhost:11434/api/tags
```

### AWS Specific
- Check ECS task status
- Verify security group rules
- Review CloudWatch logs
- Check Auto Scaling status

## Performance Monitoring
- CPU/Memory usage
- Model inference times
- Request latency
- Database performance

{% include footer.html %}
