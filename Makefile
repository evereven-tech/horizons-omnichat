CONTAINER_RUNTIME := $(shell which podman 2>/dev/null || which docker 2>/dev/null)

# Common Targets ##############################################################
.PHONY: init 

init:
	@if [ ! -d "external/bedrock-gateway" ]; then \
		git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway; \
	fi
	git submodule update --init --recursive

# Local Targets ###############################################################
.PHONY: validate-local local-up local-down

validate-local:
	@echo "Validating local configuration..."
	@cd local && test -f .env || (echo "Error: .env file not found in local/. Copy local/.env.example to local/.env first." && exit 1)

local-up: validate-local
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
.PHONY: init validate-local local-up local-down

# Hybrid Specific variables
ENV_FILE := hybrid/.env
JSON_FILE := hybrid/config.json
BEDROCK_API := BEDROCK_API_KEY

# Load vars from .env file
MAKECMDGOALS ?= ""
ifneq (,$(filter hybrid-%,$(MAKECMDGOALS)))
    include $(ENV_FILE)
    export $(shell sed 's/=.*//' $(ENV_FILE))
endif

validate-hybrid:
	@echo "Validating hybrid configuration..."
	@cd hybrid && test -f .env || (echo "Error: .env file not found in hybrid/. Copy hybrid/.env.example to hybrid/.env first." && exit 1)
	@cd hybrid && test -f config.json || (echo "Error: config.json file not found in hybrid/. Copy hybrid/config.json.template to hybrid/config.json first." && exit 1)
	@test -d external/bedrock-gateway || (echo "Error: bedrock-gateway not found. Run 'make init' first." && exit 1)

hybrid-up: validate-hybrid
	@echo "Starting hybrid deployment..."
	@sed -i 's/"$(BEDROCK_API)"/"$(BEDROCK_API_KEY)"/' $(JSON_FILE)
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
.PHONY: validate-hybrid hybrid-up hybrid-down aws-init aws-lint aws-plan aws-apply aws-deploy aws-destroy shell-webui shell-ollama shell-bedrock

# AWS Specific variables
TF_DIR := aws

aws-init:
	@echo "Checking backend configuration..."
	@test -f $(TF_DIR)/backend.hcl || (echo "Error: backend.hcl not found. Copy backend.hcl.example to backend.hcl and configure it." && exit 1)
	@echo "Initializing Terraform..."
	@cd $(TF_DIR) && terraform init -backend-config=backend.hcl

aws-plan: aws-init
	@echo "Terraform plan..."
	@cd $(TF_DIR) && terraform plan -out=tfplan

aws-lint: aws-init
	@echo "Terraform lint..."
	@cd $(TF_DIR) && terraform fmt && terraform validate

aws-apply: aws-init
	@echo "Terraform Apply..."
	@cd $(TF_DIR) && terraform apply tfplan

aws-deploy: aws-plan aws-apply

# Destruir infraestructura
aws-destroy: aws-init
	@echo "¡CAUTION! This is going to destroy all AWS infraestructure related with Horizons. Are you really sure? (y/N)"
	@read -p "Answer: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "Launch teraform destroy..."; \
		cd $(TF_DIR) && terraform destroy -auto-approve; \
	else \
		echo "Operation cancelled"; \
	fi

shell-webui: ## Connect to OpenWebUI container shell
	aws ecs execute-command \
		--cluster horizons-compute-fargate \
		--task $$(aws ecs list-tasks --cluster horizons-compute-fargate --service-name horizons-compute-webui --query 'taskArns[0]' --output text) \
		--container webui \
		--command "/bin/sh" \
		--interactive

shell-ollama: ## Connect to Ollama container shell
	aws ecs execute-command \
		--cluster horizons-compute-ec2 \
		--task $$(aws ecs list-tasks --cluster horizons-compute-ec2 --service-name horizons-compute-ollama --query 'taskArns[0]' --output text) \
		--container ollama \
		--command "/bin/sh" \
		--interactive

shell-bedrock: ## Connect to Bedrock Gateway container shell
	aws ecs execute-command \
		--cluster horizons-compute-fargate \
		--task $$(aws ecs list-tasks --cluster horizons-compute-fargate --service-name horizons-compute-bedrock --query 'taskArns[0]' --output text) \
		--container bedrock-gateway \
		--command "/bin/sh" \
		--interactive

# k8s Targets #################################################################
