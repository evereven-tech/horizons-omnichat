.PHONY: init validate-local local-up local-down

# Basic commands
init:
	git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway
	git submodule update --init --recursive

validate-local:
	@echo "Validating local configuration..."
	@cd local && test -f .env || (echo "Error: .env file not found in local/. Copy local/.env.example to local/.env first." && exit 1)

# Local deployment commands
local-up: validate-local
	@echo "Starting local deployment..."
	@echo "GPU Support: $(OLLAMA_USE_GPU)"
	@cd local && if [ "$(OLLAMA_USE_GPU)" = "true" ]; then \
		docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d; \
	else \
		docker compose up -d; \
	fi

local-down:
	@echo "Stopping local deployment..."
	@cd local && docker compose down
