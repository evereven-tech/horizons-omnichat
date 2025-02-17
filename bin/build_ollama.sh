#!/bin/bash

set -e    # Exit on error
set -x    # Print commands before executing them (helpful for debugging)

# Variables
AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
AWS_REGION="eu-west-1"
REPO_NAME="horizons-ollama"
ECR_URL="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Log información de la cuenta
echo "Using AWS Account: ${AWS_ACCOUNT}"
echo "ECR URL: ${ECR_URL}"

# Versiones a procesar
VERSIONS=("latest" "0.0.20" "0.0.19" "0.0.18")

# Login en ECR
aws ecr get-login-password --region ${AWS_REGION} | podman login --username AWS --password-stdin ${ECR_URL}

# Construir imagen de Ollama
echo "Building Ollama image..."
podman build -t ${REPO_NAME}:latest -f ../common/Dockerfile.ollama ../common/

# Procesar cada versión
for VERSION in "${VERSIONS[@]}"; do
    echo "Processing version: $VERSION"
    
    # Tag para ECR
    podman tag ${REPO_NAME}:latest ${ECR_URL}/${REPO_NAME}:${VERSION}
    
    # Push a ECR
    podman push ${ECR_URL}/${REPO_NAME}:${VERSION}
done

# Verificar las imágenes
echo "Verifying repository contents:"
aws ecr describe-images \
    --repository-name ${REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'imageDetails[*].{Tags:imageTags[],PushedAt:imagePushedAt}' \
    --output table
