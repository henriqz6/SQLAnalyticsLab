#!/usr/bin/env sh
set -eu

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
RESULTS_DIR="$PROJECT_DIR/performance/results"
mkdir -p "$RESULTS_DIR"

if ! command -v docker >/dev/null 2>&1; then
  printf 'Docker é necessário para esta coleta no modo padrão.\n' >&2
  exit 1
fi

cd "$PROJECT_DIR"
./scripts/wait-for-mysql.sh

run_admin_file() {
  file_path="$1"
  docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot --database="$MYSQL_DATABASE" --show-warnings' < "$file_path"
}

collect_phase() {
  phase="$1"
  output_file="$RESULTS_DIR/${phase}.txt"
  : > "$output_file"
  for query_file in "$PROJECT_DIR"/performance/queries/*.sql; do
    query_name="$(basename "$query_file")"
    {
      printf '\n===== %s =====\n' "$query_name"
      printf 'EXPLAIN ANALYZE\n'
    } >> "$output_file"
    { printf 'EXPLAIN ANALYZE '; sed '/^[[:space:]]*--/d' "$query_file"; printf ';\n'; } |
      docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" --database="$MYSQL_DATABASE" --table' >> "$output_file"
  done
  printf 'Planos gravados em %s\n' "$output_file"
}

run_admin_file "$PROJECT_DIR/performance/drop_analytics_indexes.sql"
collect_phase before
run_admin_file "$PROJECT_DIR/performance/create_analytics_indexes.sql"
collect_phase after

printf 'Compare performance/results/before.txt e performance/results/after.txt. Os tempos são produzidos pelo seu ambiente, não pelo repositório.\n'
