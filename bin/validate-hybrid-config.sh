#!/bin/bash

# Hybrid Configuration Validation Script
# This script validates the hybrid deployment configuration and checks
# for common issues before deployment

set -e

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/hybrid/.env"
CONFIG_FILE="${PROJECT_ROOT}/hybrid/config.json"
LITELLM_CONFIG="${PROJECT_ROOT}/hybrid/litellm_config.yaml"
DOCKER_COMPOSE_FILE="${PROJECT_ROOT}/hybrid/docker-compose.yml"

# Validation results
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Function to print coloured messages
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

# Function to show help
show_help() {
    echo "Hybrid Configuration Validation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -q, --quiet             Suppress non-error output"
    echo "  --fix-permissions       Attempt to fix file permissions"
    echo "  --check-connectivity    Test network connectivity to external services"
    echo ""
    echo "This script validates:"
    echo "  • Environment file configuration"
    echo "  • Required file permissions"
    echo "  • Docker Compose configuration"
    echo "  • LiteLLM configuration"
    echo "  • Open WebUI configuration"
    echo "  • API key formats"
    echo "  • Service dependencies"
}

# Function to validate environment file
validate_env_file() {
    log_info "Validating environment configuration..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error "Environment file not found: $ENV_FILE"
        log_info "Run: cp hybrid/.env.example hybrid/.env"
        return
    fi
    
    log_success "Environment file exists"
    
    # Load environment variables
    set -a
    source "$ENV_FILE" 2>/dev/null || {
        log_error "Failed to load environment file. Check for syntax errors."
        return
    }
    set +a
    
    # Check required variables
    local required_vars=(
        "POSTGRES_DB"
        "POSTGRES_USER" 
        "POSTGRES_PASSWORD"
        "WEBUI_SECRET_KEY"
        "LITELLM_MASTER_KEY"
        "UI_USERNAME"
        "UI_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required variable $var is not set"
        else
            log_success "Required variable $var is configured"
        fi
    done
    
    # Check for default/insecure values
    if [ "$POSTGRES_PASSWORD" = "change_me_in_production" ]; then
        log_warning "POSTGRES_PASSWORD is using default value - change for production"
    fi
    
    if [ "$WEBUI_SECRET_KEY" = "change_me_in_production" ]; then
        log_warning "WEBUI_SECRET_KEY is using default value - change for production"
    fi
    
    if [ "$UI_PASSWORD" = "change_me_in_production" ]; then
        log_warning "UI_PASSWORD is using default value - change for production"
    fi
    
    if [ "$LITELLM_MASTER_KEY" = "sk-change_me_in_production" ]; then
        log_warning "LITELLM_MASTER_KEY is using default value - change for production"
    fi
    
    # Validate API key formats
    if [ ! -z "$LITELLM_PROVIDER_OPENAI_API_KEY" ] && [ "$LITELLM_PROVIDER_OPENAI_API_KEY" != "your_openai_api_key" ]; then
        if [[ ! "$LITELLM_PROVIDER_OPENAI_API_KEY" =~ ^sk-[a-zA-Z0-9]{48,}$ ]]; then
            log_warning "OpenAI API key format appears invalid"
        else
            log_success "OpenAI API key format is valid"
        fi
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" ] && [ "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" != "your_anthropic_api_key" ]; then
        if [[ ! "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" =~ ^sk-ant-[a-zA-Z0-9_-]{95,}$ ]]; then
            log_warning "Anthropic API key format appears invalid"
        else
            log_success "Anthropic API key format is valid"
        fi
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_XAI_API_KEY" ] && [ "$LITELLM_PROVIDER_XAI_API_KEY" != "your_xai_api_key" ]; then
        if [[ ! "$LITELLM_PROVIDER_XAI_API_KEY" =~ ^xai-[a-zA-Z0-9]{64,}$ ]]; then
            log_warning "xAI API key format appears invalid"
        else
            log_success "xAI API key format is valid"
        fi
    fi
}

# Function to validate file permissions
validate_permissions() {
    log_info "Validating file permissions..."
    
    local files_to_check=(
        "$ENV_FILE"
        "$CONFIG_FILE"
        "$DOCKER_COMPOSE_FILE"
    )
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            local perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
            if [ "$perms" -gt "644" ]; then
                log_warning "File $file has overly permissive permissions: $perms"
                if [ "$FIX_PERMISSIONS" = "true" ]; then
                    chmod 644 "$file"
                    log_success "Fixed permissions for $file"
                fi
            else
                log_success "File permissions OK for $file"
            fi
        fi
    done
    
    # Check if .env file is readable but not world-readable
    if [ -f "$ENV_FILE" ]; then
        local env_perms=$(stat -c "%a" "$ENV_FILE" 2>/dev/null || stat -f "%A" "$ENV_FILE" 2>/dev/null)
        if [ "${env_perms: -1}" != "0" ] && [ "${env_perms: -1}" != "4" ]; then
            log_warning ".env file is world-readable - consider chmod 640"
        fi
    fi
}

# Function to validate Docker Compose configuration
validate_docker_compose() {
    log_info "Validating Docker Compose configuration..."
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        return
    fi
    
    # Check if docker-compose is available
    if command -v docker-compose &> /dev/null; then
        if docker-compose -f "$DOCKER_COMPOSE_FILE" config &> /dev/null; then
            log_success "Docker Compose configuration is valid"
        else
            log_error "Docker Compose configuration has syntax errors"
        fi
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        if docker compose -f "$DOCKER_COMPOSE_FILE" config &> /dev/null; then
            log_success "Docker Compose configuration is valid"
        else
            log_error "Docker Compose configuration has syntax errors"
        fi
    else
        log_warning "Docker Compose not available - cannot validate configuration"
    fi
}

# Function to validate LiteLLM configuration
validate_litellm_config() {
    log_info "Validating LiteLLM configuration..."
    
    if [ ! -f "$LITELLM_CONFIG" ]; then
        log_warning "LiteLLM config not found. Run: bin/generate-config-litellm-hybrid.sh"
        return
    fi
    
    # Check YAML syntax
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$LITELLM_CONFIG'))" 2>/dev/null; then
            log_success "LiteLLM configuration YAML syntax is valid"
        else
            log_error "LiteLLM configuration has YAML syntax errors"
        fi
    elif command -v yq &> /dev/null; then
        if yq eval . "$LITELLM_CONFIG" &> /dev/null; then
            log_success "LiteLLM configuration YAML syntax is valid"
        else
            log_error "LiteLLM configuration has YAML syntax errors"
        fi
    else
        log_warning "Cannot validate YAML syntax - python3 or yq not available"
    fi
    
    # Check for model configurations
    local model_count=$(grep -c "model_name:" "$LITELLM_CONFIG" 2>/dev/null || echo "0")
    if [ "$model_count" -gt "0" ]; then
        log_success "Found $model_count models configured in LiteLLM"
    else
        log_warning "No models found in LiteLLM configuration"
    fi
}

# Function to validate Open WebUI configuration
validate_webui_config() {
    log_info "Validating Open WebUI configuration..."
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Open WebUI config not found: $CONFIG_FILE"
        return
    fi
    
    # Check JSON syntax
    if command -v jq &> /dev/null; then
        if jq . "$CONFIG_FILE" &> /dev/null; then
            log_success "Open WebUI configuration JSON syntax is valid"
        else
            log_error "Open WebUI configuration has JSON syntax errors"
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
            log_success "Open WebUI configuration JSON syntax is valid"
        else
            log_error "Open WebUI configuration has JSON syntax errors"
        fi
    else
        log_warning "Cannot validate JSON syntax - jq or python3 not available"
    fi
}

# Function to check service dependencies
validate_dependencies() {
    log_info "Validating service dependencies..."
    
    # Check if required external directories exist
    if [ ! -d "$PROJECT_ROOT/external/bedrock-gateway" ]; then
        log_error "Bedrock gateway not found. Run: make init"
    else
        log_success "Bedrock gateway directory exists"
    fi
    
    # Check if common directory exists
    if [ ! -d "$PROJECT_ROOT/common" ]; then
        log_warning "Common directory not found - some builds may fail"
    else
        log_success "Common directory exists"
    fi
}

# Function to test connectivity
test_connectivity() {
    log_info "Testing external service connectivity..."
    
    # Test OpenAI API if configured
    if [ ! -z "$LITELLM_PROVIDER_OPENAI_API_KEY" ] && [ "$LITELLM_PROVIDER_OPENAI_API_KEY" != "your_openai_api_key" ]; then
        if command -v curl &> /dev/null; then
            local response=$(curl -s -w "%{http_code}" -o /dev/null \
                -H "Authorization: Bearer $LITELLM_PROVIDER_OPENAI_API_KEY" \
                -H "Content-Type: application/json" \
                "https://api.openai.com/v1/models" || echo "000")
            if [ "$response" = "200" ]; then
                log_success "OpenAI API is accessible"
            else
                log_warning "OpenAI API returned status: $response"
            fi
        fi
    fi
    
    # Test Mistral API if configured
    if [ ! -z "$LITELLM_PROVIDER_MISTRAL_API_KEY" ] && [ "$LITELLM_PROVIDER_MISTRAL_API_KEY" != "your_mistral_api_key" ]; then
        if command -v curl &> /dev/null; then
            local response=$(curl -s -w "%{http_code}" -o /dev/null \
                -H "Authorization: Bearer $LITELLM_PROVIDER_MISTRAL_API_KEY" \
                "https://api.mistral.ai/v1/models" || echo "000")
            if [ "$response" = "200" ]; then
                log_success "Mistral API is accessible"
            else
                log_warning "Mistral API returned status: $response"
            fi
        fi
    fi
    
    # Test AWS connectivity if configured
    if [ ! -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$AWS_SECRET_ACCESS_KEY" ]; then
        if command -v aws &> /dev/null; then
            if aws sts get-caller-identity --region "${AWS_REGION:-us-west-2}" &>/dev/null; then
                log_success "AWS credentials are valid"
            else
                log_warning "AWS credentials may be invalid or AWS CLI not configured"
            fi
        else
            log_warning "AWS CLI not available - cannot test AWS connectivity"
        fi
    fi
}

# Main validation function
main() {
    echo "Horizons OmniChat - Hybrid Configuration Validation"
    echo "=================================================="
    echo ""
    
    validate_env_file
    echo ""
    
    validate_permissions
    echo ""
    
    validate_docker_compose
    echo ""
    
    validate_litellm_config
    echo ""
    
    validate_webui_config
    echo ""
    
    validate_dependencies
    echo ""
    
    if [ "$CHECK_CONNECTIVITY" = "true" ]; then
        test_connectivity
        echo ""
    fi
    
    # Summary
    echo "Validation Summary"
    echo "=================="
    
    if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
        log_success "All validations passed! Configuration is ready for deployment."
        echo ""
        log_info "Next steps:"
        echo "  1. Run: make hybrid-up"
        echo "  2. Access Open WebUI at http://localhost:3002"
        echo "  3. Access LiteLLM at http://localhost:4000"
    elif [ $VALIDATION_ERRORS -eq 0 ]; then
        log_warning "Validation completed with $VALIDATION_WARNINGS warnings"
        echo ""
        log_info "Configuration should work but consider addressing warnings for production use"
    else
        log_error "Validation failed with $VALIDATION_ERRORS errors and $VALIDATION_WARNINGS warnings"
        echo ""
        log_info "Please fix the errors before deployment"
        exit 1
    fi
}

# Parse command line arguments
FIX_PERMISSIONS=false
CHECK_CONNECTIVITY=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --fix-permissions)
            FIX_PERMISSIONS=true
            shift
            ;;
        --check-connectivity)
            CHECK_CONNECTIVITY=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"