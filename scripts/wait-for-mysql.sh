#!/usr/bin/env sh
set -eu

attempt=1
while [ "$attempt" -le 40 ]; do
  if docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqladmin ping -uroot --silent' >/dev/null 2>&1; then
    printf 'MySQL está saudável.\n'
    exit 0
  fi
  printf 'Aguardando MySQL (%s/40)...\n' "$attempt"
  attempt=$((attempt + 1))
  sleep 2
done

printf 'MySQL não ficou disponível no tempo esperado.\n' >&2
exit 1
