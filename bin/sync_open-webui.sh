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
REPO_NAME="horizons-webui"
ECR_URL="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Log account information
echo "Using AWS Account: ${AWS_ACCOUNT}"
echo "ECR URL: ${ECR_URL}"

# Versions to process
VERSIONS=("main" "v0.6.2" "v0.6.1" "v0.6.0") 

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | $RUNTIME_CMD login --username AWS --password-stdin ${ECR_URL}

# Function to clean up orphaned images
cleanup_untagged_images() {
    echo "Checking for untagged images..."

    # Get list of untagged (orphaned) images
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

# Process each version
for VERSION in "${VERSIONS[@]}"; do
    echo "Processing version: $VERSION"

    # Pull the image
    $RUNTIME_CMD pull ghcr.io/open-webui/open-webui:${VERSION}

    # Tag for ECR (if 'main', use 'latest' as additional tag)
    if [ "$VERSION" == "main" ]; then
        $RUNTIME_CMD tag ghcr.io/open-webui/open-webui:${VERSION} ${ECR_URL}/${REPO_NAME}:latest
        $RUNTIME_CMD push ${ECR_URL}/${REPO_NAME}:latest
    fi

    # Normal tag and push
    $RUNTIME_CMD tag ghcr.io/open-webui/open-webui:${VERSION} ${ECR_URL}/${REPO_NAME}:${VERSION}
    $RUNTIME_CMD push ${ECR_URL}/${REPO_NAME}:${VERSION}
done

# Clean up orphaned images
cleanup_untagged_images

# Verify images
echo "Verifying repository contents:"
aws ecr describe-images \
    --repository-name ${REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'imageDetails[*].{Tags:imageTags[],PushedAt:imagePushedAt}' \
    --output table
