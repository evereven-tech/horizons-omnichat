.PHONY: build serve clean

# Detect container engine (docker or podman)
CONTAINER_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "docker")

build:
	$(CONTAINER_CMD) run --rm \
		--volume="$PWD:/srv/jekyll:rw" \
		-it jekyll/jekyll:latest \
		bundle update

serve: 
	$(CONTAINER_CMD) run --rm \
		--volume="$$PWD:/srv/jekyll:rw,Z" \
		-e JEKYLL_ROOTLESS=1 \
		--publish 4000:4000 \
		jekyll/jekyll \
		jekyll serve --source ./docs --destination ./dist --trace

clean:
	rm -rf dist
