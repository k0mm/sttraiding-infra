#!/usr/bin/env bash
# tests/smoke/smoke_prod.sh
# Quick post-deploy smoke check for all services
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

DOMAIN="${DOMAIN:-sttraiding.ru}"

check_https() {
  local name="$1" url="$2"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")
  if [ "$status" -ge 200 ] && [ "$status" -lt 500 ]; then
    echo "  PASS: $name reachable (status=$status)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name unreachable (status=$status)"
    FAIL=$((FAIL + 1))
  fi
}

check_container() {
  local name="$1"
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name="$name")" 2>/dev/null || echo "unknown")
  if [ "$health" = "healthy" ] || [ "$health" = "starting" ]; then
    echo "  PASS: $name ($health)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name ($health)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Smoke Tests: sttraiding.ru ==="
echo ""
echo "-- HTTPS endpoints --"
check_https "traefik-redirect"  "http://${DOMAIN}"
check_https "auth"              "https://auth.${DOMAIN}/api/health"
check_https "syncthing"        "https://syncthing.${DOMAIN}"
check_https "netdata"          "https://netdata.${DOMAIN}"
check_https "hermes"           "https://hermes.${DOMAIN}"

echo ""
echo "-- Container health --"
check_container "traefik"
check_container "authelia"
check_container "redis"
check_container "syncthing"
check_container "xray"
check_container "hermes"
check_container "netdata"
check_container "backup"

summary
