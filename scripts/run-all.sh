#!/usr/bin/env sh
set -eu

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$PROJECT_DIR"

./scripts/reset.sh
./scripts/run-tests.sh

printf 'Criação, seed e testes concluídos do zero.\n'
