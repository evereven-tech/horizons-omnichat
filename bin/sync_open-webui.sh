#!/bin/bash

set -e    # Exit on error
set -x    # Print commands before executing them (helpful for debugging)

# Variables
AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
AWS_REGION="eu-west-1"
REPO_NAME="horizons-webui"
ECR_URL="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Log información de la cuenta
echo "Using AWS Account: ${AWS_ACCOUNT}"
echo "ECR URL: ${ECR_URL}"

# Versiones a procesar
VERSIONS=("latest" "v0.5.14" "v0.5.11" "v0.5.10" "v0.5.7")

# Login en ECR
aws ecr get-login-password --region ${AWS_REGION} | podman login --username AWS --password-stdin ${ECR_URL}

# Función para limpiar imágenes huérfanas
cleanup_untagged_images() {
    echo "Checking for untagged images..."

    # Obtener lista de imágenes sin tag (huérfanas)
    untagged_images=$(aws ecr describe-images \
        --repository-name ${REPO_NAME} \
        --region ${AWS_REGION} \
        --filter tagStatus=UNTAGGED \
        --query 'imageDetails[*].imageDigest' \
        --output text)

    if [ -n "$untagged_images" ]; then
        echo "Found untagged images. Cleaning up..."
        for digest in $untagged_images; do
            echo "Deleting image: $digest"
            aws ecr batch-delete-image \
                --repository-name ${REPO_NAME} \
                --region ${AWS_REGION} \
                --image-ids imageDigest=$digest
        done
        echo "Cleanup complete!"
    else
        echo "No untagged images found."
    fi
}

# Procesar cada versión
for VERSION in "${VERSIONS[@]}"; do
    echo "Processing version: $VERSION"

    # Pull de la imagen
    podman pull ghcr.io/open-webui/open-webui:${VERSION}

    # Tag para ECR (si es 'main', usar 'latest' como tag adicional)
    if [ "$VERSION" == "main" ]; then
        podman tag ghcr.io/open-webui/open-webui:${VERSION} ${ECR_URL}/${REPO_NAME}:latest
        podman push ${ECR_URL}/${REPO_NAME}:latest
    fi

    # Tag y push normal
    podman tag ghcr.io/open-webui/open-webui:${VERSION} ${ECR_URL}/${REPO_NAME}:${VERSION}
    podman push ${ECR_URL}/${REPO_NAME}:${VERSION}
done

# Limpiar imágenes huérfanas
cleanup_untagged_images

# Verificar las imágenes
echo "Verifying repository contents:"
aws ecr describe-images \
    --repository-name ${REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'imageDetails[*].{Tags:imageTags[],PushedAt:imagePushedAt}' \
    --output table
