.PHONY: serve clean

# Detect container engine (docker or podman)
CONTAINER_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null || echo "docker")

serve:
	$(CONTAINER_CMD) run --rm \
		-v $(PWD)/docs:/site \
		-v $(PWD)/dist:/dist \
		-v $(PWD)/Gemfile:/site/Gemfile \
		-v $(PWD)/Gemfile.lock:/site/Gemfile.lock \
		-p 4200:4200 \
		jekyll/jekyll:4.2.2 \
		jekyll serve --host 0.0.0.0 --port 4200 --destination /dist

clean:
	rm -rf dist
