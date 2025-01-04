.PHONY: init validate local-up local-down

# Basic commands
init:
	git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway
	git submodule update --init --recursive

validate:
	@echo "Validating configuration..."
	@test -f .env || (echo "Error: .env file not found. Copy .env.example to .env first." && exit 1)

# Local deployment commands
local-up: validate
	@echo "Starting local deployment..."
	cd local && docker compose up -d

local-down:
	@echo "Stopping local deployment..."
	cd local && docker compose down
