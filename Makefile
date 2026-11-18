.DEFAULT_GOAL := help
.PHONY: help setup check build lint test

help: ## List the commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-7s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Once per clone: switch on the commit gate
	git config core.hooksPath .githooks

check: build lint test ## The commit gate: everything below, in order

build: ## Validate the plugin folder, which is the artifact, and the marketplace that installs it
	claude plugin validate --strict plugin
	claude plugin validate --strict .

lint: ## Skill size, names, links, plugin paths, shell syntax, stray service words
	sh scripts/lint.sh

test: ## Prove the hook templates, the lint checks, the trial runner and its report
	sh scripts/test-hooks.sh
	sh scripts/test-lint.sh
	sh scripts/test-run.sh
	sh scripts/test-after.sh
