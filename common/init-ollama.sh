#!/bin/bash
set -e

echo "Starting Ollama server..."
ollama serve &

echo "Waiting for Ollama server to be ready..."
until curl -s -f "http://localhost:11434/api/tags" > /dev/null 2>&1; do
    echo "Waiting for Ollama server..."
    sleep 5
done

# Leer los modelos desde la variable de entorno y descargarlos
echo "Downloading specified models..."
IFS=',' read -ra MODELS <<< "$OLLAMA_MODELS"
for model in "${MODELS[@]}"; do
    echo "Pulling model: $model"
    ollama pull "$model"
done

echo "Setup complete, keeping container alive..."
wait
