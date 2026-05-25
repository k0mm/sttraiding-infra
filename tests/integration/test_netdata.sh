#!/usr/bin/env bash
# tests/integration/test_netdata.sh
# TASK-033: Netdata integration tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

DOMAIN="${DOMAIN:-sttraiding.ru}"

test_netdata_protected_without_auth() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "https://netdata.${DOMAIN}")
  if [ "$status" = "302" ] || [ "$status" = "401" ]; then
    echo "  PASS: Netdata protected (status=$status)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: Netdata not protected (status=$status)"
    FAIL=$((FAIL + 1))
  fi
}

test_netdata_container_healthy() {
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=netdata)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$health" "Netdata container is healthy"
}

test_netdata_api_internal() {
  # Run from server — direct access to container
  local status
  status=$(docker exec "$(docker ps -q -f name=netdata)" \
    curl -sf -o /dev/null -w "%{http_code}" http://localhost:19999/api/v1/info \
    2>/dev/null || echo "000")
  assert_equals "200" "$status" "Netdata API /v1/info returns 200 internally"
}

echo "=== Netdata Integration Tests ==="
test_netdata_protected_without_auth
test_netdata_container_healthy
test_netdata_api_internal
summary
