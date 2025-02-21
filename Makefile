.PHONY: init build serve clean

# Detect container engine (docker or podman)
CONTAINER_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "docker")
JEKYLL_VERSION := 3

# Documentation commands
build:
	$(CONTAINER_CMD) build -t horizons-docs .

serve: docs-build
	$(CONTAINER_CMD) run --rm -v $(PWD)/docs:/site -p 4200:4200 horizons-docs

clean:
	rm -rf docs/dist
	rm -rf docs/.jekyll-cache
	rm -rf docs/.sass-cache
	rm -rf docs/vendor
	rm -rf docs/.bundle
