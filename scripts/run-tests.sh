#!/usr/bin/env sh
set -eu

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DB_NAME="${MYSQL_DATABASE:-sql_analytics_lab}"
ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root_password}"
DB_HOST="${MYSQL_HOST:-}"
DB_PORT="${MYSQL_TCP_PORT:-3306}"

run_local() {
  for sql_file in "$PROJECT_DIR"/tests/*.sql; do
    printf 'Executando %s\n' "${sql_file#"$PROJECT_DIR"/}"
    MYSQL_PWD="$ROOT_PASSWORD" mysql --protocol=TCP -h "$DB_HOST" -P "$DB_PORT" -uroot --database="$DB_NAME" --show-warnings < "$sql_file"
  done
  for query_group in basic intermediate advanced; do
    for sql_file in "$PROJECT_DIR"/queries/"$query_group"/*.sql; do
      printf 'Validando %s\n' "${sql_file#"$PROJECT_DIR"/}"
      MYSQL_PWD="$ROOT_PASSWORD" mysql --protocol=TCP -h "$DB_HOST" -P "$DB_PORT" -uroot --database="$DB_NAME" --batch --skip-column-names < "$sql_file" >/dev/null
    done
  done
}

if [ -n "$DB_HOST" ]; then
  run_local
else
  cd "$PROJECT_DIR"
  docker compose exec -T mysql sh -c '
    set -eu
    for sql_file in /workspace/tests/*.sql; do
      printf "Executando %s\n" "${sql_file#/workspace/}"
      MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot --database="$MYSQL_DATABASE" --show-warnings < "$sql_file"
    done
    for query_group in basic intermediate advanced; do
      for sql_file in /workspace/queries/$query_group/*.sql; do
        printf "Validando %s\n" "${sql_file#/workspace/}"
        MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot --database="$MYSQL_DATABASE" --batch --skip-column-names < "$sql_file" >/dev/null
      done
    done
  '
fi

printf 'Todos os testes SQL foram aprovados.\n'
