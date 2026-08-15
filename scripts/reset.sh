#!/usr/bin/env sh
set -eu

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$PROJECT_DIR"

if [ -n "${MYSQL_HOST:-}" ]; then
  exec ./scripts/load-db.sh
fi

if ! command -v docker >/dev/null 2>&1; then
  printf 'Docker não encontrado. Defina MYSQL_HOST e tenha o cliente mysql instalado, ou use Docker.\n' >&2
  exit 1
fi

docker compose up -d mysql
./scripts/wait-for-mysql.sh
docker compose exec -T mysql /workspace/scripts/load-db.sh
