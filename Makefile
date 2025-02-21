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
		--volume="$$PWD:/srv/jekyll:Z" \
		--publish 4000:4000 \
		jekyll/jekyll \
		jekyll serve -s docs --trace

clean:
	rm -rf dist
