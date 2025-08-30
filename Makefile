CONTAINER_RUNTIME := $(shell which podman 2>/dev/null || which docker 2>/dev/null)

# Common Targets ##############################################################
.PHONY: init

init:
	@if [ ! -d "external/bedrock-gateway" ]; then \
		git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway; \
	fi
	@if [ ! -d "external/sample-ollama-server" ]; then \
		git submodule add https://github.com/aws-samples/sample-ollama-server.git external/sample-ollama-server; \
	fi
	git submodule update --init --recursive

# Local Targets ###############################################################
.PHONY: local-validate local-up local-down

local-validate:
	@echo "Validating local configuration..."
	@cd local && test -f .env || (echo "Error: .env file not found in local/. Copy local/.env.example to local/.env first." && exit 1)

local-up: local-validate
	@echo "Starting local deployment..."
	@cd local && export OLLAMA_USE_GPU=$$(grep OLLAMA_USE_GPU .env | cut -d '=' -f2) && \
	echo "GPU Support enabled: $$OLLAMA_USE_GPU" && \
	if [ "$$OLLAMA_USE_GPU" = "true" ]; then \
		$(CONTAINER_RUNTIME) compose --in-pod false -f docker-compose.yml -f ../common/docker-compose.gpu.yml up -d; \
	else \
		$(CONTAINER_RUNTIME) compose up -d; \
	fi

local-down:
	@echo "Stopping local deployment..."
	@cd local && $(CONTAINER_RUNTIME) compose down

# Hybrid Targets ##############################################################
.PHONY: hybrid-validate hybrid-up hybrid-down

# Hybrid Specific variables
ENV_FILE := hybrid/.env
JSON_FILE := hybrid/config.json
BEDROCK_API := BEDROCK_API_KEY
LITELLM_API := LITELLM_API_KEY

# Load vars from .env file
MAKECMDGOALS ?= ""
ifneq (,$(filter hybrid-%,$(MAKECMDGOALS)))
    include $(ENV_FILE)
    export $(shell sed 's/=.*//' $(ENV_FILE))
endif

hybrid-validate:
	@echo "Validating hybrid configuration..."
	@cd hybrid && test -f .env || (echo "Error: .env file not found in hybrid/. Copy hybrid/.env.example to hybrid/.env first." && exit 1)
	@cd hybrid && test -f config.json || (echo "Error: config.json file not found in hybrid/. Copy hybrid/config.json.template to hybrid/config.json first." && exit 1)
	@cd hybrid && test -f litellm_config.yaml || (echo "Error: litellm_config.yaml not found. Run 'bin/generate-config-litellm-hybrid.sh' to generate LiteLLM configuration." && exit 1)
	@test -d external/bedrock-gateway || (echo "Error: bedrock-gateway not found. Run 'make init' first." && exit 1)

hybrid-up: hybrid-validate
	@echo "Starting hybrid deployment..."
	@sed -i 's/"$(BEDROCK_API)"/"$(BEDROCK_API_KEY)"/' $(JSON_FILE)
	@sed -i 's/"$(LITELLM_API)"/"$(LITELLM_MASTER_KEY)"/' $(JSON_FILE)
	@cd hybrid && export OLLAMA_USE_GPU=$$(grep OLLAMA_USE_GPU .env | cut -d '=' -f2) && \
	echo "GPU Support: $$OLLAMA_USE_GPU" && \
	if [ "$$OLLAMA_USE_GPU" = "true" ]; then \
		$(CONTAINER_RUNTIME) compose --in-pod false -f docker-compose.yml -f ../common/docker-compose.gpu.yml up -d; \
	else \
		$(CONTAINER_RUNTIME) compose up -d; \
	fi

hybrid-down:
	@echo "Stopping hybrid deployment..."
	@cd hybrid && $(CONTAINER_RUNTIME) compose down

# AWS Targets #################################################################
.PHONY: aws-validate aws-init aws-lint aws-plan aws-apply aws-upgrade aws-deploy aws-destroy aws-shell-webui aws-shell-bedrock

# AWS Specific variables
TF_DIR := aws

aws-validate:
	@echo "Validating AWS configuration..."
	@test -f $(TF_DIR)/terraform.tfvars || (echo "Error: terraform.tfvars not found in $(TF_DIR)/. Copy $(TF_DIR)/terraform.tfvars.example to $(TF_DIR)/terraform.tfvars and configure it." && exit 1)
	@test -f $(TF_DIR)/backend.hcl || (echo "Error: backend.hcl not found in $(TF_DIR)/. Copy $(TF_DIR)/backend.hcl.example to $(TF_DIR)/backend.hcl and configure it." && exit 1)
	@command -v terraform >/dev/null 2>&1 || (echo "Error: terraform is not installed. Please install Terraform first." && exit 1)
	@command -v aws >/dev/null 2>&1 || (echo "Error: AWS CLI is not installed. Please install AWS CLI first." && exit 1)

aws-init: aws-validate
	@echo "Checking backend configuration..."
	@test -f $(TF_DIR)/backend.hcl || (echo "Error: backend.hcl not found. Copy backend.hcl.example to backend.hcl and configure it." && exit 1)
	@echo "Initializing Terraform..."
	@cd $(TF_DIR) && terraform init -backend-config=backend.hcl

aws-plan: aws-init
	@echo "Terraform plan..."
	@cd $(TF_DIR) && terraform plan -out=tfplan

aws-upgrade:
	@echo "Terraform upgrade..."
	@cd $(TF_DIR) && terraform init -upgrade

aws-apply: aws-init
	@echo "Terraform Apply..."
	@cd $(TF_DIR) && terraform apply tfplan

aws-deploy: aws-plan aws-apply

aws-lint: aws-init
	@echo "Terraform lint..."
	@cd $(TF_DIR) && terraform fmt --recursive && terraform validate

aws-destroy: aws-init
	@echo "¡CAUTION! This is going to destroy all AWS infraestructure related with Horizons. Are you really sure? (y/N)"
	@read -p "Answer: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "Launch teraform destroy..."; \
		cd $(TF_DIR) && terraform destroy -auto-approve; \
	else \
		echo "Operation cancelled"; \
	fi

aws-shell-webui: ## Connect to OpenWebUI container shell
	aws ecs execute-command \
		--cluster horizons-compute-fargate \
		--task $$(aws ecs list-tasks --cluster horizons-compute-fargate --service-name horizons-compute-webui --query 'taskArns[0]' --output text) \
		--container webui \
		--command "/bin/sh" \
		--interactive

aws-shell-bedrock: ## Connect to Bedrock Gateway container shell
	aws ecs execute-command \
		--cluster horizons-compute-fargate \
		--task $$(aws ecs list-tasks --cluster horizons-compute-fargate --service-name horizons-compute-bedrock --query 'taskArns[0]' --output text) \
		--container bedrock-gateway \
		--command "/bin/sh" \
		--interactive

# k8s Targets #################################################################
# TBD
