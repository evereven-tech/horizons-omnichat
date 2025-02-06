#!/bin/bash
set -e

# Function to check if Ollama is running
is_ollama_running() {
    curl -s -f "http://localhost:11434/api/tags" > /dev/null 2>&1
    return $?
}

# Only start if not running before
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

# Check ENV-level defined models and download
echo "Checking and downloading specified models..."
IFS=',' read -ra MODELS <<< "$INSTALLED_MODELS"
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
