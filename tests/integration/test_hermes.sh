#!/usr/bin/env bash
# tests/integration/test_hermes.sh
# TASK-032: Hermes integration tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

DOMAIN="${DOMAIN:-sttraiding.ru}"

test_hermes_protected_without_auth() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "https://hermes.${DOMAIN}")
  if [ "$status" = "302" ] || [ "$status" = "401" ]; then
    echo "  PASS: Hermes protected (status=$status)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: Hermes not protected (status=$status)"
    FAIL=$((FAIL + 1))
  fi
}

test_hermes_container_healthy() {
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=hermes)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$health" "Hermes container is healthy"
}

test_docker_proxy_healthy() {
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=docker-proxy)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$health" "Docker socket proxy is healthy"
}

test_obsidian_vault_mounted() {
  local result
  result=$(docker exec "$(docker ps -q -f name=hermes)" \
    ls /vault 2>/dev/null && echo "ok" || echo "fail")
  assert_equals "ok" "$result" "obsidian-vault mounted in Hermes"
}

echo "=== Hermes Integration Tests ==="
test_hermes_protected_without_auth
test_hermes_container_healthy
test_docker_proxy_healthy
test_obsidian_vault_mounted
summary
