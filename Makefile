# Variables
DOCKER_COMPOSE = docker compose

.PHONY: help up down restart logs ps pull clean

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start the stack in detached mode
	$(DOCKER_COMPOSE) up -d

down: ## Stop the stack and remove containers
	$(DOCKER_COMPOSE) down

restart: down up ## Restart the stack

logs: ## Follow the logs of all services
	$(DOCKER_COMPOSE) logs -f

ps: ## List running containers
	$(DOCKER_COMPOSE) ps

pull: ## Pull the latest images
	$(DOCKER_COMPOSE) pull
                  
clean: ## Stop and remove containers, networks, and volumes
	$(DOCKER_COMPOSE) down -v
