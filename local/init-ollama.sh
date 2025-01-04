#!/bin/bash
# Iniciar el servidor ollama
ollama serve &
# Esperar a que el servidor esté listo
sleep 5
# Descargar el modelo
ollama pull tinyllama
# Mantener el contenedor corriendo
wait
