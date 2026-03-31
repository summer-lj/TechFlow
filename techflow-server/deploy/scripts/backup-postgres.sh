#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-production}"
BASE_DIR="/srv/backend/${ENVIRONMENT}"
COMPOSE_FILE="${BASE_DIR}/compose/docker-compose.yml"
COMPOSE_ENV_FILE="${BASE_DIR}/env/compose.env"
RUNTIME_ENV_FILE="${BASE_DIR}/env/runtime.env"
BACKUP_DIR="${BASE_DIR}/backups/postgres"

if [[ ! -f "${COMPOSE_ENV_FILE}" || ! -f "${RUNTIME_ENV_FILE}" ]]; then
  echo "Missing compose or runtime env file for ${ENVIRONMENT}"
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

set -a
source "${COMPOSE_ENV_FILE}"
source "${RUNTIME_ENV_FILE}"
set +a

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_FILE="${BACKUP_DIR}/${ENVIRONMENT}-${TIMESTAMP}.sql.gz"

docker compose --env-file "${COMPOSE_ENV_FILE}" -f "${COMPOSE_FILE}" exec -T postgres \
  pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" | gzip > "${OUTPUT_FILE}"

find "${BACKUP_DIR}" -type f -name '*.sql.gz' -mtime +7 -delete

echo "Backup created: ${OUTPUT_FILE}"
