#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"
COOKIE_JAR="${COOKIE_JAR:-/tmp/ecommerce-api-cookies.txt}"
EMAIL="${EMAIL:-ana-example-$(date +%s)@example.com}"

curl -sS -c "$COOKIE_JAR" -b "$COOKIE_JAR" -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ana Pérez\",\"email\":\"$EMAIL\",\"password\":\"Ana-password-123\"}"
printf '\n\nCatálogo:\n'
curl -sS "$BASE_URL/products/?limit=10&offset=0"
printf '\n\nOrden de visitante:\n'
curl -sS -X POST "$BASE_URL/orders/guest" \
  -H "Content-Type: application/json" \
  -d '{"items":[{"product_id":1,"quantity":1}]}'
printf '\n'
