#!/usr/bin/env bash
set -euo pipefail

wait_for_port() {
  local host="$1"
  local port="$2"

  until nc -z "${host}" "${port}"; do
    echo "Waiting for ${host}:${port}..."
    sleep 1
  done
}

pnpm config set store-dir /pnpm/store >/dev/null 2>&1 || true

wait_for_port "${DATABASE_HOST:-postgres}" "${DATABASE_PORT:-5432}"
wait_for_port "${REDIS_HOST:-redis}" "${REDIS_PORT:-6379}"

pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile
pnpm --filter @backend/api prisma:generate

if [[ "${AUTO_MIGRATE:-false}" == "true" ]]; then
  pnpm --filter @backend/api prisma:migrate:deploy
fi

if [[ "${AUTO_SEED:-false}" == "true" ]]; then
  pnpm --filter @backend/api prisma:seed
fi

exec "$@"
