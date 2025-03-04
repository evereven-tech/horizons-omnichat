#!/bin/bash

set -e    # Exit on error
set -x    # Print commands before executing them (helpful for debugging)

# Detect container runtime (podman or docker)
CONTAINER_RUNTIME=$(which podman 2>/dev/null || which docker 2>/dev/null)
if [ -z "$CONTAINER_RUNTIME" ]; then
    echo "Error: No container runtime found. Please install podman or docker."
    exit 1
fi
RUNTIME_CMD=$(basename "$CONTAINER_RUNTIME")
echo "Using container runtime: $RUNTIME_CMD"

# Variables
AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
AWS_REGION="eu-west-1"
REPO_NAME="horizons-ollama"
ECR_URL="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Log account information
echo "Using AWS Account: ${AWS_ACCOUNT}"
echo "ECR URL: ${ECR_URL}"

# Versions to process
VERSIONS=("latest")

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | $RUNTIME_CMD login --username AWS --password-stdin ${ECR_URL}

# Build Ollama image
echo "Building Ollama image..."
$RUNTIME_CMD build -t ${REPO_NAME}:latest -f ../common/Dockerfile.ollama ../common/

# Process each version
for VERSION in "${VERSIONS[@]}"; do
    echo "Processing version: $VERSION"

    # Tag for ECR
    $RUNTIME_CMD tag ${REPO_NAME}:latest ${ECR_URL}/${REPO_NAME}:${VERSION}

    # Push to ECR
    $RUNTIME_CMD push ${ECR_URL}/${REPO_NAME}:${VERSION}
done

# Verify images
echo "Verifying repository contents:"
aws ecr describe-images \
    --repository-name ${REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'imageDetails[*].{Tags:imageTags[],PushedAt:imagePushedAt}' \
    --output table
