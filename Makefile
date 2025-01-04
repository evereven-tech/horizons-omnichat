.PHONY: init local-up local-down hybrid-up hybrid-down aws-init aws-plan aws-apply aws-destroy k8s-apply k8s-delete k8s-status

include .env

# Basic commands
init:
	git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway
	git submodule update --init --recursive

validate:
	@echo "Validating configuration..."
	@test -f .env || (echo "Error: .env file not found. Copy .env.example to .env first." && exit 1)

# Local deployment
local-up: validate
	cd local && docker-compose up -d

local-down:
	cd local && docker-compose down

# Hybrid deployment
hybrid-up: validate
	cd hybrid && docker-compose up -d

hybrid-down:
	cd hybrid && docker-compose down

# AWS deployment
aws-init:
	cd aws && terraform init

aws-plan:
	cd aws && terraform plan

aws-apply:
	cd aws && terraform apply

aws-destroy:
	cd aws && terraform destroy

# Kubernetes deployment
k8s-apply:
	kubectl apply -f k8s/manifests/

k8s-delete:
	kubectl delete -f k8s/manifests/

k8s-status:
	kubectl get all -l app=chatbot
