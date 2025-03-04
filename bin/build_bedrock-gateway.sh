#!/bin/bash

# Exit on error
set -e

# Detect container runtime (podman or docker)
CONTAINER_RUNTIME=$(which podman 2>/dev/null || which docker 2>/dev/null)
if [ -z "$CONTAINER_RUNTIME" ]; then
    echo "Error: No container runtime found. Please install podman or docker."
    exit 1
fi
RUNTIME_CMD=$(basename "$CONTAINER_RUNTIME")
echo "Using container runtime: $RUNTIME_CMD"

# Default values
DEFAULT_AWS_REGION="eu-west-1"
DEFAULT_PROJECT_NAME="horizons"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    local missing_deps=0

    for cmd in $RUNTIME_CMD aws jq git; do
        if ! command -v $cmd &> /dev/null; then
            log_error "$cmd is required but not installed."
            missing_deps=1
        fi
    done

    if [ $missing_deps -eq 1 ]; then
        exit 1
    fi
}

check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' or set appropriate environment variables."
        exit 1
    fi
}

# Environment setup
AWS_REGION=${AWS_REGION:-$DEFAULT_AWS_REGION}
PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
DATE_TAG=$(date +%Y%m%d)

# Validate dependencies and AWS credentials
log_info "Checking dependencies..."
check_dependencies
check_aws_credentials

# Update git submodule
log_info "Updating bedrock-gateway git submodule..."
git submodule update --init --recursive ../external/bedrock-gateway
cd ../external/bedrock-gateway && git pull origin main && cd -
log_info "Git submodule updated successfully!"

# Login to ECR
log_info "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | $RUNTIME_CMD login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push Bedrock Gateway with both tags
log_info "Building Bedrock Gateway image..."
$RUNTIME_CMD build -t ${ECR_REGISTRY}/${PROJECT_NAME}-bedrock-gateway:latest \
    -t ${ECR_REGISTRY}/${PROJECT_NAME}-bedrock-gateway:${DATE_TAG} \
    -f ../external/bedrock-gateway/src/Dockerfile_ecs ../external/bedrock-gateway/src/

log_info "Pushing Bedrock Gateway image with latest tag..."
$RUNTIME_CMD push ${ECR_REGISTRY}/${PROJECT_NAME}-bedrock-gateway:latest

log_info "Pushing Bedrock Gateway image with date tag (${DATE_TAG})..."
$RUNTIME_CMD push ${ECR_REGISTRY}/${PROJECT_NAME}-bedrock-gateway:${DATE_TAG}

log_info "Bedrock Gateway image built and pushed successfully with tags: latest and ${DATE_TAG}!"
