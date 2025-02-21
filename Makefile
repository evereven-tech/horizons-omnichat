.PHONY: init docs-build docs-serve docs-clean docs-deploy local-up local-down hybrid-up hybrid-down aws-init aws-plan aws-apply aws-destroy k8s-apply k8s-delete k8s-status

include .env

# Detect container engine (docker or podman)
CONTAINER_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "docker")
JEKYLL_VERSION := 3

# Documentation commands
docs-build:
	$(CONTAINER_CMD) build -t horizons-docs .

docs-serve: docs-build
	$(CONTAINER_CMD) run --rm -v $(PWD)/docs:/site -p 4200:4200 horizons-docs

docs-clean:
	rm -rf docs/dist
	rm -rf docs/.jekyll-cache
	rm -rf docs/.sass-cache
	rm -rf docs/vendor
	rm -rf docs/.bundle

docs-deploy: docs-clean
	git add docs/
	git commit -m "docs: Update documentation"
	git push origin main

# Basic commands
init:
	git submodule add https://github.com/aws-samples/bedrock-access-gateway.git external/bedrock-gateway
	git submodule update --init --recursive

validate:
	@echo "Validating configuration..."
	@test -f .env || (echo "Error: .env file not found. Copy .env.example to .env first." && exit 1)

# Local deployment
local-up: validate
	cd local && $(CONTAINER_CMD)-compose up -d

local-down:
	cd local && $(CONTAINER_CMD)-compose down

# Hybrid deployment
hybrid-up: validate
	cd hybrid && $(CONTAINER_CMD)-compose up -d

hybrid-down:
	cd hybrid && $(CONTAINER_CMD)-compose down

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
