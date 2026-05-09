# Makefile for the Lykn Site

# ANSI color codes
BLUE := \033[1;34m
GREEN := \033[1;32m
YELLOW := \033[1;33m
RED := \033[1;31m
CYAN := \033[1;36m
RESET := \033[0m

# Variables
PROJECT_NAME := Lykn Site
DEST := _site
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')

# Git remotes to push to
GIT_REMOTES := origin
REMOTE_origin := git@github.com:lykn-lang/site.git

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET) $(BLUE)$(PROJECT_NAME) Build System$(RESET)                                   $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)Site:$(RESET)"
	@echo "  $(YELLOW)make build$(RESET)            - Build the site with Cobalt"
	@echo "  $(YELLOW)make serve$(RESET)            - Build and serve the site locally"
	@echo "  $(YELLOW)make watch$(RESET)            - Build, serve, and watch for changes"
	@echo ""
	@echo "$(GREEN)Cleaning:$(RESET)"
	@echo "  $(YELLOW)make clean$(RESET)            - Remove the built site ($(DEST)/)"
	@echo ""
	@echo "$(GREEN)Utilities:$(RESET)"
	@echo "  $(YELLOW)make push$(RESET)             - Push to configured remotes"
	@echo "  $(YELLOW)make tracked-files$(RESET)    - Save list of tracked files"
	@echo ""
	@echo "$(GREEN)Information:$(RESET)"
	@echo "  $(YELLOW)make info$(RESET)             - Show build information"
	@echo "  $(YELLOW)make check-tools$(RESET)      - Verify required tools are installed"
	@echo ""
	@echo "$(CYAN)Current status:$(RESET) Branch: $(GIT_BRANCH) | Commit: $(GIT_COMMIT)"
	@echo ""

# Info target
.PHONY: info
info:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET)  $(BLUE)Build Information$(RESET)                                       $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)Project:$(RESET)"
	@echo "  Name:           $(PROJECT_NAME)"
	@echo "  Build Time:     $(BUILD_TIME)"
	@echo "  Destination:    $(DEST)/"
	@echo "  Workspace:      $$(pwd)"
	@echo ""
	@echo "$(GREEN)Git:$(RESET)"
	@echo "  Branch:         $(GIT_BRANCH)"
	@echo "  Commit:         $(GIT_COMMIT)"
	@echo ""
	@echo "$(GREEN)Tools:$(RESET)"
	@echo "  Cobalt:         $$(cobalt --version 2>/dev/null || echo 'not found')"
	@echo ""

# Check tools target
.PHONY: check-tools
check-tools:
	@echo "$(BLUE)Checking for required tools...$(RESET)"
	@command -v cobalt >/dev/null 2>&1 && echo "$(GREEN)✓ cobalt found (version: $$(cobalt --version))$(RESET)" || echo "$(RED)✗ cobalt not found$(RESET)"
	@command -v git >/dev/null 2>&1 && echo "$(GREEN)✓ git found$(RESET)" || echo "$(RED)✗ git not found$(RESET)"
	@test -f _cobalt.yml && echo "$(GREEN)✓ _cobalt.yml found$(RESET)" || echo "$(RED)✗ _cobalt.yml not found$(RESET)"

# Site targets
.PHONY: build
build:
	@echo "$(BLUE)Building $(PROJECT_NAME)...$(RESET)"
	@cobalt build
	@echo "$(GREEN)✓ Site built to $(DEST)/$(RESET)"

.PHONY: serve
serve: build
	@echo "$(BLUE)Starting local server...$(RESET)"
	@echo "$(CYAN)→ http://localhost:1024$(RESET)"
	@cobalt serve

.PHONY: watch
watch:
	@echo "$(BLUE)Building, serving, and watching for changes...$(RESET)"
	@echo "$(CYAN)→ http://localhost:1024$(RESET)"
	@cobalt serve --watch

# Cleaning targets
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning built site...$(RESET)"
	@rm -rf $(DEST)
	@echo "$(GREEN)✓ Clean complete$(RESET)"

# Utility targets
.PHONY: tracked-files
tracked-files:
	@echo "$(BLUE)Saving tracked files list...$(RESET)"
	@git ls-files > git-tracked-files.txt
	@echo "$(GREEN)✓ Tracked files saved to git-tracked-files.txt$(RESET)"
	@echo "$(CYAN)• Total files: $$(wc -l < git-tracked-files.txt)$(RESET)"

.PHONY: remotes
remotes:
	@echo "$(BLUE)Configuring git remotes...$(RESET)"
	@for remote in $(GIT_REMOTES); do \
		case $$remote in \
			origin) url="$(REMOTE_origin)" ;; \
		esac; \
		if git remote get-url $$remote >/dev/null 2>&1; then \
			echo "  $(YELLOW)⊙$(RESET) $$remote already exists ($$url)"; \
		else \
			git remote add $$remote $$url; \
			echo "  $(GREEN)✓$(RESET) Added $$remote → $$url"; \
		fi; \
	done
	@echo "$(GREEN)✓ Remotes configured$(RESET)"

.PHONY: push
push:
	@echo "$(BLUE)Pushing changes...$(RESET)"
	@for remote in $(GIT_REMOTES); do \
		echo "$(CYAN)• $$remote:$(RESET)"; \
		git push $$remote main && git push $$remote --tags; \
		echo "$(GREEN)✓ Pushed$(RESET)"; \
	done
