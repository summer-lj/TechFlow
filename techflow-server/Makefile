SHELL := /bin/bash
COMPOSE := docker compose

.PHONY: init up down logs shell migrate seed lint typecheck test test-e2e build deploy-staging deploy-production

init:
	@if [ ! -f .env.local ]; then cp .env.example .env.local; fi
	$(COMPOSE) up -d postgres redis mailpit
	$(COMPOSE) run --rm api sh -lc "pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile"
	$(COMPOSE) run --rm api pnpm --filter @backend/api prisma:generate
	$(COMPOSE) run --rm api pnpm --filter @backend/api prisma:migrate:deploy
	$(COMPOSE) run --rm api pnpm --filter @backend/api prisma:seed
	$(COMPOSE) up -d api

up:
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down --remove-orphans

logs:
	$(COMPOSE) logs -f api

shell:
	$(COMPOSE) exec api sh

migrate:
	$(COMPOSE) exec api pnpm --filter @backend/api prisma:migrate:deploy

seed:
	$(COMPOSE) exec api pnpm --filter @backend/api prisma:seed

lint:
	pnpm lint

typecheck:
	pnpm typecheck

test:
	pnpm test

test-e2e:
	pnpm test:e2e

build:
	pnpm build

deploy-staging:
	@echo "Use GitHub Actions deploy.yml on main branch to deploy staging."

deploy-production:
	@echo "Use GitHub Actions deploy.yml workflow_dispatch with a validated image tag."
