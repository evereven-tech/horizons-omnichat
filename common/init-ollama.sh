#!/bin/bash
set -e

# Función para verificar si Ollama ya está corriendo
is_ollama_running() {
    curl -s -f "http://localhost:11434/api/tags" > /dev/null 2>&1
    return $?
}

# Solo iniciar el servidor si no está corriendo ya
if ! is_ollama_running; then
    echo "Starting Ollama server..."
    ollama serve &

    echo "Waiting for Ollama server to be ready..."
    until is_ollama_running; do
        echo "Waiting for Ollama server..."
        sleep 5
    done
else
    echo "Ollama server already running"
fi

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
