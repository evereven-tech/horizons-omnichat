CONTAINER_RUNTIME := $(shell which podman 2>/dev/null || which docker 2>/dev/null)
ENV_FILE := hybrid/.env
JSON_FILE := hybrid/config.json
BEDROCK_API := BEDROCK_API_KEY
# Variables para Terraform
TF_DIR := aws

# Incluir variables de AWS si existe el archivo
-include .env.aws

# Mostrar plan de Terraform
aws-plan:
	@echo "Validando credenciales AWS..."
	@if [ -z "$$AWS_ACCESS_KEY_ID" ]; then \
		echo "Error: AWS_ACCESS_KEY_ID no está definido"; \
		exit 1; \
	fi
	@if [ -z "$$AWS_SECRET_ACCESS_KEY" ]; then \
		echo "Error: AWS_SECRET_ACCESS_KEY no está definido"; \
		exit 1; \
	fi
	@echo "Inicializando Terraform..."
	@cd $(TF_DIR) && terraform init
	@echo "Generando plan de Terraform..."
	@cd $(TF_DIR) && terraform plan -out=tfplan

# Aplicar cambios de Terraform
aws-apply:
	@echo "Aplicando cambios de Terraform..."
	@cd $(TF_DIR) && terraform apply tfplan

# Destruir infraestructura
aws-destroy:
	@echo "¡ADVERTENCIA! Esto destruirá toda la infraestructura en AWS. ¿Estás seguro? (s/N)"
	@read -p "Respuesta: " confirm; \
	if [ "$$confirm" = "s" ] || [ "$$confirm" = "S" ]; then \
		echo "Iniciando destrucción de infraestructura..."; \
		cd $(TF_DIR) && terraform destroy -auto-approve; \
	else \
		echo "Operación cancelada"; \
	fi

.PHONY: init validate-local validate-hybrid local-up local-down hybrid-up hybrid-down aws-plan aws-apply aws-destroy

# Incluir variables del .env
include $(ENV_FILE)
export $(shell sed 's/=.*//' $(ENV_FILE))

# Basic commands
init:
	@if [ ! -d "external/bedrock-gateway" ]; then \
		git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway; \
	fi
	git submodule update --init --recursive

validate-local:
	@echo "Validating local configuration..."
	@cd local && test -f .env || (echo "Error: .env file not found in local/. Copy local/.env.example to local/.env first." && exit 1)

# Local deployment commands
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

# Hybrid deployment commands
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
