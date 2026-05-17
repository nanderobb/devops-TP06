#!/bin/bash

set -uo pipefail

BASE_URL="${1:-http://localhost}"
ERRORS=0

ok() {
    echo "[OK] $1"
}

fail() {
    echo "[FAIL] $1"
    ERRORS=$((ERRORS+1))
}

echo "=== Healthcheck del stack Docker Compose ==="
echo

echo "--- Servicios Docker ---"

for svc in notes-db notes-backend notes-frontend; do
    STATUS=$(sudo docker inspect --format='{{.State.Status}}' "$svc" 2>/dev/null || echo "no encontrado")

    if [ "$STATUS" = "running" ]; then
        ok "$svc → running"
    else
        fail "$svc → $STATUS"
    fi
done

echo
echo "--- Endpoints HTTP ---"

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")

if [ "$HTTP" = "200" ]; then
    ok "GET /health → 200"
else
    fail "GET /health → $HTTP"
fi

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/notes")

if [ "$HTTP" = "200" ]; then
    ok "GET /api/notes → 200"
else
    fail "GET /api/notes → $HTTP"
fi

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/")

if [ "$HTTP" = "200" ]; then
    ok "GET / (frontend) → 200"
else
    fail "GET / → $HTTP"
fi

echo
echo "--- Resultado final ---"

if [ "$ERRORS" -eq 0 ]; then
    echo "Stack OK — todos los checks pasaron"
else
    echo "$ERRORS checks fallaron"
fi
