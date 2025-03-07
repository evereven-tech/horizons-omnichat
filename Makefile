.PHONY: serve build clean

# Variables
DOCKER_CMD := $(shell command -v podman 2> /dev/null || echo docker)
JEKYLL_VERSION := latest
JEKYLL_CONTAINER := mcr.microsoft.com/devcontainers/jekyll:$(JEKYLL_VERSION)
JEKYLL_PORT := 4000

# Main Targets
bundle:
	$(DOCKER_CMD) run --rm \
		-v "$(PWD):/srv/jekyll:rw,Z" \
		-w /srv/jekyll \
		-e JEKYLL_ROOTLESS=1 \
		-it $(JEKYLL_CONTAINER) \
		bundle install 

serve:
	$(DOCKER_CMD) run --rm \
		-v "$(PWD):/srv/jekyll:rw,Z" \
		-p $(JEKYLL_PORT):$(JEKYLL_PORT) \
		-e JEKYLL_ROOTLESS=1 \
		-it $(JEKYLL_CONTAINER) \
		jekyll serve --config /srv/jekyll/_config.yml --source /srv/jekyll/ --livereload --host 0.0.0.0 --trace 

build:
	$(DOCKER_CMD) run --rm \
		-v "$(PWD):/srv/jekyll:rw,Z" \
		-e JEKYLL_ROOTLESS=1 \
		-it $(JEKYLL_CONTAINER) \
		jekyll build --config /srv/jekyll/_config.yml --source /srv/jekyll/ --destination /srv/jekyll/_site

clean:
	$(DOCKER_CMD) run --rm \
		-v "$(PWD):/srv/jekyll:rw,Z" \
		-e JEKYLL_ROOTLESS=1 \
		-it $(JEKYLL_CONTAINER) \
		jekyll clean --config /srv/jekyll/_config.yml --destination /srv/jekyll/_site

help:
	@echo "Available Commands:"
	@echo "  make serve  - Star Jekyll server on http://localhost:4000"
	@echo "  make build  - Build the static version of the site"
	@echo "  make clean  - Clean generated files"
	@echo "  make bundle - Install dependencies frome Gemfile"
