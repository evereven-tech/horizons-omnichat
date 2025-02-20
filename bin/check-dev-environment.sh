#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for failed checks
FAILED_CHECKS=0

# Function to check if a command exists
check_command() {
    local cmd=$1
    local package=$2
    local version_cmd=$3
    local min_version=$4

    printf "Checking ${cmd}... "

    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}❌ NOT FOUND${NC}"
        echo -e "${YELLOW}Please install ${package}${NC}"
        ((FAILED_CHECKS++))
        return 1
    fi

    if [ -n "$version_cmd" ] && [ -n "$min_version" ]; then
        local version
        version=$($version_cmd)
        if ! printf '%s\n%s\n' "$min_version" "$version" | sort -V -C; then
            echo -e "${YELLOW}⚠️  FOUND ${version} (minimum required: ${min_version})${NC}"
            ((FAILED_CHECKS++))
            return 1
        fi
    fi

    echo -e "${GREEN}✅ FOUND$([ -n "$version" ] && echo " ($version)")${NC}"
    return 0
}

# Function to check Python package
check_python_package() {
    local package=$1
    local min_version=$2

    printf "Checking Python package ${package}... "

    if ! pip show "$package" &> /dev/null; then
        echo -e "${RED}❌ NOT FOUND${NC}"
        echo -e "${YELLOW}Please install with: pip install ${package}${NC}"
        ((FAILED_CHECKS++))
        return 1
    fi

    if [ -n "$min_version" ]; then
        local version
        version=$(pip show "$package" | grep Version | cut -d' ' -f2)
        if ! printf '%s\n%s\n' "$min_version" "$version" | sort -V -C; then
            echo -e "${YELLOW}⚠️  FOUND ${version} (minimum required: ${min_version})${NC}"
            ((FAILED_CHECKS++))
            return 1
        fi
    fi

    echo -e "${GREEN}✅ FOUND$([ -n "$version" ] && echo " ($version)")${NC}"
    return 0
}

echo "🔍 Checking development environment..."
echo "======================================="

# Check container runtime (docker or podman)
printf "Checking container runtime... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ FOUND (docker)${NC}"
    CONTAINER_RUNTIME="docker"
elif command -v podman &> /dev/null; then
    echo -e "${GREEN}✅ FOUND (podman)${NC}"
    CONTAINER_RUNTIME="podman"
else
    echo -e "${RED}❌ NOT FOUND${NC}"
    echo -e "${YELLOW}Please install either Docker or Podman${NC}"
    ((FAILED_CHECKS++))
fi

# Core tools
check_command "make" "make" "make --version | head -n1 | cut -d' ' -f3" "4.0"
check_command "git" "git" "git --version | cut -d' ' -f3" "2.0.0"
check_command "aws" "aws-cli" "aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2" "2.0.0"
check_command "terraform" "terraform" "terraform version | head -n1 | cut -d'v' -f2" "1.0.0"
check_command "python3" "python3" "python3 --version | cut -d' ' -f2" "3.8.0"
check_command "pip" "python3-pip" "pip --version | cut -d' ' -f2" "20.0.0"

# Pre-commit and related tools
check_python_package "pre-commit" "3.0.0"
check_command "shellcheck" "shellcheck" "shellcheck --version | sed -n 2p | cut -d' ' -f2" "0.8.0"
check_command "hadolint" "hadolint" "hadolint --version | cut -d' ' -f4" "2.0.0"

# Additional linting tools
check_command "tflint" "tflint" "tflint --version | head -n1 | cut -d' ' -f2" "0.40.0"
check_command "checkov" "checkov" "checkov --version | cut -d' ' -f2" "2.0.0"
check_command "tfsec" "tfsec" "tfsec --version | cut -d'v' -f2" "1.0.0"

# Check if jq is installed (used in scripts)
check_command "jq" "jq" "jq --version | cut -d'-' -f2" "1.6"

# Check for required Python packages
check_python_package "black" "22.0.0"
check_python_package "markdownlint-cli" "0.30.0"

# Check NVIDIA tools if GPU support is needed
if [ -f "local/.env" ] && grep -q "OLLAMA_USE_GPU=true" "local/.env"; then
    check_command "nvidia-smi" "nvidia-drivers" "nvidia-smi --query-gpu=driver_version --format=csv,noheader" "470.0"
fi

echo "======================================="
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ ${FAILED_CHECKS} check(s) failed${NC}"
    echo -e "${YELLOW}Please install missing dependencies and try again${NC}"
    exit 1
fi
