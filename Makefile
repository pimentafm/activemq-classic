.PHONY: help up down restart logs status clean shell exec console ps pull health start stop rebuild

# Output colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Configuration
COMPOSE := docker compose
SERVICE := activemq
CONSOLE_URL := http://localhost:8161

help: ## Show this help message
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)  ActiveMQ Classic - Docker Compose Manager$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Available Commands:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Usage examples:$(NC)"
	@echo "  make up          $(BLUE)→$(NC) Start ActiveMQ"
	@echo "  make logs        $(BLUE)→$(NC) Follow logs"
	@echo "  make console     $(BLUE)→$(NC) Open web console"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

up: ## Start ActiveMQ in background
	@echo "$(GREEN)⚡ Starting ActiveMQ...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)✓ ActiveMQ started successfully!$(NC)"
	@echo "$(YELLOW)→ Web Console: $(CONSOLE_URL)$(NC)"
	@echo "$(YELLOW)→ Use 'make logs' to view logs$(NC)"

down: ## Stop and remove containers
	@echo "$(RED)⚠ Stopping ActiveMQ...$(NC)"
	@$(COMPOSE) down
	@echo "$(GREEN)✓ ActiveMQ stopped$(NC)"

start: ## Start already created containers
	@echo "$(GREEN)▶ Starting containers...$(NC)"
	@$(COMPOSE) start
	@echo "$(GREEN)✓ Containers started$(NC)"

stop: ## Stop containers without removing them
	@echo "$(YELLOW)⏸ Stopping containers...$(NC)"
	@$(COMPOSE) stop
	@echo "$(GREEN)✓ Containers stopped$(NC)"

restart: ## Restart ActiveMQ
	@echo "$(YELLOW)🔄 Restarting ActiveMQ...$(NC)"
	@$(COMPOSE) restart
	@echo "$(GREEN)✓ ActiveMQ restarted$(NC)"

logs: ## Show ActiveMQ logs (follow mode)
	@echo "$(BLUE)📋 ActiveMQ logs (Ctrl+C to exit):$(NC)"
	@$(COMPOSE) logs -f $(SERVICE)

logs-tail: ## Show last 100 lines of logs
	@$(COMPOSE) logs --tail=100 $(SERVICE)

status: ## Show container status
	@echo "$(BLUE)📊 Container status:$(NC)"
	@$(COMPOSE) ps

ps: status ## Alias for status

health: ## Check container health
	@echo "$(BLUE)🏥 Checking ActiveMQ health...$(NC)"
	@docker inspect --format='{{.State.Health.Status}}' activemq 2>/dev/null || echo "$(RED)Container is not running$(NC)"
	@echo ""
	@echo "$(BLUE)Complete details:$(NC)"
	@docker inspect --format='{{json .State.Health}}' activemq 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "$(YELLOW)Install python3 for JSON formatting$(NC)"

shell: ## Open shell in container (bash)
	@echo "$(GREEN)🐚 Opening shell in container...$(NC)"
	@$(COMPOSE) exec $(SERVICE) /bin/bash

exec: ## Execute command in container (use: make exec CMD="your command")
	@$(COMPOSE) exec $(SERVICE) $(CMD)

console: ## Open web console in browser
	@echo "$(GREEN)🌐 Opening web console...$(NC)"
	@echo "$(YELLOW)URL: $(CONSOLE_URL)$(NC)"
	@echo "$(YELLOW)Username: admin | Password: admin$(NC)"
	@if command -v xdg-open > /dev/null; then \
		xdg-open $(CONSOLE_URL); \
	elif command -v open > /dev/null; then \
		open $(CONSOLE_URL); \
	else \
		echo "$(RED)Could not open browser automatically$(NC)"; \
		echo "$(YELLOW)Access manually: $(CONSOLE_URL)$(NC)"; \
	fi

pull: ## Update ActiveMQ image
	@echo "$(BLUE)⬇ Downloading latest ActiveMQ version...$(NC)"
	@$(COMPOSE) pull
	@echo "$(GREEN)✓ Image updated$(NC)"

rebuild: ## Rebuild and restart container
	@echo "$(YELLOW)🔨 Rebuilding containers...$(NC)"
	@$(COMPOSE) up -d --build --force-recreate
	@echo "$(GREEN)✓ Containers rebuilt$(NC)"

clean: ## Stop containers and remove volumes (WARNING: deletes data!)
	@echo "$(RED)⚠️  WARNING: This will remove ALL ActiveMQ data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(RED)🗑 Removing containers and volumes...$(NC)"; \
		$(COMPOSE) down -v; \
		echo "$(GREEN)✓ Cleanup completed$(NC)"; \
	else \
		echo "$(YELLOW)Operation cancelled$(NC)"; \
	fi

clean-force: ## Remove containers and volumes WITHOUT confirmation
	@echo "$(RED)🗑 Removing containers and volumes...$(NC)"
	@$(COMPOSE) down -v
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

info: ## Show environment information
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)  Environment Information$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(YELLOW)Web Console:$(NC)      $(CONSOLE_URL)"
	@echo "$(YELLOW)OpenWire (JMS):$(NC)   tcp://localhost:61616"
	@echo "$(YELLOW)AMQP:$(NC)             tcp://localhost:5672"
	@echo "$(YELLOW)STOMP:$(NC)            tcp://localhost:61613"
	@echo "$(YELLOW)MQTT:$(NC)             tcp://localhost:1883"
	@echo "$(YELLOW)WebSocket:$(NC)        ws://localhost:61614"
	@echo ""
	@echo "$(YELLOW)Default credentials:$(NC)"
	@echo "  Username: admin"
	@echo "  Password: admin"
	@echo ""
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

test-connection: ## Test connection to ActiveMQ
	@echo "$(BLUE)🔌 Testing connection to ActiveMQ...$(NC)"
	@echo ""
	@echo "$(YELLOW)Testing Web Console (port 8161):$(NC)"
	@curl -s -o /dev/null -w "Status: %{http_code}\n" $(CONSOLE_URL) || echo "$(RED)Failed$(NC)"
	@echo ""
	@echo "$(YELLOW)Testing OpenWire port (61616):$(NC)"
	@timeout 2 bash -c 'cat < /dev/null > /dev/tcp/localhost/61616' 2>/dev/null && echo "$(GREEN)✓ Port accessible$(NC)" || echo "$(RED)✗ Port not accessible$(NC)"

install: ## First setup - create .env and start ActiveMQ
	@echo "$(GREEN)🚀 Initial ActiveMQ setup...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Creating .env file...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)✓ .env file created$(NC)"; \
	else \
		echo "$(YELLOW).env file already exists$(NC)"; \
	fi
	@echo ""
	@make up
	@echo ""
	@make info

update: pull rebuild ## Update image and rebuild containers

stats: ## Show resource usage statistics
	@echo "$(BLUE)📊 Resource statistics:$(NC)"
	@docker stats --no-stream activemq 2>/dev/null || echo "$(RED)Container is not running$(NC)"
