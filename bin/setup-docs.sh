#!/bin/bash

# Install pre-commit
pip install pre-commit
pre-commit install

# Initial build of documentation
make docs-build
