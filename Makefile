.PHONY: build serve clean

# Detect container engine (docker or podman)
CONTAINER_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "docker")

build:
	$(CONTAINER_CMD) build -t horizons-docs .

serve: build
	$(CONTAINER_CMD) run --rm \
		-v $(PWD)/docs:/docs \
		-v $(PWD)/dist:/dist \
		-p 4200:4200 \
		horizons-docs

clean:
	rm -rf dist
