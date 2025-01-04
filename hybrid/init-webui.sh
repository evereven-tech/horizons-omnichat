#!/bin/bash
set -e

echo "Waiting for Open WebUI to be ready..."
until curl -s -f "http://open-webui:8080/api/health" > /dev/null 2>&1; do
    echo "Waiting for Open WebUI..."
    sleep 5
done

# Esperar un tiempo adicional para asegurar que el backend esté completamente inicializado
sleep 10

echo "Waiting for Bedrock Gateway to be ready..."
until curl -s -f "http://bedrock-gateway:8000/health" > /dev/null 2>&1; do
    echo "Waiting for Bedrock Gateway..."
    sleep 5
done

echo "Configuring Bedrock connection in Open WebUI..."
curl -X POST "http://open-webui:8080/api/config/connections" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "bedrock",
        "type": "bedrock",
        "endpoint": "http://bedrock-gateway:8000/v1",
        "api_key": "'${BEDROCK_API_KEY}'",
        "models": ["anthropic.claude-3-sonnet-20240229-v1:0"]
    }'

echo "Setup complete!"
