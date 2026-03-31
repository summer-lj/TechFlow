#!/usr/bin/env bash
set -euo pipefail

BASE_DIR=/srv/backend
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_TEMPLATE="${SCRIPT_DIR}/../compose/server-compose.yml"
NGINX_TEMPLATE="${SCRIPT_DIR}/../nginx/backend-ip.conf"

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    return
  fi

  run_as_root apt-get update
  run_as_root apt-get install -y ca-certificates curl gnupg lsb-release
  run_as_root install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_as_root gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  run_as_root chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    run_as_root tee /etc/apt/sources.list.d/docker.list >/dev/null

  run_as_root apt-get update
  run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  run_as_root systemctl enable --now docker

  if [[ -n "${SUDO_USER:-}" ]]; then
    run_as_root usermod -aG docker "${SUDO_USER}"
  fi
}

install_nginx() {
  run_as_root apt-get update
  run_as_root apt-get install -y nginx logrotate
  run_as_root systemctl enable --now nginx
}

prepare_directories() {
  run_as_root mkdir -p "${BASE_DIR}/staging/compose" "${BASE_DIR}/staging/env" "${BASE_DIR}/staging/data/postgres" "${BASE_DIR}/staging/data/redis" "${BASE_DIR}/staging/backups/postgres"
  run_as_root mkdir -p "${BASE_DIR}/production/compose" "${BASE_DIR}/production/env" "${BASE_DIR}/production/data/postgres" "${BASE_DIR}/production/data/redis" "${BASE_DIR}/production/backups/postgres"
  run_as_root cp "${COMPOSE_TEMPLATE}" "${BASE_DIR}/staging/compose/docker-compose.yml"
  run_as_root cp "${COMPOSE_TEMPLATE}" "${BASE_DIR}/production/compose/docker-compose.yml"
}

install_nginx_config() {
  run_as_root cp "${NGINX_TEMPLATE}" /etc/nginx/sites-available/backend-ip.conf
  run_as_root ln -sf /etc/nginx/sites-available/backend-ip.conf /etc/nginx/sites-enabled/backend-ip.conf
  run_as_root rm -f /etc/nginx/sites-enabled/default
  run_as_root nginx -t
  run_as_root systemctl reload nginx
}

install_logrotate() {
  cat <<'EOF' | run_as_root tee /etc/logrotate.d/backend-nginx >/dev/null
/var/log/nginx/*.log {
  daily
  missingok
  rotate 14
  compress
  delaycompress
  notifempty
  create 0640 www-data adm
  sharedscripts
  postrotate
    [ -s /run/nginx.pid ] && kill -USR1 "$(cat /run/nginx.pid)"
  endscript
}
EOF
}

main() {
  install_docker
  install_nginx
  prepare_directories
  install_nginx_config
  install_logrotate

  echo "Bootstrap completed."
  echo "Next: create compose.env and runtime.env under ${BASE_DIR}/staging/env and ${BASE_DIR}/production/env."
}

main "$@"
