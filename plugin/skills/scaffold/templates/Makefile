# <Project name>: the task runner. `make` lists the commands.
#
# Filling this in: write each recipe for this project's stack, add the targets the plan
# names, and delete this paragraph. Every target keeps its `## ` description, because
# `make help` is built from them. A recipe left unfilled fails, so the gate can't pass empty.

.DEFAULT_GOAL := help
.PHONY: help setup check test build

help: ## List the commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Once per clone: install what the project needs and switch on the commit gate
	git config core.hooksPath .githooks
	@echo 'make setup: the install step is not filled in' >&2; exit 1

check: ## The commit gate: types, lint and the fast tests
	@echo 'make check: not filled in' >&2; exit 1

test: ## Run the tests
	@echo 'make test: not filled in' >&2; exit 1

build: ## Build the artifact from this clone
	@echo 'make build: not filled in' >&2; exit 1
