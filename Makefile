SHELL := /bin/bash
INFRA_DIR := infrastructure
SERVICES := traefik authelia syncthing xray hermes netdata backup

.PHONY: help status deploy deploy-infra test test-smoke logs backup-now backup-status

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

status: ## Status of all services
	@for svc in $(SERVICES); do \
	  echo "--- $$svc ---"; \
	  docker compose -f $(INFRA_DIR)/$$svc/docker-compose.yml ps 2>/dev/null || echo "not running"; \
	done

deploy: ## Deploy all services (careful!)
	@$(MAKE) deploy-infra

deploy-infra: ## Deploy infrastructure services in dependency order
	@for svc in $(SERVICES); do \
	  echo "Deploying $$svc..."; \
	  docker compose -f $(INFRA_DIR)/$$svc/docker-compose.yml pull --quiet; \
	  docker compose -f $(INFRA_DIR)/$$svc/docker-compose.yml up -d --remove-orphans; \
	  sleep 3; \
	done

test: ## Run all integration tests
	@for f in tests/integration/test_*.sh; do \
	  echo "Running $$f"; bash "$$f"; \
	done

test-smoke: ## Run smoke tests after deploy
	@bash tests/smoke/smoke_prod.sh

logs: ## Follow logs of all services
	@for svc in $(SERVICES); do \
	  docker compose -f $(INFRA_DIR)/$$svc/docker-compose.yml logs --tail=20 2>/dev/null & \
	done; wait

logs-s: ## Logs for one service: make logs-s SVC=traefik
	docker compose -f $(INFRA_DIR)/$(SVC)/docker-compose.yml logs -f

backup-now: ## Force backup right now
	docker exec $$(docker ps -q -f name=backup) /backup/scripts/backup.sh full

backup-status: ## Show last backup snapshots
	docker exec $$(docker ps -q -f name=backup) restic snapshots --last 5

task-new: ## Create new task from template: make task-new ID=NNN NAME="Task name"
	@echo "## TASK-$(ID): $(NAME)" >> $(PROJECT_DIR)/BACKLOG.md
	@echo "Created TASK-$(ID) in BACKLOG.md"

task-done: ## Archive current task
	@echo "Mark checboxes in CURRENT.md, then run: git add tasks/ && git commit -m 'chore(tasks): close TASK-XXX'"
