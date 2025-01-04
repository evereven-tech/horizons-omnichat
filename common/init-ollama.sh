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
echo "Checking and downloading specified models..."
IFS=',' read -ra MODELS <<< "$OLLAMA_MODELS"
for model in "${MODELS[@]}"; do
    if ollama list | grep -q "^$model\s"; then
        echo "Model $model already exists, skipping..."
    else
        echo "Pulling model: $model"
        ollama pull "$model"
    fi
done

echo "Setup complete, keeping container alive..."
wait
