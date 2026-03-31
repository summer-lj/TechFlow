#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
IMAGE_TAG="${2:-}"

if [[ -z "${ENVIRONMENT}" || -z "${IMAGE_TAG}" ]]; then
  echo "Usage: $0 <staging|production> <image-tag>"
  exit 1
fi

BASE_DIR="/srv/backend/${ENVIRONMENT}"
COMPOSE_FILE="${BASE_DIR}/compose/docker-compose.yml"
COMPOSE_ENV_FILE="${BASE_DIR}/env/compose.env"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Missing compose file: ${COMPOSE_FILE}"
  exit 1
fi

if [[ ! -f "${COMPOSE_ENV_FILE}" ]]; then
  echo "Missing compose env: ${COMPOSE_ENV_FILE}"
  exit 1
fi

if grep -q '^IMAGE_TAG=' "${COMPOSE_ENV_FILE}"; then
  sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=${IMAGE_TAG}/" "${COMPOSE_ENV_FILE}"
else
  echo "IMAGE_TAG=${IMAGE_TAG}" >> "${COMPOSE_ENV_FILE}"
fi

docker compose --env-file "${COMPOSE_ENV_FILE}" -f "${COMPOSE_FILE}" pull api
docker compose --env-file "${COMPOSE_ENV_FILE}" -f "${COMPOSE_FILE}" up -d --remove-orphans
docker compose --env-file "${COMPOSE_ENV_FILE}" -f "${COMPOSE_FILE}" ps
