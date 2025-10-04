#!/bin/bash

# LiteLLM Configuration Generator for Hybrid Deployment
# This script generates LiteLLM configuration YAML files by:
# 1. Discovering available AWS Bedrock models
# 2. Reading external provider API keys from .env
# 3. Generating comprehensive configuration files
# 4. Validating API key formats and provider availability
# 5. Enhanced error handling and user feedback

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
OUTPUT_DIR="${PROJECT_ROOT}/hybrid"
CONFIG_FILE="${OUTPUT_DIR}/litellm_config.yaml"
IMAGE_CONFIG_FILE="${OUTPUT_DIR}/litellm_image_config.yaml"

# Function to print coloured messages
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show help
show_help() {
    echo "LiteLLM Configuration Generator for Hybrid Deployment"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --validate-only     Only validate configuration, don't generate files"
    echo "  -q, --quiet             Suppress non-error output"
    echo "  --skip-bedrock          Skip AWS Bedrock model discovery"
    echo "  --test-providers        Test provider API connectivity"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION                      AWS region for Bedrock models"
    echo "  LITELLM_MASTER_KEY             Master key for LiteLLM (required)"
    echo "  LITELLM_PROVIDER_OPENAI_API_KEY    OpenAI API key"
    echo "  LITELLM_PROVIDER_MISTRAL_API_KEY   Mistral API key"
    echo "  LITELLM_PROVIDER_XAI_API_KEY       xAI API key"
    echo "  LITELLM_PROVIDER_ANTHROPIC_API_KEY Anthropic API key"
    echo "  LITELLM_PROVIDER_HUGGINGFACE_API_KEY HuggingFace API key"
    echo "  LITELLM_PROVIDER_COHERE_API_KEY    Cohere API key"
    echo ""
    echo "Examples:"
    echo "  $0                      Generate configuration with all available providers"
    echo "  $0 --validate-only      Only validate current configuration"
    echo "  $0 --skip-bedrock       Generate config without AWS Bedrock models"
    echo "  $0 --test-providers     Test API connectivity for configured providers"
}

# Function to validate API key format
validate_api_key() {
    local provider="$1"
    local key="$2"
    
    case "$provider" in
        "openai")
            if [[ ! "$key" =~ ^sk-[a-zA-Z0-9]{48,}$ ]]; then
                log_warning "OpenAI API key format may be invalid (should start with 'sk-')"
                return 1
            fi
            ;;
        "anthropic")
            if [[ ! "$key" =~ ^sk-ant-[a-zA-Z0-9_-]{95,}$ ]]; then
                log_warning "Anthropic API key format may be invalid (should start with 'sk-ant-')"
                return 1
            fi
            ;;
        "xai")
            if [[ ! "$key" =~ ^xai-[a-zA-Z0-9]{64,}$ ]]; then
                log_warning "xAI API key format may be invalid (should start with 'xai-')"
                return 1
            fi
            ;;
        "mistral")
            if [[ ! "$key" =~ ^[a-zA-Z0-9]{32,}$ ]]; then
                log_warning "Mistral API key format may be invalid"
                return 1
            fi
            ;;
        "huggingface")
            if [[ ! "$key" =~ ^hf_[a-zA-Z0-9]{37,}$ ]]; then
                log_warning "HuggingFace API key format may be invalid (should start with 'hf_')"
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to check provider availability
check_provider_availability() {
    local provider="$1"
    local api_key="$2"
    
    log_info "Checking $provider provider availability..."
    
    case "$provider" in
        "openai")
            if command -v curl &> /dev/null; then
                local response=$(curl -s -w "%{http_code}" -o /dev/null \
                    -H "Authorization: Bearer $api_key" \
                    -H "Content-Type: application/json" \
                    "https://api.openai.com/v1/models" || echo "000")
                if [ "$response" = "200" ]; then
                    log_success "OpenAI API is accessible"
                    return 0
                else
                    log_warning "OpenAI API returned status: $response"
                    return 1
                fi
            fi
            ;;
        "anthropic")
            if command -v curl &> /dev/null; then
                local response=$(curl -s -w "%{http_code}" -o /dev/null \
                    -H "x-api-key: $api_key" \
                    -H "Content-Type: application/json" \
                    "https://api.anthropic.com/v1/messages" \
                    -d '{"model":"claude-3-haiku-20240307","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' || echo "000")
                if [ "$response" = "200" ] || [ "$response" = "400" ]; then
                    log_success "Anthropic API is accessible"
                    return 0
                else
                    log_warning "Anthropic API returned status: $response"
                    return 1
                fi
            fi
            ;;
        "mistral")
            if command -v curl &> /dev/null; then
                local response=$(curl -s -w "%{http_code}" -o /dev/null \
                    -H "Authorization: Bearer $api_key" \
                    "https://api.mistral.ai/v1/models" || echo "000")
                if [ "$response" = "200" ]; then
                    log_success "Mistral API is accessible"
                    return 0
                else
                    log_warning "Mistral API returned status: $response"
                    return 1
                fi
            fi
            ;;
    esac
    
    log_warning "Could not verify $provider availability (curl not available or provider not supported for testing)"
    return 1
}

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    log_error "Environment file not found: $ENV_FILE"
    log_info "Please copy hybrid/.env.example to hybrid/.env and configure your API keys"
    exit 1
fi

# Load environment variables
log_info "Loading environment variables from $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

# Validate required core variables
if [ -z "$LITELLM_MASTER_KEY" ]; then
    log_error "LITELLM_MASTER_KEY is not set in .env file"
    exit 1
fi

# Check AWS CLI availability (optional for external providers only)
if ! command -v aws &> /dev/null; then
    log_warning "AWS CLI is not installed. Bedrock models will be skipped."
    SKIP_BEDROCK=true
else
    # Check AWS credentials
    if [ -z "$AWS_REGION" ]; then
        log_warning "AWS_REGION is not set in .env file. Bedrock models will be skipped."
        SKIP_BEDROCK=true
    else
        log_info "Using AWS Region: $AWS_REGION"
        SKIP_BEDROCK=false
    fi
fi

# Function to discover Bedrock text models
discover_bedrock_text_models() {
    if [ "$SKIP_BEDROCK" = "true" ]; then
        log_info "Skipping Bedrock model discovery (AWS CLI not available or not configured)"
        echo "[]" > /tmp/inference_profiles.json
        echo "[]" > /tmp/foundation_models.json
        return
    fi
    
    log_info "Discovering Bedrock text/chat models in $AWS_REGION..."
    
    # Test AWS connectivity first
    if ! aws sts get-caller-identity --region "$AWS_REGION" &>/dev/null; then
        log_warning "AWS credentials are not valid or accessible. Skipping Bedrock models."
        echo "[]" > /tmp/inference_profiles.json
        echo "[]" > /tmp/foundation_models.json
        return
    fi
    
    # Get inference profiles (cross-region models)
    local inference_profiles=$(aws bedrock list-inference-profiles \
        --region "$AWS_REGION" \
        --query 'inferenceProfileSummaries[?status==`ACTIVE`].[inferenceProfileName,inferenceProfileId,description]' \
        --output json 2>/dev/null || echo "[]")
    
    # Get foundation models (region-specific)
    local foundation_models=$(aws bedrock list-foundation-models \
        --region "$AWS_REGION" \
        --query 'modelSummaries[?modelLifecycle.status==`ACTIVE` && responseStreamingSupported==`true` && contains(inferenceTypesSupported, `ON_DEMAND`) && contains(inputModalities, `TEXT`) && contains(outputModalities, `TEXT`)].[modelName,modelId,providerName]' \
        --output json 2>/dev/null || echo "[]")
    
    echo "$inference_profiles" > /tmp/inference_profiles.json
    echo "$foundation_models" > /tmp/foundation_models.json
    
    local profile_count=$(echo "$inference_profiles" | jq length)
    local foundation_count=$(echo "$foundation_models" | jq length)
    log_success "Discovered $profile_count inference profiles and $foundation_count foundation models"
}

# Function to discover Bedrock image models
discover_bedrock_image_models() {
    if [ "$SKIP_BEDROCK" = "true" ]; then
        log_info "Skipping Bedrock image model discovery"
        echo "[]" > /tmp/image_models.json
        return
    fi
    
    log_info "Discovering Bedrock image generation models in $AWS_REGION..."
    
    local image_models=$(aws bedrock list-foundation-models \
        --region "$AWS_REGION" \
        --query 'modelSummaries[?modelLifecycle.status==`ACTIVE` && contains(outputModalities, `IMAGE`)].[modelName,modelId,providerName]' \
        --output json 2>/dev/null || echo "[]")
    
    echo "$image_models" > /tmp/image_models.json
    
    local image_count=$(echo "$image_models" | jq length)
    log_success "Discovered $image_count image generation models"
}

# Function to generate unified config with model groups
generate_unified_config() {
    log_info "Generating unified LiteLLM configuration with model groups..."
    
    cat > "$CONFIG_FILE" << 'EOF'
# LiteLLM Unified Configuration - Generated by generate-config-litellm-hybrid.sh
# This file is auto-generated. Do not edit manually.
# Generated at: $(date)

model_list:
EOF
    
    # Add Bedrock Chat Models (inference profiles + foundation models)
    echo "  # ============================================" >> "$CONFIG_FILE"
    echo "  # GROUP 1: BEDROCK CHAT MODELS" >> "$CONFIG_FILE"
    echo "  # ============================================" >> "$CONFIG_FILE"
    
    # Add Bedrock inference profiles for chat
    if [ -f /tmp/inference_profiles.json ] && [ "$(cat /tmp/inference_profiles.json)" != "[]" ]; then
        jq -r '.[] | "  - model_name: \"\(.[0])\"\n    litellm_params:\n      model: bedrock/\(.[1])\n      aws_region_name: '"$AWS_REGION"'\n    model_info:\n      tags: [\"bedrock-chat\", \"aws\", \"cross-region\"]"' /tmp/inference_profiles.json >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"
    fi
    
    # Add Bedrock foundation models for chat
    if [ -f /tmp/foundation_models.json ] && [ "$(cat /tmp/foundation_models.json)" != "[]" ]; then
        jq -r '.[] | "  - model_name: \"\(.[0])\"\n    litellm_params:\n      model: bedrock/\(.[1])\n      aws_region_name: '"$AWS_REGION"'\n    model_info:\n      tags: [\"bedrock-chat\", \"aws\", \"foundation\"]"' /tmp/foundation_models.json >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"
    fi
    
    # Add Bedrock Image Models
    echo "  # ============================================" >> "$CONFIG_FILE"
    echo "  # GROUP 2: BEDROCK IMAGE MODELS" >> "$CONFIG_FILE"
    echo "  # ============================================" >> "$CONFIG_FILE"
    
    if [ -f /tmp/image_models.json ] && [ "$(cat /tmp/image_models.json)" != "[]" ]; then
        jq -r '.[] | "  - model_name: \"\(.[0])\"\n    litellm_params:\n      model: bedrock/\(.[1])\n      aws_region_name: '"$AWS_REGION"'\n    model_info:\n      tags: [\"bedrock-image\", \"aws\", \"image-generation\"]"' /tmp/image_models.json >> "$CONFIG_FILE"
        echo "" >> "$CONFIG_FILE"
    fi
    
    # Add external providers if API keys are present
    echo "  # ============================================" >> "$CONFIG_FILE"
    echo "  # GROUP 3: EXTERNAL PROVIDER MODELS" >> "$CONFIG_FILE"
    echo "  # ============================================" >> "$CONFIG_FILE"
    
    # OpenAI
    if [ ! -z "$LITELLM_PROVIDER_OPENAI_API_KEY" ] && [ "$LITELLM_PROVIDER_OPENAI_API_KEY" != "your_openai_api_key" ]; then
        log_info "Adding OpenAI models to configuration..."
        if validate_api_key "openai" "$LITELLM_PROVIDER_OPENAI_API_KEY"; then
            log_success "OpenAI API key format is valid"
        fi
        
        cat >> "$CONFIG_FILE" << EOF
  
  # OpenAI Models
  - model_name: "gpt-4o"
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
    model_info:
      tags: ["external", "openai", "chat", "premium"]
      
  - model_name: "gpt-4o-mini"
    litellm_params:
      model: openai/gpt-4o-mini
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
    model_info:
      tags: ["external", "openai", "chat", "fast"]
      
  - model_name: "gpt-4-turbo"
    litellm_params:
      model: openai/gpt-4-turbo
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
    model_info:
      tags: ["external", "openai", "chat", "turbo"]

  # OpenAI Image Models
  - model_name: "dall-e-3"
    litellm_params:
      model: openai/dall-e-3
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
    model_info:
      tags: ["external", "openai", "image-generation", "premium"]
      
  - model_name: "dall-e-2"
    litellm_params:
      model: openai/dall-e-2
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
    model_info:
      tags: ["external", "openai", "image-generation", "standard"]
EOF
    fi
    
    # Mistral
    if [ ! -z "$LITELLM_PROVIDER_MISTRAL_API_KEY" ] && [ "$LITELLM_PROVIDER_MISTRAL_API_KEY" != "your_mistral_api_key" ]; then
        log_info "Adding Mistral models to configuration..."
        if validate_api_key "mistral" "$LITELLM_PROVIDER_MISTRAL_API_KEY"; then
            log_success "Mistral API key format is valid"
        fi
        
        cat >> "$CONFIG_FILE" << EOF
  
  # Mistral Models
  - model_name: "mistral-large"
    litellm_params:
      model: mistral/mistral-large-latest
      api_key: os.environ/LITELLM_PROVIDER_MISTRAL_API_KEY
    model_info:
      tags: ["external", "mistral", "chat", "premium"]
      
  - model_name: "mistral-medium"
    litellm_params:
      model: mistral/mistral-medium-latest
      api_key: os.environ/LITELLM_PROVIDER_MISTRAL_API_KEY
    model_info:
      tags: ["external", "mistral", "chat", "standard"]
      
  - model_name: "mistral-small"
    litellm_params:
      model: mistral/mistral-small-latest
      api_key: os.environ/LITELLM_PROVIDER_MISTRAL_API_KEY
    model_info:
      tags: ["external", "mistral", "chat", "fast"]
      
  - model_name: "codestral"
    litellm_params:
      model: mistral/codestral-latest
      api_key: os.environ/LITELLM_PROVIDER_MISTRAL_API_KEY
    model_info:
      tags: ["external", "mistral", "code", "specialized"]
EOF
    fi
    
    # Anthropic (if using direct API, not Bedrock)
    if [ ! -z "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" ] && [ "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" != "your_anthropic_api_key" ]; then
        log_info "Adding Anthropic models to configuration..."
        if validate_api_key "anthropic" "$LITELLM_PROVIDER_ANTHROPIC_API_KEY"; then
            log_success "Anthropic API key format is valid"
        fi
        
        cat >> "$CONFIG_FILE" << EOF
  
  # Anthropic Models (Direct API)
  - model_name: "claude-3-opus"
    litellm_params:
      model: anthropic/claude-3-opus-20240229
      api_key: os.environ/LITELLM_PROVIDER_ANTHROPIC_API_KEY
    model_info:
      tags: ["external", "anthropic", "chat", "premium"]
      
  - model_name: "claude-3-sonnet"
    litellm_params:
      model: anthropic/claude-3-sonnet-20240229
      api_key: os.environ/LITELLM_PROVIDER_ANTHROPIC_API_KEY
    model_info:
      tags: ["external", "anthropic", "chat", "balanced"]
EOF
    fi
    
    # HuggingFace
    if [ ! -z "$LITELLM_PROVIDER_HUGGINGFACE_API_KEY" ] && [ "$LITELLM_PROVIDER_HUGGINGFACE_API_KEY" != "your_huggingface_api_key" ]; then
        log_info "Adding HuggingFace models to configuration..."
        if validate_api_key "huggingface" "$LITELLM_PROVIDER_HUGGINGFACE_API_KEY"; then
            log_success "HuggingFace API key format is valid"
        fi
        
        cat >> "$CONFIG_FILE" << EOF
  
  # HuggingFace Models
  - model_name: "llama-3.1-8b"
    litellm_params:
      model: huggingface/meta-llama/Meta-Llama-3.1-8B-Instruct
      api_key: os.environ/LITELLM_PROVIDER_HUGGINGFACE_API_KEY
    model_info:
      tags: ["external", "huggingface", "chat", "open-source"]
      
  - model_name: "mixtral-8x7b"
    litellm_params:
      model: huggingface/mistralai/Mixtral-8x7B-Instruct-v0.1
      api_key: os.environ/LITELLM_PROVIDER_HUGGINGFACE_API_KEY
    model_info:
      tags: ["external", "huggingface", "chat", "mixture-of-experts"]
EOF
    fi
    
    # XAI (Grok) - Enhanced with more models
    if [ ! -z "$LITELLM_PROVIDER_XAI_API_KEY" ] && [ "$LITELLM_PROVIDER_XAI_API_KEY" != "your_xai_api_key" ]; then
        log_info "Adding xAI models to configuration..."
        if validate_api_key "xai" "$LITELLM_PROVIDER_XAI_API_KEY"; then
            log_success "xAI API key format is valid"
        fi
        
        cat >> "$CONFIG_FILE" << EOF
  
  # xAI Models
  - model_name: "grok-beta"
    litellm_params:
      model: xai/grok-beta
      api_key: os.environ/LITELLM_PROVIDER_XAI_API_KEY
    model_info:
      tags: ["external", "xai", "chat", "experimental"]
      
  - model_name: "grok-vision-beta"
    litellm_params:
      model: xai/grok-vision-beta
      api_key: os.environ/LITELLM_PROVIDER_XAI_API_KEY
    model_info:
      tags: ["external", "xai", "chat", "vision", "experimental"]
EOF
    fi
    
    # Cohere Models
    if [ ! -z "$LITELLM_PROVIDER_COHERE_API_KEY" ] && [ "$LITELLM_PROVIDER_COHERE_API_KEY" != "your_cohere_api_key" ]; then
        log_info "Adding Cohere models to configuration..."
        
        cat >> "$CONFIG_FILE" << EOF
  
  # Cohere Models
  - model_name: "command-r-plus"
    litellm_params:
      model: cohere/command-r-plus
      api_key: os.environ/LITELLM_PROVIDER_COHERE_API_KEY
    model_info:
      tags: ["external", "cohere", "chat", "premium"]
      
  - model_name: "command-r"
    litellm_params:
      model: cohere/command-r
      api_key: os.environ/LITELLM_PROVIDER_COHERE_API_KEY
    model_info:
      tags: ["external", "cohere", "chat", "standard"]
      
  - model_name: "command-light"
    litellm_params:
      model: cohere/command-light
      api_key: os.environ/LITELLM_PROVIDER_COHERE_API_KEY
    model_info:
      tags: ["external", "cohere", "chat", "fast"]
EOF
    fi
    
    # Add LiteLLM settings
    cat >> "$CONFIG_FILE" << EOF

# ============================================
# LiteLLM Settings
# ============================================
litellm_settings:
  drop_params: true
  success_callback: []  # Add "langfuse" for observability if needed

# ============================================
# General Settings
# ============================================
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/DATABASE_URL
  
router_settings:
  routing_strategy: simple-shuffle  # Options: simple-shuffle, least-busy, usage-based-routing
  model_group_alias:
    # Group aliases for easy access
    "bedrock-chat": ["bedrock-chat"]
    "bedrock-image": ["bedrock-image"] 
    "external": ["external"]
    # Provider-specific aliases
    "aws": ["bedrock-chat", "bedrock-image"]
    "openai": ["openai"]
    "mistral": ["mistral"]
    "anthropic": ["anthropic"]
    "huggingface": ["huggingface"]
    "xai": ["xai"]
    # Capability-based aliases
    "chat": ["chat"]
    "image-generation": ["image-generation"]
    "code": ["code"]
  num_retries: 3
  timeout: 600  # 10 minutes
  max_tokens: 4096
  fallbacks: []
EOF
}

# Function to generate image models YAML
generate_image_config() {
    log_info "Generating LiteLLM image generation configuration..."
    
    cat > "$IMAGE_CONFIG_FILE" << 'EOF'
# LiteLLM Image Generation Configuration - Generated by generate-config-litellm-hybrid.sh
# This file is auto-generated. Do not edit manually.
# Generated at: $(date)

model_list:
EOF
    
    # Add Bedrock image models
    if [ -f /tmp/image_models.json ] && [ "$(cat /tmp/image_models.json)" != "[]" ]; then
        echo "  # ============================================" >> "$IMAGE_CONFIG_FILE"
        echo "  # AWS Bedrock Image Generation Models" >> "$IMAGE_CONFIG_FILE"
        echo "  # ============================================" >> "$IMAGE_CONFIG_FILE"
        
        jq -r '.[] | "  - model_name: \"\(.[0])\"\n    litellm_params:\n      model: bedrock/\(.[1])\n      aws_region_name: '"$AWS_REGION"'"' /tmp/image_models.json >> "$IMAGE_CONFIG_FILE"
        echo "" >> "$IMAGE_CONFIG_FILE"
    fi
    
    # Add OpenAI image models if API key present
    if [ ! -z "$LITELLM_PROVIDER_OPENAI_API_KEY" ] && [ "$LITELLM_PROVIDER_OPENAI_API_KEY" != "your_openai_api_key" ]; then
        cat >> "$IMAGE_CONFIG_FILE" << EOF
  
  # OpenAI Image Models
  - model_name: "dall-e-3"
    litellm_params:
      model: openai/dall-e-3
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
      
  - model_name: "dall-e-2"
    litellm_params:
      model: openai/dall-e-2
      api_key: os.environ/LITELLM_PROVIDER_OPENAI_API_KEY
EOF
    fi
    
    # Add settings
    cat >> "$IMAGE_CONFIG_FILE" << EOF

# ============================================
# LiteLLM Settings
# ============================================
litellm_settings:
  drop_params: true

# ============================================
# General Settings
# ============================================
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
EOF
}

# Function to validate configuration completeness
validate_configuration() {
    log_info "Validating configuration completeness..."
    
    local providers_configured=0
    local providers_available=""
    
    # Check each provider
    if [ ! -z "$LITELLM_PROVIDER_OPENAI_API_KEY" ] && [ "$LITELLM_PROVIDER_OPENAI_API_KEY" != "your_openai_api_key" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available OpenAI"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_MISTRAL_API_KEY" ] && [ "$LITELLM_PROVIDER_MISTRAL_API_KEY" != "your_mistral_api_key" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available Mistral"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_XAI_API_KEY" ] && [ "$LITELLM_PROVIDER_XAI_API_KEY" != "your_xai_api_key" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available xAI"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" ] && [ "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" != "your_anthropic_api_key" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available Anthropic"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_HUGGINGFACE_API_KEY" ] && [ "$LITELLM_PROVIDER_HUGGINGFACE_API_KEY" != "your_huggingface_api_key" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available HuggingFace"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_COHERE_API_KEY" ] && [ "$LITELLM_PROVIDER_COHERE_API_KEY" != "your_cohere_api_key" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available Cohere"
    fi
    
    if [ "$SKIP_BEDROCK" = "false" ]; then
        providers_configured=$((providers_configured + 1))
        providers_available="$providers_available AWS-Bedrock"
    fi
    
    log_info "External providers configured: $providers_configured"
    if [ $providers_configured -gt 0 ]; then
        log_success "Available providers:$providers_available"
    else
        log_warning "No external providers configured. Only local Ollama models will be available."
        log_info "To add providers, configure API keys in your .env file"
    fi
}

# Main execution
main() {
    log_info "Starting LiteLLM configuration generation for hybrid deployment"
    echo ""
    
    # Validate configuration
    validate_configuration
    echo ""
    
    # Discover models
    discover_bedrock_text_models
    discover_bedrock_image_models
    
    # Generate unified configuration
    generate_unified_config
    
    # Clean up temporary files
    rm -f /tmp/inference_profiles.json /tmp/foundation_models.json /tmp/image_models.json
    
    # Summary
    echo ""
    log_success "Configuration generation completed successfully!"
    echo ""
    log_info "Generated files:"
    echo "  📄 $CONFIG_FILE"
    echo ""
    
    # Count models
    if [ -f "$CONFIG_FILE" ]; then
        local total_models=$(grep -c "model_name:" "$CONFIG_FILE" || echo "0")
        local bedrock_chat_models=0
        local bedrock_image_models=0
        local external_models=0
        
        if [ "$SKIP_BEDROCK" = "false" ]; then
            bedrock_chat_models=$(grep -A50 "GROUP 1: BEDROCK CHAT MODELS" "$CONFIG_FILE" | grep -c "model_name:" || echo "0")
            bedrock_image_models=$(grep -A20 "GROUP 2: BEDROCK IMAGE MODELS" "$CONFIG_FILE" | grep -c "model_name:" || echo "0")
        fi
        
        external_models=$(grep -A100 "GROUP 3: EXTERNAL PROVIDER MODELS" "$CONFIG_FILE" | grep -c "model_name:" || echo "0")
        
        log_info "Model Summary:"
        log_info "  └─ Total models: $total_models"
        log_info "  └─ Bedrock Chat: $bedrock_chat_models"
        log_info "  └─ Bedrock Image: $bedrock_image_models"
        log_info "  └─ External Providers: $external_models"
    fi
    
    echo ""
    log_info "Model Groups configured:"
    echo "  🔹 bedrock-chat: AWS Bedrock text/chat models"
    echo "  🔹 bedrock-image: AWS Bedrock image generation models"
    echo "  🔹 external: External provider models (OpenAI, Mistral, xAI, etc.)"
    echo ""
    log_info "Next steps:"
    echo "  1. Review the generated configuration file"
    echo "  2. Run: make hybrid-up"
    echo "  3. LiteLLM will be available at http://localhost:4000"
    echo "  4. Open WebUI will be available at http://localhost:3002"
    echo "  5. Access models through the unified API endpoint"
    echo ""
    
    if [ $providers_configured -eq 0 ] && [ "$SKIP_BEDROCK" = "true" ]; then
        log_warning "No providers are configured! Please add API keys to your .env file."
        echo ""
        log_info "Example .env configuration:"
        echo "  LITELLM_PROVIDER_OPENAI_API_KEY=sk-your-openai-key"
        echo "  LITELLM_PROVIDER_MISTRAL_API_KEY=your-mistral-key"
        echo "  LITELLM_PROVIDER_XAI_API_KEY=xai-your-xai-key"
        echo "  AWS_REGION=us-west-2"
    fi
}

# Parse command line arguments
VALIDATE_ONLY=false
QUIET=false
FORCE_SKIP_BEDROCK=false
TEST_PROVIDERS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --skip-bedrock)
            FORCE_SKIP_BEDROCK=true
            shift
            ;;
        --test-providers)
            TEST_PROVIDERS=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Override bedrock skip if forced
if [ "$FORCE_SKIP_BEDROCK" = "true" ]; then
    SKIP_BEDROCK=true
fi

# Run main function or validation only
if [ "$VALIDATE_ONLY" = "true" ]; then
    log_info "Validation mode - checking configuration only"
    validate_configuration
elif [ "$TEST_PROVIDERS" = "true" ]; then
    log_info "Testing provider connectivity..."
    validate_configuration
    
    # Test each configured provider
    if [ ! -z "$LITELLM_PROVIDER_OPENAI_API_KEY" ] && [ "$LITELLM_PROVIDER_OPENAI_API_KEY" != "your_openai_api_key" ]; then
        check_provider_availability "openai" "$LITELLM_PROVIDER_OPENAI_API_KEY"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_MISTRAL_API_KEY" ] && [ "$LITELLM_PROVIDER_MISTRAL_API_KEY" != "your_mistral_api_key" ]; then
        check_provider_availability "mistral" "$LITELLM_PROVIDER_MISTRAL_API_KEY"
    fi
    
    if [ ! -z "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" ] && [ "$LITELLM_PROVIDER_ANTHROPIC_API_KEY" != "your_anthropic_api_key" ]; then
        check_provider_availability "anthropic" "$LITELLM_PROVIDER_ANTHROPIC_API_KEY"
    fi
else
    main "$@"
fi
