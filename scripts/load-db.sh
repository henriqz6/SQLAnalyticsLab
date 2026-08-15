#!/usr/bin/env sh
set -eu

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DB_NAME="${MYSQL_DATABASE:-sql_analytics_lab}"
DB_USER="${MYSQL_USER:-analytics}"
DB_PASSWORD="${MYSQL_PASSWORD:-analytics_password}"
ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root_password}"
DB_HOST="${MYSQL_HOST:-}"
DB_PORT="${MYSQL_TCP_PORT:-3306}"

mysql_root() {
  if [ -n "$DB_HOST" ]; then
    MYSQL_PWD="$ROOT_PASSWORD" mysql --protocol=TCP -h "$DB_HOST" -P "$DB_PORT" -uroot --show-warnings "$@"
  else
    MYSQL_PWD="$ROOT_PASSWORD" mysql -uroot --show-warnings "$@"
  fi
}

run_file() {
  sql_file="$1"
  printf 'Carregando %s\n' "${sql_file#"$PROJECT_DIR"/}"
  mysql_root --database="$DB_NAME" < "$sql_file"
}

mysql_root -e "DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

for sql_file in "$PROJECT_DIR"/migrations/*.sql; do run_file "$sql_file"; done
for sql_file in "$PROJECT_DIR"/seeds/*.sql; do run_file "$sql_file"; done
for sql_file in "$PROJECT_DIR"/functions/*.sql; do run_file "$sql_file"; done
for sql_file in "$PROJECT_DIR"/procedures/*.sql; do run_file "$sql_file"; done
for sql_file in "$PROJECT_DIR"/triggers/*.sql; do run_file "$sql_file"; done
for sql_file in "$PROJECT_DIR"/views/*.sql; do run_file "$sql_file"; done

mysql_root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'; GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, SHOW VIEW ON \`$DB_NAME\`.* TO '$DB_USER'@'%'; FLUSH PRIVILEGES;"

printf 'Banco %s recriado com sucesso.\n' "$DB_NAME"
