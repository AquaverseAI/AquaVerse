# AquaVerse AI — Developer Makefile
# All commands use the uv-managed venv automatically.
# Run: make <target>

VENV    := .venv
UV      := $(shell which uv 2>/dev/null || echo $(HOME)/.local/bin/uv)
PYTHON  := $(VENV)/bin/python
PIP     := $(UV) pip
ALEMBIC := $(VENV)/bin/alembic
PYTEST  := $(VENV)/bin/pytest
RUFF    := $(VENV)/bin/ruff
MYPY    := $(VENV)/bin/mypy
UVICORN := $(VENV)/bin/uvicorn

.DEFAULT_GOAL := help

# ─────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────

.PHONY: install
install: ## Install all production + dev dependencies via uv
	$(UV) venv $(VENV) --python 3.11 --clear
	$(PIP) install -r requirements-dev.txt
	@echo "\n✅ Done. Activate with: source $(VENV)/bin/activate"

.PHONY: install-prod
install-prod: ## Install production dependencies only
	$(UV) venv $(VENV) --python 3.11 --clear
	$(PIP) install -r requirements.txt

.PHONY: sync
sync: ## Sync venv with current requirements (fast, skips existing)
	$(PIP) install -r requirements-dev.txt

# ─────────────────────────────────────────────────────────
# Running
# ─────────────────────────────────────────────────────────

.PHONY: run
run: ## Start the dev server with hot-reload
	$(UVICORN) app.main:app --host 0.0.0.0 --port 8000 --reload --log-level info

.PHONY: run-prod
run-prod: ## Start the production server (2 workers, no reload)
	$(UVICORN) app.main:app --host 0.0.0.0 --port 8000 --workers 2

# ─────────────────────────────────────────────────────────
# Database
# ─────────────────────────────────────────────────────────

.PHONY: migrate
migrate: ## Run all pending Alembic migrations
	set -a; [ -f .env ] && . ./.env; set +a; $(ALEMBIC) upgrade head

.PHONY: migrate-down
migrate-down: ## Roll back the last migration
	set -a; [ -f .env ] && . ./.env; set +a; $(ALEMBIC) downgrade -1

.PHONY: seed
seed: ## Seed the database with test users and sample data
	set -a; [ -f .env ] && . ./.env; set +a; $(PYTHON) scripts/seed_db.py

.PHONY: db-setup
db-setup: migrate seed ## Run migrations + seed in one step

# ─────────────────────────────────────────────────────────
# Testing
# ─────────────────────────────────────────────────────────

.PHONY: test
test: ## Run all tests
	$(PYTEST) tests/ -v

.PHONY: test-unit
test-unit: ## Run unit tests only (no DB/Redis needed)
	$(PYTEST) tests/unit/ -m unit -v

.PHONY: test-integration
test-integration: ## Run integration tests (requires DB + Redis)
	$(PYTEST) tests/integration/ -v --timeout=120

.PHONY: test-cov
test-cov: ## Run unit tests with coverage report
	$(PYTEST) tests/unit/ -m unit --cov=app --cov-report=term-missing

# ─────────────────────────────────────────────────────────
# Linting / formatting
# ─────────────────────────────────────────────────────────

.PHONY: lint
lint: ## Run ruff linter
	$(RUFF) check app/ tests/ scripts/

.PHONY: lint-fix
lint-fix: ## Auto-fix ruff lint issues
	$(RUFF) check --fix app/ tests/ scripts/

.PHONY: format
format: ## Auto-format code with ruff
	$(RUFF) format app/ tests/ scripts/

.PHONY: typecheck
typecheck: ## Run mypy strict type check
	$(MYPY) --strict app/

.PHONY: check
check: lint typecheck ## Run lint + type check (CI equivalent)

# ─────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────

.PHONY: smoke
smoke: ## Run the number validator smoke test
	$(PYTHON) scripts/check_number_validator.py

.PHONY: clean
clean: ## Remove venv, caches, and build artifacts
	rm -rf $(VENV) .mypy_cache .ruff_cache .pytest_cache __pycache__ dist

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Python:  $(PYTHON)"
	@echo "  uv:      $(UV)"
